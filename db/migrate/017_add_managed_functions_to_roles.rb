class AddManagedFunctionsToRoles < ActiveRecord::Migration[4.2]
  def change
    add_column :roles, :functions_managed, :boolean, :default => true, :null => false
    add_column :roles, :all_functions_managed, :boolean, :default => true, :null => false

    create_table "roles_managed_functions", id: false, force: :cascade do |t|
      t.integer "role_id",         null: false
      t.integer "managed_function_id", null: false
    end

    add_index "roles_managed_functions", ["role_id", "managed_function_id"], name: "index_roles_managed_functions", unique: true, using: :btree

  end
end
