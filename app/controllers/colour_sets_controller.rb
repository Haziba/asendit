class ColourSetsController < ApplicationController
  def new
    colour_set = RouteSetColourSet.create(place_id: params[:place_id], description: Date.today.strftime("%d %b %Y"))
    redirect_to edit_place_colour_set_path(place_id: params[:place_id], id: colour_set.id)
  end

  def edit
    @colour_set = RouteSetColourSet.find(params[:id])
    @errors = []
  end

  def update
    @colour_set = RouteSetColourSet.find(params[:id])

    if @colour_set.update(colour_set_params)
      redirect_to places_path
    else
      @errors = @colour_set.errors.full_messages
      render :edit
    end
  end

  def destroy
    @colour_set = RouteSetColourSet.find(params[:id])
    @colour_set.update(deleted: true)
    redirect_to place_path
  end

  private

  def colour_set_params
    params.require(:route_set_colour_set).permit(:description)
  end
end