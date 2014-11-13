class AddAuthorizedViewersToRoles < ActiveRecord::Migration
  def self.up
    add_column :roles, :authorized_viewers, :text
  end

  def self.down
    remove_column :roles, :authorized_viewers
  end
end
