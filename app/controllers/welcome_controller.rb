class WelcomeController < ApplicationController
  def climb
    @route_sets = [{"id": 123, "name": "Route 1"}, {"id": 456, "name": "Route 2"}]
  end

  def edit_route_sets
    @route_sets = RouteSet.all
  end

  def add_route_set_save
    route_set = RouteSet.new(
      color: params["Colour"],
      added: params["Added"]
    )
    route_set.save

    redirect_to edit_route_sets_path
  end
end
