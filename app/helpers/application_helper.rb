module ApplicationHelper
  def admin_user?
    @user&.admin?
  end

  def climb_in_progress?
    return unless @user.present?

    Climb.where(user: @user, current: true).exists?
  end

  def place
    @place ||= @user.place if @user.present?
  end

  def colour_dark?(hex_color)
    get_brightness(hex_color) < 0.5
  end

  private

  def hex_to_rgb(hex_color)
    hex_color = hex_color.gsub('#', '')
    hex_color.scan(/../).map { |component| component.to_i(16) }
  end

  def get_brightness(hex_color)
    rgb = hex_to_rgb(hex_color)
    
    brightness = (0.299 * rgb[0] + 0.587 * rgb[1] + 0.114 * rgb[2]) / 255

    brightness
  end
end
