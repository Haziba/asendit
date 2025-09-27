class Place < ApplicationRecord
  has_many :route_sets, dependent: :destroy
  has_many :tournaments, dependent: :destroy
  has_many :grades, dependent: :destroy
  has_many :climbs, dependent: :destroy
  has_one :floorplan, dependent: :destroy
  belongs_to :user

  validates :name, presence: true, length: { minimum: 4 }
  validates :latitude, presence: true, if: :longitude?
  validates :longitude, presence: true, if: :latitude?
  validates :latitude, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }, allow_nil: true
  validates :longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }, allow_nil: true

  scope :with_coordinates, -> { where.not(latitude: nil, longitude: nil) }
  scope :near, ->(latitude, longitude, limit = 20) {
    return limit(limit) if latitude.blank? || longitude.blank?

    with_coordinates
      .select("*, #{distance_sql(latitude, longitude)} AS distance")
      .order('distance ASC')
      .limit(limit)
  }

  def can_edit?(user)
    self.user == user
  end

  def distance_to(latitude, longitude)
    return nil if self.latitude.blank? || self.longitude.blank? || latitude.blank? || longitude.blank?

    self.class.calculate_distance(self.latitude, self.longitude, latitude, longitude)
  end

  def has_coordinates?
    latitude.present? && longitude.present?
  end

  private

  def self.distance_sql(lat, lng)
    # Haversine formula in SQL for calculating distance in kilometers
    <<-SQL
      (
        6371 * acos(
          cos(radians(#{lat})) *
          cos(radians(latitude)) *
          cos(radians(longitude) - radians(#{lng})) +
          sin(radians(#{lat})) *
          sin(radians(latitude))
        )
      )
    SQL
  end

  def self.calculate_distance(lat1, lng1, lat2, lng2)
    # Haversine formula for calculating distance in kilometers
    rad_per_deg = Math::PI / 180
    rkm = 6371
    rm = rkm * 1000

    dlat_rad = (lat2 - lat1) * rad_per_deg
    dlng_rad = (lng2 - lng1) * rad_per_deg

    lat1_rad = lat1 * rad_per_deg
    lat2_rad = lat2 * rad_per_deg

    a = Math.sin(dlat_rad / 2)**2 + Math.cos(lat1_rad) * Math.cos(lat2_rad) * Math.sin(dlng_rad / 2)**2
    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))

    rkm * c
  end
end