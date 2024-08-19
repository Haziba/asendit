class MenuController < ApplicationController
  include Secured

  before_action :ensure_place_chosen

  def index
    @title = "Let's Climb - #{User.me(session).place.name}"
    @user = session[:userinfo]
  end

  private

  def ensure_place_chosen
    redirect_to places_path if User.me(session).place.nil?
  end
end
