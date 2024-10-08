class Auth0Controller < ApplicationController
  def callback
    # OmniAuth stores the informatin returned from Auth0 and the IdP in request.env['omniauth.auth'].
    # In this code, you will pull the raw_info supplied from the id_token and assign it to the session.
    # Refer to https://github.com/auth0/omniauth-auth0#authentication-hash for complete information on 'omniauth.auth' contents.
    session[:userinfo] = auth_info['extra']['raw_info']

    google_login if auth_info['uid'].include? 'google-oauth2'

    # Redirect to the URL you want after successful auth
    redirect_to '/menu'
  end

  def google_login
    user = User.find_or_create_by(google_uid: auth_info['uid'])

    user.update(token: auth_info['info']['token'])

    session[:userinfo]['id'] = user.id
    session[:userinfo]['token'] = user.token
  end

  def failure
    # Handles failed authentication -- Show a failure page (you can also handle with a redirect)
    @error_msg = request.params['message']
  end

  def logout
    # you will finish this in a later step
  end

  private

  def auth_info
    @auth_info ||= request.env['omniauth.auth']
  end
end
