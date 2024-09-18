require 'rails_helper'

RSpec.feature "Tournament edit", type: :feature do
  include_context "logged_in"

  let!(:tournament) { create(:tournament) }

  before do
    visit "/places/#{tournament.place.id}/tournaments/#{tournament.id}/edit"
  end

  scenario 'routes are updatable' do
    active_routes = tournament.place.grades.first.active_route_set.routes

    expect(tournament.tournament_routes.map(&:route).map(&:id)).to eq(active_routes.first(2).map(&:id))

    find("[data-route-id='#{active_routes.last.id}']").click
    find('#floorplan-next').click
    find("[data-route-id='#{active_routes.second.id}']").click

    sleep(2)

    tournament.reload
    expect(tournament.tournament_routes.map(&:route).map(&:id)).to eq([active_routes.first.id, active_routes.last.id])
  end
end