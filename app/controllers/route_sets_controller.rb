class RouteSetsController < ApplicationController
  def edit
    @route_set = RouteSet.find(params[:id])
  end
end
