require 'rails_helper'

RSpec.feature 'RouteSets#new', type: :feature do
  context 'when logged in as admin' do
    include_context 'logged_in', admin: true

    before do
      visit '/route_sets/new'
    end

    scenario 'page renders as expected' do
      expect(page).to have_content('Add Route Set')
      expect(page).to have_selector('[data-test=back-btn]')

      expect(page).to have_selector('[data-test=color-picker]', text: 'Green')
      expect(find('[data-test=added]').value).to eq(Time.now.strftime('%Y-%m-%d'))
    end

    scenario 'submitting the colour selector redirects to the edit page' do
      find('[type=submit]').click

      expect(page).to have_current_path("/route_sets/#{RouteSet.last.id}/edit")
    end
  end

  context 'when logged in as non admin' do
    include_context 'logged_in', admin: false
    include_context 'a protected page', '/route_sets/new', return_path: '/route_sets'
  end

  context 'when anonymous' do
    include_context 'a protected page', '/route_sets/new'
  end
end