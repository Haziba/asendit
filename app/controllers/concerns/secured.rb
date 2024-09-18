# ./app/controllers/concerns/secured.rb
module Secured
  extend ActiveSupport::Concern

  included do
    before_action :logged_in_using_omniauth?
  end

  def logged_in_using_omniauth?
    return redirect_to '/' unless session[:userinfo].present?

    redirect_to '/' unless user.present?
    session[:userinfo] = nil unless user.present?
  end

  def user
    @user ||= User.me(session)
  end
end
