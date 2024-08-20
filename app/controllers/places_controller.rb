class PlacesController < ApplicationController
  include Secured

  def index
    @places = Place.all
  end

  def new
  end

  def create
    Place.create(name: params[:name], user: User.me(session))
    redirect_to places_path
  end

  def choose
    User.me(session).update(place_id: params[:place_id])
    redirect_to menu_path
  end
end