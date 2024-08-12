require 'rails_helper'

RSpec.feature "Menu", type: :feature do
  context 'when logged in' do
    include_context 'logged_in'

    scenario "User visits the menu page" do
      visit '/menu'

      expect(page).to have_content("Let's Climb")
      expect(page).to have_link('Climbs')
      expect(page).to have_link('Route Sets')
    end
  end

  context 'when anonymous' do
    scenario "User visits the menu page" do
      visit '/menu'

      expect(page).to have_current_path(root_path)
    end
  end
end
