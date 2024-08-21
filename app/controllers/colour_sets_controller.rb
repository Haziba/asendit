class ColourSetsController < ApplicationController
  def new
    @new_colour_set_form = NewColourSetForm.new(place: Place.find(params[:place_id]), description: Date.today.strftime("#{Date.today.day.ordinalize} %b %Y"))
  end
end