require_dependency 'organizations_controller'

class OrganizationsController < ApplicationController

  def update_roles
    new_members = User.find(params[:membership][:user_ids].reject(&:empty?))
    new_roles = Role.find(params[:membership][:role_ids].reject(&:empty?))
    new_functions = Function.find(params[:membership][:function_ids].reject(&:empty?))
    @organization = Organization.find(params[:organization_id])
    @organization.update_project_members(params[:project_id], new_members, new_roles)
    update_members_functions(new_functions, params[:project_id], @organization.id)
    respond_to do |format|
      format.html { redirect_to :controller => 'projects', :action => 'settings', :id => @project.id, :tab => 'members' }
      format.js
    end
  end

  private

    def update_members_functions(new_functions, project_id, organization_id)
      members = Member.joins(:user).where("organization_id = ? AND project_id = ?", organization_id, project_id).uniq
      members.each do |member|
        new_functions.each do |function_id|
          unless member.functions.map(&:id).include?(function_id)
            member.functions << Function.find(function_id)
          end
        end
      end if new_functions.present?
    end

end
