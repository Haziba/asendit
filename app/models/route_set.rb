class RouteSet < ApplicationRecord
  belongs_to :place
  has_many :routes
  
  def name
    "#{color.titleize} (#{added.to_date})"
  end
end
