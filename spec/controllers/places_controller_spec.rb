require 'rails_helper'

RSpec.describe PlacesController, type: :controller do
  describe 'GET #index' do
    context 'when logged in' do
      include_context 'logged_in'

      let!(:places) { [create(:place), create(:place)] }

      it 'assigns all places to @places' do
        get :index
        expect(assigns(:places)).to match_array(places)
      end

      it 'renders the index template' do
        get :index
        expect(response).to render_template(:index)
      end
    end

    context 'when anonymous' do
      it 'redirects to root' do
        get :index
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'GET #new' do
    context 'when logged in' do
      include_context 'logged_in'

      it 'renders the new template' do
        get :new
        expect(response).to render_template(:new)
      end
    end

    context 'when anonymous' do
      it 'redirects to root' do
        get :new
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'POST #create' do
    context 'when logged in' do
      include_context 'logged_in'

      let!(:user) { create(:user, reference: climber) }
      let(:place_params) { { name: 'New Place' } }

      before do
        user.save
      end

      it 'creates a new place with the correct attributes' do
        expect {
          post :create, params: place_params
        }.to change(Place, :count).by(1)

        new_place = Place.last
        expect(new_place.name).to eq('New Place')
        expect(new_place.user).to eq(user)
      end

      it 'redirects to the places index' do
        post :create, params: place_params
        expect(response).to redirect_to(places_path)
      end
    end

    context 'when anonymous' do
      it 'redirects to root' do
        post :create, params: {}
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'POST #choose' do
    let(:place) { create(:place) }

    context 'when logged in' do
      include_context "logged_in"

      it 'updates the user with the chosen place' do
        post :choose, params: { place_id: place.id }
        expect(User.find_by(reference: session[:userinfo]['id']).place).to eq(place)
      end

      it 'redirects to the menu path' do
        post :choose, params: { place_id: place.id }
        expect(response).to redirect_to(menu_path)
      end
    end

    context 'when anonymous' do
      it 'redirects to root' do
        post :choose, params: { place_id: place.id }
        expect(response.status).to redirect_to(root_path)
      end
    end
  end
end
