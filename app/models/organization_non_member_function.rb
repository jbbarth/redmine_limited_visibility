class OrganizationNonMemberFunction < ApplicationRecord
  include Redmine::SafeAttributes

  belongs_to :project
  belongs_to :organization
  belongs_to :function

  validates_uniqueness_of :function_id, scope: [:project_id, :organization_id]
  validates_presence_of :function_id, :project_id, :organization_id

  safe_attributes :function_id, :project_id, :organization_id

  scope :for_project, ->(project) { where("organization_non_member_functions.project_id IN (?)", project.self_and_ancestors.ids) if project.present? }

end
