class AddDescriptionToFunctions < ActiveRecord::Migration[5.2]
  def change
    add_column :functions, :description, :text
  end
end
