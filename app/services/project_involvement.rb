class ProjectInvolvement
  attr_accessor :project_id

  def initialize(project_id)
    @project_id = project_id
  end

  # Basically it returns role ids that 1/ exist on that specific project,
  # and 2/ have the right to view issues.
  #
  # It's just a first version for now and should be refined later.
  def potential_involved_roles
    Member.where(:project_id => project_id)
          .joins(:member_roles)
          .where("member_roles.role_id IN (?)", issuers_roles)
          .pluck(:role_id)
          .uniq

    Role.where(:limit_visibility => true).sorted.pluck(:id).uniq
  end

  def issuers_roles
    Role.all.select do |role|
      role.allowed_to?(:view_issues)
    end
  end
end
