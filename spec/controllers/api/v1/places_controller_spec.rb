require 'rails_helper'

RSpec.describe Api::V1::PlacesController, type: :controller do
  let!(:user) { create(:user) }
  let!(:another_user) { create(:user) }
  let!(:place1) { create(:place, :with_grades, user: user, name: 'User\'s Gym') }
  let!(:place2) { create(:place, :with_grades, user: another_user, name: 'Another Gym') }

  let(:auth0_payload) do
    {
      'sub' => user.google_uid,
      'email' => 'test@example.com',
      'name' => 'Test User'
    }
  end

  before do
    allow_any_instance_of(Api::BaseController)
      .to receive(:validate_token)
      .and_return(auth0_payload)

    user.update(place: place1)
  end

  describe 'GET #index' do
    context 'with valid authentication' do
      it 'returns all places' do
        get :index
        expect(response).to have_http_status(:success)

        json_response = JSON.parse(response.body)
        expect(json_response['places'].count).to be >= 2

        # Verify our specific places are included
        place_ids = json_response['places'].map { |p| p['id'] }
        expect(place_ids).to include(place1.id, place2.id)
      end

      it 'includes place details with owner info' do
        get :index
        json_response = JSON.parse(response.body)
        place_data = json_response['places'].first

        expect(place_data).to include('id', 'name', 'created_at', 'updated_at')
        expect(place_data['owner']).to include('id', 'email')
        expect(place_data).to include('grades_count', 'current_user_place')
      end

      it 'marks current user place correctly' do
        get :index
        json_response = JSON.parse(response.body)

        user_place = json_response['places'].find { |p| p['id'] == place1.id }
        other_place = json_response['places'].find { |p| p['id'] == place2.id }

        expect(user_place['current_user_place']).to be true
        expect(other_place['current_user_place']).to be false
      end
    end

    context 'without authentication' do
      before do
        allow_any_instance_of(Api::BaseController)
          .to receive(:validate_token)
          .and_return(nil)
      end

      it 'returns success status even without authentication' do
        get :index
        expect(response).to have_http_status(:success)
      end
    end

    context 'with location parameters' do
      let!(:nearby_place) { create(:place, latitude: 40.7589, longitude: -73.9851) } # NYC
      let!(:far_place) { create(:place, latitude: 34.0522, longitude: -118.2437) } # LA

      it 'returns places ordered by distance when lat/lng provided' do
        get :index, params: { latitude: 40.7614, longitude: -73.9776 } # Times Square
        expect(response).to have_http_status(:success)

        json_response = JSON.parse(response.body)
        places_with_coords = json_response['places'].select { |p| p['latitude'] && p['longitude'] }

        expect(places_with_coords.length).to be >= 2

        # First place should be closer (NYC) than second place (LA)
        if places_with_coords.length >= 2
          first_distance = places_with_coords[0]['distance_km']
          second_distance = places_with_coords[1]['distance_km']
          expect(first_distance).to be < second_distance
        end
      end

      it 'includes distance information in response' do
        get :index, params: { latitude: 40.7614, longitude: -73.9776 }
        json_response = JSON.parse(response.body)

        nearby_place_data = json_response['places'].find { |p| p['id'] == nearby_place.id }
        expect(nearby_place_data['distance_km']).to be_present
        expect(nearby_place_data['distance_km']).to be < 5 # Should be very close
      end

      it 'limits results to 20 places maximum' do
        # This test assumes we might have more than 20 places with coordinates
        get :index, params: { latitude: 40.7614, longitude: -73.9776 }
        json_response = JSON.parse(response.body)

        expect(json_response['places'].length).to be <= 20
      end

      it 'includes latitude and longitude in place data' do
        get :index
        json_response = JSON.parse(response.body)

        place_data = json_response['places'].find { |p| p['id'] == nearby_place.id }
        expect(place_data['latitude']).to eq(nearby_place.latitude.to_s)
        expect(place_data['longitude']).to eq(nearby_place.longitude.to_s)
      end
    end
  end

  describe 'GET #show' do
    context 'when place exists' do
      it 'returns place details' do
        get :show, params: { id: place1.id }
        expect(response).to have_http_status(:success)

        json_response = JSON.parse(response.body)
        place_data = json_response['place']

        expect(place_data['id']).to eq(place1.id)
        expect(place_data['name']).to eq('User\'s Gym')
        expect(place_data).to include('grades', 'owner', 'current_user_place')
      end

      it 'includes grades information' do
        get :show, params: { id: place1.id }
        json_response = JSON.parse(response.body)
        place_data = json_response['place']

        expect(place_data['grades']).to be_an(Array)
        expect(place_data['grades'].count).to eq(3) # from :with_grades trait

        grade = place_data['grades'].first
        expect(grade).to include('id', 'name', 'grade', 'map_tint_colour')
      end
    end

    context 'when place does not exist' do
      it 'returns not found status' do
        get :show, params: { id: 999999 }
        expect(response).to have_http_status(:not_found)
      end

      it 'returns place not found error' do
        get :show, params: { id: 999999 }
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Place not found')
      end
    end
  end

  describe 'POST #create' do
    let(:valid_params) { { name: 'New Climbing Gym' } }

    context 'with valid parameters' do
      it 'creates a new place' do
        expect {
          post :create, params: valid_params
        }.to change(Place, :count).by(1)
      end

      it 'creates associated floorplan' do
        expect {
          post :create, params: valid_params
        }.to change(Floorplan, :count).by(1)
      end

      it 'assigns place to current user' do
        post :create, params: valid_params

        place = Place.last
        expect(place.user).to eq(user)
        expect(place.name).to eq('New Climbing Gym')
      end

      it 'returns created status' do
        post :create, params: valid_params
        expect(response).to have_http_status(:created)
      end

      it 'returns place data' do
        post :create, params: valid_params
        json_response = JSON.parse(response.body)
        place_data = json_response['place']

        expect(place_data['name']).to eq('New Climbing Gym')
        expect(place_data['owner']['id']).to eq(user.id)
      end
    end

    context 'with invalid parameters' do
      it 'rejects blank name' do
        post :create, params: { name: '' }
        expect(response).to have_http_status(:unprocessable_entity)

        json_response = JSON.parse(response.body)
        expect(json_response['error']).to include('at least 4 characters')
      end

      it 'rejects short name' do
        post :create, params: { name: 'ABC' }
        expect(response).to have_http_status(:unprocessable_entity)

        json_response = JSON.parse(response.body)
        expect(json_response['error']).to include('at least 4 characters')
      end

      it 'rejects missing name' do
        post :create, params: {}
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'does not create place with invalid data' do
        expect {
          post :create, params: { name: 'ABC' }
        }.not_to change(Place, :count)
      end
    end
  end

  describe 'PATCH #update' do
    let(:valid_params) { { name: 'Updated Gym Name' } }

    context 'when user owns the place' do
      it 'updates the place name' do
        patch :update, params: { id: place1.id }.merge(valid_params)
        expect(response).to have_http_status(:success)

        place1.reload
        expect(place1.name).to eq('Updated Gym Name')
      end

      it 'returns updated place data' do
        patch :update, params: { id: place1.id }.merge(valid_params)
        json_response = JSON.parse(response.body)
        place_data = json_response['place']

        expect(place_data['name']).to eq('Updated Gym Name')
        expect(place_data).to include('id', 'updated_at')
      end
    end

    context 'when user does not own the place' do
      it 'returns forbidden status' do
        patch :update, params: { id: place2.id }.merge(valid_params)
        expect(response).to have_http_status(:forbidden)
      end

      it 'returns ownership error' do
        patch :update, params: { id: place2.id }.merge(valid_params)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Only the owner can update this place')
      end

      it 'does not update the place' do
        original_name = place2.name
        patch :update, params: { id: place2.id }.merge(valid_params)

        place2.reload
        expect(place2.name).to eq(original_name)
      end
    end

    context 'with invalid parameters' do
      it 'rejects blank name' do
        patch :update, params: { id: place1.id, name: '' }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'rejects short name' do
        patch :update, params: { id: place1.id, name: 'ABC' }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'when place does not exist' do
      it 'returns not found status' do
        patch :update, params: { id: 999999 }.merge(valid_params)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'POST #choose' do
    context 'when place exists' do
      it 'updates user current place' do
        post :choose, params: { id: place2.id }
        expect(response).to have_http_status(:success)

        user.reload
        expect(user.place).to eq(place2)
      end

      it 'returns success message with place info' do
        post :choose, params: { id: place2.id }
        json_response = JSON.parse(response.body)

        expect(json_response['message']).to eq('Place selected successfully')
        expect(json_response['selected_place']['id']).to eq(place2.id)
        expect(json_response['selected_place']['name']).to eq('Another Gym')
      end
    end

    context 'when place does not exist' do
      it 'returns not found status' do
        post :choose, params: { id: 999999 }
        expect(response).to have_http_status(:not_found)
      end

      it 'returns place not found error' do
        post :choose, params: { id: 999999 }
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Place not found')
      end

      it 'does not change user place' do
        original_place = user.place
        post :choose, params: { id: 999999 }

        user.reload
        expect(user.place).to eq(original_place)
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'when user owns the place' do
      let!(:owned_place) { create(:place, user: user, name: 'Place to Delete') }

      context 'and no users are using it' do
        it 'deletes the place' do
          expect {
            delete :destroy, params: { id: owned_place.id }
          }.to change(Place, :count).by(-1)
        end

        it 'returns success message' do
          delete :destroy, params: { id: owned_place.id }
          expect(response).to have_http_status(:success)

          json_response = JSON.parse(response.body)
          expect(json_response['message']).to eq('Place deleted successfully')
        end
      end

      context 'but users are still using it' do
        before { another_user.update(place: owned_place) }

        it 'does not delete the place' do
          expect {
            delete :destroy, params: { id: owned_place.id }
          }.not_to change(Place, :count)
        end

        it 'returns error message' do
          delete :destroy, params: { id: owned_place.id }
          expect(response).to have_http_status(:unprocessable_entity)

          json_response = JSON.parse(response.body)
          expect(json_response['error']).to include('Cannot delete place while users are using it')
        end
      end
    end

    context 'when user does not own the place' do
      it 'returns forbidden status' do
        delete :destroy, params: { id: place2.id }
        expect(response).to have_http_status(:forbidden)
      end

      it 'returns ownership error' do
        delete :destroy, params: { id: place2.id }
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Only the owner can delete this place')
      end

      it 'does not delete the place' do
        expect {
          delete :destroy, params: { id: place2.id }
        }.not_to change(Place, :count)
      end
    end

    context 'when place does not exist' do
      it 'returns not found status' do
        delete :destroy, params: { id: 999999 }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'authentication and authorization' do
    context 'without valid token' do
      before do
        allow_any_instance_of(Api::BaseController)
          .to receive(:validate_token)
          .and_return(nil)
      end

      it 'returns success for index but unauthorized for other actions' do
        get :index
        expect(response).to have_http_status(:success)

        get :show, params: { id: place1.id }
        expect(response).to have_http_status(:unauthorized)

        post :create, params: { name: 'Test Gym' }
        expect(response).to have_http_status(:unauthorized)

        patch :update, params: { id: place1.id, name: 'Updated' }
        expect(response).to have_http_status(:unauthorized)

        post :choose, params: { id: place1.id }
        expect(response).to have_http_status(:unauthorized)

        delete :destroy, params: { id: place1.id }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end