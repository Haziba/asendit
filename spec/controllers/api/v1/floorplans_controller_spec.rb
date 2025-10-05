require 'rails_helper'

RSpec.describe Api::V1::FloorplansController, type: :controller do
  include ActiveSupport::Testing::TimeHelpers
  include ActionDispatch::TestProcess::FixtureFile

  let!(:admin_user) { create(:user, admin: true) }
  let!(:regular_user) { create(:user, admin: false) }
  let!(:another_user) { create(:user) }

  let!(:place_with_floorplan) { create(:place, :with_floorplan, user: admin_user) }
  let!(:place_without_floorplan) { create(:place, user: regular_user) }
  let!(:another_place) { create(:place, :with_floorplan, user: another_user) }

  let!(:floorplan) { place_with_floorplan.floorplan }
  let!(:another_floorplan) { another_place.floorplan }

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

    regular_user.update(place: place_with_floorplan)
  end

  describe 'GET #index' do
    context 'with place that has floorplan' do
      it 'returns floorplan for the place' do
        get :index, params: { place_id: place_with_floorplan.id }
        expect(response).to have_http_status(:success)

        json_response = JSON.parse(response.body)
        expect(json_response['floorplan']).to be_present
        expect(json_response['floorplan']['id']).to eq(floorplan.id)
      end

      it 'includes floorplan summary info' do
        get :index, params: { place_id: place_with_floorplan.id }
        json_response = JSON.parse(response.body)

        expect(json_response['floorplan']).to include('id', 'name', 'data', 'images_count')
      end
    end

    context 'with place without floorplan' do
      it 'returns null floorplan' do
        get :index, params: { place_id: place_without_floorplan.id }
        expect(response).to have_http_status(:success)

        json_response = JSON.parse(response.body)
        expect(json_response['floorplan']).to be_nil
      end
    end

    context 'without place_id' do
      it 'uses user current place' do
        get :index
        expect(response).to have_http_status(:success)

        json_response = JSON.parse(response.body)
        expect(json_response['floorplan']['id']).to eq(floorplan.id)
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
    context 'when floorplan exists' do
      it 'returns floorplan details' do
        get :show, params: { id: floorplan.id, place_id: place_with_floorplan.id }
        expect(response).to have_http_status(:success)

        json_response = JSON.parse(response.body)
        expect(json_response['floorplan']['id']).to eq(floorplan.id)
        expect(json_response['floorplan']).to include('place', 'can_edit', 'images')
      end

      it 'includes place information' do
        get :show, params: { id: floorplan.id, place_id: place_with_floorplan.id }
        json_response = JSON.parse(response.body)

        expect(json_response['floorplan']['place']).to include('id', 'name')
        expect(json_response['floorplan']['place']['id']).to eq(place_with_floorplan.id)
      end

      it 'includes images data' do
        # Attach test images to floorplan
        floorplan.images.attach(
          io: StringIO.new('test image content'),
          filename: 'test.png',
          content_type: 'image/png'
        )

        get :show, params: { id: floorplan.id, place_id: place_with_floorplan.id }
        json_response = JSON.parse(response.body)

        expect(json_response['floorplan']['images']).to be_an(Array)
        expect(json_response['floorplan']['images'].first).to include('id', 'url', 'filename', 'content_type')
      end

      it 'includes can_edit permission' do
        allow_any_instance_of(Place).to receive(:can_edit?).and_return(true)

        get :show, params: { id: floorplan.id, place_id: place_with_floorplan.id }
        json_response = JSON.parse(response.body)

        expect(json_response['floorplan']['can_edit']).to be_truthy
      end
    end

    context 'when place has no floorplan' do
      it 'returns not found' do
        get :show, params: { id: 999999, place_id: place_without_floorplan.id }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'POST #create' do
    let(:valid_params) do
      {
        name: 'New Floorplan',
        data: [{ id: 0, name: 'Ground Floor', image_id: 1 }],
        place_id: place_without_floorplan.id
      }
    end

    context 'with admin permissions' do
      before do
        allow_any_instance_of(Api::BaseController)
          .to receive(:validate_token)
          .and_return({ 'sub' => admin_user.google_uid })
      end

      it 'creates new floorplan' do
        expect {
          post :create, params: valid_params
        }.to change(Floorplan, :count).by(1)
      end

      it 'returns created status' do
        post :create, params: valid_params
        expect(response).to have_http_status(:created)

        json_response = JSON.parse(response.body)
        expect(json_response['floorplan']['name']).to eq('New Floorplan')
      end

      it 'assigns floorplan to correct place' do
        post :create, params: valid_params
        new_floorplan = Floorplan.last
        expect(new_floorplan.place).to eq(place_without_floorplan)
      end
    end

    context 'with place owner permissions' do
      let!(:owner_user) { place_without_floorplan.user }

      before do
        allow_any_instance_of(Api::BaseController)
          .to receive(:validate_token)
          .and_return({ 'sub' => owner_user.google_uid })
      end

      it 'creates new floorplan' do
        expect {
          post :create, params: valid_params
        }.to change(Floorplan, :count).by(1)
      end
    end

    context 'without permissions' do
      let(:other_place) { create(:place, user: another_user) }

      before do
        regular_user.update(place: another_place)
      end

      it 'returns forbidden' do
        post :create, params: { name: 'New Floorplan', place_id: other_place.id }
        expect(response).to have_http_status(:forbidden)
      end

      it 'does not create floorplan' do
        expect {
          post :create, params: { name: 'New Floorplan', place_id: other_place.id }
        }.not_to change(Floorplan, :count)
      end
    end
  end

  describe 'PATCH #update' do
    let(:update_params) do
      {
        id: floorplan.id,
        place_id: place_with_floorplan.id,
        name: 'Updated Floorplan Name',
        data: [{ id: 0, name: 'Updated Floor', image_id: 2 }]
      }
    end

    context 'with admin permissions' do
      before do
        allow_any_instance_of(Api::BaseController)
          .to receive(:validate_token)
          .and_return({ 'sub' => admin_user.google_uid })
      end

      it 'updates floorplan' do
        patch :update, params: update_params
        expect(response).to have_http_status(:success)

        floorplan.reload
        expect(floorplan.name).to eq('Updated Floorplan Name')
        expect(floorplan.data).to eq([{ 'id' => '0', 'name' => 'Updated Floor', 'image_id' => '2' }])
      end

      it 'returns updated floorplan' do
        patch :update, params: update_params
        json_response = JSON.parse(response.body)

        expect(json_response['floorplan']['name']).to eq('Updated Floorplan Name')
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
  end

  describe 'PATCH #update_data' do
    let(:update_data_params) do
      {
        id: floorplan.id,
        place_id: place_with_floorplan.id,
        data: [
          { id: 0, name: 'Ground Floor', image_id: 1 },
          { id: 1, name: 'First Floor', image_id: 2 }
        ]
      }
    end

    context 'with admin permissions' do
      before do
        allow_any_instance_of(Api::BaseController)
          .to receive(:validate_token)
          .and_return({ 'sub' => admin_user.google_uid })
      end

      it 'updates floorplan data' do
        patch :update_data, params: update_data_params
        expect(response).to have_http_status(:success)

        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true

        floorplan.reload
        expect(floorplan.data.length).to eq(2)
      end
    end

    context 'without permissions' do
      before do
        regular_user.update(place: another_place)
      end

      it 'returns forbidden' do
        patch :update_data, params: update_data_params
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'POST #upload_image' do
    let(:image_file) do
      fixture_file_upload(Rails.root.join('spec/fixtures/files/test_image.png'), 'image/png')
    end

    let(:upload_params) do
      {
        id: floorplan.id,
        place_id: place_with_floorplan.id,
        image: image_file
      }
    end

    context 'with admin permissions' do
      before do
        allow_any_instance_of(Api::BaseController)
          .to receive(:validate_token)
          .and_return({ 'sub' => admin_user.google_uid })
      end

      it 'uploads image successfully' do
        expect {
          post :upload_image, params: upload_params
        }.to change { floorplan.reload.images.count }.by(1)

        expect(response).to have_http_status(:success)
      end

      it 'returns image details' do
        post :upload_image, params: upload_params
        json_response = JSON.parse(response.body)

        expect(json_response['success']).to be true
        expect(json_response['image']).to include('id', 'url')
      end

      it 'returns error when no image provided' do
        post :upload_image, params: { id: floorplan.id, place_id: place_with_floorplan.id }
        expect(response).to have_http_status(:bad_request)

        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('No image provided')
      end
    end

    context 'without permissions' do
      before do
        regular_user.update(place: another_place)
      end

      it 'returns forbidden' do
        post :upload_image, params: upload_params
        expect(response).to have_http_status(:forbidden)
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

      it 'deletes floorplan' do
        expect {
          delete :destroy, params: { id: floorplan.id, place_id: place_with_floorplan.id }
        }.to change(Floorplan, :count).by(-1)
      end

      it 'purges attached images' do
        # The factory creates a floorplan with 2 images already attached
        # We add one more for a total of 3
        floorplan.images.attach(
          io: StringIO.new('test image content'),
          filename: 'test.png',
          content_type: 'image/png'
        )

        expect(floorplan.images.count).to eq(3)

        expect {
          delete :destroy, params: { id: floorplan.id, place_id: place_with_floorplan.id }
        }.to change { ActiveStorage::Attachment.count }.by(-3)
      end

      it 'returns success message' do
        delete :destroy, params: { id: floorplan.id, place_id: place_with_floorplan.id }
        expect(response).to have_http_status(:success)

        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq('Floorplan deleted successfully')
      end
    end

    context 'without permissions' do
      before do
        regular_user.update(place: another_place)
      end

      it 'returns forbidden' do
        delete :destroy, params: { id: floorplan.id, place_id: place_with_floorplan.id }
        expect(response).to have_http_status(:forbidden)
      end

      it 'does not delete floorplan' do
        expect {
          delete :destroy, params: { id: floorplan.id, place_id: place_with_floorplan.id }
        }.not_to change(Floorplan, :count)
      end
    end
  end

  describe 'floorplan serialization' do
    it 'includes all required fields in summary' do
      get :index, params: { place_id: place_with_floorplan.id }
      json_response = JSON.parse(response.body)
      floorplan_data = json_response['floorplan']

      expect(floorplan_data).to include(
        'id', 'name', 'data', 'images_count',
        'created_at', 'updated_at'
      )
    end

    it 'includes all required fields in detail' do
      get :show, params: { id: floorplan.id, place_id: place_with_floorplan.id }
      json_response = JSON.parse(response.body)
      floorplan_data = json_response['floorplan']

      expect(floorplan_data).to include(
        'id', 'name', 'data', 'images_count',
        'place', 'images', 'can_edit',
        'created_at', 'updated_at'
      )
    end
  end
end