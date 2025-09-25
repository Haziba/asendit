require 'rails_helper'

RSpec.describe Api::V1::ClimbsController, type: :controller do
  let!(:user) { create(:user) }
  let!(:another_user) { create(:user) }
  let!(:place) { create(:place, :with_grades) }

  let(:auth0_payload) do
    {
      'sub' => user.google_uid,
      'email' => 'test@example.com',
      'name' => 'Test User'
    }
  end

  before do
    allow_any_instance_of(Api::BaseController)
      .to receive(:current_user)
      .and_return(auth0_payload)

    user.update(place: place)
  end

  describe 'GET #index' do
    let!(:climb1) { create(:climb, user: user, climbed_at: 1.day.ago) }
    let!(:climb2) { create(:climb, user: user, climbed_at: 2.days.ago) }
    let!(:other_user_climb) { create(:climb, user: another_user) }

    context 'with valid authentication' do
      it 'returns success response' do
        get :index
        expect(response).to have_http_status(:success)
      end

      it 'returns only current user climbs in descending order' do
        get :index
        json_response = JSON.parse(response.body)

        expect(json_response['climbs'].count).to eq(2)
        expect(json_response['climbs'][0]['id']).to eq(climb1.id)
        expect(json_response['climbs'][1]['id']).to eq(climb2.id)
      end

      it 'includes climb details' do
        get :index
        json_response = JSON.parse(response.body)
        climb_data = json_response['climbs'].first

        expect(climb_data).to include('id', 'name', 'climbed_at', 'current', 'success_percentage')
        expect(climb_data['place']).to include('id', 'name')
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
    end
  end

  describe 'GET #show' do
    let!(:climb) { create(:climb, user: user, place: place) }

    context 'when climb belongs to user' do
      it 'returns success response' do
        get :show, params: { id: climb.id }
        expect(response).to have_http_status(:success)
      end

      it 'includes climb details with routes and route_sets' do
        get :show, params: { id: climb.id }
        json_response = JSON.parse(response.body)

        expect(json_response).to have_key('climb')
        expect(json_response).to have_key('routes')
        expect(json_response).to have_key('route_sets')

        climb_data = json_response['climb']
        expect(climb_data).to include('id', 'name', 'climbed_at', 'route_states')
      end
    end

    context 'when climb belongs to another user' do
      let!(:other_climb) { create(:climb, user: another_user) }

      it 'returns forbidden status' do
        get :show, params: { id: other_climb.id }
        expect(response).to have_http_status(:forbidden)
      end

      it 'returns error message' do
        get :show, params: { id: other_climb.id }
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Access denied')
      end
    end

    context 'when climb does not exist' do
      it 'returns not found status' do
        get :show, params: { id: 999999 }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'GET #current' do
    context 'when a current climb exists' do
      let!(:current_climb) { create(:climb, user: user, current: true) }

      it 'returns the current climb' do
        get :current
        expect(response).to have_http_status(:success)

        json_response = JSON.parse(response.body)
        expect(json_response['climb']['id']).to eq(current_climb.id)
        expect(json_response['climb']['current']).to be true
      end
    end

    context 'when no current climb exists' do
      it 'returns nil climb' do
        get :current
        expect(response).to have_http_status(:success)

        json_response = JSON.parse(response.body)
        expect(json_response['climb']).to be_nil
      end
    end
  end

  describe 'POST #create' do
    let!(:active_route_set) { create(:route_set, added: Date.today, grade: place.grades.first, place: place) }

    context 'when no current climb exists' do
      it 'creates a new climb' do
        expect {
          post :create
        }.to change(Climb, :count).by(1)
      end

      it 'returns created status' do
        post :create
        expect(response).to have_http_status(:created)
      end

      it 'sets climb as current and includes active route sets' do
        post :create

        climb = Climb.last
        expect(climb.current).to be true
        expect(climb.route_sets).to include(active_route_set)
        expect(climb.user).to eq(user)
        expect(climb.place).to eq(place)
      end

      it 'returns climb details' do
        post :create
        json_response = JSON.parse(response.body)

        expect(json_response['climb']).to include('id', 'name', 'current')
        expect(json_response['climb']['place']).to include('id', 'name')
      end
    end

    context 'when current climb already exists' do
      let!(:existing_current) { create(:climb, user: user, current: true) }

      it 'does not create a new climb' do
        expect {
          post :create
        }.not_to change(Climb, :count)
      end

      it 'returns unprocessable entity status' do
        post :create
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns error with existing climb info' do
        post :create
        json_response = JSON.parse(response.body)

        expect(json_response['error']).to include('already have an active climb')
        expect(json_response['current_climb']['id']).to eq(existing_current.id)
      end
    end

    context 'when user has no place selected' do
      before { user.update(place: nil) }

      it 'returns error' do
        post :create
        expect(response).to have_http_status(:unprocessable_entity)

        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('No place selected')
      end
    end
  end

  describe 'PATCH #update' do
    let!(:climb) { create(:climb, user: user) }
    let(:route_states_params) do
      [
        { route_id: 1, status: 'flashed' },
        { route_id: 2, status: 'sent' }
      ]
    end

    context 'when climb belongs to user' do
      it 'updates the climb route states' do
        patch :update, params: { id: climb.id, route_states: route_states_params }

        expect(response).to have_http_status(:success)
        climb.reload

        expect(climb.route_states.count).to eq(2)
        expect(climb.route_states.first.route_id).to eq(1)
        expect(climb.route_states.first.status).to eq('flashed')
      end

      it 'returns updated climb data' do
        patch :update, params: { id: climb.id, route_states: route_states_params }
        json_response = JSON.parse(response.body)

        expect(json_response['climb']).to include('id', 'success_percentage', 'route_states')
        expect(json_response['climb']['route_states'].count).to eq(2)
      end
    end

    context 'when climb belongs to another user' do
      let!(:other_climb) { create(:climb, user: another_user) }

      it 'returns forbidden status' do
        patch :update, params: { id: other_climb.id, route_states: route_states_params }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'POST #complete' do
    let!(:climb) { create(:climb, user: user, current: true) }

    context 'when climb belongs to user' do
      it 'marks climb as not current' do
        post :complete, params: { id: climb.id }

        expect(response).to have_http_status(:success)
        climb.reload
        expect(climb.current).to be false
      end

      it 'returns updated climb data' do
        post :complete, params: { id: climb.id }
        json_response = JSON.parse(response.body)

        expect(json_response['climb']['current']).to be false
        expect(json_response['climb']).to include('id', 'name', 'success_percentage')
      end
    end

    context 'when climb belongs to another user' do
      let!(:other_climb) { create(:climb, user: another_user, current: true) }

      it 'returns forbidden status' do
        post :complete, params: { id: other_climb.id }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'DELETE #destroy' do
    let!(:climb) { create(:climb, user: user) }

    context 'when climb belongs to user' do
      it 'deletes the climb' do
        expect {
          delete :destroy, params: { id: climb.id }
        }.to change(Climb, :count).by(-1)
      end

      it 'returns success message' do
        delete :destroy, params: { id: climb.id }
        expect(response).to have_http_status(:success)

        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq('Climb deleted successfully')
      end
    end

    context 'when climb belongs to another user' do
      let!(:other_climb) { create(:climb, user: another_user) }

      it 'does not delete the climb' do
        expect {
          delete :destroy, params: { id: other_climb.id }
        }.not_to change(Climb, :count)
      end

      it 'returns forbidden status' do
        delete :destroy, params: { id: other_climb.id }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'authentication' do
    context 'without valid token' do
      before do
        allow_any_instance_of(Api::BaseController)
          .to receive(:current_user)
          .and_return(nil)
      end

      it 'returns unauthorized for all actions' do
        get :index
        expect(response).to have_http_status(:unauthorized)

        get :current
        expect(response).to have_http_status(:unauthorized)

        post :create
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with valid token but different user' do
      let(:different_auth0_payload) do
        { 'sub' => 'auth0|different-user' }
      end

      before do
        allow_any_instance_of(Api::BaseController)
          .to receive(:current_user)
          .and_return(different_auth0_payload)
      end

      it 'creates or finds user based on Auth0 sub' do
        get :index
        expect(response).to have_http_status(:success)

        # Should create new user with the different google_uid
        new_user = User.find_by(google_uid: 'auth0|different-user')
        expect(new_user).to be_present
      end
    end
  end
end