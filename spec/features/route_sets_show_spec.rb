require 'rails_helper'

RSpec.feature "RouteSets#show", type: :feature do
  context 'when logged in' do
    include_context 'logged_in'

    let!(:route_set) { create(:route_set, grade: create(:grade, place: logged_in_user.place)) }
    let!(:route_1) { create(:route, route_set: route_set, pos_x: 100, pos_y: 200, floor: 0) }
    let!(:route_2) { create(:route, route_set: route_set, pos_x: 200, pos_y: 400, floor: 0) }
    let!(:route_3) { create(:route, route_set: route_set, pos_x: 300, pos_y: 100, floor: 1) }
    let!(:route_4) { create(:route, route_set: route_set, pos_x: 400, pos_y: 800) }

    before do
      logged_in_user.update(place: route_set.place)
    end

    context 'when the user has climbs on this route set' do
      let!(:climb) { create(:climb, user: logged_in_user, route_state_json: [
        build(:route_status, route_id: route_1.id, status: 'sent'),
        build(:route_status, route_id: route_2.id, status: 'flashed'),
        build(:route_status, route_id: route_3.id, status: 'failed')
      ]) }

      before do
        visit "/route_sets/#{route_set.id}"
      end

      scenario 'the page renders the climbers history' do
        expect(page).to have_selector('.route', count: 3, visible: :all)
        expect(page).to have_selector('.route', text: '🟡', visible: :all)
        expect(page).to have_selector('.route', text: '✔', visible: :all)
        expect(page).to have_selector('.route', text: '❌', visible: :all)
      end

      scenario 'changing floor shows & hides the floor routes' do
        expect(page).to have_selector("[data-route-id='#{route_1.id}']", visible: true)
        expect(page).to have_selector("[data-route-id='#{route_2.id}']", visible: true)
        expect(page).to have_selector("[data-route-id='#{route_3.id}']", visible: false)

        find("#floorplan-next", visible: :all).click

        expect(page).to have_selector("[data-route-id='#{route_1.id}']", visible: false)
        expect(page).to have_selector("[data-route-id='#{route_2.id}']", visible: false)
        expect(page).to have_selector("[data-route-id='#{route_3.id}']", visible: true)

        find("#floorplan-next", visible: :all).click

        expect(page).to have_selector("[data-route-id='#{route_1.id}']", visible: true)
        expect(page).to have_selector("[data-route-id='#{route_2.id}']", visible: true)
        expect(page).to have_selector("[data-route-id='#{route_3.id}']", visible: false)

        find("#floorplan-prev", visible: :all).click

        expect(page).to have_selector("[data-route-id='#{route_1.id}']", visible: false)
        expect(page).to have_selector("[data-route-id='#{route_2.id}']", visible: false)
        expect(page).to have_selector("[data-route-id='#{route_3.id}']", visible: true)

        find("#floorplan-prev", visible: :all).click

        expect(page).to have_selector("[data-route-id='#{route_1.id}']", visible: true)
        expect(page).to have_selector("[data-route-id='#{route_2.id}']", visible: true)
        expect(page).to have_selector("[data-route-id='#{route_3.id}']", visible: false)
      end
    end

    context 'when the user has no climbs on this route set' do
      before do
        visit "/route_sets/#{route_set.id}"
      end

      scenario 'the page doesnt render any routes' do
        expect(page).to_not have_selector('.route', text: '🟡', count: 3, visible: :all)
      end
    end
  end

  context 'when anonymous' do
    include_context 'a protected page', '/route_sets/new'
  end
end