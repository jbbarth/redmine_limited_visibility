class AddLimitVisibilityToRoles < ActiveRecord::Migration[4.2]
  def self.up
    add_column :roles, :limit_visibility, :boolean
  end

  def self.down
    remove_column :roles, :limit_visibility
  end
end
