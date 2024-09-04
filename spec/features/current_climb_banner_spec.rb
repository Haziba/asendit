require 'rails_helper'

RSpec.feature "Current climb banner", type: :feature do
  include_context('logged_in')

  let!(:climb) { create(:climb, current: current, climber: logged_in_user.reference) }

  before do
    visit '/menu'
  end

  context 'when current climb in progress' do
    let(:current) { true }

    scenario 'current climb link is shown' do
      expect(page).to have_selector('#goToCurrentClimb')
      find('#goToCurrentClimb a').click
      expect(page).to have_current_path("/climbs/#{climb.id}/edit")
    end
  end

  context 'when no current climb in progress' do
    let(:current) { false }

    scenario 'current climb link is shown' do
      expect(page).to_not have_selector('#goToCurrentClimb')
    end
  end
end