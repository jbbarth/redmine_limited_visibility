module LimitedVisibilityHelper
  def function_ids_for_current_viewers(issue)
    viewers = []
    if issue.new_record? # create new issue
      current_functions = functional_roles_for_current_user(issue.project)
      if current_functions.present? # current user has at least one functional role
        current_functions.each do |r|
          viewers = viewers | r.authorized_viewer_ids
        end
      else # current user has no visibility role (can see all issues)
        viewers = Function.pluck(:id)
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
end
