require_dependency 'queries_helper'

module QueriesHelper
  include IssuesHelper

  unless instance_methods.include?(:column_content_with_limited_visibility)
    def column_content_with_limited_visibility(column, issue)
      if  column.name == :has_been_assigned_to
        get_assigned_users_and_functions(column, issue, true)
      elsif  column.name == :has_been_visible_by
        get_has_been_authorized_viewers(column, issue, true)
      else
        column_content_without_limited_visibility(column, issue)
      end
    end
    alias_method_chain :column_content, :limited_visibility
  end

  unless instance_methods.include?(:csv_content_with_limited_visibility)
    def csv_content_with_limited_visibility(column, issue)
      if  column.name == :has_been_assigned_to
        get_assigned_users_and_functions(column, issue, false)
      else
        csv_content_without_limited_visibility(column, issue)
      end
    end
    alias_method_chain :csv_content, :limited_visibility
  end

  def get_assigned_users_and_functions(column, issue, html=true)
    list_of_users = get_has_been_assigned_users(column, issue, html)
    list_of_functions = get_has_been_assigned_functions(issue)
    [list_of_functions, list_of_users].reject(&:blank?).join(', ')
  end

  def get_has_been_assigned_functions(issue)
    functions_ids = [issue.assigned_to_function_id]
    issue.journals.each do |journal|
      functions_ids << journal.details.select { |i| i.prop_key == 'assigned_to_function_id' }.map(&:old_value)
      functions_ids << journal.details.select { |i| i.prop_key == 'assigned_to_function_id' }.map(&:value)
    end
    functions_ids.flatten!
    if functions_ids.present?
      functions_ids.uniq!
      functions = Function.where('id' => functions_ids)
      functions.collect { |v| v.name }.compact.join(', ').html_safe if functions
    else
      nil
    end
  end

  def get_has_been_authorized_viewers(column, issue, html)
    functions_ids = issue.authorized_viewer_ids
    issue.journals.each do |journal|
      functions_ids << journal.details.select { |i| i.prop_key == 'authorized_viewers' }.map{ |journal_detail| journal_detail.old_value.split('|').reject(&:blank?).map(&:to_i) }
      functions_ids << journal.details.select { |i| i.prop_key == 'authorized_viewers' }.map{ |journal_detail| journal_detail.value.split('|').reject(&:blank?).map(&:to_i) }
    end
    functions_ids.flatten!
    if functions_ids.present?
      functions_ids.uniq!
      functions = Function.where('id' => functions_ids).sorted
      functions.collect { |v| v.name }.compact.join(', ').html_safe if functions
    else
      nil
    end
  end

  def get_has_been_assigned_users(column, issue, html)
    users_ids = [issue.assigned_to_id]
    issue.journals.each do |journal|
      users_ids << journal.details.select { |i| i.prop_key == 'assigned_to_id' }.map(&:old_value)
      users_ids << journal.details.select { |i| i.prop_key == 'assigned_to_id' }.map(&:value)
    end
    users_ids.flatten!
    if users_ids.present?
      users_ids.uniq!
      users = User.where('id' => users_ids) #would be great to keep the order : ORDER BY FIELD('users'.'id', users_ids)
      users.collect { |v| html ? column_value(column, issue, v) : v.to_s }.compact.join(', ').html_safe if users
    else
      nil
    end
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
        should_see_all = []
        User.current.members.map(&:functions).each do |functions|
          functions.map(&:see_all_issues).each do |param|
            should_see_all << param
          end
        end
        see_all_issues = true if User.current.admin? || should_see_all.include?(true)
        @query.filters.merge!({ 'authorized_viewers' => { :operator => (see_all_issues ? "*" : "mine"), :values => [""] } }) if @query.is_a?(IssueQuery) && !@query.filters.include?('authorized_viewers')
      end
    end
    alias_method_chain :retrieve_query, :limited_visibility
  end
end
