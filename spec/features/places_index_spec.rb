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

    let!(:not_users_place) { create(:place) }

    before do
      visit '/places'
    end

    scenario 'places are listed and selectable' do
      Place.all.each do |place|
        expect(page).to have_selector("[data-test='place-#{place.id}']", text: place.name)
      end
    end

    scenario 'selecting a place redirects the user and sets the users place' do
      within("[data-test='place-#{not_users_place.id}']") do
        find('[data-test=choose]').click
      end

      expect(page).to have_current_path('/menu')
      logged_in_user.reload
      expect(logged_in_user.place).to eq(not_users_place)
    end

    context 'when user has a place set' do
      before do
        logged_in_user.update(place: create(:place))
        logged_in_user.place.update(user: logged_in_user)

        visit '/places'
      end

      scenario 'edit button available on places that are owned by user' do
        within("[data-test='place-#{logged_in_user.place.id}']") do
          expect(page).to have_selector('[data-test=edit]')
        end
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