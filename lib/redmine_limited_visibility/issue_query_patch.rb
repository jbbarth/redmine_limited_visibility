require_dependency 'issue_query'

class IssueQuery < Query
  alias_method :plugin_limited_visibility_core_initialize_available_filters, :initialize_available_filters

  self.operators.merge!({ "mine" => :label_my_roles })
  self.operators_by_filter_type.merge!({ :list_visibility => ["mine", "*"] })
  self.available_columns << QueryColumn.new(:authorized_viewers, sortable: "#{Issue.table_name}.authorized_viewers", groupable: true)

  def initialize_available_filters
    plugin_limited_visibility_core_initialize_available_filters
    add_available_filter "authorized_viewers", type: :list_visibility, values: Role.find_all_visibility_roles.map { |s| [s.name, s.id.to_s] }
  end

  def sql_for_authorized_viewers_field(field, operator, value)
    case operator
    when "*" # display all roles
      sql = "" # no filter
    when "mine" # only my visibility roles
      if Redmine::Plugin.installed?(:redmine_organizations)
        conditions = []
        User.current.organization_involvements.each do |involvement|

          if involvement.organization_membership.present? && involvement.organization_membership.project.present?
            visibility_roles_by_orga = involvement.organization_membership.roles.find_all_visibility_roles
            if visibility_roles_by_orga.present?
              visibility_roles_by_orga.each do |role|
                conditions << "(#{Issue.table_name}.#{field} LIKE '%|#{role.id}|%' AND #{Project.table_name}.id = #{involvement.organization_membership.project.id}) "
              end
            else
              conditions << "(#{Project.table_name}.id = #{involvement.organization_membership.project.id}) "
            end
          end
        end
        sql = conditions.join(" OR ")
      else
        projects_by_role = User.current.projects_by_role
        sql = projects_by_role.map do |role, projects|
          projects.map do |project|
            "(#{Issue.table_name}.#{field} LIKE '%|#{role.id}|%' AND #{Project.table_name}.id = #{project.id}) "
          end.join(" OR ")
        end.join(" OR ")
      end
      sql = "(#{sql.present? ? '(' + sql + ') OR ' : ''} #{Issue.table_name}.#{field} IS NULL OR #{Issue.table_name}.#{field} = '||' OR #{Issue.table_name}.#{field} = '')"
      # potentially very long query #TODO Find a way to optimize it
    # when "=", "!"
    #  sql = value.map { |role| "#{Issue.table_name}.#{field} #{operator == "!" ? 'NOT' : ''} LIKE '%|#{role}|%' " }.join(" OR ")
    else
      raise "unsupported value for authorized_viewers field: '#{operator}'"
    end
    sql
  end

  # use standard method to validate filters form,
  # but ignore "can't be blank" error on authorized_viewers filter because it doesn't require any value
  def validate_query_filters
    super
    m = label_for('authorized_viewers') + " " + l(:blank, scope: 'activerecord.errors.messages')
    errors.messages[:base] = errors.messages[:base] - [m] if errors.messages[:base].present? && errors.messages[:base].include?(m)
  end
end
