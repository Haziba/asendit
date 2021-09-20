class ClimbsController < ApplicationController
  def new
    @active_route_sets = RouteSet.all
    @routes = RouteSet.all.map { |route_set| [route_set.id, route_set.routes] }.to_h

    @title = "Climb That Shit"
    @back_url = root_path
  end

  def create
    climb = Climb.new(
      climber: params["climber"],
      route_states: params["route_states"]
    )
    climb.save

    redirect_to climb_path(climb.id)
  end

  def show
    @climb = Climb.find(params[:id])
  end

  def index
    @climbs = Climb.all.order(updated_at: :desc)
  end
end
