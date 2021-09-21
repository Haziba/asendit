module ClimbsHelper
  def route_set_by_route_id(route_id)
    route = Route.find(route_id)
    RouteSet.find(route.route_set_id)
  end

  def attempted_routes(route_set)
    chosen_routes = @routes.select { |route| route.route_set_id == route_set.id }
    chosen_route_states = @climb.route_states.select { |route_state| chosen_routes.map(&:id).include?(route_state.route_id) }
    "#{chosen_route_states.count { |route_state| route_state.status != "not_attempted" }}/#{chosen_route_states.count}"
  end

  def success_rate(route_set)
    chosen_routes = @routes.select { |route| route.route_set_id == route_set.id }
    chosen_route_states = @climb.route_states.select { |route_state| chosen_routes.map(&:id).include?(route_state.route_id) }

    attempted = chosen_route_states.count { |route_state| route_state.status != "not_attempted" }
    succeeded = chosen_route_states.count { |route_state| route_state.status == "sent" }

    return "0%" if attempted == 0

    "#{((succeeded.to_f / attempted.to_f) * 100).to_i}%"
  end

  def new_wins(route_set)
    previous_climbs = Climb.where(climber: @climb.climber).where('created_at < ?', @climb.created_at)
    pp previous_climbs.map(&:route_states)
    sent_route_ids = previous_climbs
      .map(&:route_states)
      .flatten
      .select { |route_state| route_state.status == "sent" }
      .map(&:route_id)
      .uniq

    @climb.route_states
      .select { |route_state| Route.find(route_state.route_id).route_set_id == route_set.id }
      .select { |route_state| route_state.status == "sent" }
      .count { |route_state| !sent_route_ids.include?(route_state.route_id) }
  end
end
