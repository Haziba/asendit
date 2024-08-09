require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe '#admin_user?' do
    it 'returns true if the user is an admin' do
      allow(helper).to receive(:session).and_return({ userinfo: { "admin" => true } })
      expect(helper.admin_user?).to be true
    end

    it 'returns false if the user is not an admin' do
      allow(helper).to receive(:session).and_return({ userinfo: { "admin" => false } })
      expect(helper.admin_user?).to be false
    end
  end

  describe '#climb_in_progress?' do
    let(:climber_id) { 1 }

    before do
      allow(helper).to receive(:session).and_return({ userinfo: { "id" => climber_id } })
    end

    it 'returns true if there is a climb in progress' do
      create(:climb, climber: climber_id, current: true)
      expect(helper.climb_in_progress?).to be true
    end

    it 'returns false if there is no climb in progress' do
      expect(helper.climb_in_progress?).to be false
    end

    it 'gracefully handles a non logged in user' do
      allow(helper).to receive(:session).and_return({})
      expect(helper.climb_in_progress?).to be_nil
    end
  end
end
