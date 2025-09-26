class RoutePresenter
  attr_reader :route, :user

  def initialize(route, user = nil)
    @route = route
    @user = user
  end

  def present
    {
      id: route.id,
      pos_x: route.pos_x,
      pos_y: route.pos_y,
      floor: route.floor,
      added: route.added,
      route_set: {
        id: route.route_set.id,
        name: route.route_set.name,
        grade: route.route_set.grade,
        place: {
          id: route.route_set.place.id,
          name: route.route_set.place.name
        }
      },
      created_at: route.created_at,
      updated_at: route.updated_at
    }
  end

  def present_summary
    {
      id: route.id,
      pos_x: route.pos_x,
      pos_y: route.pos_y,
      floor: route.floor,
      route_set_id: route.route_set_id
    }
  end
end