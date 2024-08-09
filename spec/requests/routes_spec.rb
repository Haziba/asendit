require 'rails_helper'

RSpec.describe RoutesController, type: :controller do
  describe 'POST #create' do
    let!(:route_set) { create(:route_set) }
    let(:valid_params) do
      {
        "posX" => 100,
        "posY" => 200,
        "floor" => 1,
        "routeSet" => route_set.id
      }
    end

    it 'creates a new route with valid parameters' do
      expect {
        post :create, params: valid_params
      }.to change(Route, :count).by(1)

      route = Route.last
      expect(route.pos_x).to eq(100)
      expect(route.pos_y).to eq(200)
      expect(route.floor).to eq(1)
      expect(route.route_set).to eq(route_set)
      expect(route.added).not_to be_nil
    end

    it 'returns the created route as JSON with status :ok' do
      post :create, params: valid_params

      route = Route.last
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to eq('application/json; charset=utf-8')
      expect(JSON.parse(response.body)).to include(
                                             "id" => route.id,
                                             "pos_x" => 100,
                                             "pos_y" => 200,
                                             "floor" => 1,
                                             "route_set_id" => route_set.id
                                           )
    end
  end

  describe 'DELETE #destroy' do
    let!(:route) { create(:route) }

    it 'deletes the route' do
      expect {
        delete :destroy, params: { id: route.id }
      }.to change(Route, :count).by(-1)
    end

    it 'returns status :ok with no content' do
      delete :destroy, params: { id: route.id }

      expect(response).to have_http_status(:ok)
      expect(response.body).to be_blank
    end
  end
end
