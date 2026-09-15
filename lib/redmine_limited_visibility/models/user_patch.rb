require_dependency 'user'

module RedmineLimitedVisibility::Models
  module UserPatch

    # Returns a hash of the ids of the user's projects grouped by function id
    def project_ids_by_function
      load_project_ids_by_function unless @project_ids_by_function
      @project_ids_by_function
    end

    # Returns the ids of the user's projects where a membership has no function
    def project_ids_without_function
      load_project_ids_by_function unless @project_ids_without_function
      @project_ids_without_function
    end

    def reload(*)
      @project_ids_by_function = nil
      @project_ids_without_function = nil
      super
    end

    # Returns the functions that the user is allowed to manage for the given project
    def managed_functions(project)
      if admin?
        @managed_functions ||= Function.available_functions_for(project)
      else
        membership(project).try(:managed_functions) || []
      end
    end

    # Return user's functions for project
    def functions_for_project(project)
      # No function on archived projects
      return [] if project.nil? || project.archived?
      if membership = membership(project)
        membership.functions.to_a
      else
        []
      end
    end

    private

    # Memberships of the user, and of the builtin group on public projects where
    # the user is not a member, like User#project_ids_by_role
    def load_project_ids_by_function
      group_ids = (anonymous? ? GroupAnonymous : GroupNonMember).unscoped.pluck(:id)
      rows = Member.joins(:project)
                   .joins("LEFT OUTER JOIN #{MemberFunction.table_name} ON #{MemberFunction.table_name}.member_id = #{Member.table_name}.id")
                   .joins("LEFT OUTER JOIN #{Function.table_name} ON #{Function.table_name}.id = #{MemberFunction.table_name}.function_id")
                   .where.not(Project.table_name => { status: Project::STATUS_ARCHIVED })
                   .where("#{Member.table_name}.user_id = ? OR (#{Project.table_name}.is_public = ? AND #{Member.table_name}.user_id IN (?))", id, true, group_ids)
                   .pluck("#{Member.table_name}.id", "#{Member.table_name}.user_id", "#{Member.table_name}.project_id", "#{Function.table_name}.id")

      own_project_ids = project_ids.to_set
      rows.reject! { |_, user_id, project_id, _| user_id != id && own_project_ids.include?(project_id) }

      by_function = Hash.new { |hash, function_id| hash[function_id] = [] }
      without_function = []
      rows.group_by(&:first).each_value do |member_rows|
        project_id = member_rows.first[2]
        function_ids = member_rows.filter_map(&:last)
        without_function << project_id if function_ids.empty?
        function_ids.each { |function_id| by_function[function_id] << project_id }
      end

      if Redmine::Plugin.installed?(:redmine_organizations) && organization
        OrganizationNonMemberFunction.joins(:project).left_joins(:function)
                                     .where(organization_id: organization.self_and_ancestors_ids)
                                     .pluck("#{Function.table_name}.id", "#{Project.table_name}.lft", "#{Project.table_name}.rgt")
                                     .each do |function_id, lft, rgt|
          subproject_ids = Project.where("#{Project.table_name}.lft >= ? AND #{Project.table_name}.rgt <= ?", lft, rgt).ids
          by_function[function_id] |= subproject_ids if function_id
          without_function -= subproject_ids
        end
      end

      @project_ids_by_function = by_function.transform_values(&:uniq)
      @project_ids_without_function = without_function.uniq
    end

  end
end

class User < Principal

  prepend RedmineLimitedVisibility::Models::UserPatch

end
