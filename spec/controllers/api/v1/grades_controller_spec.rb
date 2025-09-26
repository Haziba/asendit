require 'rails_helper'

RSpec.describe Api::V1::GradesController, type: :controller do
  include ActiveSupport::Testing::TimeHelpers
  let!(:admin_user) { create(:user, admin: true) }
  let!(:regular_user) { create(:user, admin: false) }
  let!(:another_user) { create(:user) }

  let!(:place) { create(:place, :with_grades, user: admin_user) }
  let!(:another_place) { create(:place, :with_grades, user: another_user) }

  let!(:grade) { place.grades.first }
  let!(:another_grade) { another_place.grades.first }

  let!(:route_set) { create(:route_set, place: place, grade: grade) }

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
      it 'returns grades for the place' do
        get :index, params: { place_id: place.id }
        expect(response).to have_http_status(:success)

        json_response = JSON.parse(response.body)
        expect(json_response['grades'].count).to eq(3)
        expect(json_response['grades'].first['id']).to eq(grade.id)
      end

      it 'includes grade summary info' do
        get :index, params: { place_id: place.id }
        json_response = JSON.parse(response.body)
        grade_data = json_response['grades'].first

        expect(grade_data).to include('id', 'name', 'grade', 'map_tint_colour', 'route_sets_count', 'active_route_set')
        expect(grade_data['route_sets_count']).to eq(1)
      end

      it 'includes active route set info' do
        get :index, params: { place_id: place.id }
        json_response = JSON.parse(response.body)
        grade_data = json_response['grades'].first

        expect(grade_data['active_route_set']).to include('id', 'name', 'added')
        expect(grade_data['active_route_set']['id']).to eq(route_set.id)
      end

      it 'does not include grades from other places' do
        get :index, params: { place_id: place.id }
        json_response = JSON.parse(response.body)

        grade_ids = json_response['grades'].map { |g| g['id'] }
        expect(grade_ids).not_to include(another_grade.id)
      end
    end

    context 'without place_id' do
      it 'uses user current place' do
        get :index
        expect(response).to have_http_status(:success)

        json_response = JSON.parse(response.body)
        expect(json_response['grades'].count).to eq(3)
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
    context 'when grade exists' do
      it 'returns grade details' do
        get :show, params: { id: grade.id }
        expect(response).to have_http_status(:success)

        json_response = JSON.parse(response.body)
        expect(json_response['grade']['id']).to eq(grade.id)
        expect(json_response['grade']).to include('place', 'can_edit', 'route_sets')
      end

      it 'includes place information' do
        get :show, params: { id: grade.id }
        json_response = JSON.parse(response.body)

        expect(json_response['grade']['place']).to include('id', 'name')
        expect(json_response['grade']['place']['id']).to eq(place.id)
      end

      it 'includes route sets ordered by added date' do
        # Create a newer route set to test ordering
        newer_route_set = nil
        travel_to 1.day.from_now do
          newer_route_set = create(:route_set, place: place, grade: grade)
        end

        get :show, params: { id: grade.id }
        json_response = JSON.parse(response.body)

        route_sets = json_response['grade']['route_sets']
        expect(route_sets.count).to be >= 2
        expect(route_sets.first['id']).to eq(newer_route_set.id)
      end

      it 'includes can_edit permission' do
        allow_any_instance_of(Place).to receive(:can_edit?).with(regular_user).and_return(true)

        get :show, params: { id: grade.id }
        json_response = JSON.parse(response.body)

        expect(json_response['grade']['can_edit']).to be_truthy
      end
    end

    context 'when grade does not exist' do
      it 'returns not found' do
        get :show, params: { id: 999999 }
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when grade belongs to different place' do
      it 'returns not found' do
        get :show, params: { id: another_grade.id, place_id: place.id }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'POST #create' do
    let(:valid_params) do
      {
        name: 'New Grade',
        grade: 'V5',
        map_tint_colour: '#FF5733',
        place_id: place.id
      }
    end

    context 'with admin permissions' do
      before do
        allow_any_instance_of(Api::BaseController)
          .to receive(:validate_token)
          .and_return({ 'sub' => admin_user.google_uid })
      end

      it 'creates new grade' do
        expect {
          post :create, params: valid_params
        }.to change(Grade, :count).by(1)
      end

      it 'returns created status' do
        post :create, params: valid_params
        expect(response).to have_http_status(:created)

        json_response = JSON.parse(response.body)
        expect(json_response['grade']['name']).to eq('New Grade')
        expect(json_response['grade']['grade']).to eq('V5')
      end

      it 'assigns grade to correct place' do
        post :create, params: valid_params
        new_grade = Grade.last
        expect(new_grade.place).to eq(place)
      end
    end

    context 'with place owner permissions' do
      let!(:owner_user) { place.user }

      before do
        allow_any_instance_of(Api::BaseController)
          .to receive(:validate_token)
          .and_return({ 'sub' => owner_user.google_uid })
      end

      it 'creates new grade' do
        expect {
          post :create, params: valid_params
        }.to change(Grade, :count).by(1)
      end
    end

    context 'without permissions' do
      before do
        regular_user.update(place: another_place)
      end

      it 'returns forbidden' do
        post :create, params: valid_params
        expect(response).to have_http_status(:forbidden)
      end

      it 'does not create grade' do
        expect {
          post :create, params: valid_params
        }.not_to change(Grade, :count)
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

        json_response = JSON.parse(response.body)
        expect(json_response['error']).to be_present
      end
    end
  end

  describe 'PATCH #update' do
    let(:update_params) do
      {
        id: grade.id,
        name: 'Updated Grade Name',
        grade: 'V6',
        map_tint_colour: '#00FF00'
      }
    end

    context 'with admin permissions' do
      before do
        allow_any_instance_of(Api::BaseController)
          .to receive(:validate_token)
          .and_return({ 'sub' => admin_user.google_uid })
      end

      it 'updates grade' do
        patch :update, params: update_params
        expect(response).to have_http_status(:success)

        grade.reload
        expect(grade.name).to eq('Updated Grade Name')
        expect(grade.grade).to eq('V6')
        expect(grade.map_tint_colour).to eq('#00FF00')
      end

      it 'returns updated grade' do
        patch :update, params: update_params
        json_response = JSON.parse(response.body)

        expect(json_response['grade']['name']).to eq('Updated Grade Name')
        expect(json_response['grade']['grade']).to eq('V6')
      end

      it 'allows partial updates' do
        patch :update, params: { id: grade.id, name: 'Only Name Changed' }
        expect(response).to have_http_status(:success)

        grade.reload
        expect(grade.name).to eq('Only Name Changed')
      end
    end

    context 'with place owner permissions' do
      before do
        allow_any_instance_of(Place).to receive(:can_edit?).with(regular_user).and_return(true)
      end

      it 'updates grade' do
        patch :update, params: update_params
        expect(response).to have_http_status(:success)
      end
    end

    context 'without permissions' do
      before do
        regular_user.update(place: another_place)
      end

      it 'returns forbidden' do
        patch :update, params: update_params
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when grade does not exist' do
      it 'returns not found' do
        patch :update, params: { id: 999999, name: 'Test' }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'with admin permissions' do
      before do
        allow_any_instance_of(Api::BaseController)
          .to receive(:validate_token)
          .and_return({ 'sub' => admin_user.google_uid })
      end

      context 'when grade has no route sets' do
        let!(:empty_grade) { create(:grade, place: place) }

        it 'deletes grade' do
          expect {
            delete :destroy, params: { id: empty_grade.id }
          }.to change(Grade, :count).by(-1)
        end

        it 'returns success message' do
          delete :destroy, params: { id: empty_grade.id }
          expect(response).to have_http_status(:success)

          json_response = JSON.parse(response.body)
          expect(json_response['message']).to eq('Grade deleted successfully')
        end
      end

      context 'when grade has route sets' do
        it 'returns error' do
          delete :destroy, params: { id: grade.id }
          expect(response).to have_http_status(:unprocessable_entity)

          json_response = JSON.parse(response.body)
          expect(json_response['error']).to eq('Cannot delete grade with existing route sets')
        end

        it 'does not delete grade' do
          expect {
            delete :destroy, params: { id: grade.id }
          }.not_to change(Grade, :count)
        end
      end
    end

    context 'without permissions' do
      before do
        regular_user.update(place: another_place)
      end

      it 'returns forbidden' do
        delete :destroy, params: { id: grade.id }
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when grade does not exist' do
      it 'returns not found' do
        delete :destroy, params: { id: 999999 }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'grade serialization' do
    it 'includes all required fields in summary' do
      get :index, params: { place_id: place.id }
      json_response = JSON.parse(response.body)
      grade_data = json_response['grades'].first

      expect(grade_data).to include(
        'id', 'name', 'grade', 'map_tint_colour',
        'route_sets_count', 'active_route_set'
      )
    end

    it 'includes all required fields in detail' do
      get :show, params: { id: grade.id }
      json_response = JSON.parse(response.body)
      grade_data = json_response['grade']

      expect(grade_data).to include(
        'id', 'name', 'grade', 'map_tint_colour',
        'route_sets_count', 'active_route_set',
        'place', 'route_sets', 'can_edit',
        'created_at', 'updated_at'
      )
    end
  end
end