require 'webmock/rspec'
require 'rails_helper'
require 'jwt'

RSpec.describe 'API V1 Authentication Flow', type: :request do
  let(:auth0_domain) { 'shrill-hat-2743.us.auth0.com' }
  let(:auth0_client_id) { '9WK1xVxjodv58HVwdIfBjisusg4yB4nR' }
  let(:kid) { 'test-key-id' }
  let(:rsa_private) { OpenSSL::PKey::RSA.generate(2048) }
  let(:rsa_public) { rsa_private.public_key }

  # Mock JWKS response
  let(:jwks) do
    {
      keys: [
        {
          kid: kid,
          kty: 'RSA',
          use: 'sig',
          n: Base64.urlsafe_encode64(rsa_public.n.to_s(2), padding: false),
          e: Base64.urlsafe_encode64(rsa_public.e.to_s(2), padding: false)
        }
      ]
    }
  end

  before do
    allow(Rails.application).to receive(:config_for).with(:auth0).and_return({
      'auth0_domain' => auth0_domain,
      'auth0_client_id' => auth0_client_id
    })

    # Clear the cache before each test
    Auth0JwtValidator.instance_variable_set(:@jwks_cache, nil)
    Auth0JwtValidator.instance_variable_set(:@jwks_cache_time, nil)

    # Stub the JWKS endpoint
    stub_request(:get, "https://#{auth0_domain}/.well-known/jwks.json")
      .to_return(status: 200, body: jwks.to_json, headers: { 'Content-Type' => 'application/json' })
  end

  describe 'Complete authentication flow' do
    let(:user_sub) { 'auth0|123456789' }
    let(:user_email) { 'testuser@example.com' }
    let(:user_name) { 'Test User' }

    let(:valid_payload) do
      {
        sub: user_sub,
        email: user_email,
        name: user_name,
        iss: "https://#{auth0_domain}/",
        aud: [auth0_client_id],
        exp: (Time.now + 1.hour).to_i,
        iat: Time.now.to_i
      }
    end

    let(:valid_token) do
      JWT.encode(valid_payload, rsa_private, 'RS256', kid: kid)
    end

    context 'successful authentication' do
      it 'allows access to protected endpoint with valid token' do
        get '/api/v1/climbs',
            headers: { 'Authorization' => "Bearer #{valid_token}" }

        expect(response).to have_http_status(:success)

        json = JSON.parse(response.body)
        expect(json['message']).to eq('Authenticated successfully')
        expect(json['user']['sub']).to eq(user_sub)
        expect(json['user']['email']).to eq(user_email)
        expect(json['user']['name']).to eq(user_name)
      end

      it 'returns consistent user data across multiple requests' do
        # First request
        get '/api/v1/climbs',
            headers: { 'Authorization' => "Bearer #{valid_token}" }

        first_response = JSON.parse(response.body)

        # Second request with same token
        get '/api/v1/climbs',
            headers: { 'Authorization' => "Bearer #{valid_token}" }

        second_response = JSON.parse(response.body)

        expect(first_response['user']).to eq(second_response['user'])
      end

      it 'caches JWKS to minimize external API calls' do
        # Make multiple requests
        5.times do
          get '/api/v1/climbs',
              headers: { 'Authorization' => "Bearer #{valid_token}" }
          expect(response).to have_http_status(:success)
        end

        # JWKS endpoint should only be called once
        expect(WebMock).to have_requested(:get, "https://#{auth0_domain}/.well-known/jwks.json").once
      end
    end

    context 'failed authentication scenarios' do
      it 'rejects request without Authorization header' do
        get '/api/v1/climbs'

        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Unauthorized')
      end

      it 'rejects request with malformed Authorization header' do
        get '/api/v1/climbs',
            headers: { 'Authorization' => 'InvalidFormat token123' }

        expect(response).to have_http_status(:unauthorized)
      end

      it 'rejects request with expired token' do
        expired_payload = valid_payload.merge(
          exp: (Time.now - 1.hour).to_i,
          iat: (Time.now - 2.hours).to_i
        )
        expired_token = JWT.encode(expired_payload, rsa_private, 'RS256', kid: kid)

        get '/api/v1/climbs',
            headers: { 'Authorization' => "Bearer #{expired_token}" }

        expect(response).to have_http_status(:unauthorized)
      end

      it 'rejects request with token signed by different key' do
        different_key = OpenSSL::PKey::RSA.generate(2048)
        invalid_token = JWT.encode(valid_payload, different_key, 'RS256', kid: kid)

        get '/api/v1/climbs',
            headers: { 'Authorization' => "Bearer #{invalid_token}" }

        expect(response).to have_http_status(:unauthorized)
      end

      it 'rejects request with wrong issuer' do
        wrong_issuer_payload = valid_payload.merge(iss: 'https://wrong-domain.auth0.com/')
        wrong_issuer_token = JWT.encode(wrong_issuer_payload, rsa_private, 'RS256', kid: kid)

        get '/api/v1/climbs',
            headers: { 'Authorization' => "Bearer #{wrong_issuer_token}" }

        expect(response).to have_http_status(:unauthorized)
      end

      it 'rejects request with wrong audience' do
        wrong_audience_payload = valid_payload.merge(aud: ['wrong-client-id'])
        wrong_audience_token = JWT.encode(wrong_audience_payload, rsa_private, 'RS256', kid: kid)

        get '/api/v1/climbs',
            headers: { 'Authorization' => "Bearer #{wrong_audience_token}" }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'token refresh scenario' do
      it 'accepts new token after previous one expires' do
        # First token (will be expired)
        first_payload = valid_payload.merge(
          exp: (Time.now + 5.seconds).to_i,
          jti: 'token-1'
        )
        first_token = JWT.encode(first_payload, rsa_private, 'RS256', kid: kid)

        # Make request with first token
        get '/api/v1/climbs',
            headers: { 'Authorization' => "Bearer #{first_token}" }
        expect(response).to have_http_status(:success)

        # Wait for token to expire
        sleep 6

        # Try with expired token
        get '/api/v1/climbs',
            headers: { 'Authorization' => "Bearer #{first_token}" }
        expect(response).to have_http_status(:unauthorized)

        # New token (refreshed)
        second_payload = valid_payload.merge(
          exp: (Time.now + 1.hour).to_i,
          jti: 'token-2'
        )
        second_token = JWT.encode(second_payload, rsa_private, 'RS256', kid: kid)

        # Make request with new token
        get '/api/v1/climbs',
            headers: { 'Authorization' => "Bearer #{second_token}" }
        expect(response).to have_http_status(:success)
      end
    end

    context 'JWKS endpoint failure handling' do
      before do
        Auth0JwtValidator.instance_variable_set(:@jwks_cache, nil)
        Auth0JwtValidator.instance_variable_set(:@jwks_cache_time, nil)
      end

      it 'handles JWKS endpoint being temporarily unavailable' do
        # First request succeeds and caches JWKS
        get '/api/v1/climbs',
            headers: { 'Authorization' => "Bearer #{valid_token}" }
        expect(response).to have_http_status(:success)

        # Simulate JWKS endpoint going down
        stub_request(:get, "https://#{auth0_domain}/.well-known/jwks.json")
          .to_return(status: 500)

        # Should still work with cached JWKS
        get '/api/v1/climbs',
            headers: { 'Authorization' => "Bearer #{valid_token}" }
        expect(response).to have_http_status(:success)
      end
    end
  end
end