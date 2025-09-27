class PlacesPresenter
  attr_reader :places, :user

  def initialize(places, user = nil)
    @places = places
    @user = user
  end

  def present(latitude: nil, longitude: nil)
    {
      places: places.map { |place|
        PlacePresenter.new(place, user).present_for_index(
          latitude: latitude,
          longitude: longitude
        )
      }
    }
  end
end