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
require "test_helper"

class RouteSetTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
