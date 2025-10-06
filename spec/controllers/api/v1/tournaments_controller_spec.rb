require 'rails_helper'

RSpec.describe Api::V1::TournamentsController, type: :controller do
  let!(:admin_user) { create(:user, admin: true) }
  let!(:regular_user) { create(:user, admin: false) }
  let!(:another_user) { create(:user) }

  let!(:place) { create(:place, :with_grades, user: admin_user) }
  let!(:another_place) { create(:place, :with_grades, user: another_user) }

  let!(:route_set) { create(:route_set, :with_routes, place: place, grade: place.grades.first) }
  let!(:route1) { route_set.routes.first }
  let!(:route2) { route_set.routes.last }

  let!(:tournament) do
    create(:tournament,
      place: place,
      name: 'Test Tournament',
      starting: Date.tomorrow,
      ending: Date.tomorrow + 7.days
    )
  end

  let!(:another_tournament) do
    create(:tournament,
      place: another_place,
      name: 'Other Tournament'
    )
  end

  let(:auth0_payload) do
    {
      'sub' => regular_user.google_uid,
      'email' => 'test@example.com',
      'name' => 'Test User'
    }
  end

  before do
    allow_any_instance_of(Api::BaseController)
      .to receive(:validate_token)
      .and_return(auth0_payload)

    regular_user.update(place: place)
  end

  describe 'GET #index' do
    context 'with valid place' do
      it 'returns tournaments for the place' do
        get :index, params: { place_id: place.id }
        expect(response).to have_http_status(:success)

        json_response = JSON.parse(response.body)
        expect(json_response['tournaments'].count).to eq(1)
        expect(json_response['tournaments'].first['id']).to eq(tournament.id)
      end

      it 'includes tournament summary info' do
        get :index, params: { place_id: place.id }
        json_response = JSON.parse(response.body)
        tournament_data = json_response['tournaments'].first

        expect(tournament_data).to include('id', 'name', 'starting', 'ending', 'route_count', 'status')
        expect(tournament_data['status']).to eq('upcoming')
      end

      it 'does not include tournaments from other places' do
        get :index, params: { place_id: place.id }
        json_response = JSON.parse(response.body)

        tournament_ids = json_response['tournaments'].map { |t| t['id'] }
        expect(tournament_ids).not_to include(another_tournament.id)
      end
    end

    context 'without place_id' do
      it 'uses user current place' do
        get :index
        expect(response).to have_http_status(:success)

        json_response = JSON.parse(response.body)
        expect(json_response['tournaments'].first['id']).to eq(tournament.id)
      end
    end

    context 'without authentication' do
      before do
        allow_any_instance_of(Api::BaseController)
          .to receive(:validate_token)
          .and_return(nil)
      end

      it 'returns unauthorized' do
        get :index
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'GET #show' do
    let!(:tournament_route1) { create(:tournament_route, tournament: tournament, route: route1, order: 1) }
    let!(:tournament_route2) { create(:tournament_route, tournament: tournament, route: route2, order: 2) }

    context 'when tournament exists' do
      it 'returns tournament details' do
        get :show, params: { id: tournament.id }
        expect(response).to have_http_status(:success)

        json_response = JSON.parse(response.body)
        expect(json_response['tournament']['id']).to eq(tournament.id)
        expect(json_response['tournament']).to include('place', 'can_edit')
      end

      it 'includes tournament routes in order' do
        get :show, params: { id: tournament.id }
        json_response = JSON.parse(response.body)

        expect(json_response['tournament_routes'].count).to eq(2)
        expect(json_response['tournament_routes'][0]['order']).to eq(1)
        expect(json_response['tournament_routes'][1]['order']).to eq(2)
      end

      it 'includes route details with route_set info' do
        get :show, params: { id: tournament.id }
        json_response = JSON.parse(response.body)
        route_data = json_response['tournament_routes'].first['route']

        expect(route_data).to include('id', 'pos_x', 'pos_y', 'floorplan_image_id')
        expect(route_data['route_set']).to include('id', 'name', 'grade')
      end
    end

    context 'when tournament does not exist' do
      it 'returns not found' do
        get :show, params: { id: 999999 }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'POST #create' do
    let(:valid_params) do
      {
        name: 'New Competition',
        starting: (Date.today + 2.days).to_s,
        ending: (Date.today + 9.days).to_s,
        place_id: place.id
      }
    end

    context 'as admin user' do
      before do
        allow_any_instance_of(Api::BaseController)
          .to receive(:validate_token)
          .and_return({ 'sub' => admin_user.google_uid })
      end

      it 'creates new tournament' do
        expect {
          post :create, params: valid_params
        }.to change(Tournament, :count).by(1)
      end

      it 'returns created status' do
        post :create, params: valid_params
        expect(response).to have_http_status(:created)

        json_response = JSON.parse(response.body)
        expect(json_response['tournament']['name']).to eq('New Competition')
      end

      it 'uses default dates if not provided' do
        post :create, params: { name: 'Default Dates Tournament', place_id: place.id }

        tournament = Tournament.last
        expect(tournament.starting).to eq(Date.tomorrow)
        expect(tournament.ending).to eq(Date.tomorrow + 7.days)
      end
    end

    context 'as regular user' do
      it 'returns forbidden' do
        post :create, params: valid_params
        expect(response).to have_http_status(:forbidden)
      end

      it 'does not create tournament' do
        expect {
          post :create, params: valid_params
        }.not_to change(Tournament, :count)
      end
    end

    context 'with invalid parameters' do
      before do
        allow_any_instance_of(Api::BaseController)
          .to receive(:validate_token)
          .and_return({ 'sub' => admin_user.google_uid })
      end

      it 'returns error for missing name' do
        post :create, params: valid_params.except(:name)
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns error for invalid date format' do
        post :create, params: valid_params.merge(starting: 'invalid-date')
        expect(response).to have_http_status(:unprocessable_entity)

        json_response = JSON.parse(response.body)
        expect(json_response['error']).to include('Invalid date format')
      end

      it 'returns error when ending before starting' do
        post :create, params: valid_params.merge(
          starting: Date.today + 5.days,
          ending: Date.today + 2.days
        )
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'PATCH #update' do
    let(:update_params) do
      {
        id: tournament.id,
        name: 'Updated Tournament Name',
        starting: (Date.today + 3.days).to_s
      }
    end

    context 'as admin user' do
      before do
        allow_any_instance_of(Api::BaseController)
          .to receive(:validate_token)
          .and_return({ 'sub' => admin_user.google_uid })
      end

      it 'updates tournament' do
        patch :update, params: update_params
        expect(response).to have_http_status(:success)

        tournament.reload
        expect(tournament.name).to eq('Updated Tournament Name')
        expect(tournament.starting).to eq(Date.today + 3.days)
      end

      it 'returns updated tournament' do
        patch :update, params: update_params
        json_response = JSON.parse(response.body)

        expect(json_response['tournament']['name']).to eq('Updated Tournament Name')
      end
    end

    context 'as regular user' do
      it 'returns forbidden' do
        patch :update, params: update_params
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'with invalid date' do
      before do
        allow_any_instance_of(Api::BaseController)
          .to receive(:validate_token)
          .and_return({ 'sub' => admin_user.google_uid })
      end

      it 'returns error for invalid date format' do
        patch :update, params: { id: tournament.id, ending: 'not-a-date' }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'PATCH #update_routes' do
    let(:update_routes_params) do
      {
        id: tournament.id,
        tournament_routes: [
          { route_id: route1.id, order: 1 },
          { route_id: route2.id, order: 2 }
        ]
      }
    end

    context 'as admin user' do
      before do
        allow_any_instance_of(Api::BaseController)
          .to receive(:validate_token)
          .and_return({ 'sub' => admin_user.google_uid })
      end

      it 'creates tournament routes' do
        expect {
          patch :update_routes, params: update_routes_params
        }.to change(TournamentRoute, :count).by(2)
      end

      it 'updates existing tournament route orders' do
        tournament_route = create(:tournament_route, tournament: tournament, route: route1, order: 5)

        patch :update_routes, params: update_routes_params

        tournament_route.reload
        expect(tournament_route.order).to eq(1)
      end

      it 'removes routes not in update list' do
        extra_route = create(:tournament_route, tournament: tournament, route: route1, order: 1)

        patch :update_routes, params: {
          id: tournament.id,
          tournament_routes: [{ route_id: route2.id, order: 1 }]
        }

        expect(TournamentRoute.exists?(extra_route.id)).to be false
      end

      it 'returns success with route count' do
        patch :update_routes, params: update_routes_params
        json_response = JSON.parse(response.body)

        expect(json_response['success']).to be true
        expect(json_response['tournament_routes_count']).to eq(2)
      end

      it 'ignores routes from other places' do
        other_route = create(:route, route_set: create(:route_set, place: another_place))

        patch :update_routes, params: {
          id: tournament.id,
          tournament_routes: [{ route_id: other_route.id, order: 1 }]
        }

        expect(tournament.tournament_routes.count).to eq(0)
      end
    end

    context 'as regular user' do
      it 'returns forbidden' do
        patch :update_routes, params: update_routes_params
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'as admin user' do
      before do
        allow_any_instance_of(Api::BaseController)
          .to receive(:validate_token)
          .and_return({ 'sub' => admin_user.google_uid })
      end

      it 'deletes tournament' do
        expect {
          delete :destroy, params: { id: tournament.id }
        }.to change(Tournament, :count).by(-1)
      end

      it 'deletes associated tournament routes' do
        create(:tournament_route, tournament: tournament, route: route1)
        create(:tournament_route, tournament: tournament, route: route2)

        expect {
          delete :destroy, params: { id: tournament.id }
        }.to change(TournamentRoute, :count).by(-2)
      end

      it 'returns success message' do
        delete :destroy, params: { id: tournament.id }
        expect(response).to have_http_status(:success)

        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq('Tournament deleted successfully')
      end
    end

    context 'as regular user' do
      it 'returns forbidden' do
        delete :destroy, params: { id: tournament.id }
        expect(response).to have_http_status(:forbidden)
      end

      it 'does not delete tournament' do
        expect {
          delete :destroy, params: { id: tournament.id }
        }.not_to change(Tournament, :count)
      end
    end

    context 'when tournament does not exist' do
      it 'returns not found' do
        delete :destroy, params: { id: 999999 }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'tournament status' do
    it 'returns upcoming for future tournaments' do
      future_tournament = create(:tournament,
        place: place,
        starting: Date.today + 5.days,
        ending: Date.today + 10.days
      )

      get :show, params: { id: future_tournament.id }
      json_response = JSON.parse(response.body)

      expect(json_response['tournament']['status']).to eq('upcoming')
    end

    it 'returns active for current tournaments' do
      active_tournament = create(:tournament,
        place: place,
        starting: Date.today - 2.days,
        ending: Date.today + 2.days
      )

      get :show, params: { id: active_tournament.id }
      json_response = JSON.parse(response.body)

      expect(json_response['tournament']['status']).to eq('active')
    end

    it 'returns ended for past tournaments' do
      past_tournament = create(:tournament,
        place: place,
        starting: Date.today - 10.days,
        ending: Date.today - 5.days
      )

      get :show, params: { id: past_tournament.id }
      json_response = JSON.parse(response.body)

      expect(json_response['tournament']['status']).to eq('ended')
    end
  end
end