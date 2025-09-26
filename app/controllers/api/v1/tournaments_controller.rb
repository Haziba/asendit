module Api
  module V1
    class TournamentsController < BaseController
      before_action :set_tournament, only: [:show, :update, :destroy, :update_routes]
      before_action :set_place
      before_action :ensure_can_edit, only: [:create, :update, :destroy, :update_routes]

      def index
        tournaments = @place.tournaments.includes(:tournament_routes)

        render json: TournamentsPresenter.new(tournaments, current_user).present
      end

      def show
        # Include routes and their details for the tournament
        tournament_routes = @tournament.tournament_routes.includes(route: :route_set).order(:order)

        render json: {
          tournament: TournamentPresenter.new(@tournament, current_user).present_detail,
          tournament_routes: tournament_routes.map do |tr|
            TournamentRoutePresenter.new(tr, current_user).present
          end
        }
      end

      def create
        tournament = Tournament.new(
          name: params[:name],
          place: @place,
          starting: params[:starting] ? Date.parse(params[:starting]) : Date.tomorrow,
          ending: params[:ending] ? Date.parse(params[:ending]) : Date.tomorrow + 7.days
        )

        if tournament.save
          render json: {
            tournament: TournamentPresenter.new(tournament, current_user).present_detail
          }, status: :created
        else
          render json: { error: tournament.errors.full_messages }, status: :unprocessable_entity
        end
      rescue Date::Error => e
        render json: { error: "Invalid date format: #{e.message}" }, status: :unprocessable_entity
      end

      def update
        update_params = {}

        begin
          update_params[:name] = params[:name] if params[:name].present?
          update_params[:starting] = Date.parse(params[:starting]) if params[:starting].present?
          update_params[:ending] = Date.parse(params[:ending]) if params[:ending].present?
        rescue Date::Error => e
          return render json: { error: "Invalid date format: #{e.message}" }, status: :unprocessable_entity
        end

        if @tournament.update(update_params)
          render json: {
            tournament: TournamentPresenter.new(@tournament, current_user).present_detail
          }
        else
          render json: { error: @tournament.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update_routes
        routes = params[:tournament_routes] || []

        # Process each route update/creation
        routes.each do |route_params|
          route_id = route_params[:route_id]
          order = route_params[:order]

          next unless route_id.present? && order.present?

          tournament_route = @tournament.tournament_routes.find_by(route_id: route_id)

          if tournament_route
            tournament_route.update(order: order) unless tournament_route.order == order.to_i
          else
            # Verify the route exists and belongs to the place
            route = Route.joins(:route_set).where(id: route_id, route_sets: { place_id: @place.id }).first
            if route
              TournamentRoute.create!(tournament: @tournament, route: route, order: order)
            end
          end
        end

        # Remove routes not in the update list
        if routes.any?
          route_ids_to_keep = routes.map { |r| r[:route_id].to_i }
          @tournament.tournament_routes.where.not(route_id: route_ids_to_keep).destroy_all
        else
          @tournament.tournament_routes.destroy_all
        end

        render json: {
          success: true,
          tournament_routes_count: @tournament.tournament_routes.count
        }
      end

      def destroy
        if @tournament.destroy
          render json: { message: 'Tournament deleted successfully' }
        else
          render json: { error: 'Failed to delete tournament' }, status: :unprocessable_entity
        end
      end

      private

      def set_tournament
        @tournament = Tournament.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Tournament not found' }, status: :not_found
      end

      def set_place
        if params[:place_id].present?
          @place = Place.find(params[:place_id])
        elsif @tournament
          @place = @tournament.place
        else
          @place = current_user.place
        end

        if @place.nil?
          render json: { error: 'No place selected or found' }, status: :unprocessable_entity
        end
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Place not found' }, status: :not_found
      end

      def ensure_can_edit
        unless current_user.admin || @place.can_edit?(current_user)
          render json: { error: 'You do not have permission to modify tournaments at this place' }, status: :forbidden
        end
      end

    end
  end
end