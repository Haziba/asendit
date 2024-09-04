class RouteSet < ApplicationRecord
  belongs_to :place
  belongs_to :grade
  has_many :routes
  
  def name
    "#{grade&.name&.titleize || color.titleize} (#{added.to_date})"
  end
end
