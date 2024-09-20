require 'rails_helper'

RSpec.feature 'Climbs#edit', type: :feature do
  context 'when logged in as the climb\'s user' do
    include_context 'logged_in'

    let!(:grade_green) { create(:grade, name: 'green', place: logged_in_user.place) }
    let!(:grade_red) { create(:grade, name: 'red', place: logged_in_user.place) }

    let!(:route_set_green) { create(:route_set, added: Date.yesterday, grade: grade_green) }
    let!(:route_set_old_green) { create(:route_set, added: Date.yesterday - 1.day, grade: grade_green) }
    let!(:route_set_red) { create(:route_set, added: Date.today, grade: grade_red) }

    let!(:route_set_green_route_1) { create(:route, route_set: route_set_green) }
    let!(:route_set_green_route_2) { create(:route, route_set: route_set_green) }
    let!(:route_set_green_route_3) { create(:route, route_set: route_set_green) }
    let!(:route_set_green_route_4) { create(:route, route_set: route_set_green) }
    let!(:route_set_red_route_1) { create(:route, route_set: route_set_red) }

    let!(:previous_climb) { create(:climb, user: logged_in_user, route_state_json: [
      build(:route_status, route_id: route_set_green_route_1.id, status: 'sent'),
      build(:route_status, route_id: route_set_green_route_2.id, status: 'failed'),
      build(:route_status, route_id: route_set_green_route_3.id, status: 'not_attempted'),
    ])}
    let!(:climb) { create(:climb, user: logged_in_user, route_sets: [route_set_green, route_set_red], current: true) }

    before do
      visit "/climbs/#{climb.id}/edit"
    end

    scenario 'only newest sets per colour are options' do
      within('[data-test=route-set-picker]') do
        expect(page).to have_selector("button[data-route-set-id='#{route_set_green.id}'][data-grade='#{route_set_green.grade.id}']")
        expect(page).to have_selector("button[data-route-set-id='#{route_set_red.id}'][data-grade='#{route_set_red.grade.id}']")
        expect(page).to_not have_selector("button[data-route-set-id='#{route_set_old_green.id}']")
      end
    end

    scenario 'displays alphabetically first route set on load' do
      expect(page).to have_selector("button[data-route-set-id='#{route_set_green.id}'].current")

      expect(page).to have_selector("[data-route-id='#{route_set_green_route_1.id}']", visible: :all)
      expect(page).to have_selector("[data-route-id='#{route_set_green_route_2.id}']", visible: :all)
      expect(page).to have_selector("[data-route-id='#{route_set_green_route_3.id}']", visible: :all)
      expect(page).to have_selector("[data-route-id='#{route_set_green_route_4.id}']", visible: :all)
      expect(page).to_not have_selector("[data-route-id='#{route_set_red_route_1.id}']", visible: :all)
    end

    scenario 'selecting a different route set changes the routes' do
      find("button[data-route-set-id='#{route_set_red.id}']").click

      expect(page).to_not have_selector("[data-route-id='#{route_set_green_route_1.id}']", visible: :all)
      expect(page).to_not have_selector("[data-route-id='#{route_set_green_route_2.id}']", visible: :all)
      expect(page).to_not have_selector("[data-route-id='#{route_set_green_route_3.id}']", visible: :all)
      expect(page).to_not have_selector("[data-route-id='#{route_set_green_route_4.id}']", visible: :all)
      expect(page).to have_selector("[data-route-id='#{route_set_red_route_1.id}']", visible: :all)
    end

    scenario 'climbers history reflected in route icons' do
      expect(page).to have_selector("[data-route-id='#{route_set_green_route_1.id}']", text: '🟢', visible: :all)
      expect(page).to have_selector("[data-route-id='#{route_set_green_route_2.id}']", text: '🟡', visible: :all)
      expect(page).to have_selector("[data-route-id='#{route_set_green_route_3.id}']", text: '🔴', visible: :all)
      expect(page).to have_selector("[data-route-id='#{route_set_green_route_4.id}']", text: '🔴', visible: :all)
    end

    scenario 'recording routes' do
      click_native_element("[data-route-id='#{route_set_green_route_1.id}']")
      expect(page).to have_selector("[data-route-id='#{route_set_green_route_1.id}']", text: '❌', visible: :all)

      click_native_element("[data-route-id='#{route_set_green_route_2.id}']")
      click_native_element("[data-route-id='#{route_set_green_route_2.id}']")
      expect(page).to have_selector("[data-route-id='#{route_set_green_route_2.id}']", text: '✔', visible: :all)

      click_native_element("[data-route-id='#{route_set_green_route_3.id}']")
      click_native_element("[data-route-id='#{route_set_green_route_3.id}']")
      click_native_element("[data-route-id='#{route_set_green_route_3.id}']")
      expect(page).to have_selector("[data-route-id='#{route_set_green_route_3.id}']", text: '⚡', visible: :all)

      click_native_element("[data-route-id='#{route_set_green_route_4.id}']")
      click_native_element("[data-route-id='#{route_set_green_route_4.id}']")
      click_native_element("[data-route-id='#{route_set_green_route_4.id}']")
      click_native_element("[data-route-id='#{route_set_green_route_4.id}']")
      expect(page).to have_selector("[data-route-id='#{route_set_green_route_4.id}']", text: '🔴', visible: :all)

      find("button[data-route-set-id='#{route_set_red.id}']").click

      click_native_element("[data-route-id='#{route_set_red_route_1.id}']")
      expect(page).to have_selector("[data-route-id='#{route_set_red_route_1.id}']", text: '❌', visible: :all)

      # todo: Replace with an 'updating' spinner to track the debounce & update better
      sleep(1.5)

      visit "/climbs/#{climb.id}/edit"

      expect(page).to have_selector("[data-route-id='#{route_set_green_route_1.id}']", text: '❌', visible: :all)
      expect(page).to have_selector("[data-route-id='#{route_set_green_route_2.id}']", text: '✔', visible: :all)
      expect(page).to have_selector("[data-route-id='#{route_set_green_route_3.id}']", text: '⚡', visible: :all)
      expect(page).to have_selector("[data-route-id='#{route_set_green_route_4.id}']", text: '🔴', visible: :all)
      find("button[data-route-set-id='#{route_set_red.id}']").click
      expect(page).to have_selector("[data-route-id='#{route_set_red_route_1.id}']", text: '❌', visible: :all)
    end

    scenario 'completing a climb' do
      expect(climb.current).to be_truthy
      find('[data-test=complete]').click
      expect(page).to have_current_path("/climbs/#{climb.id}")
      climb.reload
      expect(climb.current).to be(false)
    end
  end

  context 'when logged in as a rando' do
    include_context 'logged_in'

    let!(:climb) { create(:climb, user: create(:user)) }

    scenario 'visiting another user\'s climb' do
      visit "/climbs/#{climb.id}/edit"

      expect(page).to have_current_path('/climbs')
    end
  end

  context 'when anonymous' do
    let!(:climb) { create(:climb) }

    scenario "redirects to the root page when accessed by an anonymous user" do
      visit "/climbs/#{climb.id}/edit"

      expect(page).to have_current_path('/')
    end
  end
end