class ProjectFunction < ActiveRecord::Base
  belongs_to :project
  belongs_to :function

  validates_uniqueness_of :project_id, scope: [:function_id]
  validates_presence_of :project, :function
end
