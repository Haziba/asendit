class Climb < ApplicationRecord
  has_many :route_states

  def name
    created_at.strftime("#{created_at.day.ordinalize} %b")
  end

  def success_percentage
    percentage = (route_states.count(&:success?).to_f / route_states.count(&:tried?).to_f) * 100
    "#{percentage.to_i}%"
  end
end
