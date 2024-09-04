module ClimbsHelper
  def route_attempt_percentages(route_states)
    routes = Route.find(route_states.select(&:tried?).map(&:route_id))
    route_sets = RouteSet.find(routes.map(&:route_set_id).uniq)

    route_sets.map { |route_set| [route_set.grade.name, (routes.count { |route| route.route_set_id == route_set.id }.to_f * 100) / routes.count.to_f] }
  end

  def route_set_by_route_id(route_id)
    route = Route.find(route_id)
    RouteSet.find(route.route_set_id)
  end

  def attempted_routes(route_set)
    chosen_routes = @routes[route_set.id]
    chosen_route_states = @climb.route_states.select { |route_state| chosen_routes.map(&:id).include?(route_state.route_id.to_i) }
    "#{chosen_route_states.count { |route_state| route_state.status != "not_attempted" }}/#{chosen_route_states.count}"
  end

  def success_rate(route_set)
    chosen_routes = @routes[route_set.id]
    chosen_route_states = @climb.route_states.select { |route_state| chosen_routes.map(&:id).include?(route_state.route_id) }

    attempted = chosen_route_states.count(&:tried?)
    succeeded = chosen_route_states.count(&:success?)

    return "0%" if attempted == 0

    "#{((succeeded.to_f / attempted.to_f) * 100).to_i}%"
  end

  def new_wins
    previous_climbs = Climb.where(climber: @climb.climber).where('climbed_at < ?', @climb.climbed_at)
    sent_route_ids = previous_climbs
      .map(&:route_states)
      .flatten
      .select { |route_state| route_state.success? }
      .map(&:route_id)
      .uniq

    @climb.route_states
      .select { |route_state| route_state.success? }
      .select { |route_state| !sent_route_ids.include?(route_state.route_id) }
  end

  def new_wins_count_for_set(route_set)
    routes = Route.find(new_wins.map(&:route_id))
    new_wins.count { |win| routes.select { |route| route.id == win.route_id.to_i }.first.route_set_id == route_set.id }
  end

  def previous_states
    Climb.where(climber: @climb ? @climb.climber : session[:userinfo]["id"])
      .reject { |climb| climb == @climb }
      .map(&:route_states)
      .flatten
      .group_by(&:route_id)
      .map do |route_states|
        route_id, states = route_states

        if states.any? { |route_state| route_state.status == "sent" || route_state.status == "flashed" }
          [route_id, "sent"]
        elsif states.any? { |route_state| route_state.status == "failed" }
          [route_id, "failed"]
        end
      end
      .reject { |state| state == nil }
      .to_h
  end
end
