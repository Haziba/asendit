class ColourSetColoursController < ApplicationController
  before_action :set_colour_set_colour, only: [:show, :update, :destroy]

  def index
    @colour_sets_colours = RouteSetColourSetColour.all
    render json: @colour_sets_colours
  end

  def show
    render json: @colour_set_colour
  end

  def create
    @colour_set_colour = RouteSetColourSetColour.new(colour_set_colour_params)

    if @colour_set_colour.save
      render json: @colour_set_colour, status: :created
    else
      render json: @colour_set_colour.errors, status: :unprocessable_entity
    end
  end

  def update
    if @colour_set_colour.update(colour_set_colour_params)
      render json: @colour_set_colour
    else
      render json: @colour_set_colour.errors, status: :unprocessable_entity
    end
  end

  def destroy
    @colour_set_colour.destroy
  end

  private

  def set_colour_set_colour
    @colour_set_colour = RouteSetColourSetColour.find(params[:id])
  end

  def colour_set_colour_params
    params.require(:colour_set_colour).permit(:route_set_colour_set_id, :colour_id, :colour, :grade, :map_tint_colour)
  end
end