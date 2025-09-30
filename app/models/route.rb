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
class Route < ApplicationRecord
  belongs_to :route_set

  validates :pos_x, presence: true, numericality: true
  validates :pos_y, presence: true, numericality: true
  validates :floor, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :added, presence: true
end
