class WelcomeController < ApplicationController
  before_action :redirect_if_logged_in

  def index
    @title = "Let's Climb!"
  end

  def redirect_if_logged_in
    redirect_to menu_path if @user.present?
  end
end
