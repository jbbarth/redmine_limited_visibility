require_dependency 'organization'

class Organization < ActiveRecord::Base

  has_many :organization_functions

  def functions
    Function.joins(:member_functions => {:member => :project})
        .where("user_id IN (?) AND projects.status = ?", self.users.map(&:id), Project::STATUS_ACTIVE)
        .sorted.uniq
  end

  def functions_by_project(project)
    Function.joins(:member_functions => :member)
        .where("user_id IN (?) AND project_id = ?", self.users.map(&:id), project.id)
        .sorted.uniq
  end

  def projects_by_function(function)
    Project.joins(:members => :member_functions)
        .where("function_id = ? AND user_id IN (?)", function.id, self.users.map(&:id))
        .active.sorted.uniq
  end

  def users_with(project:, functions:)
    users.joins(:members => :member_functions)
        .where("users.status = ? AND members.project_id = ? AND function_id IN (?)", User::STATUS_ACTIVE, project.id, functions.map(&:id))
        .sorted
  end

  def default_functions_by_project(project)
    organization_functions.includes(:function).where("project_id = ?", project.id).map(&:function).reject { |f| f.blank? }.sort_by { |f| f.position }.uniq
  end

  def delete_all_organization_functions(project_id, excluded_functions = [])
    organization_functions.where(project_id: project_id).where.not(function_id: excluded_functions.map(&:id)).each do |organization_function|
      organization_function.try(:destroy) if organization_function.id
    end
  end

end
