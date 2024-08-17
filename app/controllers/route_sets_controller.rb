class RouteSetsController < ApplicationController
  include Secured

  before_action :admin_only, only: [:new, :create, :edit, :update, :destroy]

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

  def update
    @route_set = RouteSet.find(params[:id])

    @route_set.update(expires_at: Date.parse(params[:route_set][:expires_at]))

    redirect_to edit_route_set_path(@route_set)
  end

  def index
    @active_route_sets = RouteSet.all
      .order(added: :desc)
      .group_by(&:color)
      .map { |key, value| value.first }
      .sort_by { |route_set| -route_set.added.to_i }
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

  def admin_only
    redirect_to route_sets_path unless session[:userinfo]["admin"]
  end
end
