class GradePresenter
  attr_reader :grade, :user

  def initialize(grade, user = nil)
    @grade = grade
    @user = user
  end

  def present_summary
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

  def present_detail
    present_summary.merge(
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
      can_edit: user&.admin || grade.place.can_edit?(user),
      created_at: grade.created_at,
      updated_at: grade.updated_at
    )
  end
end