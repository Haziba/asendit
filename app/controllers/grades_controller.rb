class GradesController < ApplicationController
  before_action :set_place
  before_action :set_grade, only: [:show, :edit, :update, :destroy]

  def new
    @grade = @place.grades.new
  end

  def create
    @place.grades.create!(grade_params)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @place}
    end
  end

  def update
    @grade.update!(update_grade_params)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @place, notice: 'Grade was successfully updated.' }
    end
  end

  def destroy
    @grade.destroy

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @place}
    end
  end

  private

  def set_grade
    @grade = Grade.find(params[:id])
  end

  def set_place
    @place = Place.find(params[:place_id])
  end

  def grade_params
    params.require(:grade).permit(:place_id, :name, :grade, :map_tint_colour)
  end

  def update_grade_params
    params.require(:grade).permit(:name, :grade, :map_tint_colour)
  end
end