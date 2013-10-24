class ProjectInvolvement
  attr_accessor :project_id

  def initialize(project_id)
    @project_id = project_id
  end

  def potential_involved_teams
    User.where(:id => issuers_user_ids)
        .pluck(:organization_id)
        .compact
        .uniq
  end

  def issuers_user_ids
    Member.where(:project_id => project_id)
          .joins(:member_roles)
          .where("member_roles.role_id IN (?)", issuers_roles)
          .map(&:user_id)
  end

  def issuers_roles
    allowed_roles = Role.all.select do |role|
      role.allowed_to?(:view_issues)
    end
  end
end
