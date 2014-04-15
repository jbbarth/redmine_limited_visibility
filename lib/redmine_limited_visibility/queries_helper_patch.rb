require_dependency 'queries_helper'

module QueriesHelper

  alias_method :core_column_value, :column_value

  def column_value(column, issue, value)
    if column.name == :authorized_viewers && value.class == String
      roles = Role.find(value.split('|').delete_if(&:blank?)).join(", ")
    else
      core_column_value(column, issue, value)
    end
  end

end
