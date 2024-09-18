require 'rails_helper'


RSpec.describe ClimbsHelper, type: :helper do
  include_context 'climb setup'

  before do
    helper.instance_variable_set(:@routes, routes)
    helper.instance_variable_set(:@climb, climb)
  end

  describe '#route_attempt_percentages' do
    it 'returns the correct percentages for route attempts' do
      expect(helper.route_attempt_percentages(route_states)).to eq([[route_set1.grade.name, 100.0/3.0*2.0], [route_set2.grade.name, 100.0/3.0]])
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
      create(:climb, user: user, climbed_at: 1.day.ago, route_state_json: previous_route_states)
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
