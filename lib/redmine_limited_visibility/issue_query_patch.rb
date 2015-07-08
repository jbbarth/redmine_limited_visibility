require_dependency 'issue_query'

class IssueQuery < Query

  self.operators.merge!({ "mine" => :label_my_roles })
  self.operators_by_filter_type.merge!({ :list_visibility => ["mine", "*"] })
  self.available_columns << QueryColumn.new(:authorized_viewers, sortable: "#{Issue.table_name}.authorized_viewers", groupable: true) if self.available_columns.select { |c| c.name == :authorized_viewers }.empty?
  self.available_columns << QueryColumn.new(:has_been_assigned_to, :sortable => lambda {User.fields_for_order_statement}, :groupable => true) if self.available_columns.select { |c| c.name == :has_been_assigned_to }.empty?

  unless instance_methods.include?(:initialize_available_filters_with_authorized_viewers)
    def initialize_available_filters_with_authorized_viewers
      initialize_available_filters_without_authorized_viewers

      add_available_filter "authorized_viewers", type: :list_visibility, values: Function.all.map { |s| [s.name, s.id.to_s] }

      assigned_to_values = @available_filters["assigned_to_id"][:values]
      add_available_filter("has_been_assigned_to_id",
                           :type => :list_optional, :values => assigned_to_values
      ) unless assigned_to_values.empty?
    end
    alias_method_chain :initialize_available_filters, :authorized_viewers
  end

  def sql_for_has_been_assigned_to_id_field(field, operator, value)

    if value.delete('me')
      value.push User.current.id.to_s
    end

    case operator
      when "*", "!*" # All / None
        boolean_switch = operator == "!*" ? 'NOT' : ''
        statement = operator == "!*" ? "#{Issue.table_name}.assigned_to_id IS NULL AND" : "(#{Issue.table_name}.assigned_to_id IS NOT NULL) OR"
        "(#{statement} #{boolean_switch} EXISTS (SELECT DISTINCT #{Journal.table_name}.journalized_id FROM #{Journal.table_name}, #{JournalDetail.table_name}" +
            " WHERE #{Issue.table_name}.id = #{Journal.table_name}.journalized_id AND #{Journal.table_name}.id = #{JournalDetail.table_name}.journal_id AND #{Journal.table_name}.journalized_type = 'Issue' AND #{JournalDetail.table_name}.prop_key = 'assigned_to_id'))"
      when "=", "!"
        boolean_switch = operator == "!" ? 'NOT' : ''
        operator_switch = operator == "!" ? 'AND' : 'OR'

        assigned_to_empty = "#{Issue.table_name}.assigned_to_id IS NULL"
        assigned_to_id_statement = operator == "!" ? "#{assigned_to_empty} OR" : ''

        issue_attr_sql = "(#{assigned_to_id_statement} #{Issue.table_name}.assigned_to_id #{boolean_switch} IN (" + value.collect{|val| val.include?('function') ? "null" : "'#{self.class.connection.quote_string(val)}'"}.join(",") + "))"

        values = value.collect{|val| "'#{self.class.connection.quote_string(val)}'"}.join(",")
        journal_condition1 = value.any? ? "#{JournalDetail.table_name}.value IN (" + values + ")" : "1=0"
        journal_condition2 = value.any? ? "#{JournalDetail.table_name}.old_value IN (" + values + ")" : "1=0"
        journal_sql = "#{boolean_switch} EXISTS (SELECT DISTINCT #{Journal.table_name}.journalized_id FROM #{Journal.table_name}, #{JournalDetail.table_name}" +
            " WHERE #{Issue.table_name}.id = #{Journal.table_name}.journalized_id AND #{Journal.table_name}.id = #{JournalDetail.table_name}.journal_id AND #{Journal.table_name}.journalized_type = 'Issue' AND #{JournalDetail.table_name}.prop_key = 'assigned_to_id'" +
            " AND (#{journal_condition1} OR #{journal_condition2}))"

        "((#{issue_attr_sql}) #{operator_switch} (#{journal_sql}))"
    end
  end

  def sql_for_authorized_viewers_field(field, operator, value)
    case operator
    when "*" # display all functional roles
      sql = "" # no filter
    when "mine" # only my functional roles
      sql = sql_conditions_for_functions_per_projects(field)
    # when "=", "!"
    #  sql = value.map { |role| "#{Issue.table_name}.#{field} #{operator == "!" ? 'NOT' : ''} LIKE '%|#{role}|%' " }.join(" OR ")
    else
      raise "unsupported value for authorized_viewers field: '#{operator}'"
    end
    sql
  end

  def sql_conditions_for_functions_per_projects(field)
    projects_by_function = User.current.projects_by_function
    projects_without_functions = User.current.projects_without_function
    projects_ids_where_module_is_enabled = EnabledModule.where("name = ?", "limited_visibility").pluck(:project_id)

    sql = projects_by_function.map do |function, projects|
      projects.map do |project|
        if projects_ids_where_module_is_enabled.include?(project.id)
          if Redmine::Plugin.installed?(:redmine_multiprojects_issue)
            "(#{Issue.table_name}.#{field} LIKE '%|#{function.id}|%' AND (#{Project.table_name}.id = #{project.id} OR #{project.id} IN ( SELECT project_id FROM issues_projects WHERE issue_id = #{Issue.table_name}.id )) )"
          else
            "(#{Issue.table_name}.#{field} LIKE '%|#{function.id}|%' AND #{Project.table_name}.id = #{project.id}) "
          end
        else
          projects_without_functions << project
          " false "
        end
      end.join(" OR ")
    end.join(" OR ")

    # potentially very long query #TODO Find a way to optimize it
    "(#{sql.present? ? '(' + sql + ') OR ' : ''} #{Issue.table_name}.#{field} IS NULL"\
    " OR #{Issue.table_name}.#{field} = '||' "\
    " OR #{Issue.table_name}.#{field} = '' "\
    " OR #{Issue.table_name}.assigned_to_id = #{User.current.id} "\
    " OR #{Issue.table_name}.author_id = #{User.current.id} "\
    " OR #{Project.table_name}.id IN ( #{projects_without_functions.present? ? projects_without_functions.map(&:id).join(',') : 0} ) ) "
  end

  # use standard method to validate filters form,
  # but ignore "can't be blank" error on authorized_viewers filter because it doesn't require any value
  def validate_query_filters
    super
    m = label_for('authorized_viewers') + " " + l(:blank, scope: 'activerecord.errors.messages')
    errors.messages[:base] = errors.messages[:base] - [m] if errors.messages[:base].present? && errors.messages[:base].include?(m)
  end
end
