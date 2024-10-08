require 'rails_helper'

RSpec.describe RouteSet do
  let!(:route_set) { create(:route_set, added: Date.new(2020, 3, 13) )}

  describe '#name' do
    it 'should compose the name out of the colour and the date' do
      expect(route_set.name).to eq("#{route_set.grade.name.titleize} (2020-03-13)")
    end
  end
end