module Api
  module V1
    class RouteSetsController < BaseController
      before_action :set_user
      before_action :set_place
      before_action :set_route_set, only: [:show, :update, :destroy]
      before_action :ensure_can_edit, only: [:create, :update, :destroy]

      def index
        # Get active (most recent) route set for each grade
        active_route_sets = @place.grades.map(&:active_route_set).compact
          .sort_by { |route_set| -route_set.added.to_i }

        # Get past route sets (all except the most recent for each grade)
        old_route_sets = @place.grades.map(&:past_route_sets).flatten.compact

        render json: {
          active_route_sets: serialize_route_sets(active_route_sets),
          past_route_sets: serialize_route_sets(old_route_sets)
        }
      end

      def show
        # Get user's climbing history for this route set's routes
        route_states = Climb.where(user: @user).map(&:route_states).flatten
        climbed_route_ids = route_states.select(&:tried?).map(&:route_id)
        climbed_routes = @route_set.routes.where(id: climbed_route_ids)

        render json: {
          route_set: serialize_route_set_detail(@route_set),
          routes: serialize_routes(@route_set.routes),
          climbed_routes: serialize_routes(climbed_routes),
          user_route_states: route_states.select { |rs|
            @route_set.routes.pluck(:id).include?(rs.route_id)
          }.map { |rs|
            { route_id: rs.route_id, status: rs.status }
          }
        }
      end

      def create
        route_set = RouteSet.new(
          grade_id: params[:grade_id],
          added: params[:added] || Date.today,
          place: @place
        )

        if route_set.save
          render json: {
            route_set: serialize_route_set_detail(route_set)
          }, status: :created
        else
          render json: { error: route_set.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        update_params = {}

        begin
          update_params[:expires_at] = Date.parse(params[:expires_at]) if params[:expires_at].present?
          update_params[:added] = Date.parse(params[:added]) if params[:added].present?
        rescue Date::Error => e
          return render json: { error: "Invalid date format: #{e.message}" }, status: :unprocessable_entity
        end

        if @route_set.update(update_params)
          render json: {
            route_set: serialize_route_set_detail(@route_set)
          }
        else
          render json: { error: @route_set.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        if @route_set.destroy
          render json: { message: 'Route set deleted successfully' }
        else
          render json: { error: 'Failed to delete route set' }, status: :unprocessable_entity
        end
      end

      private

      def set_user
        auth0_sub = current_user['sub'] if current_user
        @user = User.find_or_create_by(google_uid: auth0_sub) do |user|
          user.token = SecureRandom.hex(16)
        end
      end

      def set_place
        # Priority: explicit place_id param > route_set's place > user's current place
        if params[:place_id].present?
          @place = Place.find(params[:place_id])
        elsif params[:id].present? && action_name != 'create'
          route_set = RouteSet.find_by(id: params[:id])
          if route_set
            @place = route_set.place
          else
            return render json: { error: 'Route set not found' }, status: :not_found
          end
        else
          @place = @user.place
        end

        if @place.nil?
          render json: { error: 'No place selected or found' }, status: :unprocessable_entity
        end
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Place not found' }, status: :not_found
      end

      def set_route_set
        @route_set = RouteSet.find(params[:id])
        # Allow access to route sets from other places for viewing
        # Permission check is in ensure_can_edit for modifications
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Route set not found' }, status: :not_found
      end

      def ensure_can_edit
        unless @user.admin || @place.can_edit?(@user)
          render json: { error: 'You do not have permission to modify route sets at this place' }, status: :forbidden
        end
      end

      def serialize_route_sets(route_sets)
        route_sets.map { |rs| serialize_route_set_summary(rs) }
      end

      def serialize_route_set_summary(route_set)
        {
          id: route_set.id,
          name: route_set.name,
          added: route_set.added,
          expires_at: route_set.expires_at,
          route_count: route_set.routes.count,
          grade: {
            id: route_set.grade.id,
            name: route_set.grade.name,
            grade: route_set.grade.grade,
            map_tint_colour: route_set.grade.map_tint_colour
          }
        }
      end

      def serialize_route_set_detail(route_set)
        serialize_route_set_summary(route_set).merge(
          place: {
            id: route_set.place.id,
            name: route_set.place.name
          },
          can_edit: route_set.can_edit?(@user),
          created_at: route_set.created_at,
          updated_at: route_set.updated_at
        )
      end

      def serialize_routes(routes)
        routes.map do |route|
          {
            id: route.id,
            pos_x: route.pos_x,
            pos_y: route.pos_y,
            floor: route.floor,
            added: route.added
          }
        end
      end
    end
  end
end