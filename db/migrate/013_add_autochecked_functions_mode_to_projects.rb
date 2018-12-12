class AddAutocheckedFunctionsModeToProjects < ActiveRecord::Migration[4.2]
  def self.up
    add_column :projects, :autochecked_functions_mode, :string
  end

  def self.down
    remove_column :projects, :autochecked_functions_mode
  end
end
