# == Schema Information
#
# Table name: climbs
#
#  id               :bigint           not null, primary key
#  climbed_at       :date
#  climber          :text
#  current          :boolean
#  route_state_json :json
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  place_id         :bigint
#  user_id          :bigint
#
# Indexes
#
#  index_climbs_on_place_id  (place_id)
#  index_climbs_on_user_id   (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
require "test_helper"

class ClimbTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
