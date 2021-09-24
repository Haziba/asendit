class RouteSetsController < ApplicationController
  def create
    route_set = RouteSet.new(
      color: params["Colour"],
      added: params["Added"]
    )
    route_set.save

    redirect_to edit_route_set_path(route_set[:id])
  end

  def edit
    @route_set = RouteSet.find(params[:id])
  end

  def index
    @route_sets = RouteSet.all
  end
end
