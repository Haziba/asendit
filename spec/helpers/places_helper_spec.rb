require 'rails_helper'

RSpec.describe PlacesHelper, type: :helper do
  describe '#user_can_edit_place?' do
    let(:user) { create(:user) }
    let(:place_owner) { create(:user) }
    let(:place) { create(:place, user: place_owner) }

    before do
      allow(User).to receive(:me).with(session).and_return(user)
    end

    context 'when the current user is the owner of the place' do
      let(:place_owner) { user }

      it 'returns true' do
        expect(helper.user_can_edit_place?(place)).to be true
      end
    end

    context 'when the current user is an admin' do
      before do
        session['admin'] = true
      end

      it 'returns true' do
        expect(helper.user_can_edit_place?(place)).to be true
      end
    end

    context 'when the current user is neither the owner nor an admin' do
      it 'returns false' do
        expect(helper.user_can_edit_place?(place)).to be false
      end
    end

    context 'when the current user is not an admin and is also not the owner of the place' do
      before do
        session['admin'] = false
      end

      it 'returns false' do
        expect(helper.user_can_edit_place?(place)).to be false
      end
    end
  end
end
