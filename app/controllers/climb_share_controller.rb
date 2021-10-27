class ClimbShareController < ApplicationController
  def show
    @climb = Climb.find(params[:climb_id])
    climbed_route_sets = Route.where(id: @climb.route_states.select(&:tried?).map(&:route_id)).map(&:route_set_id).uniq
    @routes = RouteSet.find(climbed_route_sets).map { |route_set| [route_set.id, route_set.routes] }.to_h
    @route_sets = RouteSet.find(@routes.keys)
  end
end
