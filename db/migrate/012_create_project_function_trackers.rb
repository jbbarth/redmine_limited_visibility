class CreateProjectFunctionTrackers < ActiveRecord::Migration
  def self.up
    drop_table :project_function_trackers if ActiveRecord::Base.connection.table_exists? 'project_function_trackers'
    create_table "project_function_trackers", :force => true do |t|
      t.integer "project_function_id", :null => false
      t.integer "tracker_id", :null => false
      t.boolean "visible"
      t.boolean "checked"
    end unless ActiveRecord::Base.connection.table_exists? 'project_function_trackers'

    add_index "project_function_trackers", ["project_function_id"], :name => "index_project_function_trackers_on_project_function_id" unless index_exists?(:project_function_trackers, [:project_function_id], :name => "index_project_function_trackers_on_project_function_id")
    add_index "project_function_trackers", ["tracker_id"], :name => "index_project_function_trackers_on_tracker_id" unless index_exists?(:project_function_trackers, [:tracker_id], :name => "index_project_function_trackers_on_tracker_id")
  end

  def self.down
    drop_table :project_function_trackers
    remove_index :project_function_trackers, :project_function_id
    remove_index :project_function_trackers, :tracker_id
  end
end
