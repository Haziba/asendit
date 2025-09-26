module Api
  module V1
    class FloorplansController < BaseController
      before_action :set_place
      before_action :set_floorplan, only: [:show, :update, :destroy, :update_data, :upload_image]
      before_action :ensure_can_edit, only: [:create, :update, :destroy, :update_data, :upload_image]

      def index
        floorplan = @place.floorplan

        if floorplan
          render json: {
            floorplan: FloorplanPresenter.new(floorplan, current_user).present
          }
        else
          render json: { floorplan: nil }
        end
      end

      def show
        render json: {
          floorplan: FloorplanPresenter.new(@floorplan, @user).present_detail
        }
      end

      def create
        existing_floorplan = @place.floorplan
        if existing_floorplan
          return render json: {
            error: 'Place already has a floorplan'
          }, status: :unprocessable_entity
        end

        floorplan = Floorplan.new(
          place: @place,
          name: params[:name] || 'Main Floorplan',
          data: params[:data] || []
        )

        if floorplan.save
          render json: {
            floorplan: FloorplanPresenter.new(floorplan, current_user).present_detail
          }, status: :created
        else
          render json: { error: floorplan.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        update_params = {
          name: params[:name],
          data: params[:data]
        }.compact

        if @floorplan.update(update_params)
          render json: {
            floorplan: FloorplanPresenter.new(@floorplan, current_user).present_detail
          }
        else
          render json: { error: @floorplan.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update_data
        if @floorplan.update(data: params[:data])
          render json: {
            success: true,
            floorplan: FloorplanPresenter.new(@floorplan, current_user).present
          }
        else
          render json: {
            success: false,
            error: @floorplan.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      def upload_image
        unless params[:image].present?
          return render json: {
            error: 'No image provided'
          }, status: :bad_request
        end

        @floorplan.images.attach(params[:image])

        if @floorplan.images.last
          render json: {
            success: true,
            image: {
              id: @floorplan.images.last.id,
              url: rails_blob_url(@floorplan.images.last)
            }
          }
        else
          render json: {
            error: 'Failed to upload image'
          }, status: :unprocessable_entity
        end
      rescue => e
        render json: {
          error: "Upload failed: #{e.message}"
        }, status: :unprocessable_entity
      end

      def destroy
        if @floorplan.images.attached?
          @floorplan.images.purge
        end

        if @floorplan.destroy
          render json: { message: 'Floorplan deleted successfully' }
        else
          render json: { error: 'Failed to delete floorplan' }, status: :unprocessable_entity
        end
      end

      private

      def set_place
        if params[:place_id].present?
          @place = Place.find(params[:place_id])
        else
          @place = current_user.place
        end

        if @place.nil?
          render json: { error: 'No place selected or found' }, status: :unprocessable_entity
        end
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Place not found' }, status: :not_found
      end

      def set_floorplan
        @floorplan = @place.floorplan

        if @floorplan.nil?
          render json: { error: 'Floorplan not found' }, status: :not_found
        end
      end

      def ensure_can_edit
        unless current_user.admin || @place.can_edit?(current_user)
          render json: { error: 'You do not have permission to modify floorplans at this place' }, status: :forbidden
        end
      end

    end
  end
end