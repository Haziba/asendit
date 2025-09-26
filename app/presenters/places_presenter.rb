class PlacesPresenter
  attr_reader :places, :user

  def initialize(places, user = nil)
    @places = places
    @user = user
  end

  def present
    {
      places: places.map { |place| PlacePresenter.new(place, user).present_for_index }
    }
  end
end