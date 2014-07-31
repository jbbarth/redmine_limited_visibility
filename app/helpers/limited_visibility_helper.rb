module LimitedVisibilityHelper
  def role_ids_for_current_viewers(issue)
    viewers = []
    if issue.new_record? # create new issue
      current_visibility_roles = visibility_roles_for_current_user(issue.project)
      if current_visibility_roles.present? # current user has at least one visibility role
        current_visibility_roles.each do |r|
          viewers = viewers | r.authorized_viewers.split('|') if r.authorized_viewers
        end
      else # current user has no visibility role (can see all issues)
        viewers = Role.visibility_roles.pluck(:id)
      end
    else # update existing issue
      if issue && issue.authorized_viewers.present?
        viewers = issue.authorized_viewers.split('|').delete_if(&:blank?)
      else
        viewers = Role.visibility_roles.pluck(:id)
      end
    end
    viewers
  end

  def visibility_roles_for_current_user(project)
    if Redmine::Plugin.installed?(:redmine_organizations)
      roles = Role.joins('LEFT OUTER JOIN organization_roles ON roles.id = organization_roles.role_id')
      .joins('LEFT OUTER JOIN organization_memberships ON organization_memberships.id = organization_roles.organization_membership_id')
      .joins('LEFT OUTER JOIN organization_involvements ON organization_involvements.organization_membership_id = organization_memberships.id')
      .where("#{OrganizationMembership.table_name}.project_id = ? AND #{OrganizationInvolvement.table_name}.user_id IN (?)", project.id, User.current.id)
      .visibility_roles.all
    else
      member = Member.find_by_user_id_and_project_id(User.current.id, project.id)
      # member cannot remove his current roles
      roles = member.roles.visibility_roles.all if member.present?
    end
    roles
  end
end
