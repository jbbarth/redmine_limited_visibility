module LimitedVisibilityHelper

  def function_ids_for_current_tracker(issue, previous_tracker_id)
    viewers = []
    if issue.new_record? # create new issue
      if issue.authorized_viewer_ids.present? && previous_tracker_id.to_i == issue.tracker_id
        viewers = issue.authorized_viewer_ids
      else
        viewers = issue.default_authorized_viewer_ids_for_tracker
      end
    else # update existing issue
      if issue && issue.authorized_viewers.present?
        viewers = issue.authorized_viewer_ids
      else
        viewers = Function.available_functions_for(issue.project).sorted.pluck(:id)
      end
    end
    viewers.reject(&:blank?).map(&:to_i)
  end

  def function_ids_for_current_viewers(issue)
    if issue.new_record? # create new issue
      if issue.authorized_viewer_ids.present?
        viewers = issue.authorized_viewer_ids
      else
        viewers = issue.default_authorized_viewer_ids_for_user(User.current)
      end
    else # update existing issue
      if issue && issue.authorized_viewers.present?
        viewers = issue.authorized_viewer_ids
      else
        viewers = Function.available_functions_for(issue.project).sorted.pluck(:id)
      end
    end
    viewers.reject(&:blank?).map(&:to_i)
  end

  def functional_roles_for_current_user(project)
    Function.of_user_in_project(User.current, project).to_a
  end

  # Returns a string for users/groups option tags
  def assignable_options_for_select(issue, users, selected = nil)
    # Defer to Redmine's core rendering if the module is not enabled or the assignee is required
    unless issue.project.present? &&
           issue.project.module_enabled?('limited_visibility') &&
           !issue.required_attribute?('assigned_to_id')
      return principals_options_for_select(users, selected)
    end

    s = ''
    functional_roles = Function.available_functions_for(issue.project).sorted
    functional_roles.each do |function|
      s << content_tag('option', "#{function.name}", :value => "function-#{function.id}", :selected => (option_value_selected?(function.id, selected) || function.id == selected))
    end
    s << "<option disabled>──────────────</option>"
    if users.include?(User.current)
      s << content_tag('option', "<< #{l(:label_me)} >>", :value => User.current.id)
    end
    groups = ''

    functions_per_user = issue.project.functions_per_user
    users.sort.each do |user|
      selected_attribute = ' selected="selected"' if option_value_selected?(user, selected) || user.id.to_s == selected
      functional_roles_ids = functions_per_user[user.id]
      functional_roles_attribute = functional_roles_ids.present? ? " functional_roles='#{functional_roles_ids.join(',')}'" : ""
      (user.is_a?(Group) ? groups : s) << %(<option value="#{user.id}"#{selected_attribute}#{functional_roles_attribute}>#{h user.name}</option>)
    end
    unless groups.empty?
      s << %(<optgroup label="#{h(l(:label_group_plural))}">#{groups}</optgroup>)
    end
    s.html_safe
  end

end
