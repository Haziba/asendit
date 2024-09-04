require 'rails_helper'

RSpec.feature 'Places#edit', type: :feature do
  context 'when logged in' do
    include_context 'logged_in'

    let!(:place) { create(:place) }

    before do
      visit "/places/#{place.id}/edit"
    end

    scenario 'page renders as expected' do
      expect(page).to have_content("Edit #{place.name}")
      expect(page).to have_selector('[data-test=back-btn]')

      expect(page).to have_selector('[data-test=name]')
    end

    scenario 'submitting the form updates a place' do
      name = 'Cooler Place'

      fill_in 'place_name', with: name
      find('[type=submit]').click

      expect(page).to have_current_path("/places")
      place.reload
      expect(place.name).to eq(name)
    end

    scenario 'lists grades' do
      place.grades.each do |grade|
        expect(page).to have_content(grade.name)
        expect(page).to have_content(grade.grade)
        expect(page).to have_content(grade.map_tint_colour)
      end
    end

    scenario 'adding a grade' do
      fill_in 'grade_name', with: 'New Grade'
      fill_in 'grade_grade', with: 'V1'
      fill_in 'grade_map_tint_colour', with: '#f00000'
      find('#add_grade').click

      expect(page).to have_content('New Grade')

      place.reload
      expect(place.grades.where(name: 'New Grade', grade: 'V1', map_tint_colour: '#f00000')).to exist
    end

    scenario 'removing a grade' do
      grade_to_remove = place.grades.first

      within("[data-grade-id='#{grade_to_remove.id}']") do
        find('[name=remove-grade]').click
      end

      expect(page).to_not have_content(grade_to_remove.name)

      place.reload
      expect(place.grades).to_not include(grade_to_remove)
    end
  end

  context 'when anonymous' do
    include_context 'a protected page'
  end
end