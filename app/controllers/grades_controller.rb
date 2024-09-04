class GradesController < ApplicationController
  before_action :set_grade, only: [:show, :update, :destroy]

  def create
    @grade = Grade.new(place_id: params[:place_id], name: params[:name], grade: params[:grade], map_tint_colour: params[:map_tint_colour])

    if @grade.save
      render json: @grade, status: :created
    else
      render json: @grade.errors, status: :unprocessable_entity
    end
  end

  def update
    if @grade.update(name: params[:name], grade: params[:grade], map_tint_colour: params[:map_tint_colour])
      render json: @grade
    else
      render json: @grade.errors, status: :unprocessable_entity
    end
  end

  def destroy
    @grade.destroy
  end

  private

  def set_grade
    @grade = Grade.find(params[:id])
  end
end