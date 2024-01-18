require_dependency 'issue_query'

module RedmineLimitedVisibility::Models
  module IssueQueryPatch

    def initialize_available_filters
      super

      if project.present?
        all_functions = project.functions.sorted.map { |s| [s.name, s.id.to_s] }
      else
        all_functions = Function.sorted.map { |s| [s.name, s.id.to_s] }
      end

      add_available_filter "authorized_viewers", type: :list_visibility, values: all_functions

      add_available_filter("assigned_to_member_with_function_id",
                           :type => :list_optional, :values => all_functions
      ) unless all_functions.empty?

      add_available_filter("assigned_to_function_id",
                           :type => :list_optional, :values => all_functions
      ) unless all_functions.empty?

      add_available_filter("has_been_visible_by_id",
                           :type => :list_optional, :values => all_functions
      ) unless all_functions.empty?

      assigned_to_values = @available_filters["assigned_to_id"][:values]
      add_available_filter("has_been_assigned_to_id",
                           :type => :list_optional, :values => assigned_to_values
      ) unless assigned_to_values.empty?

      add_available_filter("has_been_assigned_to_function_id",
                           :type => :list_optional, :values => all_functions
      ) unless all_functions.empty?
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

        issue_attr_sql = "(#{assigned_to_id_statement} #{Issue.table_name}.assigned_to_id #{boolean_switch} IN (" + value.collect { |val| val.include?('function') ? "null" : "'#{self.class.connection.quote_string(val)}'" }.join(",") + "))"

        values = value.collect { |val| "'#{self.class.connection.quote_string(val)}'" }.join(",")
        journal_condition1 = value.any? ? "#{JournalDetail.table_name}.value IN (" + values + ")" : "1=0"
        journal_condition2 = value.any? ? "#{JournalDetail.table_name}.old_value IN (" + values + ")" : "1=0"
        journal_sql = "#{boolean_switch} EXISTS (SELECT DISTINCT #{Journal.table_name}.journalized_id FROM #{Journal.table_name}, #{JournalDetail.table_name}" +
          " WHERE #{Issue.table_name}.id = #{Journal.table_name}.journalized_id AND #{Journal.table_name}.id = #{JournalDetail.table_name}.journal_id AND #{Journal.table_name}.journalized_type = 'Issue' AND #{JournalDetail.table_name}.prop_key = 'assigned_to_id'" +
          " AND (#{journal_condition1} OR #{journal_condition2}))"

        "((#{issue_attr_sql}) #{operator_switch} (#{journal_sql}))"
      end
    end

    def sql_for_assigned_to_function_id_field(field, operator, value)
      case operator
      when "*", "!*" # All / None
        boolean_switch = (operator == "!*" ? '' : 'NOT')
        "(#{Issue.table_name}.assigned_to_function_id IS #{boolean_switch} NULL)"
      when "=", "!"
        boolean_switch = operator == "!" ? 'NOT' : ''

        assigned_to_empty = "#{Issue.table_name}.assigned_to_function_id IS NULL"
        assigned_to_id_statement = operator == "!" ? "#{assigned_to_empty} OR" : ''

        issue_attr_sql = "(#{assigned_to_id_statement} #{Issue.table_name}.assigned_to_function_id #{boolean_switch} IN (" + value.collect { |val| val.include?('function') ? "null" : "'#{self.class.connection.quote_string(val)}'" }.join(",") + "))"

        "(#{issue_attr_sql})"
      end
    end

    def sql_for_assigned_to_member_with_function_id_field(field, operator, value)
      case operator
      when "*", "!*" # Member / Not member
        sw = operator == "!*" ? 'NOT' : ''
        nl = operator == "!*" ? "#{Issue.table_name}.assigned_to_id IS NULL OR" : ''
        "(#{nl} #{Issue.table_name}.assigned_to_id #{sw} IN (SELECT DISTINCT #{Member.table_name}.user_id FROM #{Member.table_name}" +
          " WHERE #{Member.table_name}.project_id = #{Issue.table_name}.project_id))"
      when "=", "!"
        function_cond = value.any? ?
                          "#{MemberFunction.table_name}.function_id IN (" + value.collect { |val| "'#{self.class.connection.quote_string(val)}'" }.join(",") + ")" :
                          "1=0"

        sw = operator == "!" ? 'NOT' : ''
        nl = operator == "!" ? "#{Issue.table_name}.assigned_to_id IS NULL OR" : ''
        "(#{nl} (#{Issue.table_name}.assigned_to_id, #{Issue.table_name}.project_id) #{sw} IN (SELECT DISTINCT #{Member.table_name}.user_id, #{Member.table_name}.project_id FROM #{Member.table_name}, #{MemberFunction.table_name}" +
          " WHERE #{Member.table_name}.id = #{MemberFunction.table_name}.member_id AND #{function_cond}))"
      end
    end

    def sql_for_has_been_assigned_to_function_id_field(field, operator, value)
      case operator
      when "*", "!*" # All / None
        boolean_switch = operator == "!*" ? 'NOT' : ''
        statement = operator == "!*" ? "#{Issue.table_name}.assigned_to_function_id IS NULL AND" : "(#{Issue.table_name}.assigned_to_function_id IS NOT NULL) OR"
        "(#{statement} #{boolean_switch} EXISTS (SELECT DISTINCT #{Journal.table_name}.journalized_id FROM #{Journal.table_name}, #{JournalDetail.table_name}" +
          " WHERE #{Issue.table_name}.id = #{Journal.table_name}.journalized_id AND #{Journal.table_name}.id = #{JournalDetail.table_name}.journal_id AND #{Journal.table_name}.journalized_type = 'Issue' AND #{JournalDetail.table_name}.prop_key = 'assigned_to_function_id'))"
      when "=", "!"
        boolean_switch = operator == "!" ? 'NOT' : ''
        operator_switch = operator == "!" ? 'AND' : 'OR'

        assigned_to_empty = "#{Issue.table_name}.assigned_to_function_id IS NULL"
        assigned_to_id_statement = operator == "!" ? "#{assigned_to_empty} OR" : ''

        issue_attr_sql = "(#{assigned_to_id_statement} #{Issue.table_name}.assigned_to_function_id #{boolean_switch} IN (" + value.collect { |val| val.include?('function') ? "null" : "'#{self.class.connection.quote_string(val)}'" }.join(",") + "))"

        values = value.collect { |val| "'#{self.class.connection.quote_string(val)}'" }.join(",")
        journal_condition1 = value.any? ? "#{JournalDetail.table_name}.value IN (" + values + ")" : "1=0"
        journal_condition2 = value.any? ? "#{JournalDetail.table_name}.old_value IN (" + values + ")" : "1=0"
        journal_sql = "#{boolean_switch} EXISTS (SELECT DISTINCT #{Journal.table_name}.journalized_id FROM #{Journal.table_name}, #{JournalDetail.table_name}" +
          " WHERE #{Issue.table_name}.id = #{Journal.table_name}.journalized_id AND #{Journal.table_name}.id = #{JournalDetail.table_name}.journal_id AND #{Journal.table_name}.journalized_type = 'Issue' AND #{JournalDetail.table_name}.prop_key = 'assigned_to_function_id'" +
          " AND (#{journal_condition1} OR #{journal_condition2}))"

        "((#{issue_attr_sql}) #{operator_switch} (#{journal_sql}))"
      end
    end

    def sql_for_has_been_visible_by_id_field(field, operator, value)
      case operator
      when "*", "!*" # All / None
        boolean_switch = operator == "!*" ? 'NOT' : ''
        statement = operator == "!*" ? "#{Issue.table_name}.authorized_viewers IS NULL AND" : "(#{Issue.table_name}.authorized_viewers IS NOT NULL) OR"
        "(#{statement} #{boolean_switch} EXISTS (SELECT DISTINCT #{Journal.table_name}.journalized_id FROM #{Journal.table_name}, #{JournalDetail.table_name}" +
          " WHERE #{Issue.table_name}.id = #{Journal.table_name}.journalized_id AND #{Journal.table_name}.id = #{JournalDetail.table_name}.journal_id AND #{Journal.table_name}.journalized_type = 'Issue' AND #{JournalDetail.table_name}.prop_key = 'authorized_viewers'))"
      when "=", "!"
        boolean_switch = operator == "!" ? 'NOT' : ''
        operator_switch = operator == "!" ? 'AND' : 'OR'

        has_no_specified_visibility = "#{Issue.table_name}.authorized_viewers IS NULL"
        visible_by_statement = operator == "!" ? "(#{has_no_specified_visibility}) OR" : ''

        issue_attr_sql, journal_condition1, journal_condition2 = ""
        values = value.collect { |val| self.class.connection.quote_string(val) }
        values.each_with_index do |function_id, index|
          if index > 0
            issue_attr_sql << " #{operator_switch} "
            journal_condition1 << " #{operator_switch} "
            journal_condition2 << " #{operator_switch} "
          end
          issue_attr_sql << "(#{visible_by_statement} #{Issue.table_name}.authorized_viewers #{boolean_switch} LIKE '%|#{function_id}|%' )"
          journal_condition1 = "#{JournalDetail.table_name}.value #{boolean_switch} LIKE '%|#{function_id}|%' "
          journal_condition2 = "#{JournalDetail.table_name}.old_value #{boolean_switch} LIKE '%|#{function_id}|%' "
        end
        journal_condition1 = "1=0" if journal_condition1.blank?
        journal_condition2 = "1=0" if journal_condition2.blank?
        journal_sql = "#{boolean_switch} EXISTS (SELECT DISTINCT #{Journal.table_name}.journalized_id FROM #{Journal.table_name}, #{JournalDetail.table_name}" +
          " WHERE #{Issue.table_name}.id = #{Journal.table_name}.journalized_id AND #{Journal.table_name}.id = #{JournalDetail.table_name}.journal_id AND #{Journal.table_name}.journalized_type = 'Issue' AND #{JournalDetail.table_name}.prop_key = 'authorized_viewers'" +
          " AND ((#{journal_condition1}) OR (#{journal_condition2})))"

        "((#{issue_attr_sql}) #{operator_switch} (#{journal_sql}))"
      end
    end

    def sql_for_authorized_viewers_field(field, operator, value)
      case operator
      when "*" # display all functional roles
        sql = "" # no filter
      when "mine" # only my functional roles
        sql = sql_conditions_for_functions_per_projects(field)
      when "=", "!"
        sql = value.map { |role| "#{Issue.table_name}.#{field} #{operator == "!" ? 'NOT' : ''} LIKE '%|#{role}|%' " }.join(operator == "!" ? " AND " : " OR ")
      else
        raise "unsupported value for authorized_viewers field: '#{operator}'"
      end
      sql.present? ? "(#{sql})" : ""
    end

    def sql_conditions_for_functions_per_projects(field)

      conditions = Rails.cache.fetch ['sql_conditions_for_functions_per_projects',
                                      User.current,
                                      Member.maximum(:id),
                                      MemberFunction.maximum(:id),
                                      Project.maximum(:updated_on),
                                      OrganizationNonMemberFunction.maximum(:id),
                                      (Time.now.strftime("%Y%m%d%H").to_i)].join('/') do

        projects_by_function = User.current.projects_by_function
        projects_without_functions_ids = User.current.projects_without_function.map(&:id)
        projects_ids_where_module_is_enabled = EnabledModule.where("name = ?", "limited_visibility").pluck(:project_id)

        sql_by_function = []
        projects_by_function.each do |function, projects|
          user_projects_ids = projects.map(&:id)
          user_projects_ids_where_module_is_enabled = user_projects_ids & projects_ids_where_module_is_enabled
          projects_without_functions_ids |= user_projects_ids - user_projects_ids_where_module_is_enabled

          if Redmine::Plugin.installed?(:redmine_multiprojects_issue)
            additional_statement = " OR #{Issue.table_name}.project_id IN ( SELECT project_id FROM issues_projects WHERE issue_id = #{Issue.table_name}.id AND project_id IN (#{user_projects_ids_where_module_is_enabled.join(',')}) )"
          end
          sql_by_function << " (#{Issue.table_name}.#{field} LIKE '%|#{function.id}|%' AND (#{Project.table_name}.id IN (#{user_projects_ids_where_module_is_enabled.join(',')}) #{additional_statement} )) " if user_projects_ids_where_module_is_enabled.present?
        end
        sql = sql_by_function.join(" OR ")

        # potentially very long query #TODO Find a way to optimize it
        "(#{sql.present? ? '(' + sql + ') OR ' : ''} #{Issue.table_name}.#{field} IS NULL"\
      " OR #{Issue.table_name}.#{field} = '||' "\
      " OR #{Issue.table_name}.#{field} = '' "\
      " OR #{Issue.table_name}.assigned_to_id = #{User.current.id} "\
      " OR #{Issue.table_name}.author_id = #{User.current.id} "\
      " OR #{Project.table_name}.id IN ( #{projects_without_functions_ids.present? ? projects_without_functions_ids.join(',') : 0} ) ) "
      end
      conditions
    end

  end
end

class IssueQuery < Query

  prepend RedmineLimitedVisibility::Models::IssueQueryPatch

  self.operators.merge!({ "mine" => :label_my_roles })
  self.operators_by_filter_type.merge!({ :list_visibility => ["mine", "*", "=", "!"] })
  self.available_columns << QueryColumn.new(:authorized_viewers, sortable: "#{Issue.table_name}.authorized_viewers", groupable: true) if self.available_columns.select { |c| c.name == :authorized_viewers }.empty?
  self.available_columns << QueryColumn.new(:has_been_assigned_to, :sortable => lambda { User.fields_for_order_statement }, :groupable => true) if self.available_columns.select { |c| c.name == :has_been_assigned_to }.empty?
  self.available_columns << QueryColumn.new(:has_been_visible_by, :sortable => false, :groupable => true) if self.available_columns.select { |c| c.name == :has_been_visible_by }.empty?

  # use standard method to validate filters form,
  # but ignore "can't be blank" error on authorized_viewers filter because it doesn't require any value
  def validate_query_filters
    super
    m = label_for('authorized_viewers') + " " + l(:blank, scope: 'activerecord.errors.messages')
    errors.messages[:base] = errors.messages[:base] - [m] if errors.messages[:base].present? && errors.messages[:base].include?(m)
  end
end
