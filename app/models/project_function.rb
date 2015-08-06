class ProjectFunction < ActiveRecord::Base
  belongs_to :project
  belongs_to :function

  has_many :project_function_trackers

  validates_uniqueness_of :project_id, scope: [:function_id]
  validates_presence_of :project, :function

  attr_accessible :function_id
end
