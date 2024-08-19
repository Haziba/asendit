class PlacesController < ApplicationController
  include Secured

  def index
    @places = Place.all
  end

  def choose
    User.me(session).update(place_id: params[:place_id])
    redirect_to menu_path
  end
end