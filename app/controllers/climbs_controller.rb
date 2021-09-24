class ClimbsController < ApplicationController
  include Secured

  def new
    @active_route_sets = RouteSet.all
    @routes = RouteSet.all.map { |route_set| [route_set.id, route_set.routes] }.to_h
  end

  def create
    climb = Climb.new(
      climber: climber_name,
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

  def edit
    @climb = Climb.find(params[:id])
    @active_route_sets = RouteSet.all
    @routes = RouteSet.all.map { |route_set| [route_set.id, route_set.routes] }.to_h
  end

  def update
    climb = Climb.find(params[:id])
    climb.route_states = JSON.parse(params["route_states"]).map do |route_state|
      RouteState.new(
        route_id: route_state["routeId"],
        status: route_state["status"])
    end
    climb.save

    redirect_to climb_path(climb.id)
  end

  def index
    @climbs = Climb.where(climber: climber_name).order(updated_at: :desc)
  end

  def destroy
    Climb.find(params[:id]).destroy
    redirect_to climbs_path
  end

  def climber_name
    "#{session[:userinfo]["nickname"]}-#{session[:userinfo]["sub"]}"
  end
end
