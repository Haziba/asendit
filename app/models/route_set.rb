# == Schema Information
#
# Table name: route_sets
#
#  id           :bigint           not null, primary key
#  added        :datetime
#  expires_at   :date
#  starts_on    :date
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  floorplan_id :bigint
#  grade_id     :bigint
#  place_id     :bigint           not null
#
# Indexes
#
#  index_route_sets_on_floorplan_id  (floorplan_id)
#  index_route_sets_on_grade_id      (grade_id)
#  index_route_sets_on_place_id      (place_id)
#
# Foreign Keys
#
#  fk_rails_...  (floorplan_id => floorplans.id)
#  fk_rails_...  (grade_id => grades.id)
#  fk_rails_...  (place_id => places.id)
#
class RouteSet < ApplicationRecord
  belongs_to :place
  belongs_to :grade
  belongs_to :floorplan, optional: true
  has_many :routes

  before_validation :set_default_floorplan, on: :create

  def name
    "#{grade&.name&.titleize || color.titleize} (#{added.to_date})"
  end

  def can_edit?(user)
    user.admin? || place.user == user
  end

  private

  def set_default_floorplan
    self.floorplan ||= place&.floorplans&.order(created_at: :desc)&.first
  end
end
