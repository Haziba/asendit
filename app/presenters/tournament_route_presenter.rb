class TournamentRoutePresenter
  attr_reader :tournament_route, :user

  def initialize(tournament_route, user = nil)
    @tournament_route = tournament_route
    @user = user
  end

  def present
    {
      id: tournament_route.id,
      order: tournament_route.order,
      route: {
        id: tournament_route.route.id,
        pos_x: tournament_route.route.pos_x,
        pos_y: tournament_route.route.pos_y,
        floorplan_image_id: tournament_route.route.floorplan_image_id,
        route_set: {
          id: tournament_route.route.route_set.id,
          name: tournament_route.route.route_set.name,
          grade: {
            id: tournament_route.route.route_set.grade.id,
            name: tournament_route.route.route_set.grade.name,
            grade: tournament_route.route.route_set.grade.grade
          }
        }
      }
    }
  end
end