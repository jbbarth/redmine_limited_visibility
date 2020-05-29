class AddAssignedToFunctionIdToIssues < ActiveRecord::Migration[4.2]
  def self.up
    add_column :issues, :assigned_to_function_id, :integer
    add_index "issues", ["assigned_to_function_id"], :name => "index_issues_on_assigned_to_function_id"
  end

  def self.down
    remove_column :issues, :assigned_to_function_id
  end
end
