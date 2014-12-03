require_dependency 'queries_helper'

module QueriesHelper
  include IssuesHelper

  unless instance_methods.include?(:column_value_with_limited_visibility)
    def column_value_with_limited_visibility(column, issue, value)
      if column.name == :authorized_viewers && value.class == String
        functions_from_authorized_viewers(value).join(", ")
      else
        column_value_without_limited_visibility(column, issue, value)
      end
    end
    alias_method_chain :column_value, :limited_visibility
  end

  unless instance_methods.include?(:retrieve_query_with_limited_visibility)
    # Add 'authorized_viewers' filter if not present
    def retrieve_query_with_limited_visibility
      retrieve_query_without_limited_visibility
      if @project.present? && @project.module_enabled?("limited_visibility")
        @query.filters.merge!({ 'authorized_viewers' => { :operator => (User.current.admin? ? "*" : "mine"), :values => [""] } }) if @query.is_a?(IssueQuery) && !@query.filters.include?('authorized_viewers')
      end
    end
    alias_method_chain :retrieve_query, :limited_visibility
  end
end
