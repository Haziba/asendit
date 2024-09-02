require 'rails_helper'

RSpec.describe ColourSetColoursController, type: :controller do
  let(:colour_set) { create(:route_set_colour_set)}

  describe 'GET #index' do
    it 'returns a success response' do
      get :index, params: { place_id: colour_set.place_id, colour_set_id: colour_set.id }
      expect(response).to be_successful
    end
  end

  describe 'GET #show' do
    let(:colour_set_colour) { create(:route_set_colour_set_colour) }

    it 'returns a success response' do
      get :show, params: { id: colour_set_colour.id, place_id: colour_set.place_id, colour_set_id: colour_set.id }
      expect(response).to be_successful
    end
  end

  describe 'POST #create' do
    let(:valid_params) { { colour_set_colour: { colour: 'Red', grade: 'V1', map_tint_colour: '#FF0000', route_set_colour_set_id: colour_set.id }, place_id: colour_set.place_id, colour_set_id: colour_set.id } }

    context 'with valid params' do
      it 'creates a new colour set colour' do
        post :create, params: valid_params
        expect(RouteSetColourSetColour.exists?(colour: 'Red', grade: 'V1', map_tint_colour: '#FF0000')).to be_truthy
      end

      it 'returns a success response' do
        post :create, params: valid_params
        expect(response).to be_successful
      end
    end

    context 'with invalid params' do
      it 'does not create a new colour set colour' do
        post :create, params: { colour_set_colour: { colour: nil, map_tint_colour: '#FF0000' }, place_id: colour_set.place_id, colour_set_id: colour_set.id }
        expect(RouteSetColourSetColour.exists?(colour: 'Red', grade: 'V1', map_tint_colour: '#FF0000')).to be_falsey
      end

      it 'returns an unprocessable entity response' do
        post :create, params: { colour_set_colour: { colour: nil, map_tint_colour: '#FF0000' }, place_id: colour_set.place_id, colour_set_id: colour_set.id }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'PATCH #update' do
    let(:colour_set_colour) { create(:route_set_colour_set_colour) }

    context 'with valid params' do
      let(:new_params) { { colour: 'Blue' } }

      it 'updates the requested colour set colour' do
        patch :update, params: { id: colour_set_colour.id, colour_set_colour: new_params, place_id: colour_set.place_id, colour_set_id: colour_set.id }
        colour_set_colour.reload
        expect(colour_set_colour.colour).to eq('Blue')
      end

      it 'returns a success response' do
        patch :update, params: { id: colour_set_colour.id, colour_set_colour: new_params, place_id: colour_set.place_id, colour_set_id: colour_set.id }
        expect(response).to be_successful
      end
    end

    context 'with invalid params' do
      it 'does not update the requested colour set colour' do
        patch :update, params: { id: colour_set_colour.id, colour_set_colour: { colour: nil }, place_id: colour_set.place_id, colour_set_id: colour_set.id }
        colour_set_colour.reload
        expect(colour_set_colour.colour).to_not be_nil
      end

      it 'returns an unprocessable entity response' do
        patch :update, params: { id: colour_set_colour.id, colour_set_colour: { colour: nil }, place_id: colour_set.place_id, colour_set_id: colour_set.id }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'DELETE #destroy' do
    let!(:colour_set_colour) { create(:route_set_colour_set_colour) }

    it 'destroys the requested colour set colour' do
      delete :destroy, params: { id: colour_set_colour.id, place_id: colour_set.place_id, colour_set_id: colour_set.id }
      expect(RouteSetColourSetColour.exists?(colour_set_colour.id)).to be_falsey
    end

    it 'returns a success response' do
      delete :destroy, params: { id: colour_set_colour.id, place_id: colour_set.place_id, colour_set_id: colour_set.id }
      expect(response).to be_successful
    end
  end
end