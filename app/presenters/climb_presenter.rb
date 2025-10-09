class ClimbPresenter
  attr_reader :climb, :user

  def initialize(climb, user = nil)
    @climb = climb
    @user = user
  end

  def present
    {
      id: climb.id,
      name: climb.name,
      climbed_at: climb.climbed_at,
      current: climb.current,
      success_percentage: climb.success_percentage,
      place: {
        id: climb.place.id,
        name: climb.place.name
      }
    }
  end

  def present_with_route_states
    present.merge(
      route_states: climb.route_states.map do |route_state|
        {
          route_id: route_state.route_id,
          status: route_state.status
        }
      end
    )
  end

  def present_with_route_states_and_routes(routes:, route_sets:)
    present_with_route_states.merge(
      routes: routes,
      route_sets: route_sets
    )
  end
end