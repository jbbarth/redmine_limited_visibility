class RemoveLimitVisibilityFromRoles < ActiveRecord::Migration
  def self.up
    remove_column :roles, :limit_visibility
    remove_column :roles, :authorized_viewers
  end

  def self.down
    add_column :roles, :limit_visibility, :boolean
    add_column :roles, :authorized_viewers, :text
  end
end
