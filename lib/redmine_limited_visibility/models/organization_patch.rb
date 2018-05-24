require_dependency 'organization'

class Organization < ActiveRecord::Base

  has_many :organization_functions

  def functions_by_project(project)
    Function.joins(:member_functions => :member).where("user_id IN (?) AND project_id = ?", self.users.map(&:id), project.id).uniq
  end

  def default_functions_by_project(project)
    organization_functions.includes(:function).where("project_id = ?", project.id).map(&:function).reject{|f| f.blank?}.sort_by { |f| f.position}.uniq
  end

  def delete_all_organization_functions(project_id, excluded = [])
    organization_functions.where(project_id: project_id).each do |f|
      next if excluded.include?(f)
      f.try(:destroy) if f.id
    end
  end

end
