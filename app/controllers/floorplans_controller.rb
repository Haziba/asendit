class FloorplansController < ApplicationController
  before_action :set_place
  before_action :set_floorplan, only: [:show, :edit, :update, :destroy, :update_data, :upload_file]

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
    if @floorplan.update(floorplan_params)
      redirect_to edit_place_floorplan_path(@floorplan), notice: 'Floorplan was successfully updated.'
    else
      render :edit
    end
  end

  def update_data
    if @floorplan.update(data: params[:data])
      render json: { success: true }
    else
      render json: { success: false }
    end
  end

  def upload_file
    new_image_id = @floorplan.images.count
    @floorplan.images.attach(params[:image])
    render json: { success: true, id: new_image_id }
  end

  def destroy
    @floorplan.destroy
    redirect_to place_floorplans_url(@place.id), notice: 'Floorplan was successfully destroyed.'
  end

  private

  def set_floorplan
    @floorplan = params[:floorplan_id].present? ? Floorplan.find(params[:floorplan_id]) : Floorplan.find(params[:id])
  end

  def set_place
    @place = Place.find(params[:place_id])
  end

  def floorplan_params
    params.require(:floorplan).permit(:name, :data, images: [])
  end
end