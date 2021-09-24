class WelcomeController < ApplicationController
  before_action :redirect_if_logged_in

  def index
    @title = "Let's Climb Some Shit"
  end

  def redirect_if_logged_in
    redirect_to menu_path if session[:userinfo].present?
  end
end
