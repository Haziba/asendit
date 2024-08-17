require 'rails_helper'

RSpec.feature 'Climbs#show', type: :feature do
  context 'when logged in as the climb\'s climber' do
    include ClimbsHelper

    include_context 'logged_in'

    let!(:route_set_green) { create(:route_set, color: 'Green') }
    let!(:route_set_blue) { create(:route_set, color: 'Blue') }
    let!(:route_set_red) { create(:route_set, color: 'Red') }

    let!(:route_set_green_route_1) { create(:route, route_set: route_set_green) }
    let!(:route_set_green_route_2) { create(:route, route_set: route_set_green) }
    let!(:route_set_green_route_3) { create(:route, route_set: route_set_green) }
    let!(:route_set_green_route_4) { create(:route, route_set: route_set_green) }
    let!(:route_set_red_route_1) { create(:route, route_set: route_set_red) }

    let!(:climb) { create(:climb, climber: climber, route_state_json: [
      build(:route_status, route_id: route_set_green_route_1.id, status: 'sent'),
      build(:route_status, route_id: route_set_green_route_2.id, status: 'failed'),
      build(:route_status, route_id: route_set_green_route_3.id, status: 'not_attempted'),
      build(:route_status, route_id: route_set_red_route_1.id, status: 'sent'),
    ])}

    before do
      @climb = climb

      @routes = {}
      @routes[route_set_green.id] = [route_set_green_route_1, route_set_green_route_2, route_set_green_route_3, route_set_green_route_4]
      @routes[route_set_red.id] = [route_set_red_route_1]

      visit "/climbs/#{climb.id}"
    end

    scenario 'shows route sets with attempts' do
      expect(page).to have_selector("[data-test='route-set-#{route_set_green.id}']", visible: :all)
      expect(page).to have_selector("[data-test='route-set-#{route_set_red.id}']", visible: :all)
      expect(page).to_not have_selector("[data-test='route-set-#{route_set_blue.id}']", visible: :all)
    end

    scenario 'route set headers contain correct info' do
      within("[data-test='route-set-#{route_set_green.id}']", visible: :all) do
        expect(page).to have_content(route_set_green.color)
        expect(page).to have_content(attempted_routes(route_set_green))
        expect(page).to have_content(success_rate(route_set_green))
        expect(page).to have_content(new_wins_count_for_set(route_set_green))
      end
    end

    scenario 'clicking the route set shows & hides the map' do
      expect(page).to_not have_selector("[data-test='route-set-#{route_set_green.id}'] [data-test='map']")
      find("[data-test='route-set-#{route_set_green.id}']", visible: :all).click
      expect(page).to have_selector("[data-test='route-set-#{route_set_green.id}'] [data-test='map']")
    end
  end

  context 'when logged in as a rando' do
    include_context 'logged_in'

    let!(:climb) { create(:climb, climber: 'rando@example.com') }

    scenario 'visiting another user\'s climb' do
      visit "/climbs/#{climb.id}"

      expect(page).to have_current_path('/climbs')
    end
  end

  context 'when anonymous' do
    let!(:climb) { create(:climb) }

    scenario "redirects to the root page when accessed by an anonymous user" do
      visit "/climbs/#{climb.id}"

      expect(page).to have_current_path('/')
    end
  end
end