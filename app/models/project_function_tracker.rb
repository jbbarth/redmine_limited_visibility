class ProjectFunctionTracker < ApplicationRecord
  include Redmine::SafeAttributes

  belongs_to :project_function
  belongs_to :tracker
  delegate :function, :to => :project_function, :allow_nil => true

  validates_uniqueness_of :project_function_id, scope: [:tracker_id]
  validates_presence_of :project_function, :tracker

  safe_attributes :tracker_id, :project_function_id, :visible, :checked
end
