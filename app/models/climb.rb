class Climb < ApplicationRecord
  has_many :route_states

  def name
    created_at.strftime("#{created_at.day.ordinalize} %b")
  end
end
