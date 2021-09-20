class Climb < ApplicationRecord
  def emoji
    case climber
    when "harry"
      "🧔🏻"
    when "rachel"
      "👩🏻‍🦰"
    when "ryan"
      "👨🏼"
    when "joel"
      "👨🏻"
    else
      climber
    end
  end
end
