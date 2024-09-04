require 'rails_helper'

RSpec.feature "RouteSets#Index", type: :feature do
  context 'when logged in' do
    include_context 'logged_in', admin: false

    let!(:grade_red) { create(:grade, name: 'red', place: logged_in_user.place) }
    let!(:grade_blue) { create(:grade, name: 'blue', place: logged_in_user.place) }
    let!(:grade_other) { create(:grade) }

    let!(:old_blue_set) { create(:route_set, grade: grade_blue, added: Date.today - 1.year, place: logged_in_user.place) }
    let!(:new_blue_set) { create(:route_set, grade: grade_blue, added: Date.today, place: logged_in_user.place) }
    let!(:red_set) { create(:route_set, grade: grade_red, added: Date.today - 1.day, place: logged_in_user.place) }
    let!(:not_place_set) { create(:route_set, grade: grade_other, place: grade_other.place) }

    before do
      visit '/route_sets'
    end

    scenario 'User visits route sets index' do
      expect(page).to have_content('Route Sets')
      expect(page).to have_selector('[data-test=back-btn]')
    end

    scenario 'Has disabled add button' do
      expect(page).to have_selector('.btn', text: 'ADD', class: 'disabled')
    end

    scenario 'Lists correct current sets' do
      within('[data-test=current-sets] table tbody') do
        within('tr:nth-child(1)') do
          expect(page).to have_content(new_blue_set.name)
          expect(page).to have_link("History", href: "/route_sets/#{new_blue_set.id}")
          expect(page).to have_link('Edit', href: "/route_sets/#{new_blue_set.id}/edit", class: 'disabled')
          expect(page).to have_button('Delete', disabled: true)
        end

        within('tr:nth-child(2)') do
          expect(page).to have_content(red_set.name)
          expect(page).to have_link("History", href: "/route_sets/#{red_set.id}")
          expect(page).to have_link('Edit', href: "/route_sets/#{red_set.id}/edit", class: 'disabled')
          expect(page).to have_button('Delete', disabled: true)
        end
      end
    end

    scenario 'Lists correct previous sets' do
      find('[data-test=previous-sets] .card-header').click

      within('[data-test=previous-sets] table tbody') do
        within('tr:nth-child(1)') do
          expect(page).to have_content(old_blue_set.name)
          expect(page).to have_link("History", href: "/route_sets/#{old_blue_set.id}")
          expect(page).to have_link('Edit', href: "/route_sets/#{old_blue_set.id}/edit", class: 'disabled')
          expect(page).to have_button('Delete', disabled: true)
        end
      end
    end

    scenario 'Doesnt list other place sets' do
      expect(page).not_to have_content('other-place-colour')
    end
  end

  context 'when logged in as admin' do
    include_context 'logged_in', admin: true

    let!(:grade_red) { create(:grade, name: 'red', place: logged_in_user.place) }
    let!(:grade_blue) { create(:grade, name: 'blue', place: logged_in_user.place) }
    let!(:grade_other) { create(:grade) }

    let!(:old_blue_set) { create(:route_set, grade: grade_blue, added: Date.today - 1.year, place: logged_in_user.place) }
    let!(:new_blue_set) { create(:route_set, grade: grade_blue, added: Date.today, place: logged_in_user.place) }
    let!(:red_set) { create(:route_set, grade: grade_red, added: Date.today - 1.day, place: logged_in_user.place) }
    let!(:not_place_set) { create(:route_set, grade: grade_other, place: grade_other.place) }
    before do
      visit '/route_sets'
    end

    scenario 'User visits route sets index' do
      expect(page).to have_content('Route Sets')
    end

    scenario 'Has disabled add button' do
      add_button = find('.btn', text: 'ADD')
      add_button.click
      expect(page).to have_current_path("/places/#{logged_in_user.place.id}/route_sets/new")
    end

    scenario 'Lists correct current sets' do
      within('[data-test=current-sets] table tbody') do
        within('tr:nth-child(1)') do
          expect(page).to have_content(new_blue_set.name)
          expect(page).to have_link("History", href: "/route_sets/#{new_blue_set.id}")
          edit_link = find("a[href='/route_sets/#{new_blue_set.id}/edit']")
          expect(edit_link[:class]).not_to include('disabled')
          expect(page).to have_button('Delete', disabled: false)
        end

        within('tr:nth-child(2)') do
          expect(page).to have_content(red_set.name)
          expect(page).to have_link("History", href: "/route_sets/#{red_set.id}")
          expect(page).to have_link('Edit', href: "/route_sets/#{red_set.id}/edit")
          edit_link = find("a[href='/route_sets/#{red_set.id}/edit']")
          expect(edit_link[:class]).not_to include('disabled')
          expect(page).to have_button('Delete', disabled: false)
        end
      end
    end

    scenario 'Lists correct previous sets' do
      find('[data-test=previous-sets] .card-header').click

      within('[data-test=previous-sets] table tbody') do
        within('tr:nth-child(1)') do
          expect(page).to have_content(old_blue_set.name)
          expect(page).to have_link("History", href: "/route_sets/#{old_blue_set.id}")
          edit_link = find("a[href='/route_sets/#{old_blue_set.id}/edit']")
          expect(edit_link[:class]).not_to include('disabled')
          expect(page).to have_button('Delete', disabled: false)
        end
      end
    end

    scenario 'Can delete sets' do
      find("[data-test=route-set-#{new_blue_set.id}] [data-test=delete-button]").click()

      page.accept_confirm

      within('[data-test=current-sets] table tbody') do
        expect(page).to have_selector('tr:nth-child(1)', text: red_set.name)
        expect(page).to have_selector('tr:nth-child(2)', text: old_blue_set.name)
      end

      expect(page).to have_selector('[data-test=previous-sets] table tbody tr', count: 0)
    end

    scenario 'Can edit sets' do
      find("a[href='/route_sets/#{new_blue_set.id}/edit']").click()
      expect(page).to have_current_path("/route_sets/#{new_blue_set.id}/edit")
    end
  end

  context 'when anonymous' do
    include_context 'a protected page', '/route_sets'
  end
end
