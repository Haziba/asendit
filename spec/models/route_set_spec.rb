# == Schema Information
#
# Table name: route_sets
#
#  id         :bigint           not null, primary key
#  added      :datetime
#  expires_at :date
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  grade_id   :bigint
#  place_id   :bigint           not null
#
# Indexes
#
#  index_route_sets_on_grade_id  (grade_id)
#  index_route_sets_on_place_id  (place_id)
#
# Foreign Keys
#
#  fk_rails_...  (grade_id => grades.id)
#  fk_rails_...  (place_id => places.id)
#
require 'rails_helper'

RSpec.describe RouteSet do
  let!(:route_set) { create(:route_set, added: Date.new(2020, 3, 13) )}

  describe '#name' do
    it 'should compose the name out of the colour and the date' do
      expect(route_set.name).to eq("#{route_set.grade.name.titleize} (2020-03-13)")
    end
  end
end
