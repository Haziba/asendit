require 'rails_helper'

RSpec.describe Api::V1::RoutesController, type: :controller do
  let!(:user) { create(:user) }
  let!(:another_user) { create(:user) }
  let!(:place) { create(:place, :with_grades, user: user) }
  let!(:another_place) { create(:place, :with_grades, user: another_user) }
  let!(:route_set) { create(:route_set, place: place, grade: place.grades.first) }
  let!(:another_route_set) { create(:route_set, place: another_place, grade: another_place.grades.first) }

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
    another_user.update(place: another_place)
  end

  describe 'GET #index' do
    let!(:route1) { create(:route, route_set: route_set, pos_x: 100, pos_y: 200) }
    let!(:route2) { create(:route, route_set: route_set, pos_x: 150, pos_y: 250) }
    let!(:other_place_route) { create(:route, route_set: another_route_set) }

    context 'without route_set_id parameter' do
      it 'returns all routes for user place' do
        get :index
        expect(response).to have_http_status(:success)

        json_response = JSON.parse(response.body)
        expect(json_response['routes'].count).to eq(2)

        route_ids = json_response['routes'].map { |r| r['id'] }
        expect(route_ids).to include(route1.id, route2.id)
        expect(route_ids).not_to include(other_place_route.id)
      end

      it 'includes route details with route_set info' do
        get :index
        json_response = JSON.parse(response.body)
        route_data = json_response['routes'].first

        expect(route_data).to include('id', 'pos_x', 'pos_y', 'floor', 'added')
        expect(route_data['route_set']).to include('id', 'name', 'grade')
      end
    end

    context 'with route_set_id parameter' do
      it 'returns routes for specific route set' do
        get :index, params: { route_set_id: route_set.id }
        expect(response).to have_http_status(:success)

        json_response = JSON.parse(response.body)
        expect(json_response['routes'].count).to eq(2)

        json_response['routes'].each do |route|
          expect(route['route_set']['id']).to eq(route_set.id)
        end
      end

      it 'returns empty array for route set with no routes' do
        empty_route_set = create(:route_set, place: place, grade: place.grades.last)

        get :index, params: { route_set_id: empty_route_set.id }
        json_response = JSON.parse(response.body)

        expect(json_response['routes']).to be_empty
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
    let!(:route) { create(:route, route_set: route_set, pos_x: 100, pos_y: 200, floor: 1) }
    let!(:other_place_route) { create(:route, route_set: another_route_set) }

    context 'when route belongs to user place' do
      it 'returns success response' do
        get :show, params: { id: route.id }
        expect(response).to have_http_status(:success)
      end

      it 'includes full route details' do
        get :show, params: { id: route.id }
        json_response = JSON.parse(response.body)
        route_data = json_response['route']

        expect(route_data['id']).to eq(route.id)
        expect(route_data['pos_x']).to eq(100)
        expect(route_data['pos_y']).to eq(200)
        expect(route_data['floor']).to eq(1)
        expect(route_data['route_set']['place']).to include('id', 'name')
      end
    end

    context 'when route belongs to different place' do
      it 'returns forbidden status' do
        get :show, params: { id: other_place_route.id }
        expect(response).to have_http_status(:forbidden)
      end

      it 'returns access denied error' do
        get :show, params: { id: other_place_route.id }
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Access denied')
      end
    end

    context 'when route does not exist' do
      it 'returns not found status' do
        get :show, params: { id: 999999 }
        expect(response).to have_http_status(:not_found)
      end

      it 'returns route not found error' do
        get :show, params: { id: 999999 }
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Route not found')
      end
    end
  end

  describe 'POST #create' do
    let(:valid_params) do
      {
        route_set_id: route_set.id,
        pos_x: 300,
        pos_y: 400,
        floor: 0
      }
    end

    context 'with valid parameters for user place' do
      it 'creates a new route' do
        expect {
          post :create, params: valid_params
        }.to change(Route, :count).by(1)
      end

      it 'returns created status' do
        post :create, params: valid_params
        expect(response).to have_http_status(:created)
      end

      it 'returns route data' do
        post :create, params: valid_params
        json_response = JSON.parse(response.body)
        route_data = json_response['route']

        expect(route_data['pos_x']).to eq(300)
        expect(route_data['pos_y']).to eq(400)
        expect(route_data['floor']).to eq(0)
        expect(route_data['route_set']['id']).to eq(route_set.id)
      end

      it 'sets added timestamp' do
        post :create, params: valid_params
        route = Route.last
        expect(route.added).to be_within(1.second).of(Time.now)
      end
    end

    context 'with route_set from different place' do
      it 'does not create route' do
        expect {
          post :create, params: valid_params.merge(route_set_id: another_route_set.id)
        }.not_to change(Route, :count)
      end

      it 'returns forbidden status' do
        post :create, params: valid_params.merge(route_set_id: another_route_set.id)
        expect(response).to have_http_status(:forbidden)
      end

      it 'returns access denied error' do
        post :create, params: valid_params.merge(route_set_id: another_route_set.id)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Access denied')
      end
    end

    context 'with invalid parameters' do
      it 'returns unprocessable entity for missing pos_x' do
        post :create, params: valid_params.except(:pos_x)
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns error message for validation failures' do
        post :create, params: valid_params.merge(pos_x: nil)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('error')
      end
    end

    context 'with non-existent route_set' do
      it 'raises record not found' do
        expect {
          post :create, params: valid_params.merge(route_set_id: 999999)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe 'DELETE #destroy' do
    let!(:route) { create(:route, route_set: route_set) }
    let!(:other_place_route) { create(:route, route_set: another_route_set) }

    context 'when route belongs to user place' do
      it 'deletes the route' do
        expect {
          delete :destroy, params: { id: route.id }
        }.to change(Route, :count).by(-1)
      end

      it 'returns success message' do
        delete :destroy, params: { id: route.id }
        expect(response).to have_http_status(:success)

        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq('Route deleted successfully')
      end
    end

    context 'when route belongs to different place' do
      it 'does not delete the route' do
        expect {
          delete :destroy, params: { id: other_place_route.id }
        }.not_to change(Route, :count)
      end

      it 'returns forbidden status' do
        delete :destroy, params: { id: other_place_route.id }
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when route does not exist' do
      it 'returns not found status' do
        delete :destroy, params: { id: 999999 }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'authentication and authorization' do
    let!(:route) { create(:route, route_set: route_set) }

    context 'without valid token' do
      before do
        allow_any_instance_of(Api::BaseController)
          .to receive(:current_user)
          .and_return(nil)
      end

      it 'returns unauthorized for all actions' do
        get :index
        expect(response).to have_http_status(:unauthorized)

        get :show, params: { id: route.id }
        expect(response).to have_http_status(:unauthorized)

        post :create, params: { route_set_id: route_set.id, pos_x: 100, pos_y: 200, floor: 0 }
        expect(response).to have_http_status(:unauthorized)

        delete :destroy, params: { id: route.id }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'user without place' do
      before { user.update(place: nil) }

      it 'returns empty routes for index' do
        get :index
        json_response = JSON.parse(response.body)
        expect(json_response['routes']).to be_empty
      end

      it 'returns forbidden for routes from other places' do
        get :show, params: { id: route.id }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end