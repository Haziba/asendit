class RoutesController < ApplicationController
  def create
    route = Route.new(
      pos_x: params["posX"],
      pos_y: params["posY"],
      route_set: RouteSet.find(params["routeSet"]),
      floorplan_image_id: params["floorplanImageId"],
      added: Time.now
    )
    route.save

    render json: route, status: :ok
  end

  def destroy
    route = Route.find(params[:id])
    route.destroy!

    head :ok
  end
end
