require_dependency 'member'

class Member < ActiveRecord::Base

  has_many :member_functions, :dependent => :destroy
  has_many :functions, :through => :member_functions

  # Creates memberships for principal with the attributes
  # * project_ids : one or more project ids
  # * role_ids : ids of the roles to give to each membership
  # * function_ids : ids of the functional roles to give to each membership
  #
  # Example:
  #   Member.create_principal_memberships(user, :project_ids => [2, 5], :role_ids => [1, 3], :function_ids => [5, 6])
  def self.create_principal_memberships(principal, attributes)
    members = []
    if attributes
      project_ids = Array.wrap(attributes[:project_ids] || attributes[:project_id])
      role_ids = []
      role_ids |= attributes[:role_ids] if attributes[:role_ids]
      function_ids = []
      function_ids |= attributes[:function_ids] if attributes[:function_ids]
      project_ids.each do |project_id|
        if Redmine::Plugin.installed?(:redmine_organizations)
          role_ids_by_project = role_ids | OrganizationRole.where(organization_id: principal.organization_id, project_id: project_id).all.collect{|r| r.role_id}
        end
        if Redmine::Plugin.installed?(:redmine_limited_visibility)
          function_ids_by_project = function_ids | OrganizationFunction.where(organization_id: principal.organization_id, project_id: project_id).all.collect{|f| f.function_id}
          project = Project.find(project_id)
          function_ids_by_project.each do |function_id|
            if project.functions.present? && !project.functions.map(&:id).include?(function_id.to_i)
              function_ids_by_project.reject! { |id| id == function_id }
            end
          end
        end
        members << Member.new(:principal => principal, :role_ids => role_ids_by_project, :function_ids => function_ids_by_project, :project_id => project_id)
      end
      principal.members << members
    end
    members
  end
end
