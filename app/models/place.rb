# == Schema Information
#
# Table name: places
#
#  id         :bigint           not null, primary key
#  latitude   :decimal(10, 6)   not null
#  longitude  :decimal(10, 6)   not null
#  name       :text
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint
#
# Indexes
#
#  index_places_on_latitude_and_longitude  (latitude,longitude)
#  index_places_on_user_id                 (user_id)
#
class Place < ApplicationRecord
  has_many :route_sets, dependent: :destroy
  has_many :tournaments, dependent: :destroy
  has_many :grades, dependent: :destroy
  has_many :climbs, dependent: :destroy
  has_many :floorplans, dependent: :destroy
  belongs_to :user

  validates :name, presence: true, length: { minimum: 4 }
  validates :latitude, presence: true
  validates :longitude, presence: true
  validates :latitude, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }
  validates :longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }

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
