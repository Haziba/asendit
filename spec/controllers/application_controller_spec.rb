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
      before do
        allow(ENV).to receive(:[]).with('DEV_USER').and_return('dev_user')
        allow(ENV).to receive(:[]).with('DEV_NONADMIN_USER').and_return(nil)
        get :index
      end

      it 'sets session[:userinfo] with admin true' do
        expect(session[:userinfo]["id"]).to eq('dev_user')
        expect(session[:userinfo]["admin"]).to eq(true)
      end
    end

    context 'when session[:userinfo] is not present and DEV_NONADMIN_USER is set' do
      before do
        allow(ENV).to receive(:[]).with('DEV_USER').and_return(nil)
        allow(ENV).to receive(:[]).with('DEV_NONADMIN_USER').and_return('dev_nonadmin_user')
        get :index
      end

      it 'sets session[:userinfo] with admin false' do
        expect(session[:userinfo]["id"]).to eq('dev_nonadmin_user')
        expect(session[:userinfo]["admin"]).to eq(false)
      end
    end

    context 'when session[:userinfo] is not present and no DEV_USER or DEV_NONADMIN_USER is set' do
      before do
        allow(ENV).to receive(:[]).with('DEV_USER').and_return(nil)
        allow(ENV).to receive(:[]).with('DEV_NONADMIN_USER').and_return(nil)
        get :index
      end

      it 'does not set session[:userinfo]' do
        expect(session[:userinfo]).to be_nil
      end
    end
  end
end
