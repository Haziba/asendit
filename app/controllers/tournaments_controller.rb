class TournamentsController < ApplicationController
  before_action :set_tournament, except: [:new, :create]
  before_action :set_place

  def new
    @tournament = Tournament.new
  end

  def create
    Tournament.create!(
      name: params[:tournament][:name],
      place: @place,
      starting: Date.tomorrow,
      ending: Date.tomorrow + 7.days
    )

    redirect_to(place_path(@place))
  end

  def edit
    @active_route_sets = @place.grades.map(&:active_route_set)
    @routes = @active_route_sets.map { |route_set| [route_set.id, route_set.routes] }.to_h
  end

  def update_routes
    routes = params.has_key?(:tournament_routes) ? params[:tournament_routes].values : []

    routes.each do |route|
      current_route = @tournament.tournament_routes.find_by(route_id: route[:route_id])

      current_route.update(order: route[:order]) unless current_route.nil? || route[:order] == current_route.order
      TournamentRoute.create!(tournament: @tournament, route_id: route[:route_id], order: route[:order]) if current_route.nil?
    end

    to_remove = @tournament.tournament_routes.reject { |t_r| routes.map { |param| param['route_id'].to_i }.include?(t_r[:route_id]) }
    to_remove.each(&:destroy)

    render json: {success: true}
  end

  private

  def set_tournament
    @tournament = params[:tournament_id].present? ? Tournament.find(params[:tournament_id]) : Tournament.find(params[:id])
  end

  def set_place
    @place = params[:place_id].present? ? Place.find(params[:place_id]) : User.me(session).place
  end
end