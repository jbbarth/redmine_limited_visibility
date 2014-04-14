require_dependency 'issue_query'

class IssueQuery < Query

  alias_method :core_initialize, :initialize
  alias_method :core_initialize_available_filters, :initialize_available_filters

  self.operators.merge!({"mine" => :label_my_roles})
  self.operators_by_filter_type.merge!({:list_visibility => [ "mine", "*" ]})
  self.available_columns << QueryColumn.new(:authorized_viewers, :sortable => "#{Issue.table_name}.authorized_viewers", :groupable => true)

  def initialize(attributes=nil, *args)
    core_initialize(attributes, args)
    self.filters.merge!({ 'authorized_viewers' => {:operator => "*", :values => [""]} })
  end

  def initialize_available_filters
    core_initialize_available_filters
    add_available_filter "authorized_viewers", :type => :list_visibility, :values => Role.find_all_visibility_roles.collect{|s| [s.name, s.id.to_s] }
  end

  def sql_for_authorized_viewers_field(field, operator, value)
    case operator
      when "*" # display all roles
        sql = "" # no filter
      when "mine" # only my visibility roles
        projects_by_role = User.current.projects_by_role
        sql = projects_by_role.map do |role, projects|
          projects.map do |project|
            "(#{Issue.table_name}.#{field} LIKE '%|#{role.id}|%' AND #{Project.table_name}.id = #{project.id}) "
          end.join(" OR ")
        end.join(" OR ")
        sql = "((#{sql}) OR #{Issue.table_name}.#{field} IS NULL OR #{Issue.table_name}.#{field} = '||' OR #{Issue.table_name}.#{field} = '')"
        # potentially very long query #TODO Find a way to optimize it
      # when "=", "!"
      #  sql = value.map { |role| "#{Issue.table_name}.#{field} #{operator == "!" ? 'NOT' : ''} LIKE '%|#{role}|%' " }.join(" OR ")
    end
    sql
  end

end
