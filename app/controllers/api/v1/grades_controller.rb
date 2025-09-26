module Api
  module V1
    class GradesController < BaseController
      before_action :set_user
      before_action :set_place
      before_action :set_grade, only: [:show, :update, :destroy]
      before_action :ensure_can_edit, only: [:create, :update, :destroy]

      def index
        grades = @place.grades.includes(:route_sets)

        render json: {
          grades: grades.map do |grade|
            serialize_grade_summary(grade)
          end
        }
      end

      def show
        render json: {
          grade: serialize_grade_detail(@grade)
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
            grade: serialize_grade_detail(grade)
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
            grade: serialize_grade_detail(@grade)
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

      def set_user
        auth0_sub = current_user['sub'] if current_user
        @user = User.find_or_create_by(google_uid: auth0_sub) do |user|
          user.token = SecureRandom.hex(16)
        end
      end

      def set_place
        if params[:place_id].present?
          @place = Place.find(params[:place_id])
        elsif params[:id].present?
          # For show/update/destroy actions, find place through grade
          grade = Grade.find(params[:id])
          @place = grade.place
        else
          @place = @user.place
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
        unless @user.admin || @place.can_edit?(@user)
          render json: { error: 'You do not have permission to modify grades at this place' }, status: :forbidden
        end
      end

      def serialize_grade_summary(grade)
        {
          id: grade.id,
          name: grade.name,
          grade: grade.grade,
          map_tint_colour: grade.map_tint_colour,
          route_sets_count: grade.route_sets.count,
          active_route_set: grade.active_route_set ? {
            id: grade.active_route_set.id,
            name: grade.active_route_set.name,
            added: grade.active_route_set.added
          } : nil
        }
      end

      def serialize_grade_detail(grade)
        serialize_grade_summary(grade).merge(
          place: {
            id: grade.place.id,
            name: grade.place.name
          },
          route_sets: grade.route_sets.order(added: :desc).map do |route_set|
            {
              id: route_set.id,
              name: route_set.name,
              added: route_set.added,
              expires_at: route_set.expires_at,
              routes_count: route_set.routes.count
            }
          end,
          can_edit: @user.admin || grade.place.can_edit?(@user),
          created_at: grade.created_at,
          updated_at: grade.updated_at
        )
      end
    end
  end
end