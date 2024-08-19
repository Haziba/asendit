require 'rails_helper'

RSpec.describe WelcomeController, type: :controller do
  describe 'GET #index' do
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
