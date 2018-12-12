class AddAuthorizedViewersToIssues < ActiveRecord::Migration[4.2]
  def self.up
    add_column :issues, :authorized_viewers, :text
  end

  def self.down
    remove_column :issues, :authorized_viewers
  end
end
