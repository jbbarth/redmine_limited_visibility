require_dependency 'queries_helper'

module QueriesHelper
  include IssuesHelper

  alias_method :plugin_limited_visibility_core_column_value, :column_value
  alias_method :plugin_limited_visibility_core_retrieve_query, :retrieve_query

  def column_value(column, issue, value)
    if column.name == :authorized_viewers && value.class == String
      involved_roles(value).join(", ")
    else
      plugin_limited_visibility_core_column_value(column, issue, value)
    end
  end

  # Add 'authorized_viewers' filter if not present
  def retrieve_query
    plugin_limited_visibility_core_retrieve_query
    @query.filters.merge!({ 'authorized_viewers' => { :operator => "mine", :values => [""] } }) if @query.is_a?IssueQuery && !@query.filters.include?('authorized_viewers')
  end
end
