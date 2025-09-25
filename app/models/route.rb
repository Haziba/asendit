class Route < ApplicationRecord
  belongs_to :route_set

  validates :pos_x, presence: true, numericality: true
  validates :pos_y, presence: true, numericality: true
  validates :floor, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :added, presence: true
end
