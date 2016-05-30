require_dependency 'organization'

class Organization < ActiveRecord::Base

  has_many :organization_functions

  def functions_by_project(project)
    Function.joins(:member_functions => :member).where("user_id IN (?) AND project_id = ?", self.users.map(&:id), project.id).uniq
  end

  def default_functions_by_project(project)
    organization_functions.includes(:function).where("project_id = ?", project.id).map(&:function).reject{|f| f.blank?}.sort_by { |f| f.position}.uniq
  end

  def update_project_members_with_roles_and_functions(project_id, new_members, new_roles, old_organization_roles, new_functions, old_organization_functions)
    delete_old_project_members(project_id, new_members)

    new_members.each do |user|
      add_member_through_organization(user, project_id, new_roles, old_organization_roles, new_functions, old_organization_functions)
    end if new_roles.present?
  end

  def delete_all_organization_functions(project_id, excluded = [])
    organization_functions.where(project_id: project_id).each do |f|
      next if excluded.include?(f)
      f.try(:destroy) if f.id
    end
  end

  private

    def add_member_through_organization(user, project_id, new_roles, old_organization_roles, new_functions, old_organization_functions)
      member = Member.where(user_id: user.id, project_id: project_id).first_or_initialize
      old_personal_roles = member.roles - old_organization_roles
      old_personal_functions = member.functions - old_organization_functions
      member.roles = []
      (new_roles | old_personal_roles).each do |new_role|
        unless member.roles.include?(new_role)
          member.roles << new_role
        end
      end
      member.functions = []
      (new_functions | old_personal_functions).each do |new_function|
        unless member.functions.include?(new_function)
          member.functions << new_function
        end
      end
      member.save! if member.project.present? && member.user.present?
    end
end
