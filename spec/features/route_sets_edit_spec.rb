require 'rails_helper'

RSpec.feature 'RouteSets#edit', type: :feature do
  context 'when logged in as admin' do
    include_context 'logged_in', admin: true

    let!(:route_set) { create(:route_set, place: logged_in_user.place) }
    let!(:route) { create(:route, route_set: route_set, pos_x: 200, pos_y: 200) }

    before do
      visit "/route_sets/#{route_set.id}/edit"
    end

    scenario 'components are rendered as expected' do
      expect(page).to have_content("Edit #{route_set.name}")
      expect(page).to have_selector('[data-test=back-btn]')
      expect(page).to have_selector('#map img')
    end

    scenario 'renders existing routes' do
      expect(page).to have_selector('.route', visible: :all, wait: 1)

      found_route = find(".route[data-route-id='#{route.id}']", visible: :all)
      route_pos = /left: ([0-9]+\.?[0-9]*)%; top: ([0-9]+\.?[0-9]*)%;/.match(found_route[:style])
      expect(route_pos[1].to_f).to eq(25)
      expect(route_pos[2].to_i).to eq(16)
    end

    scenario 'adding a route' do
      image = find('#map img[data-floorplan-id="0"]')

      page.execute_script <<-JS, image.native
  var rect = arguments[0].getBoundingClientRect();
  var x = rect.left + rect.width * 0.6;
  var y = rect.top + rect.height * 0.3;
  var clickEvent = new MouseEvent('click', {
    view: window,
    bubbles: true,
    cancelable: true,
    clientX: x,
    clientY: y
  });
  arguments[0].dispatchEvent(clickEvent);
JS

      expect(page).to have_selector('.route', visible: :all)

      new_route = find(".route[data-route-id='#{route.id+1}']", visible: :all)
      route_pos = /left: ([0-9]+\.?[0-9]*)%; top: ([0-9]+\.?[0-9]*)%;/.match(new_route[:style])
      expect((59..61)).to cover(route_pos[1].to_f)
      expect((29..31)).to cover(route_pos[2].to_f)

      route_set.reload
      expect(route_set.routes.last.floor).to eq(0)
    end

    scenario 'removing a route' do
      find('[data-test=add-or-remove]').select('Remove')
      find("[data-route-id='#{route.id}']", visible: :all).click
      expect(page).to_not have_selector('.route', visible: :all)
      expect(Route.where(id: route.id)).to be_empty
    end

    scenario 'adding a route to the second floorplan' do
      find("#floorplan-next", visible: :all).click

      image = find('#map img[data-floorplan-id="1"]')

      page.execute_script <<-JS, image.native
  var rect = arguments[0].getBoundingClientRect();
  var x = rect.left + rect.width * 0.6;
  var y = rect.top + rect.height * 0.3;
  var clickEvent = new MouseEvent('click', {
    view: window,
    bubbles: true,
    cancelable: true,
    clientX: x,
    clientY: y
  });
  arguments[0].dispatchEvent(clickEvent);
JS

      expect(page).to have_selector('.route', visible: :all)

      new_route = find(".route[data-route-id='#{route.id+1}']", visible: :all)
      route_pos = /left: ([0-9]+\.?[0-9]*)%; top: ([0-9]+\.?[0-9]*)%;/.match(new_route[:style])
      expect((59..61)).to cover(route_pos[1].to_f)
      expect((29..31)).to cover(route_pos[2].to_f)

      route_set.reload
      expect(route_set.routes.last.floor).to eq(1)
    end
  end

  context 'when logged in as non admin' do
    include_context 'logged_in', admin: false
    include_context 'a protected page', '/places/1/route_sets/new', return_path: '/route_sets'

    before do
      logged_in_user.update(place: create(:place))
    end
  end

  context 'when anonymous' do
    include_context 'a protected page', '/route_sets/new'
  end
end