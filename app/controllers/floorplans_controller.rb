class FloorplansController < ApplicationController
  before_action :set_place
  before_action :set_floorplan, only: [:show, :edit, :update, :destroy, :update_data, :upload_file]

  def update_data
    if @floorplan.update(data: params[:data])
      render json: { success: true }
    else
      render json: { success: false }
    end
  end

  def upload_file
    @floorplan.images.attach(params[:image])
    render json: { success: true, id: @floorplan.images.last.id, url: url_for(@floorplan.images.last) }
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