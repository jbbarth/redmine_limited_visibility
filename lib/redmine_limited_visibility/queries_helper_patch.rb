require_dependency 'queries_helper'

module QueriesHelper
  include IssuesHelper

  unless instance_methods.include?(:column_content_with_limited_visibility)
    def column_content_with_limited_visibility(column, issue)
      if  column.name == :has_been_assigned_to
        results = [issue.assigned_to_id]
        issue.journals.each do |journal|
          results << journal.details.select {|i| i.prop_key == 'assigned_to_id' }.map(&:value)
        end
        results.flatten!
        if results.present?
          results.uniq!
          users = User.where('id' => results)
          users.collect {|v| column_value(column, issue, v)}.compact.join(', ').html_safe  if users
        else
          ""
        end
      else
        column_content_without_limited_visibility(column, issue)
      end
    end
    alias_method_chain :column_content, :limited_visibility
  end

  unless instance_methods.include?(:column_value_with_limited_visibility)
    def column_value_with_limited_visibility(column, issue, value)
      if column.name == :authorized_viewers && value.class == String
        functions_from_authorized_viewers(value).join(", ")
      elsif column.name == :assigned_to && value.blank?
        if issue.assigned_to_function_id.present?
          "&#10148; #{issue.assigned_function.name}".html_safe
        end
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
      if @project.blank? || @project.module_enabled?("limited_visibility")
        @query.filters.merge!({ 'authorized_viewers' => { :operator => (User.current.admin? ? "*" : "mine"), :values => [""] } }) if @query.is_a?(IssueQuery) && !@query.filters.include?('authorized_viewers')
      end
    end
    alias_method_chain :retrieve_query, :limited_visibility
  end
end
