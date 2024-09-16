class TournamentsController < ApplicationController
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

  private

  def set_place
    @place = params[:place_id].present? ? Place.find(params[:place_id]) : User.me(session).place
  end
end