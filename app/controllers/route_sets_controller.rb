class RouteSetsController < ApplicationController
  include Secured

  before_action :admin_only, only: [:new, :create, :edit, :update, :destroy]
  before_action :set_place

  def create
    route_set = RouteSet.new(
      route_set_colour_set_colour_id: params["colour"],
      added: params["added"],
      place_id: @place.id
    )
    route_set.save

    redirect_to edit_route_set_path(id: route_set.id)
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
    @active_route_sets = @place.active_colour_set.colours.map(&:active_route_set)
      .sort_by { |route_set| -route_set.added.to_i }
    @old_route_sets = @place.active_colour_set.colours.map(&:past_route_sets).flatten
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

  private

  def admin_only
    redirect_to route_sets_path unless session[:userinfo]["admin"]
  end

  def set_place
    @place = params[:place_id].present? ? Place.find(params[:place_id]) : User.me(session).place
    redirect_to menu_path if @place.nil?
  end
end
