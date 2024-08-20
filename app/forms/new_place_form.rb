class NewPlaceForm
  include ActiveModel::Model

  attr_accessor :name, :user

  validates :name, presence: true, length: { minimum: 4 }
  validates :user, presence: true

  def save
    return false unless valid?

    Place.create(name: name, user: user)
  end
end
