require 'rails_helper'

# A dummy controller to test the Secured concern
class SecuredDummyController < ApplicationController
  include Secured

  def index
    render plain: 'Success'
  end
end

RSpec.describe SecuredDummyController, type: :controller do
  controller(SecuredDummyController) do
    # The dummy action to test the concern
    def index
      render plain: 'Success'
    end
  end

  describe 'before_action :logged_in_using_omniauth?' do
    let!(:user) { create(:user) }

    context 'when user is logged in' do
      before do
        allow(controller).to receive(:session).and_return(userinfo: { "id" => user.id, "token" => user.token })
        get :index
      end

      it 'allows the request to proceed' do
        expect(response).to have_http_status(:ok)
        expect(response.body).to eq('Success')
      end
    end

    context 'when user is not logged in' do
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
