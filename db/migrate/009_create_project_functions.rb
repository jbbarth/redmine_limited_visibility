class CreateProjectFunctions < ActiveRecord::Migration
  def self.up
    drop :project_functions if ActiveRecord::Base.connection.table_exists? 'project_functions'
    create_table "project_functions", :force => true do |t|
      t.integer "project_id", :null => false
      t.integer "function_id", :null => false
    end unless ActiveRecord::Base.connection.table_exists? 'project_functions'

    add_index "project_functions", ["project_id"], :name => "index_project_functions_on_project_id" unless index_exists?(:project_functions, [:project_id], :name => "index_project_functions_on_project_id")
    add_index "project_functions", ["function_id"], :name => "index_project_functions_on_function_id" unless index_exists?(:project_functions, [:function_id], :name => "index_project_functions_on_function_id")
  end

  def self.down
    drop_table :project_functions
    remove_index :project_functions, :project_id
    remove_index :project_functions, :function_id
  end
end
