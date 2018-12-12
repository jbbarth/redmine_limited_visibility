class AddAuthorizedViewersToRoles < ActiveRecord::Migration[4.2]
  def self.up
    add_column :roles, :authorized_viewers, :text
  end

  def self.down
    remove_column :roles, :authorized_viewers
  end
end
