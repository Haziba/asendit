require 'rails_helper'

RSpec.feature 'RouteSets#new', type: :feature do
  context 'when logged in as admin' do
    include_context 'logged_in', admin: true

    before do
      visit "/places/#{logged_in_user.place.id}/route_sets/new"
    end

    scenario 'page renders as expected' do
      expect(page).to have_content('Add Route Set')
      expect(page).to have_selector('[data-test=back-btn]')
      expect(find('[data-test=added]').value).to eq(Time.now.strftime('%Y-%m-%d'))
    end

    scenario 'renders appropriate colour sets' do
      expect(page).to have_selector('[data-test=grade]') do
        expect(page).to have_selector('option:nth-child(1)', text: logged_in_user.place.grades[0].name)
        expect(page).to have_selector('option:nth-child(2)', text: logged_in_user.place.grades[1].name)
        expect(page).to have_selector('option:nth-child(3)', text: logged_in_user.place.grades[2].name)
      end
    end

    scenario 'submitting the colour selector redirects to the edit page' do
      find('[type=submit]').click

      expect(page).to have_current_path("/route_sets/#{RouteSet.last.id}/edit")
    end
  end

  context 'when logged in as non admin' do
    include_context 'logged_in', admin: false
    let!(:place) { create(:place) }

    scenario "redirects to the route_sets page when accessed by an anonymous user" do
      visit "/places/#{place.id}/route_sets/new"

      expect(page).to have_current_path('/route_sets')
    end
  end

  context 'when anonymous' do
    include_context 'a protected page', '/route_sets/new'
  end
end