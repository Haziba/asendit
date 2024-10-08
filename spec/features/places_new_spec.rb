require 'rails_helper'

RSpec.feature 'Places#new', type: :feature do
  context 'when logged in' do
    include_context 'logged_in'

    before do
      visit '/places/new'
    end

    scenario 'page renders as expected' do
      expect(page).to have_content('Add Place')
      expect(page).to have_selector('[data-test=back-btn]')

      expect(page).to have_selector('[data-test=name]')
    end

    scenario 'submitting the form creates a place' do
      name = 'Cool Place'

      fill_in 'new_place_form_name', with: name
      expect {
        find('[type=submit]').click
      }.to change(Place, :count).by(1)

      expect(page).to have_current_path("/places")
      expect(Place.last.name).to eq(name)
    end

    scenario 'unable to submit form with name less than 4 characters' do
      name = 'Sho'

      fill_in 'new_place_form_name', with: name
      expect {
        find('[type=submit]').click
      }.to_not change(Place, :count)
    end
  end

  context 'when anonymous' do
    include_context 'a protected page'
  end
end