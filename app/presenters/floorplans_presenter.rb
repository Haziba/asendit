class FloorplansPresenter
  attr_reader :floorplans, :user

  def initialize(floorplans, user = nil)
    @floorplans = floorplans
    @user = user
  end

  def present
    {
      floorplans: floorplans.map { |floorplan| FloorplanPresenter.new(floorplan, user).present }
    }
  end
end