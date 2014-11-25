require_dependency 'user'

class User < Principal

  # Returns a hash of user's projects grouped by functions
  def projects_by_function
    return @projects_by_function if @projects_by_function

    hash = Hash.new([])

    members = Member.joins(:project).
        where("#{Project.table_name}.status <> 9").
        where("#{Member.table_name}.user_id = ? OR (#{Project.table_name}.is_public = ? AND #{Member.table_name}.user_id = ?)", self.id, true, Group.builtin_id(self)).
        preload(:project, :functions)

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

end
