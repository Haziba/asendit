module Api
  module V1
    class ClimbsController < BaseController
      before_action :set_user
      before_action :set_climb, only: [:show, :update, :destroy, :complete]
      before_action :check_climb_ownership, only: [:show, :update, :destroy, :complete]

      def index
        climbs = Climb.where(user: @user).order(climbed_at: :desc).includes(:place, :route_sets)

        render json: {
          climbs: climbs.map do |climb|
            {
              id: climb.id,
              name: climb.name,
              climbed_at: climb.climbed_at,
              current: climb.current,
              success_percentage: climb.success_percentage,
              place: {
                id: climb.place.id,
                name: climb.place.name
              }
            }
          end
        }
      end

      def show
        climbed_route_sets = Route.where(id: @climb.route_states.select(&:tried?).map(&:route_id)).map(&:route_set_id).uniq
        routes = RouteSet.find(climbed_route_sets).map { |route_set| [route_set.id, route_set.routes] }.to_h
        route_sets = RouteSet.find(routes.keys)

        render json: {
          climb: {
            id: @climb.id,
            name: @climb.name,
            climbed_at: @climb.climbed_at,
            current: @climb.current,
            success_percentage: @climb.success_percentage,
            place: {
              id: @climb.place.id,
              name: @climb.place.name
            },
            route_states: @climb.route_states.map do |route_state|
              {
                route_id: route_state.route_id,
                status: route_state.status
              }
            end
          },
          routes: routes,
          route_sets: route_sets.map do |rs|
            {
              id: rs.id,
              name: rs.name,
              grade: rs.grade
            }
          end
        }
      end

      def current
        current_climb = Climb.where(user: @user, current: true).first

        if current_climb
          render json: {
            climb: {
              id: current_climb.id,
              name: current_climb.name,
              climbed_at: current_climb.climbed_at,
              current: current_climb.current
            }
          }
        else
          render json: { climb: nil }
        end
      end

      def create
        existing_current = Climb.where(user: @user, current: true).first

        if existing_current
          return render json: {
            error: 'You already have an active climb session',
            current_climb: {
              id: existing_current.id,
              name: existing_current.name,
              climbed_at: existing_current.climbed_at
            }
          }, status: :unprocessable_entity
        end

        place = @user.place
        return render json: { error: 'No place selected' }, status: :unprocessable_entity unless place

        active_route_sets = place.grades.map(&:active_route_set).reject(&:nil?)

        climb = Climb.new(
          climbed_at: Time.now,
          user: @user,
          route_sets: active_route_sets,
          place: place,
          current: true
        )

        if climb.save
          render json: {
            climb: {
              id: climb.id,
              name: climb.name,
              climbed_at: climb.climbed_at,
              current: climb.current,
              place: {
                id: place.id,
                name: place.name
              }
            }
          }, status: :created
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
          render json: {
            climb: {
              id: @climb.id,
              name: @climb.name,
              success_percentage: @climb.success_percentage,
              route_states: @climb.route_states.map do |rs|
                { route_id: rs.route_id, status: rs.status }
              end
            }
          }
        else
          render json: { error: @climb.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def complete
        if @climb.update(current: false)
          render json: {
            climb: {
              id: @climb.id,
              name: @climb.name,
              current: @climb.current,
              success_percentage: @climb.success_percentage
            }
          }
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

      def set_user
        # Map Auth0 user to actual User record
        auth0_sub = current_user['sub'] if current_user
        @user = User.find_or_create_by(google_uid: auth0_sub) do |user|
          user.token = SecureRandom.hex(16)
        end
      end

      def set_climb
        @climb = Climb.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Climb not found' }, status: :not_found
      end

      def check_climb_ownership
        unless @climb&.user == @user
          render json: { error: 'Access denied' }, status: :forbidden
        end
      end
    end
  end
end