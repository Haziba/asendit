class RouteSetsController < ApplicationController
  def edit
    @route_set = RouteSet.find(params[:id])
    @routes = Route.where(route_set: @route_set.id)
  end
end
