class AddAutocheckedFunctionsModeToProjects < ActiveRecord::Migration
  def self.up
    add_column :projects, :autochecked_functions_mode, :string
  end

  def self.down
    remove_column :projects, :autochecked_functions_mode
  end
end
