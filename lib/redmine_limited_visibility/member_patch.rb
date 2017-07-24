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
      role_ids |= Array.wrap(attributes[:role_ids]).map(&:to_i) if attributes[:role_ids]
      function_ids = []
      function_ids_by_project = []
      function_ids |= Array.wrap(attributes[:function_ids]).map(&:to_i) if attributes[:function_ids]
      project_ids.each do |project_id|
        if Redmine::Plugin.installed?(:redmine_organizations)
          # Member must have the selected role AND the role given by his/her organization
          all_roles_ids = Role.all.collect(&:id)
          role_ids_by_project = role_ids | OrganizationRole.where(organization_id: principal.organization_id, project_id: project_id).all.map{|r| all_roles_ids.include?(r.role_id) ? r.role_id : nil}
        else
          role_ids_by_project = role_ids
        end
        if Redmine::Plugin.installed?(:redmine_limited_visibility)
          all_functions_ids = Function.all.collect(&:id)
          function_ids_by_project = function_ids | OrganizationFunction.where(organization_id: principal.organization_id, project_id: project_id).all.map{|f| all_functions_ids.include?(f.function_id) ? f.function_id : nil}
          project = Project.where('id = ?', project_id).first
          function_ids_by_project.each do |function_id|
            if project.functions.present? && !project.functions.map(&:id).include?(function_id.to_i)
              function_ids_by_project.reject! { |id| id == function_id }
            end
          end if project.present?
        end
        member = Member.find_or_new(project_id, principal)
        member.role_ids |= role_ids_by_project
        member.function_ids |= function_ids_by_project
        member.save
        members << member
      end
      principal.members << members
    end
    members
  end

end
