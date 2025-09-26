class ClimbsPresenter
  attr_reader :climbs, :user

  def initialize(climbs, user)
    @climbs = climbs
    @user = user
  end

  def present
    {
      climbs: climbs.map { |climb| ClimbPresenter.new(climb, user).present }
    }
  end
end