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

    context 'when no floorplan data' do
      before do
        place.floorplan.update(data: [])
        visit "/places/#{place.id}/edit"
      end

      scenario 'a floorplan is added' do
        expect(page).to have_field('floorplan-name', with: 'New Floorplan')

        # Floorplan without image isn't uploaded
        fill_in 'floorplan-name', with: 'Cool Floorplan'
        sleep 0.5
        place.reload
        expect(place.floorplan.data).to eq([])

        # First floorplan image is uploaded
        previous_image_src = find('#floorplan-img', visible: :any)['src']
        attach_file('floorplan-image-upload', './public/GroundFloor.png', visible: false)
        sleep 0.5
        expect(find('#floorplan-img', visible: :any)['src']).to_not eq(previous_image_src)

        place.reload
        expect(place.floorplan.data).to eq([{ 'name' => 'Cool Floorplan', 'image_id' => place.floorplan.images.last.id }])
      end
    end

    context 'when floorplan data' do
      scenario 'a floorplan is switched between' do
        expect(page).to have_field('floorplan-name', with: place.floorplan.data.first['name'])
        find('#floorplan-next').click
        expect(page).to have_field('floorplan-name', with: place.floorplan.data.last['name'])
        find('#floorplan-next').click
        expect(page).to have_field('floorplan-name', with: place.floorplan.data.first['name'])
        find('#floorplan-prev').click
        expect(page).to have_field('floorplan-name', with: place.floorplan.data.last['name'])
        find('#floorplan-prev').click
        expect(page).to have_field('floorplan-name', with: place.floorplan.data.first['name'])
      end

      scenario 'a floorplan is edited' do
        expect(page).to have_field('floorplan-name', with: place.floorplan.data.first['name'])

        fill_in 'floorplan-name', with: 'Cool Floorplan'
        sleep 0.5
        place.reload
        expect(place.floorplan.data.first['name']).to eq('Cool Floorplan')

        previous_image_src = find('#floorplan-img', visible: :any)['src']

        attach_file('floorplan-image-upload', './public/GroundFloor.png', visible: false)
        sleep 0.5
        expect(find('#floorplan-img', visible: :any)['src']).to_not eq(previous_image_src)

        place.reload
        expect(place.floorplan.data).to eq([{ 'name' => 'Cool Floorplan', 'image_id' => place.floorplan.images.last.id }] + place.floorplan.data[1..])
      end

      scenario 'a floorplan is marked as deleted' do
        # Remove the first floorplan
        find('#floorplan-remove').click
        expect(page).to have_field('floorplan-name', with: place.floorplan.data.last['name'])

        updated_old_place_data = place.floorplan.data
        updated_old_place_data.first['deleted'] = true
        place.reload
        expect(place.floorplan.data).to eq(updated_old_place_data)
      end
    end
  end

  context 'when anonymous' do
    include_context 'a protected page'
  end
end