class PlacesController < ApplicationController
  include Secured

  def index
    @places = Place.all
  end

  def new
    @place_form = NewPlaceForm.new
  end

  def create
    @place_form = NewPlaceForm.new(name: new_place_params[:name], user: User.me(session))

    if @place_form.save
      redirect_to places_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def choose
    User.me(session).update(place_id: params[:place_id])
    redirect_to menu_path
  end

  private

  def new_place_params
    params.require(:new_place_form).permit(:name)
  end
end