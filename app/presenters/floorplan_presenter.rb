class FloorplanPresenter
  attr_reader :floorplan, :user

  def initialize(floorplan, user = nil)
    @floorplan = floorplan
    @user = user
  end

  def present
    {
      id: floorplan.id,
      name: floorplan.name,
      data: floorplan.data,
      images_count: floorplan.images.count,
      created_at: floorplan.created_at,
      updated_at: floorplan.updated_at
    }
  end

  def present_detail
    present.merge(
      place: {
        id: floorplan.place.id,
        name: floorplan.place.name
      },
      images: floorplan.images.map do |image|
        {
          id: image.id,
          url: Rails.application.routes.url_helpers.rails_blob_url(image, only_path: true),
          filename: image.filename.to_s,
          content_type: image.content_type,
          byte_size: image.byte_size,
          created_at: image.created_at
        }
      end,
      can_edit: user&.admin || floorplan.place.can_edit?(user)
    )
  end
end