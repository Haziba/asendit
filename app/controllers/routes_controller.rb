class RoutesController < ApplicationController
  def create
    route = Route.new(
      color: params["color"],
      pos_x: params["posX"],
      pos_y: params["posY"],
      floor: params["floor"],
      added: Time.now
    )
    route.save

    render json: route, status: :ok
  end

  def index
    render json: Route.all
  end
end
