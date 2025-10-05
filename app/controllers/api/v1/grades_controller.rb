module Api
  module V1
    class GradesController < BaseController
      before_action :set_place
      before_action :set_grade, only: [:show, :update, :destroy]
      before_action :ensure_can_edit, only: [:create, :update, :destroy]

      def index
        grades = @place.grades.includes(:route_sets)

        render json: GradesPresenter.new(grades, current_user).present
      end

      def show
        render json: {
          grade: GradePresenter.new(@grade, current_user).present_detail
        }
      end

      def create
        grade = Grade.new(
          place: @place,
          name: params[:name],
          grade: params[:grade],
          map_tint_colour: params[:map_tint_colour]
        )

        if grade.save
          render json: {
            grade: GradePresenter.new(grade, current_user).present_detail
          }, status: :created
        else
          render json: { error: grade.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        update_params = {
          name: params[:name],
          grade: params[:grade],
          map_tint_colour: params[:map_tint_colour]
        }.compact

        if @grade.update(update_params)
          render json: {
            grade: GradePresenter.new(@grade, current_user).present_detail
          }
        else
          render json: { error: @grade.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        # Check if grade has route sets before deleting
        if @grade.route_sets.exists?
          return render json: {
            error: 'Cannot delete grade with existing route sets'
          }, status: :unprocessable_entity
        end

        if @grade.destroy
          render json: { message: 'Grade deleted successfully' }
        else
          render json: { error: 'Failed to delete grade' }, status: :unprocessable_entity
        end
      end

      private

      def set_place
        if params[:place_id].present?
          @place = Place.find(params[:place_id])
        elsif params[:id].present?
          # For show/update/destroy actions, find place through grade
          grade = Grade.find(params[:id])
          @place = grade.place
        else
          @place = current_user.place
        end

        if @place.nil?
          render json: { error: 'No place selected or found' }, status: :unprocessable_entity
        end
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Place not found' }, status: :not_found
      end

      def set_grade
        @grade = @place.grades.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Grade not found' }, status: :not_found
      end

      def ensure_can_edit
        pp @place
        pp current_user
        unless current_user.admin || @place.can_edit?(current_user)
          render json: { error: 'You do not have permission to modify grades at this place' }, status: :forbidden
        end
      end

    end
  end
end