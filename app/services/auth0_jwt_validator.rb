require 'net/http'
require 'uri'
require 'jwt'

class Auth0JwtValidator
  class << self
    def validate(token)
      return nil if token.nil?

      # Decode without verification to get the kid (key id)
      unverified_payload = JWT.decode(token, nil, false)
      kid = unverified_payload[1]['kid']

      # Get the public key from Auth0
      public_key = get_public_key(kid)

      # Verify and decode the token
      decoded_token = JWT.decode(
        token,
        public_key,
        true,
        {
          algorithm: 'RS256',
          iss: "https://#{auth0_domain}/",
          verify_iss: true,
          aud: [auth0_client_id, "https://#{auth0_domain}/userinfo"],
          verify_aud: true
        }
      )

      decoded_token[0] # Return the payload
    rescue JWT::DecodeError => e
      Rails.logger.error "JWT decode error: #{e.message}"
      nil
    rescue => e
      Rails.logger.error "Auth0 JWT validation error: #{e.message}"
      nil
    end

    private

    def auth0_domain
      @auth0_domain ||= ENV['AUTH0_DOMAIN'] || raise('AUTH0_DOMAIN environment variable not set')
    end

    def auth0_client_id
      @auth0_client_id ||= ENV['AUTH0_CLIENT_ID'] || raise('AUTH0_CLIENT_ID environment variable not set')
    end

    def get_public_key(kid)
      # Cache JWKS to avoid repeated HTTP calls
      @jwks_cache ||= {}
      @jwks_cache_time ||= Time.now

      # Refresh cache every hour
      if @jwks_cache.empty? || (Time.now - @jwks_cache_time) > 3600
        @jwks_cache = fetch_jwks
        @jwks_cache_time = Time.now
      end

      key = @jwks_cache.find { |k| k['kid'] == kid }
      raise 'Public key not found' unless key

      # Convert the key to PEM format
      # Build the RSA public key from the JWK components
      JWT::JWK.import(key).public_key
    end

    def fetch_jwks
      uri = URI("https://#{auth0_domain}/.well-known/jwks.json")
      response = Net::HTTP.get_response(uri)

      if response.is_a?(Net::HTTPSuccess)
        JSON.parse(response.body)['keys']
      else
        raise "Failed to fetch JWKS: #{response.code}"
      end
    end
  end
end