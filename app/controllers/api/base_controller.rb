module Api
  class BaseController < ActionController::API
    before_action :authenticate_request

    private

    def authenticate_request
      render json: { error: 'Unauthorized' }, status: :unauthorized unless current_user
    end

    def current_user
      @current_user ||= validate_token
    end

    def validate_token
      auth_header = request.headers['Authorization']
      return nil unless auth_header.present?

      # Extract token from "Bearer <token>" format
      token = auth_header.split(' ').last
      return nil unless token.present?

      # Validate the JWT token with Auth0
      auth0_payload = Auth0JwtValidator.validate(token)

      # You can map Auth0 user to your User model here if needed
      # Example: User.find_or_create_by(auth0_id: auth0_payload['sub']) if auth0_payload
      auth0_payload
    end
  end
end