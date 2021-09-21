class ClimbsController < ApplicationController
  def new
    @active_route_sets = RouteSet.all
    @routes = RouteSet.all.map { |route_set| [route_set.id, route_set.routes] }.to_h
  end

  def create
    climb = Climb.new(
      climber: params["climber"],
      route_states: JSON.parse(params["route_states"]).map do |route_state|
        RouteState.new(
          route_id: route_state["routeId"],
          status: route_state["status"])
      end
    )
    climb.save

    redirect_to climb_path(climb.id)
  end

  def show
    @climb = Climb.find(params[:id])
    @routes = Route.find(@climb.route_states.map(&:route_id))
    @route_sets = RouteSet.find(@routes.map(&:route_set_id).uniq)
  end

  def index
    @climbs = Climb.all.order(updated_at: :desc)
  end
end
