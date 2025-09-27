class PlacePresenter
  attr_reader :place, :user

  def initialize(place, user = nil)
    @place = place
    @user = user
  end

  def present
    {
      id: place.id,
      name: place.name,
      created_at: place.created_at,
      updated_at: place.updated_at,
      latitude: place.latitude,
      longitude: place.longitude,
      owner: place.user ? { id: place.user.id, email: place.user.token } : nil
    }
  end

  def present_for_index(latitude: nil, longitude: nil)
    result = present.merge(
      owner: {
        id: place.user.id,
        email: place.user.token
      },
      grades_count: place.grades.count,
      current_user_place: user && (place.id == user.place_id),
      latitude: place.latitude,
      longitude: place.longitude
    )

    # Add distance if user location is provided and place has coordinates
    if latitude && longitude && place.has_coordinates?
      if place.respond_to?(:distance) && place.distance.present?
        # Distance from SQL query (more accurate)
        result[:distance_km] = place.distance.round(2)
      else
        # Calculate distance using model method
        distance = place.distance_to(latitude, longitude)
        result[:distance_km] = distance.round(2) if distance
      end
    end

    result
  end

  def present_with_details
    present.merge(
      owner: {
        id: place.user.id,
        email: place.user.token
      },
      grades: place.grades.map do |grade|
        {
          id: grade.id,
          name: grade.name,
          grade: grade.grade,
          map_tint_colour: grade.map_tint_colour
        }
      end,
      current_user_place: user && (place.id == user.place_id)
    )
  end
end