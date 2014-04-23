require_dependency 'queries_helper'

module QueriesHelper

  include IssuesHelper

  alias_method :plugin_limited_visibility_core_column_value, :column_value

  def column_value(column, issue, value)
    if column.name == :authorized_viewers && value.class == String
      involved_roles(value).join(", ")
    else
      plugin_limited_visibility_core_column_value(column, issue, value)
    end
  end

end
