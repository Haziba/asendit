class ApplicationController < ActionController::Base
  before_action :login_if_in_dev
  before_action :set_user

  def login_if_in_dev
    return if session[:userinfo].present?

    session[:userinfo] = {
      "id" => ENV['DEV_USER'].to_i,
      "token" => User.find(ENV['DEV_USER'].to_i).token
    } unless ENV['DEV_USER'].nil?
  end

  private

  def set_user
    @user ||= User.me(session) if session[:userinfo].present?
  end
end
