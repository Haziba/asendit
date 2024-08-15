require 'rails_helper'

RSpec.feature "RouteSets#show", type: :feature do
  let!(:route_set) { create(:route_set) }
  let!(:route_1) { create(:route, route_set: route_set, pos_x: 100, pos_y: 200) }
  let!(:route_2) { create(:route, route_set: route_set, pos_x: 200, pos_y: 400) }
  let!(:route_3) { create(:route, route_set: route_set, pos_x: 300, pos_y: 600) }
  let!(:route_4) { create(:route, route_set: route_set, pos_x: 400, pos_y: 800) }

  context 'when logged in' do
    include_context 'logged_in'

    context 'when the user has climbs on this route set' do
      let!(:climb) { create(:climb, climber: climber, route_state_json: [
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