require 'rails_helper'

RSpec.describe NewPlaceForm, type: :model do
  let(:user) { build(:user) }
  let(:valid_attributes) { { name: "Valid Name", user: user } }

  describe 'validations' do
    it 'is valid with a name and user' do
      form = NewPlaceForm.new(valid_attributes)
      expect(form).to be_valid
    end

    it 'is invalid without a name' do
      form = NewPlaceForm.new(valid_attributes.merge(name: ''))
      expect(form).to_not be_valid
      expect(form.errors[:name]).to include("can't be blank")
    end

    it 'is invalid with a name shorter than 4 characters' do
      form = NewPlaceForm.new(valid_attributes.merge(name: 'Abc'))
      expect(form).to_not be_valid
      expect(form.errors[:name]).to include("is too short (minimum is 4 characters)")
    end

    it 'is invalid without a user' do
      form = NewPlaceForm.new(valid_attributes.merge(user: nil))
      expect(form).to_not be_valid
      expect(form.errors[:user]).to include("can't be blank")
    end
  end

  describe '#save' do
    context 'when valid' do
      it 'creates a new place' do
        form = NewPlaceForm.new(valid_attributes)
        expect { form.save }.to change(Place, :count).by(1)
      end

      it 'associates the place with the correct user' do
        form = NewPlaceForm.new(valid_attributes)
        form.save
        new_place = Place.last
        expect(new_place.name).to eq("Valid Name")
        expect(new_place.user).to eq(user)
      end
    end

    context 'when invalid' do
      it 'does not create a new place' do
        form = NewPlaceForm.new(valid_attributes.merge(name: ''))
        expect { form.save }.to_not change(Place, :count)
      end
    end
  end
end
