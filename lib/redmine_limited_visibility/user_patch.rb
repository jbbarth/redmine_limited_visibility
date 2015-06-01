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

    members.reject! {|member| member.user_id != id && project_ids.include?(member.project_id)}
    members.each do |member|
      if member.project
        member.functions.each do |function|
          hash[function] = [] unless hash.key?(function)
          hash[function] << member.project
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

    members.reject! {|member| member.user_id != id && project_ids.include?(member.project_id)}
    members.each do |member|
      if member.functions.blank?
        @projects_without_function << member.project
      end
    end

    @projects_without_function.uniq!

    return @projects_without_function
  end

end
