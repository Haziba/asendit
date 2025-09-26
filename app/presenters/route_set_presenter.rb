class RouteSetPresenter
  attr_reader :route_set, :user

  def initialize(route_set, user = nil)
    @route_set = route_set
    @user = user
  end

  def present
    {
      id: route_set.id,
      name: route_set.name,
      added: route_set.added,
      expires_at: route_set.expires_at,
      routes_count: route_set.routes.count,
      grade: {
        id: route_set.grade.id,
        name: route_set.grade.name,
        grade: route_set.grade.grade
      },
      created_at: route_set.created_at,
      updated_at: route_set.updated_at
    }
  end

  def present_with_details
    present.merge(
      place: {
        id: route_set.place.id,
        name: route_set.place.name
      },
      routes: route_set.routes.map { |route| RoutePresenter.new(route).present_summary },
      can_edit: can_edit?,
      created_at: route_set.created_at,
      updated_at: route_set.updated_at
    )
  end

  def present_summary
    {
      id: route_set.id,
      name: route_set.name,
      added: route_set.added,
      expires_at: route_set.expires_at,
      route_count: route_set.routes.count,
      grade: {
        id: route_set.grade.id,
        name: route_set.grade.name,
        grade: route_set.grade.grade,
        map_tint_colour: route_set.grade.map_tint_colour
      }
    }
  end

  private

  def can_edit?
    return false unless user
    user.admin || route_set.place.can_edit?(user)
  end
end