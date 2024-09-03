class ClimbsController < ApplicationController
  include Secured

  before_action :check_auth, only: [:show, :edit, :update, :destroy]

  def create
    current_climb = Climb.where(climber: session[:userinfo]["id"], current: true).first
    
    return redirect_to(edit_climb_path(current_climb)) if current_climb != nil

    routes = RouteSet.all
      .order(added: :desc)
      .group_by(&:route_set_colour_set_colour_id)
      .map { |key, value| value.first }
      .sort { |route_set| route_set.added.to_i }
      .map(&:routes)
      .flatten

    active_colour_set = User.me(session).place.active_colour_set
    active_colours = active_colour_set.colours
    active_route_sets = active_colours.map(&:active_route_set).reject { |r_s| r_s.nil? }

    climb = Climb.new(
      climbed_at: Time.now,
      climber: session[:userinfo]["id"],
      route_sets: active_route_sets,
      current: true
    )

    climb.save

    redirect_to(edit_climb_path(climb))
  end

  def show
    @climb = Climb.find(params[:id])
    climbed_route_sets = Route.where(id: @climb.route_states.select(&:tried?).map(&:route_id)).map(&:route_set_id).uniq
    @routes = RouteSet.find(climbed_route_sets).map { |route_set| [route_set.id, route_set.routes] }.to_h
    @route_sets = RouteSet.find(@routes.keys)
  end

  def current
    current_climb = Climb.where(climber: session[:userinfo]["id"], current: true).first

    if(current_climb)
      redirect_to edit_climb_path(current_climb.id)
    else
      redirect_to climbs_path
    end
  end

  def edit
    @climb = Climb.find(params[:id])
    @active_route_sets = RouteSet.all
      .order(added: :desc)
      .group_by(&:route_set_colour_set_colour_id)
      .map { |key, value| value.first }
      .sort_by { |route_set| route_set.route_set_colour_set_colour_id }

    @routes = @active_route_sets.map { |route_set| [route_set.id, route_set.routes] }.to_h
  end

  def update
    climb = Climb.find(params[:id])
    climb.climbed_at = params["climbed_at"]
    climb.route_state_json = params["route_states"].to_unsafe_h.map do |index, route_state|
      RouteStatus.new(
        route_state["routeId"].to_i,
        route_state["status"]
      )
    end
    climb.save
  end

  def complete
    climb = Climb.find(params[:climb_id])
    climb.update_attribute(:current, false)
    redirect_to climb_path(climb)
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
