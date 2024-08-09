class WelcomeController < ApplicationController
  before_action :login_if_in_dev
  before_action :redirect_if_logged_in

  def index
    @title = "Let's Climb!"
  end

  def login_if_in_dev
    session[:userinfo] = {
      "id": ENV['DEV_USER'],
      "admin": true
    } unless ENV['DEV_USER'].nil?
  end

  def redirect_if_logged_in
    redirect_to menu_path if session[:userinfo].present?
  end
end
