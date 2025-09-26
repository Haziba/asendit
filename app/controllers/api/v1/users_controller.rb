module Api
  module V1
    class UsersController < BaseController
      def show
        # Get current climb if one exists
        current_climb = current_user.climbs.where(current: true).first

        # Get places owned by this user
        owned_places = current_user.place ? [current_user.place] : []

        # Get last 10 climbs
        recent_climbs = current_user.climbs
          .order(climbed_at: :desc)
          .limit(10)
          .includes(:place, :route_sets)

        render json: UserPresenter.new(
          current_user,
          current_climb: current_climb,
          owned_places: owned_places,
          recent_climbs: recent_climbs
        ).present
      end
    end
  end
end