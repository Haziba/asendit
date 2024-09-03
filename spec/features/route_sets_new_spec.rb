require 'rails_helper'

RSpec.feature 'RouteSets#new', type: :feature do
  context 'when logged in as admin' do
    include_context 'logged_in', admin: true

    let!(:place) { create(:place) }

    before do
      logged_in_user.update(place: place)
      visit "/places/#{place.id}/route_sets/new"
    end

    scenario 'page renders as expected' do
      expect(page).to have_content('Add Route Set')
      expect(page).to have_selector('[data-test=back-btn]')
      expect(find('[data-test=added]').value).to eq(Time.now.strftime('%Y-%m-%d'))
    end

    scenario 'renders appropriate colour sets' do
      expect(page).to have_selector('[data-test=color-set-picker]')
      within('[data-test=color-set-picker]') do
        expect(page).to have_selector('option:nth-child(1)', text: place.colour_sets[0].description)
        expect(page).to have_selector('option:nth-child(2)', text: place.colour_sets[1].description)
        expect(page).to have_selector('option:nth-child(3)', text: place.colour_sets[2].description)
      end

      expect(page).to have_selector('[data-test=color-picker]') do
        expect(page).to have_selector('option:nth-child(1)', text: place.colour_sets.first.colours[0].colour)
        expect(page).to have_selector('option:nth-child(2)', text: place.colour_sets.first.colours[1].colour)
        expect(page).to have_selector('option:nth-child(3)', text: place.colour_sets.first.colours[2].colour)
      end
    end

    scenario 'choosing a different colour set updates the colour set colours' do
      find('[data-test=color-set-picker]').select(place.colour_sets[1].description)

      expect(page).to have_selector('[data-test=color-picker]') do
        expect(page).to have_selector('option:nth-child(1)', text: place.colour_sets[1].colours[0].colour)
        expect(page).to have_selector('option:nth-child(2)', text: place.colour_sets[1].colours[1].colour)
        expect(page).to have_selector('option:nth-child(3)', text: place.colour_sets[1].colours[2].colour)
      end
    end

    scenario 'submitting the colour selector redirects to the edit page' do
      find('[type=submit]').click

      expect(page).to have_current_path("/route_sets/#{RouteSet.last.id}/edit")
    end
  end

  context 'when logged in as non admin' do
    include_context 'logged_in', admin: false
    include_context 'a protected page', "/places/1/route_sets/new", return_path: '/route_sets'

    let!(:place) { create(:place) }

    before do
      logged_in_user.update(place: place)
    end
  end

  context 'when anonymous' do
    include_context 'a protected page', '/route_sets/new'
  end
end