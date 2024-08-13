class ApplicationController < ActionController::Base
  before_action :login_if_in_dev

  def login_if_in_dev
    return if session[:userinfo].present?

    session[:userinfo] = {
      "id" => ENV['DEV_USER'],
      "admin" => true
    } unless ENV['DEV_USER'].nil?

    session[:userinfo] = {
      "id" => ENV['DEV_NONADMIN_USER'],
      "admin" => false
    } unless ENV['DEV_NONADMIN_USER'].nil?
  end
end
