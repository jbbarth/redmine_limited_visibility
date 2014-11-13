class CreateFunctionsTable < ActiveRecord::Migration
  def self.up
    create_table :functions, :force => true do |t|
      t.column :name, :string, :limit => 30, :default => "", :null => false
      t.column :position, :integer, :default => 1, :null => true
      t.column :authorized_viewers, :text, :null => true
    end
  end

  def self.down
    drop_table :functions
  end
end
