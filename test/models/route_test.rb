# == Schema Information
#
# Table name: routes
#
#  id           :bigint           not null, primary key
#  added        :datetime
#  floor        :integer
#  pos_x        :integer
#  pos_y        :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  route_set_id :bigint
#
# Indexes
#
#  index_routes_on_route_set_id  (route_set_id)
#
require "test_helper"

class RouteTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
