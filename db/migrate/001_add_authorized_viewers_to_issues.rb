class AddAuthorizedViewersToIssues < ActiveRecord::Migration
  def self.up
    add_column :issues, :authorized_viewers, :text
  end

  def self.down
    remove_column :issues, :authorized_viewers
  end
end
