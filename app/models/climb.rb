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
class Climb < ApplicationRecord
  has_and_belongs_to_many :route_sets
  belongs_to :place
  belongs_to :user

  def name
    climbed_at.strftime("#{climbed_at.day.ordinalize} %b")
  end

  def success_percentage
    return "-" if route_states.empty?
    percentage = (route_states.count(&:success?).to_f / route_states.count(&:tried?).to_f) * 100
    "#{percentage.to_i}%"
  end

  def route_states
    route_state_json.map { |route_state| RouteStatus.new(route_state["route_id"], route_state["status"]) }
  end
end
