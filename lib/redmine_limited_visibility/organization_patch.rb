require_dependency 'organization'

class Organization < ActiveRecord::Base
  def functions_by_project(project)
    Function.joins(:member_functions => :member).where("user_id IN (?) AND project_id = ?", self.users.map(&:id), project.id).uniq
  end
end
