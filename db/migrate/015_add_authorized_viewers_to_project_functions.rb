class AddAuthorizedViewersToProjectFunctions < ActiveRecord::Migration[4.2]
  def self.up
    add_column :project_functions, :authorized_viewers, :text
  end

  def self.down
    remove_column :project_functions, :authorized_viewers
  end
end
