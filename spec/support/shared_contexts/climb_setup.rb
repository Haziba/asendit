RSpec.shared_context 'climb setup' do
  let!(:setup_place) { create(:place, :with_grades) }

  let(:route_set1) { create(:route_set, grade: setup_place.grades.first) }
  let(:route_set2) { create(:route_set, grade: setup_place.grades.first) }

  let(:route_set1_route1) { create(:route, route_set: route_set1) }
  let(:route_set1_route2) { create(:route, route_set: route_set1) }
  let(:route_set2_route1) { create(:route, route_set: route_set2) }
  let(:route_set2_route2) { create(:route, route_set: route_set2) }

  let(:route_status_sent) { build(:route_status, route_id: route_set1_route1.id, status: 'sent') }
  let(:route_status_flashed) { build(:route_status, route_id: route_set1_route2.id, status: 'flashed') }
  let(:route_status_failed) { build(:route_status, route_id: route_set2_route1.id, status: 'failed') }
  let(:route_status_not_attempted) { build(:route_status, route_id: route_set2_route2.id, status: 'not_attempted') }
  let(:route_states) { [route_status_sent, route_status_flashed, route_status_failed, route_status_not_attempted] }

  let(:routes) { { route_set1.id => [route_set1_route1, route_set1_route2], route_set2.id => [route_set2_route1, route_set2_route2] } }

  let(:user) { create(:user, place: setup_place) }
  let(:climb) { create(:climb, user: user, route_state_json: route_states, route_sets: [route_set1, route_set2], place: setup_place) }
end
