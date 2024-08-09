require 'rails_helper'


RSpec.describe ClimbsHelper, type: :helper do
  let!(:route_set1) { create(:route_set, color: 'red') }
  let!(:route_set2) { create(:route_set, color: 'blue') }

  let!(:route_set1_route1) { create(:route, route_set: route_set1) }
  let!(:route_set1_route2) { create(:route, route_set: route_set1) }
  let!(:route_set2_route1) { create(:route, route_set: route_set2) }
  let!(:route_set2_route2) { create(:route, route_set: route_set2) }

  let!(:route_status_sent) { build(:route_status, route_id: route_set1_route1.id, status: 'sent') }
  let!(:route_status_flashed) { build(:route_status, route_id: route_set1_route2.id, status: 'flashed') }
  let!(:route_status_failed) { build(:route_status, route_id: route_set2_route1.id, status: 'failed') }
  let!(:route_status_not_attempted) { build(:route_status, route_id: route_set2_route2.id, status: 'not_attempted') }
  let!(:route_states) { [route_status_sent, route_status_flashed, route_status_failed, route_status_not_attempted] }

  let!(:routes) { { route_set1.id => [route_set1_route1, route_set1_route2], route_set2.id => [route_set2_route1, route_set2_route2] } }

  let!(:climber) { '1234' }
  let!(:climb) { create(:climb, climber: climber, route_state_json: route_states) }

  before do
    helper.instance_variable_set(:@routes, routes)
    helper.instance_variable_set(:@climb, climb)
  end

  describe '#route_attempt_percentages' do
    it 'returns the correct percentages for route attempts' do
      expect(helper.route_attempt_percentages(route_states)).to eq([['red', 100.0/3.0*2.0], ['blue', 100.0/3.0]])
    end
  end

  describe '#route_set_by_route_id' do
    it 'returns the correct route set for a given route id' do
      expect(helper.route_set_by_route_id(route_set1_route1.id)).to eq(route_set1)
    end
  end

  describe '#attempted_routes' do
    it 'returns the correct attempted routes string' do
      expect(helper.attempted_routes(route_set2)).to eq('1/2')
    end
  end

  describe '#success_rate' do
    it 'returns the correct success rate for successful climbs' do
      expect(helper.success_rate(route_set1)).to eq('100%')
    end

    it 'returns 0% when there are no successes' do
      expect(helper.success_rate(route_set2)).to eq('0%')
    end
  end

  context 'when the climber has previous climbs on these sets' do
    before do
      previous_route_states = [build(:route_status, route_id: route_set1_route1.id, status: 'sent')]
      create(:climb, climber: climber, climbed_at: 1.day.ago, route_state_json: previous_route_states)
    end

    describe '#new_wins' do
      it 'returns new wins for the current climb' do
        expect(helper.new_wins.map(&:route_id)).to eq([route_status_flashed.route_id])
      end
    end

    describe '#new_wins_count_for_set' do
      it 'returns the correct count of new wins for a route set' do
        expect(helper.new_wins_count_for_set(route_set1)).to eq(1)
      end
    end

    describe '#previous_states' do
      it 'returns the correct previous states' do
        expect(helper.previous_states).to eq({ route_set1_route1.id => 'sent' })
      end
    end
  end

  context 'when the climber has no previous climbs on these sets' do
    describe '#new_wins' do
      it 'returns new wins for the current climb' do
        expect(helper.new_wins.map(&:route_id)).to eq([route_status_sent.route_id, route_status_flashed.route_id])
      end
    end

    describe '#new_wins_count_for_set' do
      it 'returns the correct count of new wins for a route set' do
        expect(helper.new_wins_count_for_set(route_set1)).to eq(2)
      end
    end

    describe '#previous_states' do
      it 'returns the correct previous states' do
        expect(helper.previous_states).to eq({})
      end
    end
  end
end
