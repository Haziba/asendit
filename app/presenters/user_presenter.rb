class UserPresenter
  attr_reader :user, :current_climb, :owned_places, :recent_climbs

  def initialize(user, current_climb: nil, owned_places: [], recent_climbs: [])
    @user = user
    @current_climb = current_climb
    @owned_places = owned_places
    @recent_climbs = recent_climbs
  end

  def present
    {
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        profile_picture_url: user.profile_picture_url,
        current_place: user.place ? {
          id: user.place.id,
          name: user.place.name
        } : nil,
        admin: user.admin || false,
        current_climb: current_climb ? ClimbPresenter.new(current_climb, user).present : nil,
        owned_places: owned_places.map { |place| PlacePresenter.new(place, user).present },
        recent_climbs: recent_climbs.map { |climb| ClimbPresenter.new(climb, user).present }
      },
    }
  end
end