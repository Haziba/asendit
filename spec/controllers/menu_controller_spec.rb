require 'rails_helper'

RSpec.describe MenuController, type: :controller do
  describe 'GET #index' do
    context 'when the user is logged in' do
      before do
        allow(controller).to receive(:session).and_return(userinfo: { "id" => "1234", "name" => "Test User" })
        get :index
      end

      it 'sets the @title instance variable' do
        expect(assigns(:title)).to eq("Let's Climb")
      end

      it 'sets the @user instance variable with session userinfo' do
        expect(assigns(:user)).to eq({ "id" => "1234", "name" => "Test User" })
      end

      it 'renders the index template' do
        expect(response).to render_template(:index)
      end

      it 'returns a 200 OK status' do
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when the user is not logged in' do
      before do
        allow(controller).to receive(:session).and_return({})
        get :index
      end

      it 'redirects to the root path' do
        expect(response).to redirect_to('/')
      end
    end
  end
end
