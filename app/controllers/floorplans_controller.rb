class FloorplansController < ApplicationController
  before_action :set_place
  before_action :set_floorplan, only: [:show, :edit, :update, :destroy]

  def index
    @floorplans = @place.floorplans
  end

  def show
  end

  def new
    @floorplan = Floorplan.new
  end

  def create
    @floorplan = Floorplan.new(floorplan_params.merge(place: @place))

    if @floorplan.save
      redirect_to place_floorplans_path(@place)
    else
      render :new
    end
  end

  def edit
  end

  def update
    pp params
    pp floorplan_params
    if @floorplan.update(floorplan_params)
      redirect_to edit_place_floorplan_path(@floorplan), notice: 'Floorplan was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @floorplan.destroy
    redirect_to place_floorplans_url(@place.id), notice: 'Floorplan was successfully destroyed.'
  end

  private

  def set_floorplan
    @floorplan = Floorplan.find(params[:id])
  end

  def set_place
    @place = Place.find(params[:place_id])
  end

  def floorplan_params
    params.require(:floorplan).permit(:name, :data, images: [])
  end
end