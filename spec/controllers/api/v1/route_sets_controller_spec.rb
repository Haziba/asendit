require 'rails_helper'

RSpec.describe Api::V1::RouteSetsController, type: :controller do
  let!(:admin_user) { create(:user, admin: true) }
  let!(:regular_user) { create(:user, admin: false) }
  let!(:another_user) { create(:user) }

  let!(:place) { create(:place, :with_grades, user: admin_user) }
  let!(:another_place) { create(:place, :with_grades, user: another_user) }

  let!(:grade1) { place.grades.first }
  let!(:grade2) { place.grades.second }

  let!(:recent_route_set) { create(:route_set, :with_routes, place: place, grade: grade1, added: Date.today) }
  let!(:old_route_set) { create(:route_set, place: place, grade: grade1, added: 1.month.ago) }
  let!(:another_grade_route_set) { create(:route_set, place: place, grade: grade2, added: Date.today) }
  let!(:other_place_route_set) { create(:route_set, place: another_place, grade: another_place.grades.first) }

  let(:auth0_payload) do
    {
      'sub' => regular_user.google_uid,
      'email' => 'test@example.com',
      'name' => 'Test User'
    }
  end

  before do
    allow_any_instance_of(Api::BaseController)
      .to receive(:current_user)
      .and_return(auth0_payload)

    regular_user.update(place: place)
  end

  describe 'GET #index' do
    context 'with valid authentication and place' do
      it 'returns active and past route sets' do
        get :index, params: { place_id: place.id }
        expect(response).to have_http_status(:success)

        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('active_route_sets')
        expect(json_response).to have_key('past_route_sets')
      end

      it 'includes only most recent route set per grade as active' do
        get :index, params: { place_id: place.id }
        json_response = JSON.parse(response.body)

        active_ids = json_response['active_route_sets'].map { |rs| rs['id'] }
        expect(active_ids).to include(recent_route_set.id, another_grade_route_set.id)
        expect(active_ids).not_to include(old_route_set.id)
      end

      it 'includes older route sets as past' do
        get :index, params: { place_id: place.id }
        json_response = JSON.parse(response.body)

        past_ids = json_response['past_route_sets'].map { |rs| rs['id'] }
        expect(past_ids).to include(old_route_set.id)
        expect(past_ids).not_to include(recent_route_set.id)
      end

      it 'includes grade information' do
        get :index, params: { place_id: place.id }
        json_response = JSON.parse(response.body)

        route_set = json_response['active_route_sets'].first
        expect(route_set['grade']).to include('id', 'name', 'grade', 'map_tint_colour')
      end
    end

    context 'without place_id parameter' do
      it 'uses user current place' do
        get :index
        expect(response).to have_http_status(:success)

        json_response = JSON.parse(response.body)
        active_ids = json_response['active_route_sets'].map { |rs| rs['id'] }
        expect(active_ids).to include(recent_route_set.id)
      end
    end

    context 'when user has no place' do
      before { regular_user.update(place: nil) }

      it 'returns unprocessable entity' do
        get :index
        expect(response).to have_http_status(:unprocessable_entity)

        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('No place selected or found')
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
    let!(:climb) { create(:climb, user: regular_user, route_sets: [recent_route_set]) }

    before do
      # Create some route states for the climb
      route_state = RouteStatus.new(recent_route_set.routes.first.id, 'sent')
      climb.update(route_state_json: [{ route_id: route_state.route_id, status: route_state.status }])
    end

    context 'when route set exists at current place' do
      it 'returns route set details' do
        get :show, params: { id: recent_route_set.id }
        expect(response).to have_http_status(:success)

        json_response = JSON.parse(response.body)
        expect(json_response['route_set']['id']).to eq(recent_route_set.id)
      end

      it 'includes routes for the route set' do
        get :show, params: { id: recent_route_set.id }
        json_response = JSON.parse(response.body)

        expect(json_response['routes']).to be_an(Array)
        expect(json_response['routes'].count).to eq(recent_route_set.routes.count)
      end

      it 'includes user climbing history' do
        get :show, params: { id: recent_route_set.id }
        json_response = JSON.parse(response.body)

        expect(json_response['climbed_routes']).to be_an(Array)
        expect(json_response['user_route_states']).to be_an(Array)
        expect(json_response['user_route_states'].first).to include('route_id', 'status')
      end

      it 'includes edit permissions' do
        get :show, params: { id: recent_route_set.id }
        json_response = JSON.parse(response.body)

        expect(json_response['route_set']['can_edit']).to be false
      end
    end

    context 'when route set belongs to different place' do
      it 'returns success and shows the route set' do
        get :show, params: { id: other_place_route_set.id }
        expect(response).to have_http_status(:success)

        json_response = JSON.parse(response.body)
        expect(json_response['route_set']['id']).to eq(other_place_route_set.id)
      end
    end

    context 'when route set does not exist' do
      it 'returns not found' do
        get :show, params: { id: 999999 }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'POST #create' do
    let(:valid_params) do
      {
        grade_id: grade1.id,
        added: Date.today.to_s,
        place_id: place.id
      }
    end

    context 'as admin user' do
      before do
        allow_any_instance_of(Api::BaseController)
          .to receive(:current_user)
          .and_return({ 'sub' => admin_user.google_uid })
      end

      it 'creates new route set' do
        expect {
          post :create, params: valid_params
        }.to change(RouteSet, :count).by(1)
      end

      it 'returns created status' do
        post :create, params: valid_params
        expect(response).to have_http_status(:created)

        json_response = JSON.parse(response.body)
        expect(json_response['route_set']['grade']['id']).to eq(grade1.id)
      end

      it 'uses current date if added not provided' do
        post :create, params: valid_params.except(:added)

        route_set = RouteSet.last
        expect(route_set.added.to_date).to eq(Date.today)
      end
    end

    context 'as place owner' do
      before do
        place.update(user: regular_user)
      end

      it 'allows creation' do
        expect {
          post :create, params: valid_params
        }.to change(RouteSet, :count).by(1)
      end
    end

    context 'as regular user (not owner)' do
      it 'returns forbidden' do
        post :create, params: valid_params
        expect(response).to have_http_status(:forbidden)

        json_response = JSON.parse(response.body)
        expect(json_response['error']).to include('permission')
      end

      it 'does not create route set' do
        expect {
          post :create, params: valid_params
        }.not_to change(RouteSet, :count)
      end
    end

    context 'with invalid parameters' do
      it 'returns forbidden for non-admin user regardless of params' do
        post :create, params: { place_id: place.id }
        expect(response).to have_http_status(:forbidden)
      end

      context 'as admin with invalid params' do
        before do
          allow_any_instance_of(Api::BaseController)
            .to receive(:current_user)
            .and_return({ 'sub' => admin_user.google_uid })
        end

        it 'returns unprocessable entity for missing grade' do
          post :create, params: { place_id: place.id }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
  end

  describe 'PATCH #update' do
    let(:update_params) do
      {
        id: recent_route_set.id,
        expires_at: 1.week.from_now.to_date.to_s
      }
    end

    context 'as admin user' do
      before do
        allow_any_instance_of(Api::BaseController)
          .to receive(:current_user)
          .and_return({ 'sub' => admin_user.google_uid })
      end

      it 'updates the route set' do
        patch :update, params: update_params
        expect(response).to have_http_status(:success)

        recent_route_set.reload
        expect(recent_route_set.expires_at).to eq(1.week.from_now.to_date)
      end

      it 'returns updated route set' do
        patch :update, params: update_params
        json_response = JSON.parse(response.body)

        expect(json_response['route_set']['expires_at']).to be_present
      end
    end

    context 'as regular user' do
      it 'returns forbidden' do
        patch :update, params: update_params
        expect(response).to have_http_status(:forbidden)
      end

      it 'does not update route set' do
        original_expires = recent_route_set.expires_at
        patch :update, params: update_params

        recent_route_set.reload
        expect(recent_route_set.expires_at).to eq(original_expires)
      end
    end

    context 'with invalid date format' do
      context 'as admin user' do
        before do
          allow_any_instance_of(Api::BaseController)
            .to receive(:current_user)
            .and_return({ 'sub' => admin_user.google_uid })
        end

        it 'returns unprocessable entity for invalid date' do
          patch :update, params: { id: recent_route_set.id, expires_at: 'invalid-date' }
          expect(response).to have_http_status(:unprocessable_entity)

          json_response = JSON.parse(response.body)
          expect(json_response['error']).to include('Invalid date format')
        end
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'as admin user' do
      before do
        allow_any_instance_of(Api::BaseController)
          .to receive(:current_user)
          .and_return({ 'sub' => admin_user.google_uid })
      end

      it 'deletes the route set' do
        expect {
          delete :destroy, params: { id: recent_route_set.id }
        }.to change(RouteSet, :count).by(-1)
      end

      it 'returns success message' do
        delete :destroy, params: { id: recent_route_set.id }
        expect(response).to have_http_status(:success)

        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq('Route set deleted successfully')
      end
    end

    context 'as regular user' do
      it 'returns forbidden' do
        delete :destroy, params: { id: recent_route_set.id }
        expect(response).to have_http_status(:forbidden)
      end

      it 'does not delete route set' do
        expect {
          delete :destroy, params: { id: recent_route_set.id }
        }.not_to change(RouteSet, :count)
      end
    end

    context 'when route set does not exist' do
      it 'returns not found' do
        delete :destroy, params: { id: 999999 }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'authorization checks' do
    context 'without valid token' do
      before do
        allow_any_instance_of(Api::BaseController)
          .to receive(:current_user)
          .and_return(nil)
      end

      it 'returns unauthorized for all actions' do
        get :index
        expect(response).to have_http_status(:unauthorized)

        get :show, params: { id: recent_route_set.id }
        expect(response).to have_http_status(:unauthorized)

        post :create, params: { grade_id: grade1.id }
        expect(response).to have_http_status(:unauthorized)

        patch :update, params: { id: recent_route_set.id }
        expect(response).to have_http_status(:unauthorized)

        delete :destroy, params: { id: recent_route_set.id }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end