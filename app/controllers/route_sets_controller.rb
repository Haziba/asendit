class RouteSetsController < ApplicationController
  include Secured

  def create
    route_set = RouteSet.new(
      color: params["colour"],
      added: params["added"]
    )
    route_set.save

    redirect_to edit_route_set_path(route_set[:id])
  end

  def edit
    @route_set = RouteSet.find(params[:id])
  end

  def index
    @active_route_sets = RouteSet.all
      .order(added: :desc)
      .group_by(&:color)
      .map { |key, value| value.first }
      .sort { |route_set| route_set.added.to_i }
    @old_route_sets = RouteSet.where.not(id: @active_route_sets.map(&:id)).sort { |route_set| route_set.added.to_i }
  end

  def show
    @route_states = Climb.where(climber: session[:userinfo]["id"]).map(&:route_states).flatten

    @climbed_routes = Route.find(@route_states.map(&:route_id)).select { |route| route.route_set_id == params[:id].to_i }
    @route_set = RouteSet.find(params[:id])
  end

  def destroy
    RouteSet.find(params[:id]).destroy
    redirect_to route_sets_path
  end
end
