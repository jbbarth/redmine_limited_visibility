class AddSeeAllIssuesToFunctions < ActiveRecord::Migration
  def self.up
    add_column :functions, :see_all_issues, :boolean, :default => false
  end

  def self.down
    remove_column :functions, :see_all_issues
  end
end
