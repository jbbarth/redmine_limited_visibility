require_dependency 'member'

module RedmineLimitedVisibility::Models::MemberPatch

  # Returns true if the member's function is editable by user
  def function_editable?(function, user = User.current)
    user.managed_functions(project).include?(function)
  end

end

class Member < ActiveRecord::Base

  prepend RedmineLimitedVisibility::Models::MemberPatch

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
          role_ids_by_project = role_ids | OrganizationRole.where(organization_id: principal.organization_id, project_id: project_id).all.map { |r| all_roles_ids.include?(r.role_id) ? r.role_id : nil }
        else
          role_ids_by_project = role_ids
        end
        if Redmine::Plugin.installed?(:redmine_limited_visibility)
          all_functions_ids = Function.all.collect(&:id)
          function_ids_by_project = function_ids
          function_ids_by_project |= OrganizationFunction.where(organization_id: principal.organization_id, project_id: project_id).all.map { |f| all_functions_ids.include?(f.function_id) ? f.function_id : nil } if Redmine::Plugin.installed?(:redmine_organizations)
          project = Project.where('id = ?', project_id).first
          function_ids_by_project.each do |function_id|
            if project.functions.present? && !project.functions.map(&:id).include?(function_id.to_i)
              function_ids_by_project.reject! { |id| id == function_id }
            end
          end if project.present?
        end
        member = Member.find_or_initialize_by(project_id: project_id, user_id: principal.id)
        member.role_ids |= role_ids_by_project
        member.function_ids |= function_ids_by_project
        member.save
        members << member
      end
      principal.members << members
    end
    members
  end

  def function_ids=(arg)
    ids = (arg || []).collect(&:to_i) - [0]
    new_function_ids = ids - function_ids
    # Add new functions
    new_function_ids.each { |id| member_functions << MemberFunction.new(:function_id => id, :member => self) }
    # Remove functions (Rails' #function_ids= will not trigger MemberFunction#on_destroy)
    member_functions_to_destroy = member_functions.select { |mr| !ids.include?(mr.function_id) }
    if member_functions_to_destroy.any?
      member_functions_to_destroy.each(&:destroy)
    end
  end

  def set_functional_roles(ids)
    ids = (ids || []).collect(&:to_i) - [0]
    if Redmine::Plugin.installed?(:redmine_organizations) && self.principal && principal.is_a?(User) && self.principal.organization
      organization_function_ids = self.principal.organization.default_functions_by_project(self.project).map(&:id)
      self.function_ids = ids | organization_function_ids
    else
      self.function_ids = ids
    end
  end

  # Returns the functions that the member is allowed to manage
  # in the project the member belongs to
  def managed_functions
    all_available_functions = Function.available_functions_for(project)
    @managed_functions ||= begin
                             if principal.try(:admin?)
                               all_available_functions
                             else
                               members_management_roles = roles.select do |role|
                                 role.has_permission?(:manage_members)
                               end
                               if members_management_roles.empty?
                                 []
                               elsif members_management_roles.any?(&:functions_managed?) == false
                                 []
                               elsif members_management_roles.any?(&:all_functions_managed?)
                                 all_available_functions
                               else
                                 all_available_functions & members_management_roles.map(&:managed_functions).reduce(&:|)
                               end
                             end
                           end
  end

end
