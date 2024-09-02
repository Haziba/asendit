module ApplicationHelper
  def admin_user?
    session[:userinfo]["admin"]
  end

  def climb_in_progress?
    return unless session[:userinfo]

    Climb.where(climber: session[:userinfo]["id"], current: true).exists?
  end

  def place
    @place ||= User.me(session).place
  end
end
