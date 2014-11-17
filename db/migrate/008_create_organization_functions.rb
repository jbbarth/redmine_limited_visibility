class CreateOrganizationFunctions < ActiveRecord::Migration
  def self.up
    create_table :organization_functions do |t|
      t.column :organization_id, :integer, :null => false
      t.column :project_id, :integer, :null => false
      t.column :function_id, :integer, :null => false
    end
    add_index :organization_functions, [:organization_id], :name => :index_org_functions_on_orga_id
    add_index :organization_functions, [:project_id], :name => :index_org_functions_on_project_id
    add_index :organization_functions, [:function_id], :name => :index_org_functions_on_function_id
    add_index :organization_functions, [:function_id, :project_id, :organization_id], unique: true, :name => :unicity_index_org_functions_on_function_and_project

    # init current organizations functions
    member_count = Member.count
    Member.all.each_with_index do |member, i|
      puts "#{i}/#{member_count}" if i % 250 == 0
      member.functions.each do |function|
        OrganizationFunction.create(:project_id => member.project_id, :organization_id => member.user.organization_id, :function_id => function.id) if member.user
      end
    end
  end

  def self.down
    drop_table :organization_functions
  end
end
