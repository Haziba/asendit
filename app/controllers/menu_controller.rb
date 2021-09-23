class MenuController < ApplicationController
  include Secured

  def index
    @title = "Let's Climb Some Shit"
    @user = session[:userinfo]
  end
end
