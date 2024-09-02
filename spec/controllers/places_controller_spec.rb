require 'rails_helper'

RSpec.describe PlacesController, type: :controller do
  describe 'GET #index' do
    context 'when logged in' do
      include_context 'logged_in'

      let!(:places) { [create(:place), create(:place)] }

      it 'assigns all places to @places' do
        get :index
        expect(assigns(:places)).to match_array(Place.all)
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

      it 'assigns a new NewPlaceForm to @place_form' do
        get :new
        expect(assigns(:place_form)).to be_a(NewPlaceForm)
      end

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
      let(:valid_params) { { name: 'Cool Place' } }

      before do
        user.save
      end

      context 'with valid attributes' do
        it 'creates a new place and redirects to places index' do
          expect_any_instance_of(NewPlaceForm).to receive(:save).and_return(true)

          post :create, params: { new_place_form: valid_params }

          expect(assigns(:place_form)).to be_a(NewPlaceForm)
          expect(assigns(:place_form).name).to eq('Cool Place')
          expect(assigns(:place_form).user.reference).to eq(user.reference)
          expect(response).to redirect_to(places_path)
        end
      end

      context 'with invalid attributes' do
        it 'does not save the place and re-renders the new template with unprocessable entity status' do
          expect_any_instance_of(NewPlaceForm).to receive(:save).and_return(false)

          post :create, params: { new_place_form: { name: '' } }

          expect(assigns(:place_form)).to be_a(NewPlaceForm)
          expect(response).to render_template(:new)
          expect(response.status).to eq(422)
        end
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
