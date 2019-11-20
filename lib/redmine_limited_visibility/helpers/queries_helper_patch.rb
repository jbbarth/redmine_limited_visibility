require_dependency 'queries_helper'

module PluginLimitedVisibility
  module QueriesHelperPatch

    def column_value(column, item, value)
      if column.name == :authorized_viewers && value.class == String
        Function.functions_from_authorized_viewers(value).join(", ")
      elsif column.name == :assigned_to && value.blank?
        if item.assigned_function.present?
          "&#10148; #{item.assigned_function.name}".html_safe
        end
      else
        super
      end
    end

    def csv_content(column, issue)
      if column.name == :has_been_assigned_to
        get_assigned_users_and_functions(column, issue, false)
      elsif column.name == :has_been_visible_by
        get_has_been_authorized_viewers(column, issue, false)
      else
        super
      end
    end

    def column_content(column, issue)
      if column.name == :has_been_assigned_to
        get_assigned_users_and_functions(column, issue, true)
      elsif  column.name == :has_been_visible_by
        get_has_been_authorized_viewers(column, issue, true)
      else
        super
      end
    end

    def get_assigned_users_and_functions(column, issue, html=true)
      list_of_users = get_has_been_assigned_users(column, issue, html)
      list_of_functions = get_has_been_assigned_functions(issue)
      [list_of_functions, list_of_users].reject(&:blank?).join(', ').html_safe
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
        functions_ids << journal.details.select { |i| i.prop_key == 'authorized_viewers' && i.old_value.present? }.map{ |journal_detail| journal_detail.old_value.split('|').reject(&:blank?).map(&:to_i) }
        functions_ids << journal.details.select { |i| i.prop_key == 'authorized_viewers' && i.value.present? }.map{ |journal_detail| journal_detail.value.split('|').reject(&:blank?).map(&:to_i) }
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

    def filters_options_for_select(query)
      ungrouped = []
      grouped = {}
      query.available_filters.map do |field, field_options|
        if field_options[:type] == :relation
          group = :label_relations
        elsif field_options[:type] == :tree
          group = query.is_a?(IssueQuery) ? :label_relations : nil
        elsif field =~ /^cf_\d+\./
          group = (field_options[:through] || field_options[:field]).try(:name)
        elsif field =~ /^(.+)\./
          # association filters
          group = "field_#{$1}".to_sym

          ## Start PATCH
        elsif %w(member_of_group
                assigned_to_role
                assigned_to_member_with_function_id
                assigned_to_function_id
                has_been_assigned_to_id
                has_been_assigned_to_function_id).include?(field)
          group = :field_assigned_to
        elsif %w(authorized_viewers has_been_visible_by_id).include?(field)
          group = :field_authorized_viewers
          ## End PATCH

        elsif field_options[:type] == :date_past || field_options[:type] == :date
          group = :label_date
        end
        if group
          (grouped[group] ||= []) << [field_options[:name], field]
        else
          ungrouped << [field_options[:name], field]
        end
      end
      # Don't group dates if there's only one (eg. time entries filters)
      if grouped[:label_date].try(:size) == 1
        ungrouped << grouped.delete(:label_date).first
      end
      s = options_for_select([[]] + ungrouped)
      if grouped.present?
        localized_grouped = grouped.map {|k,v| [k.is_a?(Symbol) ? l(k) : k.to_s, v]}
        s << grouped_options_for_select(localized_grouped)
      end
      s
    end

  end
end

module QueriesHelper
  unless instance_methods.include?(:retrieve_query_with_limited_visibility)
    # Add 'authorized_viewers' filter if not present
    def retrieve_query_with_limited_visibility(klass=IssueQuery, use_session=true, options={})
      retrieve_query_without_limited_visibility(klass, use_session, options)

      if @project.blank? || @project.module_enabled?("limited_visibility")
        should_see_all = false

        if @project.present?
          member = User.current.members.where(project: @project).first
          should_see_all = true if member && member.functions.detect(&:see_all_issues)
        else
          User.current.members.map(&:functions).each do |functions|
            should_see_all = true if functions.detect(&:see_all_issues)
          end
        end

        see_all_issues = true if User.current.admin? || should_see_all
        @query.filters.merge!({ 'authorized_viewers' => { :operator => (see_all_issues ? "*" : "mine"), :values => [""] } }) if @query.is_a?(IssueQuery) && !@query.filters.include?('authorized_viewers')
      end
      @query
    end
    alias_method :retrieve_query_without_limited_visibility, :retrieve_query
    alias_method :retrieve_query, :retrieve_query_with_limited_visibility
    # we don't use prepend here because the helper is included in many controllers
  end
end

QueriesHelper.prepend PluginLimitedVisibility::QueriesHelperPatch
ActionView::Base.prepend QueriesHelper
IssuesController.prepend QueriesHelper
