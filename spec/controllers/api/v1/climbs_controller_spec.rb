require 'rails_helper'

RSpec.describe Api::V1::ClimbsController, type: :controller do
  describe 'GET #index' do
    context 'with valid authentication' do
      let(:valid_auth0_payload) do
        {
          'sub' => 'auth0|123456',
          'email' => 'test@example.com',
          'name' => 'Test User'
        }
      end

      before do
        allow_any_instance_of(Api::BaseController)
          .to receive(:current_user)
          .and_return(valid_auth0_payload)
      end

      it 'returns success response' do
        get :index
        expect(response).to have_http_status(:success)
      end

      it 'returns JSON with user information' do
        get :index
        json_response = JSON.parse(response.body)

        expect(json_response['message']).to eq('Authenticated successfully')
        expect(json_response['user']['sub']).to eq('auth0|123456')
        expect(json_response['user']['email']).to eq('test@example.com')
      end

      it 'includes climbs array in response' do
        get :index
        json_response = JSON.parse(response.body)

        expect(json_response).to have_key('climbs')
        expect(json_response['climbs']).to be_an(Array)
      end
    end

    context 'without authentication' do
      before do
        allow_any_instance_of(Api::BaseController)
          .to receive(:current_user)
          .and_return(nil)
      end

      it 'returns unauthorized status' do
        get :index
        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns error message' do
        get :index
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Unauthorized')
      end
    end

    context 'with Authorization header but invalid token' do
      before do
        request.headers['Authorization'] = 'Bearer invalid-token'
        allow(Auth0JwtValidator).to receive(:validate).and_return(nil)
      end

      it 'returns unauthorized status' do
        get :index
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with valid Authorization header' do
      let(:valid_token) { 'valid-jwt-token' }
      let(:valid_auth0_payload) do
        {
          'sub' => 'auth0|789012',
          'email' => 'authorized@example.com'
        }
      end

      before do
        request.headers['Authorization'] = "Bearer #{valid_token}"
        allow(Auth0JwtValidator).to receive(:validate)
          .with(valid_token)
          .and_return(valid_auth0_payload)
      end

      it 'authenticates the request' do
        get :index
        expect(response).to have_http_status(:success)
      end

      it 'returns the authenticated user data' do
        get :index
        json_response = JSON.parse(response.body)
        expect(json_response['user']['email']).to eq('authorized@example.com')
      end
    end
  end
end