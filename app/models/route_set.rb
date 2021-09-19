class RouteSet < ApplicationRecord
  has_many :routes
  
  def name
    "#{color.titleize} (#{added.to_date})"
  end
end
