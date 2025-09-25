require 'rails_helper'
require 'jwt'

RSpec.describe Auth0JwtValidator do
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
    described_class.instance_variable_set(:@jwks_cache, nil)
    described_class.instance_variable_set(:@jwks_cache_time, nil)
  end

  describe '.validate' do
    context 'with a valid token' do
      let(:payload) do
        {
          sub: 'auth0|123456',
          iss: "https://#{auth0_domain}/",
          aud: [auth0_client_id],
          exp: (Time.now + 1.hour).to_i,
          iat: Time.now.to_i
        }
      end

      let(:valid_token) do
        JWT.encode(payload, rsa_private, 'RS256', kid: kid)
      end

      before do
        stub_request(:get, "https://#{auth0_domain}/.well-known/jwks.json")
          .to_return(status: 200, body: jwks.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'returns the decoded payload' do
        result = described_class.validate(valid_token)

        expect(result).to be_a(Hash)
        expect(result['sub']).to eq('auth0|123456')
        expect(result['iss']).to eq("https://#{auth0_domain}/")
      end

      it 'caches JWKS to avoid repeated HTTP calls' do
        # First call should fetch JWKS
        result1 = described_class.validate(valid_token)
        expect(result1).to be_a(Hash)

        # Second call should use cache
        result2 = described_class.validate(valid_token)
        expect(result2).to be_a(Hash)

        expect(WebMock).to have_requested(:get, "https://#{auth0_domain}/.well-known/jwks.json").once
      end
    end

    context 'with an expired token' do
      let(:payload) do
        {
          sub: 'auth0|123456',
          iss: "https://#{auth0_domain}/",
          aud: [auth0_client_id],
          exp: (Time.now - 1.hour).to_i,
          iat: (Time.now - 2.hours).to_i
        }
      end

      let(:expired_token) do
        JWT.encode(payload, rsa_private, 'RS256', kid: kid)
      end

      before do
        stub_request(:get, "https://#{auth0_domain}/.well-known/jwks.json")
          .to_return(status: 200, body: jwks.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'returns nil' do
        result = described_class.validate(expired_token)
        expect(result).to be_nil
      end
    end

    context 'with invalid signature' do
      let(:different_key) { OpenSSL::PKey::RSA.generate(2048) }
      let(:payload) do
        {
          sub: 'auth0|123456',
          iss: "https://#{auth0_domain}/",
          aud: [auth0_client_id],
          exp: (Time.now + 1.hour).to_i,
          iat: Time.now.to_i
        }
      end

      let(:invalid_token) do
        JWT.encode(payload, different_key, 'RS256', kid: kid)
      end

      before do
        stub_request(:get, "https://#{auth0_domain}/.well-known/jwks.json")
          .to_return(status: 200, body: jwks.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'returns nil' do
        result = described_class.validate(invalid_token)
        expect(result).to be_nil
      end
    end

    context 'with wrong issuer' do
      let(:payload) do
        {
          sub: 'auth0|123456',
          iss: 'https://wrong-domain.auth0.com/',
          aud: [auth0_client_id],
          exp: (Time.now + 1.hour).to_i,
          iat: Time.now.to_i
        }
      end

      let(:wrong_issuer_token) do
        JWT.encode(payload, rsa_private, 'RS256', kid: kid)
      end

      before do
        stub_request(:get, "https://#{auth0_domain}/.well-known/jwks.json")
          .to_return(status: 200, body: jwks.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'returns nil' do
        result = described_class.validate(wrong_issuer_token)
        expect(result).to be_nil
      end
    end

    context 'with wrong audience' do
      let(:payload) do
        {
          sub: 'auth0|123456',
          iss: "https://#{auth0_domain}/",
          aud: ['wrong-client-id'],
          exp: (Time.now + 1.hour).to_i,
          iat: Time.now.to_i
        }
      end

      let(:wrong_audience_token) do
        JWT.encode(payload, rsa_private, 'RS256', kid: kid)
      end

      before do
        stub_request(:get, "https://#{auth0_domain}/.well-known/jwks.json")
          .to_return(status: 200, body: jwks.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'returns nil' do
        result = described_class.validate(wrong_audience_token)
        expect(result).to be_nil
      end
    end

    context 'with nil token' do
      it 'returns nil' do
        result = described_class.validate(nil)
        expect(result).to be_nil
      end
    end

    context 'with empty token' do
      it 'returns nil' do
        result = described_class.validate('')
        expect(result).to be_nil
      end
    end

    context 'when JWKS endpoint is unavailable' do
      let(:payload) do
        {
          sub: 'auth0|123456',
          iss: "https://#{auth0_domain}/",
          aud: [auth0_client_id],
          exp: (Time.now + 1.hour).to_i,
          iat: Time.now.to_i
        }
      end

      let(:valid_token) do
        JWT.encode(payload, rsa_private, 'RS256', kid: kid)
      end

      before do
        stub_request(:get, "https://#{auth0_domain}/.well-known/jwks.json")
          .to_return(status: 500)
      end

      it 'returns nil and logs error' do
        expect(Rails.logger).to receive(:error).with(/Auth0 JWT validation error/)
        result = described_class.validate(valid_token)
        expect(result).to be_nil
      end
    end
  end
end