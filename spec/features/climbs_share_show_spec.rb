require 'rails_helper'

RSpec.feature 'ClimbsShare#show', type: :feature do
  context 'when anonymous' do
    include ClimbsHelper

    let!(:place) { create(:place) }

    let!(:grade_green) { create(:grade, name: 'green', place: place) }
    let!(:grade_red) { create(:grade, name: 'red', place: place) }
    let!(:grade_blue) { create(:grade, name: 'blue', place: place) }

    let!(:route_set_green) { create(:route_set, grade: grade_green, place: place) }
    let!(:route_set_blue) { create(:route_set, grade: grade_blue, place: place) }
    let!(:route_set_red) { create(:route_set, grade: grade_red, place: place) }

    let!(:route_set_green_route_1) { create(:route, route_set: route_set_green, floor: 0) }
    let!(:route_set_green_route_2) { create(:route, route_set: route_set_green, floor: 0) }
    let!(:route_set_green_route_3) { create(:route, route_set: route_set_green, floor: 1) }
    let!(:route_set_green_route_4) { create(:route, route_set: route_set_green, floor: 1) }
    let!(:route_set_red_route_1) { create(:route, route_set: route_set_red) }

    let!(:climb) { create(:climb, climber: 'some@random.com', route_state_json: [
      build(:route_status, route_id: route_set_green_route_1.id, status: 'sent'),
      build(:route_status, route_id: route_set_green_route_2.id, status: 'failed'),
      build(:route_status, route_id: route_set_green_route_3.id, status: 'not_attempted'),
      build(:route_status, route_id: route_set_red_route_1.id, status: 'sent'),
    ], route_sets: [route_set_green, route_set_red])}

    before do
      @climb = climb

      @routes = {}
      @routes[route_set_green.id] = [route_set_green_route_1, route_set_green_route_2, route_set_green_route_3, route_set_green_route_4]
      @routes[route_set_red.id] = [route_set_red_route_1]

      visit "/climbs/#{climb.id}/share"
    end

    scenario 'shows route sets with attempts' do
      expect(page).to have_selector("[data-test='route-set-#{route_set_green.id}']", visible: :all)
      expect(page).to have_selector("[data-test='route-set-#{route_set_red.id}']", visible: :all)
      expect(page).to_not have_selector("[data-test='route-set-#{route_set_blue.id}']", visible: :all)
    end

    scenario 'route set headers contain correct info' do
      within("[data-test='route-set-#{route_set_green.id}']", visible: :all) do
        expect(page).to have_content(route_set_green.grade.name.titleize)
        expect(page).to have_content(attempted_routes(route_set_green))
        expect(page).to have_content(success_rate(route_set_green))
        expect(page).to have_content(new_wins_count_for_set(route_set_green))
      end
    end

    scenario 'clicking the route set shows & hides the map' do
      expect(page).to_not have_selector("[data-test='route-set-#{route_set_green.id}'] .map")
      find("[data-test='route-set-#{route_set_green.id}']", visible: :all).click
      expect(page).to have_selector("[data-test='route-set-#{route_set_green.id}'] .map")
    end

    scenario 'changing floor shows & hides the floor routes' do
      find("[data-test='route-set-#{route_set_green.id}']", visible: :all).click

      expect(page).to have_selector("[data-route-id='#{route_set_green_route_1.id}']", visible: true)
      expect(page).to have_selector("[data-route-id='#{route_set_green_route_2.id}']", visible: true)
      expect(page).to have_selector("[data-route-id='#{route_set_green_route_3.id}']", visible: false)
      expect(page).to have_selector("[data-route-id='#{route_set_green_route_4.id}']", visible: false)

      find("[data-test='route-set-#{route_set_green.id}'] .floorplan-next", visible: :all).click

      expect(page).to have_selector("[data-route-id='#{route_set_green_route_1.id}']", visible: false)
      expect(page).to have_selector("[data-route-id='#{route_set_green_route_2.id}']", visible: false)
      expect(page).to have_selector("[data-route-id='#{route_set_green_route_3.id}']", visible: true)
      expect(page).to have_selector("[data-route-id='#{route_set_green_route_4.id}']", visible: true)

      find("[data-test='route-set-#{route_set_green.id}'] .floorplan-next", visible: :all).click

      expect(page).to have_selector("[data-route-id='#{route_set_green_route_1.id}']", visible: true)
      expect(page).to have_selector("[data-route-id='#{route_set_green_route_2.id}']", visible: true)
      expect(page).to have_selector("[data-route-id='#{route_set_green_route_3.id}']", visible: false)
      expect(page).to have_selector("[data-route-id='#{route_set_green_route_4.id}']", visible: false)

      find("[data-test='route-set-#{route_set_green.id}'] .floorplan-prev", visible: :all).click

      expect(page).to have_selector("[data-route-id='#{route_set_green_route_1.id}']", visible: false)
      expect(page).to have_selector("[data-route-id='#{route_set_green_route_2.id}']", visible: false)
      expect(page).to have_selector("[data-route-id='#{route_set_green_route_3.id}']", visible: true)
      expect(page).to have_selector("[data-route-id='#{route_set_green_route_4.id}']", visible: true)

      find("[data-test='route-set-#{route_set_green.id}'] .floorplan-prev", visible: :all).click

      expect(page).to have_selector("[data-route-id='#{route_set_green_route_1.id}']", visible: true)
      expect(page).to have_selector("[data-route-id='#{route_set_green_route_2.id}']", visible: true)
      expect(page).to have_selector("[data-route-id='#{route_set_green_route_3.id}']", visible: false)
      expect(page).to have_selector("[data-route-id='#{route_set_green_route_4.id}']", visible: false)
    end
  end
end