module Api
  module V1
    class RoutesController < BaseController
      before_action :set_user
      before_action :set_route, only: [:show, :destroy]
      before_action :check_route_access, only: [:show, :destroy]

      def index
        # Return routes for a specific route_set if provided
        if params[:route_set_id]
          route_set = RouteSet.find(params[:route_set_id])
          routes = route_set.routes.includes(:route_set)
        else
          # Return all routes for user's place
          routes = Route.joins(route_set: :place).where(places: { id: @user.place_id }).includes(:route_set)
        end

        render json: RoutesPresenter.new(routes, @user).present
      end

      def show
        render json: {
          route: RoutePresenter.new(@route, @user).present
        }
      end

      def create
        route_set = RouteSet.find(params[:route_set_id])

        # Check if user has access to this route set's place
        unless route_set.place == @user.place
          return render json: { error: 'Access denied' }, status: :forbidden
        end

        route = Route.new(
          pos_x: params[:pos_x],
          pos_y: params[:pos_y],
          floor: params[:floor],
          route_set: route_set,
          added: Time.now
        )

        if route.save
          render json: {
            route: RoutePresenter.new(route, @user).present
          }, status: :created
        else
          render json: { error: route.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        if @route.destroy
          render json: { message: 'Route deleted successfully' }
        else
          render json: { error: 'Failed to delete route' }, status: :unprocessable_entity
        end
      end

      private

      def set_user
        # Map Auth0 user to actual User record
        auth0_sub = current_user['sub'] if current_user
        @user = User.find_or_create_by(google_uid: auth0_sub) do |user|
          user.token = SecureRandom.hex(16)
        end
      end

      def set_route
        @route = Route.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Route not found' }, status: :not_found
      end

      def check_route_access
        # User can only access routes at their current place
        unless @route&.route_set&.place == @user.place
          render json: { error: 'Access denied' }, status: :forbidden
        end
      end
    end
  end
end