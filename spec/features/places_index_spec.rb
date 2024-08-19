require 'rails_helper'

RSpec.feature 'Places#index', type: :feature do
  context 'when logged in as admin' do
    include_context 'logged_in', admin: true

    let!(:not_users_place) { create(:place) }

    before do
      visit '/places'
    end

    scenario 'places are listed' do
      expect(page).to have_selector("[data-test='place-#{not_users_place.id}']", text: not_users_place.name)
    end

    scenario 'edit button available' do
      within("[data-test='place-#{not_users_place.id}']") do
        expect(page).to have_selector('[data-test=edit]')
      end
    end
  end

  context 'when logged in' do
    include_context 'logged_in', admin: false

    let!(:user) { create(:user, reference: climber) }
    let!(:users_place) { create(:place, user: user) }
    let!(:not_users_place) { create(:place) }
    let!(:places) { [users_place, not_users_place] }

    before do
      visit '/places'
    end

    scenario 'places are listed and selectable' do
      places.each do |place|
        expect(page).to have_selector("[data-test='place-#{place.id}']", text: place.name)
      end
    end

    scenario 'selecting a place redirects the user and sets the users place' do
      within("[data-test='place-#{not_users_place.id}']") do
        find('[data-test=choose]').click
      end

      expect(page).to have_current_path('/menu')
      user.reload
      expect(user.place).to eq(not_users_place)
    end

    scenario 'edit button available on places that are owned by user' do
      within("[data-test='place-#{users_place.id}']") do
        expect(page).to have_selector('[data-test=edit]')
      end
    end

    scenario 'no edit button available on places that arent owned by user' do
      within("[data-test='place-#{not_users_place.id}']") do
        expect(page).to have_selector('[data-test=edit].disabled')
      end
    end

    scenario 'add button available' do
      expect(page).to have_selector('[data-test=add]')
    end
  end

  context 'when anonymous' do
    include_context 'a protected page', '/places'
  end
end