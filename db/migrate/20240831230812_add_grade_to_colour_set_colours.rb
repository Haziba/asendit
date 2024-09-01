class AddGradeToColourSetColours < ActiveRecord::Migration[7.1]
  def change
    add_column :route_set_colour_set_colours, :grade, :string
  end
end