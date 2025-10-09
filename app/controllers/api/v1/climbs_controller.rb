module Api
  module V1
    class ClimbsController < BaseController
      before_action :set_climb, only: [:show, :update, :destroy, :complete]
      before_action :check_climb_ownership, only: [:show, :update, :destroy, :complete]

      def index
        climbs = Climb.where(user: current_user).order(climbed_at: :desc).includes(:place, :route_sets)

        render json: ClimbsPresenter.new(climbs, current_user).present
      end

      def show
        climbed_route_sets = Route.where(id: @climb.route_states.select(&:tried?).map(&:route_id)).map(&:route_set_id).uniq
        routes = RouteSet.find(climbed_route_sets).map { |route_set| [route_set.id, route_set.routes] }.to_h
        route_sets = RouteSet.find(routes.keys)

        render json: {
          climb: ClimbPresenter.new(@climb).present_with_route_states_and_routes(routes: routes, route_sets: route_sets.map do |rs|
            {
              id: rs.id,
              name: rs.name,
              grade: rs.grade,
              floorplan: {
                id: rs.floorplan.id,
                name: rs.floorplan.name,
                images: rs.floorplan.floorplan_images.map do |fp_image|
                  {
                    id: fp_image.id,
                    name: fp_image.name,
                    order: fp_image.order,
                    uri: fp_image.image.url
                  }
                end
              }
            }
          end),
        }
      end

      def current
        current_climb = Climb.where(user: current_user, current: true).first

        if current_climb
          render json: { climb: ClimbPresenter.new(current_climb).present }
        else
          render json: { climb: nil }
        end
      end

      def create
        pp params
        route_state_json = create_params[:route_sets].map { |rs| rs[:route_states] }.flatten.map do |route_state|
          RouteStatus.new(
            route_state[:route_id].to_i,
            route_state[:status]
          )
        end

        climb = Climb.new(
          climbed_at: create_params[:climbed_at],
          user: current_user,
          route_sets: RouteSet.where(id: create_params[:route_sets].map { |rs| rs[:id] }),
          route_state_json: route_state_json,
          place: Place.find(create_params[:place_id]),
          current: true
        )

        if climb.save
          render json: { climb: ClimbPresenter.new(climb).present }, status: :created
        else
          render json: { error: climb.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        route_states = params[:route_states]&.map do |route_state|
          RouteStatus.new(
            route_state[:route_id].to_i,
            route_state[:status]
          )
        end

        @climb.route_state_json = route_states || []

        if @climb.save
          render json: { climb: ClimbPresenter.new(@climb).present_with_route_states }
        else
          render json: { error: @climb.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def complete
        if @climb.update(current: false)
          render json: { climb: ClimbPresenter.new(@climb).present }
        else
          render json: { error: @climb.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        if @climb.destroy
          render json: { message: 'Climb deleted successfully' }
        else
          render json: { error: 'Failed to delete climb' }, status: :unprocessable_entity
        end
      end

      private


      def set_climb
        @climb = Climb.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Climb not found' }, status: :not_found
      end

      def check_climb_ownership
        unless @climb&.user == current_user
          render json: { error: 'Access denied' }, status: :forbidden
        end
      end

      def create_params
        @create_params ||= params.permit([
          :climbed_at,
          :place_id,
          route_sets: [
            :id,
            route_states: [
              :route_id,
              :status
            ]
          ]
        ])
      end
    end
  end
end