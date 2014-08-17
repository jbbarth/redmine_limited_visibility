module LimitedVisibilityHelper
  def role_ids_for_current_viewers(issue)
    viewers = []
    if issue.new_record? # create new issue
      current_visibility_roles = visibility_roles_for_current_user(issue.project)
      if current_visibility_roles.present? # current user has at least one visibility role
        current_visibility_roles.each do |r|
          viewers = viewers | r.authorized_viewer_ids
        end
      else # current user has no visibility role (can see all issues)
        viewers = Role.visibility_roles.pluck(:id)
      end
    else # update existing issue
      if issue && issue.authorized_viewers.present?
        viewers = issue.authorized_viewers.split('|')
      else
        viewers = Role.visibility_roles.pluck(:id)
      end
    end
    viewers.reject(&:blank?).map(&:to_i)
  end

  def visibility_roles_for_current_user(project)
    Role.visibility_roles.joins(:members).where(:members => { :user_id => User.current.id, :project_id => @project.id })
  end
end
