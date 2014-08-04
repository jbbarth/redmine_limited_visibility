require_dependency 'issue_query'

class IssueQuery < Query

  self.operators.merge!({ "mine" => :label_my_roles })
  self.operators_by_filter_type.merge!({ :list_visibility => ["mine", "*"] })
  self.available_columns << QueryColumn.new(:authorized_viewers, sortable: "#{Issue.table_name}.authorized_viewers", groupable: true)

  unless instance_methods.include?(:initialize_available_filters_with_authorized_viewers)
    def initialize_available_filters_with_authorized_viewers
      initialize_available_filters_without_authorized_viewers
      add_available_filter "authorized_viewers", type: :list_visibility, values: Role.visibility_roles.all.map { |s| [s.name, s.id.to_s] }
    end
    alias_method_chain :initialize_available_filters, :authorized_viewers
  end

  def sql_for_authorized_viewers_field(field, operator, value)
    case operator
    when "*" # display all roles
      sql = "" # no filter
    when "mine" # only my visibility roles
      sql = sql_conditions_for_roles_per_projects(field)
    # when "=", "!"
    #  sql = value.map { |role| "#{Issue.table_name}.#{field} #{operator == "!" ? 'NOT' : ''} LIKE '%|#{role}|%' " }.join(" OR ")
    else
      raise "unsupported value for authorized_viewers field: '#{operator}'"
    end
    sql
  end

  def sql_conditions_for_roles_per_projects(field)
    projects_by_role = User.current.projects_by_role
    sql = projects_by_role.map do |role, projects|
      projects.map do |project|
        "(#{Issue.table_name}.#{field} LIKE '%|#{role.id}|%' AND #{Project.table_name}.id = #{project.id}) "
      end.join(" OR ")
    end.join(" OR ")
    # potentially very long query #TODO Find a way to optimize it
    sql = "(#{sql.present? ? '(' + sql + ') OR ' : ''} #{Issue.table_name}.#{field} IS NULL OR #{Issue.table_name}.#{field} = '||' OR #{Issue.table_name}.#{field} = '' OR #{Issue.table_name}.assigned_to_id = #{User.current.id} OR #{Issue.table_name}.author_id = #{User.current.id})"
  end

  # use standard method to validate filters form,
  # but ignore "can't be blank" error on authorized_viewers filter because it doesn't require any value
  def validate_query_filters
    super
    m = label_for('authorized_viewers') + " " + l(:blank, scope: 'activerecord.errors.messages')
    errors.messages[:base] = errors.messages[:base] - [m] if errors.messages[:base].present? && errors.messages[:base].include?(m)
  end
end
