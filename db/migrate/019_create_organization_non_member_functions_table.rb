class CreateOrganizationNonMemberFunctionsTable < ActiveRecord::Migration[4.2]

  def self.up
    create_table :organization_non_member_functions do |t|
      t.column :organization_id, :integer, :null => false
      t.column :project_id, :integer, :null => false
      t.column :function_id, :integer, :null => false
    end
    add_index :organization_non_member_functions, [:organization_id], :name => :index_org_non_member_functions_on_orga_id
    add_index :organization_non_member_functions, [:project_id], :name => :index_org_non_member_functions_on_project_id
    add_index :organization_non_member_functions, [:function_id], :name => :index_org_non_member_functions_on_function_id
    add_index :organization_non_member_functions, [:function_id, :project_id, :organization_id], unique: true, :name => :unicity_index_org_non_member_functions_on_function_and_project
  end

  def self.down
    drop_table :organization_non_member_functions
  end

end
