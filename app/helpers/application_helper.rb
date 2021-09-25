module ApplicationHelper
  def admin_user
    session[:userinfo]["admin"]
  end
end
