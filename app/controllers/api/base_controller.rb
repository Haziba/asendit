module Api
  class BaseController < ActionController::API
    before_action :authenticate_request

    private

    def authenticate_request
      # For now, we'll create a placeholder that we'll implement with JWT in step 2
      # This will check for a valid Auth0 token in the Authorization header
      render json: { error: 'Unauthorized' }, status: :unauthorized unless valid_token?
    end

    def valid_token?
      # Placeholder - will be implemented with JWT validation in step 2
      # For now, allow requests with any Bearer token to test the structure
      auth_header = request.headers['Authorization']
      return false unless auth_header.present?

      token = auth_header.split(' ').last
      token.present?
    end

    def current_user
      # Placeholder - will return the authenticated user from the JWT token
      @current_user ||= nil
    end
  end
end