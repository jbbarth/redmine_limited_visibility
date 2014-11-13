class CreateMemberFunctions < ActiveRecord::Migration
  def self.up
    create_table "member_functions", :force => true do |t|
      t.integer "member_id", :null => false
      t.integer "function_id", :null => false
      t.integer "inherited_from"
    end

    add_index "member_functions", ["member_id"], :name => "index_member_functions_on_member_id"
    add_index "member_functions", ["function_id"], :name => "index_member_functions_on_function_id"
  end

  def self.down
    drop_table :member_functions
    remove_index :member_functions, :member_id
    remove_index :member_functions, :function_id
  end
end


