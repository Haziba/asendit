module Api
  class BaseController < ActionController::API
    before_action :authenticate_request

    private

    def authenticate_request
      render json: { error: 'Unauthorized' }, status: :unauthorized unless current_user
    end

    def current_user
      @current_user ||= get_create_or_update_user
    end

    def get_create_or_update_user
      auth0_payload = validate_token
      return nil unless auth0_payload

      auth0_sub = auth0_payload['sub']
      auth0_email = auth0_payload['email']
      auth0_name = auth0_payload['name']
      auth0_picture = auth0_payload['picture']

      user = User.find_or_create_by(google_uid: auth0_sub) do |u|
        u.token = SecureRandom.hex(16)
        u.email = auth0_email
        u.name = auth0_name
        u.profile_picture_url = auth0_picture
      end

      # Update user info if it has changed in Auth0
      if user.persisted? && (
        user.email != auth0_email ||
        user.name != auth0_name ||
        user.profile_picture_url != auth0_picture
      )
        user.update(
          email: auth0_email,
          name: auth0_name,
          profile_picture_url: auth0_picture
        )
      end

      user
    end

    def validate_token
      auth_header = request.headers['Authorization']
      return nil unless auth_header.present?

      # Extract token from "Bearer <token>" format
      token = auth_header.split(' ').last
      return nil unless token.present?

      # Validate the JWT token with Auth0
      Auth0JwtValidator.validate(token)
    end
  end
end