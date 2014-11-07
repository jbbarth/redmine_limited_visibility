class Function < ActiveRecord::Base
  unloadable

  attr_accessible :name, :position, :authorized_viewers

  validates_presence_of :name

  scope :sorted, lambda { order("#{table_name}.position ASC") }

end
