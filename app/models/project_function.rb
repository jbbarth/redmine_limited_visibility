class ProjectFunction < ActiveRecord::Base
  include Redmine::SafeAttributes

  belongs_to :project
  belongs_to :function

  has_many :project_function_trackers

  validates_uniqueness_of :project_id, scope: [:function_id]
  validates_presence_of :project, :function

  safe_attributes :function_id, :project_id, :authorized_viewers

  def authorized_viewer_ids
    "#{authorized_viewers}".split("|").reject(&:blank?).map(&:to_i)
  end
end
