class AddSeeAllIssuesToFunctions < ActiveRecord::Migration[4.2]
  def self.up
    add_column :functions, :see_all_issues, :boolean, :default => false
  end

  def self.down
    remove_column :functions, :see_all_issues
  end
end
