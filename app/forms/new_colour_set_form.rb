class NewColourSetForm
  include ActiveModel::Model

  attr_accessor :place, :description, :colours

  validates :place, presence: true

  def save
    return false unless valid?

    RouteSetColourSet.create(place: place, description: description)
  end
end
