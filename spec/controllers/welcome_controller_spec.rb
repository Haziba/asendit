require 'rails_helper'

RSpec.describe WelcomeController, type: :controller do
  describe 'GET #index' do
    before do
      allow(ENV).to receive(:[]).with('DEV_USER')
      allow(ENV).to receive(:[]).with('DEV_NONADMIN_USER')
    end

    context 'when DEV_USER is set' do
      before do
        allow(ENV).to receive(:[]).with('DEV_USER').and_return('1234')
        get :index
      end

      it 'logs in the user with DEV_USER' do
        expect(session[:userinfo]['id']).to eq('1234')
        expect(session[:userinfo]['admin']).to be true
      end

      it 'redirects to menu' do
        expect(response).to redirect_to(menu_path)
      end
    end

    context 'when DEV_NONADMIN_USER is set' do
      before do
        allow(ENV).to receive(:[]).with('DEV_NONADMIN_USER').and_return('1234')
        get :index
      end

      it 'logs in the user with DEV_USER' do
        expect(session[:userinfo]['id']).to eq('1234')
        expect(session[:userinfo]['admin']).to be false
      end

      it 'redirects to menu' do
        expect(response).to redirect_to(menu_path)
      end
    end

    context 'when user is already logged in' do
      before do
        session[:userinfo] = { "id" => '1234', "admin" => true }
        get :index
      end

      it 'redirects to the menu path' do
        expect(response).to redirect_to(menu_path)
      end
    end

    context 'when user is anonymous' do
      before do
        session[:userinfo] = {}
        get :index
      end

      it 'displays the index page' do
        expect(response).to render_template(:index)
      end
    end
  end
end
