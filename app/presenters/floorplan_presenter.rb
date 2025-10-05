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
      images: floorplan.floorplan_images.order(:order).map do |floorplan_image|
        {
          id: floorplan_image.id,
          url: floorplan_image.image.attached? ? floorplan_image.image.url : nil,
          name: floorplan_image.name,
          order: floorplan_image.order,
          created_at: floorplan_image.created_at
        }
      end,
      can_edit: user&.admin || floorplan.place.can_edit?(user)
    )
  end
end