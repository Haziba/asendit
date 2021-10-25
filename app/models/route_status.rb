class RouteStatus
  attr_accessor :route_id, :status

  def initialize(route_id, status)
    @route_id = route_id
    @status = status
  end

  def success?
    ["sent", "flashed"].include? @status
  end

  def tried?
    ["sent", "flashed", "failed"].include? @status
  end
end
