class WelcomeController < ApplicationController

  def index
    @title = "Let's Climb Some Shit"
  end

  def edit_route_sets
    @route_sets = RouteSet.all

    @title = "Route Sets"
    @back_url = menu_path
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
