require 'rails_helper'

RSpec.describe Climb, type: :model do
  describe '#name' do
    it 'returns the correct formatted name based on climbed_at date' do
      climb = Climb.new(climbed_at: Date.new(2023, 8, 8))
      expect(climb.name).to eq('8th Aug')
    end
  end

  describe '#success_percentage' do
    let(:climb) { Climb.new(route_state_json: route_state_json) }

    context 'when there is no route state data' do
      let(:route_state_json) { [] }

      it 'returns "-"' do
        expect(climb.success_percentage).to eq('-')
      end
    end

    context 'when there is route state data' do
      let(:route_state_json) do
        [
          { "route_id" => 1, "status" => "sent" },
          { "route_id" => 2, "status" => "failed" },
          { "route_id" => 3, "status" => "flashed" },
          { "route_id" => 4, "status" => "not_attempted" }
        ]
      end

      it 'calculates the correct success percentage' do
        expect(climb.success_percentage).to eq('66%')
      end
    end
  end

  describe '#route_states' do
    let(:climb) { Climb.new(route_state_json: route_state_json) }

    context 'when there is route state data' do
      let(:route_state_json) do
        [
          { "route_id" => 1, "status" => "sent" },
          { "route_id" => 2, "status" => "failed" }
        ]
      end

      it 'returns an array of RouteStatus objects' do
        route_states = climb.route_states
        expect(route_states.count).to eq(2)
        expect(route_states.first).to be_a(RouteStatus)
        expect(route_states.first.route_id).to eq(1)
        expect(route_states.first.status).to eq("sent")
      end
    end

    context 'when there is no route state data' do
      let(:route_state_json) { [] }

      it 'returns an empty array' do
        expect(climb.route_states).to eq([])
      end
    end
  end
end
