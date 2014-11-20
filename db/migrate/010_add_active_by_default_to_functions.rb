class AddActiveByDefaultToFunctions < ActiveRecord::Migration
  def self.up
    add_column :functions, :active_by_default, :boolean, :default => true
  end

  def self.down
    remove_column :functions, :active_by_default
  end
end
