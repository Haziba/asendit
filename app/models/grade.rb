# == Schema Information
#
# Table name: grades
#
#  id              :bigint           not null, primary key
#  grade           :string
#  map_tint_colour :string
#  name            :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  place_id        :bigint           not null
#
# Indexes
#
#  index_grades_on_place_id  (place_id)
#
# Foreign Keys
#
#  fk_rails_...  (place_id => places.id)
#
class Grade < ApplicationRecord
  belongs_to :place
  has_many :route_sets

  validates :name, presence: true
  validates :map_tint_colour, presence: true

  def active_route_set
    route_sets.sort_by(&:added).last
  end

  def past_route_sets
    route_sets.order(added: :desc).offset(1)
  end
end
