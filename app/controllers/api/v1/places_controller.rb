module Api
  module V1
    class PlacesController < BaseController
      skip_before_action :authenticate_request, only: [:index]
      before_action :set_place, only: [:show, :update, :destroy]

      def index
        places = Place.all.includes(:user, :grades)

        render json: PlacesPresenter.new(places, current_user).present
      end

      def show
        render json: {
          place: PlacePresenter.new(@place, current_user).present_with_details
        }
      end

      def create
        # Check if name meets minimum requirements like NewPlaceForm
        if params[:name].blank? || params[:name].length < 4
          return render json: {
            error: 'Name is required and must be at least 4 characters long'
          }, status: :unprocessable_entity
        end

        place = Place.new(name: params[:name], user: current_user)

        if place.save
          # Create initial floorplan like the form does
          Floorplan.create(name: 'Initial floorplan', data: [], place: place)

          render json: {
            place: PlacePresenter.new(place, current_user).present
          }, status: :created
        else
          render json: { error: place.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        # Only owner can update their place
        unless @place.user == current_user
          return render json: { error: 'Only the owner can update this place' }, status: :forbidden
        end

        if params[:name].blank? || params[:name].length < 4
          return render json: {
            error: 'Name is required and must be at least 4 characters long'
          }, status: :unprocessable_entity
        end

        if @place.update(name: params[:name])
          render json: {
            place: PlacePresenter.new(@place, current_user).present
          }
        else
          render json: { error: @place.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def choose
        place = Place.find(params[:id])

        if current_user.update(place: place)
          render json: {
            message: 'Place selected successfully',
            selected_place: {
              id: place.id,
              name: place.name
            }
          }
        else
          render json: { error: 'Failed to select place' }, status: :unprocessable_entity
        end
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Place not found' }, status: :not_found
      end

      def destroy
        # Only owner can delete their place
        unless @place.user == current_user
          return render json: { error: 'Only the owner can delete this place' }, status: :forbidden
        end

        # Don't allow deleting if it's someone's current place
        if User.where(place: @place).exists?
          return render json: {
            error: 'Cannot delete place while users are using it'
          }, status: :unprocessable_entity
        end

        if @place.destroy
          render json: { message: 'Place deleted successfully' }
        else
          render json: { error: 'Failed to delete place' }, status: :unprocessable_entity
        end
      end

      private

      def set_place
        @place = Place.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Place not found' }, status: :not_found
      end
    end
  end
end