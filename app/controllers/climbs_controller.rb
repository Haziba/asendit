class ClimbsController < ApplicationController
  include Secured

  before_action :check_auth, only: [:edit, :update, :destroy]

  def new
    @active_route_sets = RouteSet.all
      .order(added: :desc)
      .group_by(&:color)
      .map { |key, value| value.first }
      .sort { |route_set| route_set.added.to_i }

    @routes = @active_route_sets
      .map { |route_set| [route_set.id, route_set.routes] }
      .to_h
  end

  def create
    climb = Climb.new(
      climber: session[:userinfo]["id"],
      route_state_json: JSON.parse(params["route_states"]).map do |route_state|
        RouteStatus.new(
          route_state["routeId"],
          route_state["status"]
        )
      end
    )
    climb.save

    redirect_to climb_path(climb.id)
  end

  def show
    @climb = Climb.find(params[:id])
    climbed_route_sets = Route.where(id: @climb.route_states.select(&:tried?).map(&:route_id)).map(&:route_set_id).uniq
    @routes = RouteSet.find(climbed_route_sets).map { |route_set| [route_set.id, route_set.routes] }.to_h
    @route_sets = RouteSet.find(@routes.keys)
  end

  def edit
    @climb = Climb.find(params[:id])
    @active_route_sets = RouteSet.all
      .order(added: :desc)
      .group_by(&:color)
      .map { |key, value| value.first }
      .sort { |route_set| route_set.added.to_i }

    @routes = @active_route_sets.map { |route_set| [route_set.id, route_set.routes] }.to_h
  end

  def update
    climb = Climb.find(params[:id])
    climb.route_state_json = JSON.parse(params["route_states"]).map do |route_state|
      RouteStatus.new(
        route_state["routeId"],
        route_state["status"])
    end
    climb.save

    redirect_to climb_path(climb.id)
  end

  def index
    @climbs = Climb.where(climber: session[:userinfo]["id"]).order(updated_at: :desc)
  end

  def destroy
    Climb.find(params[:id]).destroy
    redirect_to climbs_path
  end

  def check_auth
    redirect_to climbs_path unless Climb.find(params[:id]).climber == session[:userinfo]["id"]
  end
end
