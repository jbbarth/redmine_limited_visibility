module LimitedVisibilityHelper

  def function_ids_for_current_tracker(issue, previous_tracker_id)
    viewers = []
    if issue.new_record? # create new issue
      if issue.authorized_viewer_ids.present? && previous_tracker_id.to_i == issue.tracker_id
        viewers = issue.authorized_viewer_ids
      else
        current_functions = ProjectFunctionTracker.joins(:project_function).where("project_id = ? AND tracker_id = ?", issue.project_id, issue.tracker_id)
        if current_functions.present? # current tracker has at least one functional role in settings
          viewers = current_functions.select {|f| f.checked == true}.map {|c| c.function.id}
        else # else check all functions
          viewers = Function.available_functions_for(issue.project).sorted.pluck(:id)
        end
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
        current_functions = functional_roles_for_current_user(issue.project)
        if current_functions.present? # current user has at least one functional role
          activated_functions = []
          current_functions.each do |f|
            functions_per_project = ProjectFunction.where('project_id = ? AND function_id = ?', issue.project_id, f.id)
            enabled_functions_per_project = []
            functions_per_project.each do |pf|
              if pf.authorized_viewer_ids.present?
                enabled_functions_per_project |= Function.where("id in (?)", pf.authorized_viewer_ids).sorted
              end
            end
            if enabled_functions_per_project.present?
              activated_functions |= enabled_functions_per_project
            else
              activated_functions |= Function.where("id in (?)", f.authorized_viewer_ids).sorted
            end
          end
          activated_functions = activated_functions & Function.available_functions_for(@project).sorted
          activated_functions.sort_by {|a| a.position}
          viewers = activated_functions.map {|f| f.id}
        else # current user has no visibility role (can see all issues available for the current project)
          viewers = Function.available_functions_for(issue.project).sorted.pluck(:id)
        end
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
    Function.joins(:members).where(:members => {:user_id => User.current.id, :project_id => project.id}).sorted
  end

  # Returns a string for users/groups option tags
  def assignable_options_for_select(issue, users, selected = nil)
    s = ''
    if @issue.project.present?
      if @issue.project.module_enabled?("limited_visibility")
        functional_roles_ids = Function.available_functions_for(issue.project).sorted.pluck(:id)
        functional_roles_ids.each do |function_id|
          s << content_tag('option', "#{Function.find(function_id).name}", :value => "function-#{function_id}", :selected => (option_value_selected?(function_id, selected) || function_id == selected))
        end
        s << "<option disabled>──────────────</option>"
      end
      if users.include?(User.current)
        s << content_tag('option', "<< #{l(:label_me)} >>", :value => User.current.id)
      end
      groups = ''

      users.sort.each do |element|
        selected_attribute = ' selected="selected"' if option_value_selected?(element, selected) || element.id.to_s == selected
        functional_roles_ids = issue.project.functions_per_user[element.id]
        functional_roles_attribute = functional_roles_ids.present? ? " functional_roles='#{functional_roles_ids.join(',')}'" : ""
        (element.is_a?(Group) ? groups : s) << %(<option value="#{element.id}"#{selected_attribute}#{functional_roles_attribute}>#{h element.name}</option>)
      end
      unless groups.empty?
        s << %(<optgroup label="#{h(l(:label_group_plural))}">#{groups}</optgroup>)
      end
    end
    s.html_safe
  end

end
