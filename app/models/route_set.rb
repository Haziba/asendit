class RouteSet < ApplicationRecord
  def name
    "#{color.titleize} (#{added.to_date})"
  end
end
