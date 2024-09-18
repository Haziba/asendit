require 'rails_helper'

RSpec.describe ApplicationController, type: :controller do
  controller do
    def index
      render plain: "OK"
    end
  end

  before do
    routes.draw { get 'index' => 'anonymous#index' }
  end

  describe '#login_if_in_dev' do
    context 'when session[:userinfo] is present' do
      before do
        session[:userinfo] = { "id" => "existing_user", "admin" => true }
        get :index
      end

      it 'does not modify session[:userinfo]' do
        expect(session[:userinfo]["id"]).to eq("existing_user")
        expect(session[:userinfo]["admin"]).to eq(true)
      end
    end

    context 'when session[:userinfo] is not present and DEV_USER is set' do
      let!(:user) { create(:user) }

      before do
        allow(ENV).to receive(:[]).with('DEV_USER').and_return(user.id.to_s)
        get :index
      end

      it 'sets session[:userinfo] true' do
        expect(session[:userinfo]["id"]).to eq(user.id)
      end
    end

    context 'when session[:userinfo] is not present and no DEV_USER is set' do
      before do
        allow(ENV).to receive(:[]).with('DEV_USER').and_return(nil)
        get :index
      end

      it 'does not set session[:userinfo]' do
        expect(session[:userinfo]).to be_nil
      end
    end
  end
end
