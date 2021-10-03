module ClimbsHelper
  def route_set_by_route_id(route_id)
    route = Route.find(route_id)
    RouteSet.find(route.route_set_id)
  end

  def attempted_routes(route_set)
    chosen_routes = @routes[route_set.id]
    chosen_route_states = @climb.route_states.select { |route_state| chosen_routes.map(&:id).include?(route_state.route_id) }
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
    previous_climbs = Climb.where(climber: @climb.climber).where('created_at < ?', @climb.created_at)
    sent_route_ids = previous_climbs
      .map(&:route_states)
      .flatten
      .select { |route_state| route_state.success? }
      .map(&:route_id)
      .uniq

    puts "*"*30
    puts "Send route ids"
    pp sent_route_ids

    @climb.route_states
      .select { |route_state| route_state.success? }
      .select { |route_state| !sent_route_ids.include?(route_state.route_id) }
  end

  def new_wins_count_for_set(route_set)
    routes = Route.find(new_wins.map(&:route_id))
    new_wins.count { |win| routes.select { |route| route.id == win.route_id }.first.route_set_id == route_set.id }
  end

  def previous_states
    Climb.where(climber: @climb ? @climb.climber : session[:userinfo]["id"])
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
