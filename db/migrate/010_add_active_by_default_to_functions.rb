class AddActiveByDefaultToFunctions < ActiveRecord::Migration[4.2]
  def self.up
    add_column :functions, :active_by_default, :boolean, :default => true
  end

  def self.down
    remove_column :functions, :active_by_default
  end
end
