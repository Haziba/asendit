module Api
  module V1
    class RouteSetsController < BaseController
      before_action :set_place
      before_action :set_route_set, only: [:show, :update, :destroy]
      before_action :ensure_can_edit, only: [:create, :update, :destroy]

      def index
        # Get active (most recent) route set for each grade
        active_route_sets = @place.grades.map(&:active_route_set).compact
          .sort_by { |route_set| -route_set.added.to_i }

        # Get past route sets (all except the most recent for each grade)
        old_route_sets = @place.grades.map(&:past_route_sets).flatten.compact

        render json: RouteSetsPresenter.new([], current_user).present_grouped_by_status(active_route_sets, old_route_sets)
      end

      def show
        # Get user's climbing history for this route set's routes
        route_states = Climb.where(user: current_user).map(&:route_states).flatten
        climbed_route_ids = route_states.select(&:tried?).map(&:route_id)
        climbed_routes = @route_set.routes.where(id: climbed_route_ids)

        render json: {
          route_set: RouteSetPresenter.new(@route_set, current_user).present_with_details,
          routes: @route_set.routes.map { |route| RoutePresenter.new(route, current_user).present_summary },
          climbed_routes: climbed_routes.map { |route| RoutePresenter.new(route, current_user).present_summary },
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
            route_set: RouteSetPresenter.new(route_set, current_user).present_with_details
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
            route_set: RouteSetPresenter.new(@route_set, current_user).present_with_details
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
          @place = current_user.place
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
        unless current_user.admin || @place.can_edit?(current_user)
          render json: { error: 'You do not have permission to modify route sets at this place' }, status: :forbidden
        end
      end

    end
  end
end