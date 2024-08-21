class EditPlaceForm
  include ActiveModel::Model

  attr_accessor :place

  validates :place, presence: true

  def save
    return false unless valid?
    puts "Save update"
  end
end
