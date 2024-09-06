class NewPlaceForm
  include ActiveModel::Model

  attr_accessor :name, :user

  validates :name, presence: true, length: { minimum: 4 }
  validates :user, presence: true

  def save
    return false unless valid?

    place = Place.create(name: name, user: user)
    Floorplan.create(name: 'Initial floorplan', data: [], place: place)
    place
  end
end
