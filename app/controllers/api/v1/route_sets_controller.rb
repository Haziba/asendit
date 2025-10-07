module Api
  module V1
    class RouteSetsController < BaseController
      before_action :set_route_set, only: [:show, :update, :destroy]
      before_action :set_place
      before_action :set_grade
      before_action :ensure_can_edit, only: [:create, :update, :destroy]

      def index
        route_sets = @grade.route_sets.order(added: :desc)
        render json: RouteSetsPresenter.new(route_sets, current_user).present
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
          grade: @grade,
          added: params[:added] || Date.today,
          place: @place
        )

        if route_set.save
          create_routes_for_route_set(route_set) if params[:routes].present?

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
          create_routes_for_route_set(@route_set) if params[:routes].present?

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
        if @route_set
          @place = @route_set.place
        elsif params[:place_id].present?
          @place = Place.find(params[:place_id])
        elsif params[:grade_id].present?
          # For /grades/:grade_id/route_sets routes
          grade = Grade.find(params[:grade_id])
          @place = grade.place
        elsif params[:id].present?
          # For /route_sets/:id routes
          route_set = RouteSet.find(params[:id])
          @place = route_set.place
        else
          @place = current_user.place
        end
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Place not found' }, status: :not_found
      end

      def set_grade
        if @route_set
          @grade = @route_set.grade
        elsif params[:grade_id].present?
          @grade = Grade.find(params[:grade_id])
        elsif @place
          # For nested routes, we need grade_id in params
          return render json: { error: 'Grade ID required' }, status: :bad_request unless params[:grade_id]
        end
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Grade not found' }, status: :not_found
      end

      def set_route_set
        @route_set = RouteSet.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Route set not found' }, status: :not_found
      end

      def ensure_can_edit
        unless current_user.admin || @place.can_edit?(current_user)
          render json: { error: 'You do not have permission to modify route sets at this place' }, status: :forbidden
        end
      end

      def create_routes_for_route_set(route_set)
        return unless params[:routes].is_a?(Array)

        params[:routes].each do |route_params|
          route_set.routes.create(
            pos_x: route_params[:pos_x],
            pos_y: route_params[:pos_y],
            floorplan_image_id: route_params[:floorplan_image_id],
            added: route_params[:added] || route_set.added || Date.today
          )
        end
      end

    end
  end
end