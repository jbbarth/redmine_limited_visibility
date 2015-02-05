module LimitedVisibilityHelper
  def function_ids_for_current_viewers(issue)
    viewers = []
    if issue.new_record? # create new issue
      if issue.authorized_viewer_ids.present?
        viewers = issue.authorized_viewer_ids
      else
        current_functions = functional_roles_for_current_user(issue.project)
        if current_functions.present? # current user has at least one functional role
          current_functions.each do |r|
            viewers = viewers | r.authorized_viewer_ids
          end
        else # current user has no visibility role (can see all issues)
          viewers = Function.pluck(:id)
        end
      end
    else # update existing issue
      if issue && issue.authorized_viewers.present?
        viewers = issue.authorized_viewers.split('|')
      else
        viewers = Function.pluck(:id)
      end
    end
    viewers.reject(&:blank?).map(&:to_i)
  end

  def functional_roles_for_current_user(project)
    Function.joins(:members).where(:members => { :user_id => User.current.id, :project_id => project.id })
  end

  # Returns a string for users/groups option tags
  def assignable_options_for_select(issue, users, selected=nil)
    s = ''
    if @issue.project.module_enabled?("limited_visibility")
      if issue.authorized_viewer_ids.present?
        functional_roles_ids = issue.authorized_viewer_ids
      else
        functional_roles_ids = function_ids_for_current_viewers(issue)
      end
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
      (element.is_a?(Group) ? groups : s) << %(<option value="#{element.id}"#{selected_attribute}>#{h element.name}</option>)
    end
    unless groups.empty?
      s << %(<optgroup label="#{h(l(:label_group_plural))}">#{groups}</optgroup>)
    end
    s.html_safe
  end
end
