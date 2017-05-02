class AuthorizeLongerNames < ActiveRecord::Migration
  def up
    change_column :functions, :name, :string, :limit => 40, :default => "", :null => false
  end
  def down
    change_column :functions, :name, :string, :limit => 30, :default => "", :null => false
  end
end
