require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  let!(:admin) { false }
  let!(:user) { create(:user, admin: admin) }

  before do
    helper.instance_variable_set(:@user, user)
  end

  describe '#admin_user?' do
    context 'when an admin' do
      let(:user) { create(:user, admin: true ) }

      it 'returns true if the user is an admin' do
        expect(helper.admin_user?).to be true
      end
    end

    it 'returns false if the user is not an admin' do
      expect(helper.admin_user?).to be_falsy
    end
  end

  describe '#climb_in_progress?' do
    context 'when logged in' do
      let(:user) { create(:user, admin: true ) }

      it 'returns true if there is a climb in progress' do
        create(:climb, user: user, current: true)

        expect(helper.climb_in_progress?).to be true
      end

      it 'returns false if there is no climb in progress' do
        expect(helper.climb_in_progress?).to be_falsy
      end
    end

    it 'gracefully handles a non logged in user' do
      allow(helper).to receive(:session).and_return({})
      expect(helper.climb_in_progress?).to be_falsy
    end
  end
end
