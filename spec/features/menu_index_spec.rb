require 'rails_helper'

RSpec.feature "Menu#Index", type: :feature do
  context 'when logged in' do
    include_context 'logged_in'

    before do
      visit '/menu'
    end

    scenario "User visits the menu page" do
      expect(page).to have_content("Let's Climb")
      expect(page).to have_link('Climbs')
      expect(page).to have_link('Route Sets')
    end

    scenario "User clicks the Climbs link" do
      page.click_link('Climbs')
      expect(page).to have_current_path('/climbs')
    end

    scenario "User clicks the Route Sets link" do
      page.click_link('Route Sets')
      expect(page).to have_current_path('/route_sets')
    end
  end

  context 'when anonymous' do
    include_context 'a protected page', '/menu'
  end
end
