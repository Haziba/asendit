require 'rails_helper'

RSpec.describe ClimbShareController, type: :controller do
  include_context 'climb setup'

  describe 'GET #show' do
    before do
      get :show, params: { climb_id: climb.id }
    end

    it 'assigns the requested climb to @climb' do
      expect(assigns(:climb)).to eq(climb)
    end

    it 'assigns the correct routes to @routes' do
      expect(assigns(:routes)).to eq(routes)
    end

    it 'assigns the correct route sets to @route_sets' do
      expect(assigns(:route_sets)).to match_array([route_set1, route_set2])
    end

    it 'renders the show template' do
      expect(response).to render_template(:show)
    end
  end
end
