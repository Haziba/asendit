module Api
  module V1
    class ClimbsController < BaseController
      def index
        render json: {
          message: 'Authenticated successfully',
          user: current_user,
          climbs: [] # Placeholder - will be implemented later
        }
      end
    end
  end
end