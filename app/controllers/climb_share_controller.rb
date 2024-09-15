class ClimbShareController < ApplicationController
  before_action :set_climb, only: [:show, :edit, :update, :destroy]
  before_action :set_place, only: [:show, :edit, :update, :destroy]

  def show
    climbed_route_sets = Route.where(id: @climb.route_states.select(&:tried?).map(&:route_id)).map(&:route_set_id).uniq
    @routes = RouteSet.find(climbed_route_sets).map { |route_set| [route_set.id, route_set.routes] }.to_h
    @route_sets = RouteSet.find(@routes.keys)
  end

  def set_climb
    @climb = Climb.find(params[:climb_id])
  end

  def set_place
    @place = @climb.route_sets.first.place
  end
end
