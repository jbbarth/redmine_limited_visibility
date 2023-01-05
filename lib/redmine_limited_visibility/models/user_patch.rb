require_dependency 'user'

class User < Principal

  # Returns a hash of user's projects grouped by functions
  def projects_by_function
    return @projects_by_function if @projects_by_function

    hash = Hash.new([])

    group_class = anonymous? ? GroupAnonymous : GroupNonMember
    members = Member.joins(:project, :principal).
      where("#{Project.table_name}.status <> 9").
      where("#{Member.table_name}.user_id = ? OR (#{Project.table_name}.is_public = ? AND #{Principal.table_name}.type = ?)", self.id, true, group_class.name).
      preload(:project, :functions).
      to_a

    members.reject! { |member| member.user_id != id && project_ids.include?(member.project_id) }
    members.each do |member|
      if member.project
        member.functions.each do |function|
          hash[function] = [] unless hash.key?(function)
          hash[function] << member.project
        end
      end
    end

    # Organization Non Member Exceptions
    if Redmine::Plugin.installed?(:redmine_organizations)
      if self.organization
        functions = Function.distinct.joins(:organization_non_member_functions)
                            .where("organization_non_member_functions.organization_id IN (?)", self.organization.self_and_ancestors_ids)
        functions.each do |function|
          hash[function] ||= []
          projects = Project.joins(:organization_non_member_functions)
                            .where("organization_non_member_functions.organization_id IN (?)", self.organization.self_and_ancestors_ids)
                            .where("organization_non_member_functions.function_id = ?", function.id)
          hash[function] |= projects.map(&:self_and_descendants).flatten
        end
      end
    end

    hash.each do |function, projects|
      projects.uniq!
    end

    @projects_by_function = hash
  end

  def projects_without_function
    return @projects_without_function if @projects_without_function

    @projects_without_function = []

    group_class = anonymous? ? GroupAnonymous : GroupNonMember
    members = Member.joins(:project, :principal).
      where("#{Project.table_name}.status <> 9").
      where("#{Member.table_name}.user_id = ? OR (#{Project.table_name}.is_public = ? AND #{Principal.table_name}.type = ?)", self.id, true, group_class.name).
      preload(:project, :functions).
      to_a

    members.reject! { |member| member.user_id != id && project_ids.include?(member.project_id) }
    members.each do |member|
      if member.functions.blank?
        @projects_without_function << member.project
      end
    end

    # Organization Non Member Exceptions
    if Redmine::Plugin.installed?(:redmine_organizations)
      if self.organization
        @projects_without_function -= Project.joins(:organization_non_member_functions)
                                             .where("organization_non_member_functions.organization_id IN (?)", self.organization.self_and_ancestors_ids)
                                             .map(&:self_and_descendants).flatten
      end
    end

    @projects_without_function.reject(&:blank?).uniq
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

end
