# ./app/controllers/auth0_controller.rb
class Auth0Controller < ApplicationController
  def callback
    # OmniAuth stores the informatin returned from Auth0 and the IdP in request.env['omniauth.auth'].
    # In this code, you will pull the raw_info supplied from the id_token and assign it to the session.
    # Refer to https://github.com/auth0/omniauth-auth0#authentication-hash for complete information on 'omniauth.auth' contents.
    auth_info = request.env['omniauth.auth']
    session[:userinfo] = auth_info['extra']['raw_info']

    session[:userinfo]["id"] = "#{session[:userinfo]["nickname"]}-#{session[:userinfo]["sub"]}"
    session[:userinfo]["admin"] = true if session[:userinfo]["sub"] == "google-oauth2|117779992736146613352"

    # Redirect to the URL you want after successful auth
    redirect_to '/menu'
  end

  def failure
    # Handles failed authentication -- Show a failure page (you can also handle with a redirect)
    @error_msg = request.params['message']
  end

  def logout
    # you will finish this in a later step
  end
end
