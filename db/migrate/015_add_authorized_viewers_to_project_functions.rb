class AddAuthorizedViewersToProjectFunctions < ActiveRecord::Migration
  def self.up
    add_column :project_functions, :authorized_viewers, :text
  end

  def self.down
    remove_column :project_functions, :authorized_viewers
  end
end
