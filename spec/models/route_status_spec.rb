require 'rails_helper'

RSpec.describe RouteStatus, type: :model do
  describe '#success?' do
    it 'returns true when the status is "sent"' do
      route_status = RouteStatus.new(1, "sent")
      expect(route_status.success?).to be true
    end

    it 'returns true when the status is "flashed"' do
      route_status = RouteStatus.new(1, "flashed")
      expect(route_status.success?).to be true
    end

    it 'returns false when the status is "failed"' do
      route_status = RouteStatus.new(1, "failed")
      expect(route_status.success?).to be false
    end

    it 'returns false when the status is "not_attempted"' do
      route_status = RouteStatus.new(1, "not_attempted")
      expect(route_status.success?).to be false
    end
  end

  describe '#tried?' do
    it 'returns true when the status is "sent"' do
      route_status = RouteStatus.new(1, "sent")
      expect(route_status.tried?).to be true
    end

    it 'returns true when the status is "flashed"' do
      route_status = RouteStatus.new(1, "flashed")
      expect(route_status.tried?).to be true
    end

    it 'returns true when the status is "failed"' do
      route_status = RouteStatus.new(1, "failed")
      expect(route_status.tried?).to be true
    end

    it 'returns false when the status is "not_attempted"' do
      route_status = RouteStatus.new(1, "not_attempted")
      expect(route_status.tried?).to be false
    end
  end
end
