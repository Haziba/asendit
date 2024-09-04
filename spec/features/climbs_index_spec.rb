require 'rails_helper'

RSpec.feature 'Climbs#index', type: :feature do
  context 'when logged in' do
    include_context 'logged_in'

    let!(:route_set_red) { create(:route_set, grade: logged_in_user.place.grades.first) }
    let!(:route_set_old_red) { create(:route_set, grade: logged_in_user.place.grades.first, added: Date.yesterday) }
    let!(:route_set_green) { create(:route_set, grade: logged_in_user.place.grades.last) }
    let!(:route_red) { create(:route, route_set_id: route_set_red.id) }
    let!(:route_old_red) { create(:route, route_set_id: route_set_old_red.id) }
    let!(:route_green) { create(:route, route_set_id: route_set_green.id) }

    let!(:climb_half_and_half) { create(:climb, climber: climber, route_state_json: [build(:route_status, route_id: route_red.id, status: 'sent'), build(:route_status, route_id: route_green.id, status: 'sent')], climbed_at: Date.yesterday) }
    let!(:climb_no_data) { create(:climb, climber: climber, climbed_at: Date.today) }

    before do
      visit '/climbs'
    end

    scenario 'the page renders the climbers climbs' do
      within('#climbs tbody') do
        within('tr:nth-child(1)') do
          expect(page).to have_content(climb_no_data.name)
          expect(page).to have_content('None Set')
          expect(page).to have_link('👁', href: "/climbs/#{climb_no_data.id}")
          expect(page).to have_link('✏️', href: "/climbs/#{climb_no_data.id}/edit")
          expect(page).to have_button('🗑')
        end

        within('tr:nth-child(2)') do
          expect(page).to have_content(climb_half_and_half.name)
          expect(page).to have_link('👁', href: "/climbs/#{climb_half_and_half.id}")
          expect(page).to have_link('✏️', href: "/climbs/#{climb_half_and_half.id}/edit")
          expect(page).to have_button('🗑')
        end
      end
    end

    scenario 'show a climb' do
      within("tr[data-test=climb-#{climb_no_data.id}") do
        find('[data-test=show]').click
      end
      expect(page).to have_current_path("/climbs/#{climb_no_data.id}")
    end

    scenario 'edit a climb' do
      within("tr[data-test=climb-#{climb_no_data.id}") do
        find('[data-test=edit]').click
      end
      expect(page).to have_current_path("/climbs/#{climb_no_data.id}/edit")
    end

    scenario 'deleting a climb' do
      within("tr[data-test=climb-#{climb_no_data.id}") do
        find('[data-test=delete]').click
      end
      page.accept_confirm
      expect(page).to have_selector("[data-test=climb-#{climb_no_data.id}]", count: 0)
    end

    scenario 'adding a climb' do
      old_climb_count = Climb.count

      find('[data-test=add]').click

      expect(Climb.count).to eq(old_climb_count+1)

      new_climb = Climb.last
      expect(new_climb.climber).to eq(climber)
      expect(new_climb.climbed_at).to eq(Date.today)
      expect(new_climb.current).to be_truthy

      expect(page).to have_current_path("/climbs/#{new_climb.id}/edit")
    end
  end

  context 'when anonymous' do
    include_context 'a protected page', '/climbs'
  end
end