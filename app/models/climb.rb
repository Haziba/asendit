class Climb < ApplicationRecord
  def name
    created_at.strftime("#{created_at.day.ordinalize} %b")
  end

  def success_percentage
    return "-" if route_states.empty?
    percentage = (route_states.count(&:success?).to_f / route_states.count(&:tried?).to_f) * 100
    "#{percentage.to_i}%"
  end

  def route_states
    route_state_json.map { |route_state| RouteStatus.new(route_state["route_id"], route_state["status"]) }
  end
end
