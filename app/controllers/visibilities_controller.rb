class VisibilitiesController < ApplicationController
  # Update 'visibility' roles and do NOT modify 'standard' roles
  # params: member_id (:id) and membership with visibility roles (:role_ids)
  def update_visibility_roles
    member = Member.find(params[:id]) if params[:id]
    @project = member.project if member
    # role_ids = standard roles + updated visibility roles
    member.role_ids = ((member.role_ids - Role.visibility_roles.pluck(:id)) + params[:membership][:role_ids]) if params[:membership]
    saved = member.save
    respond_to do |format|
      format.html { redirect_to_settings_in_projects }
      format.js
      format.api do
        if saved
          render_api_ok
        else
          render_validation_errors(member)
        end
      end
    end
  end

  # Update 'permissions' roles and do NOT modify 'visibility' roles
  def update_permissions_roles_by_organization
    membership = OrganizationMembership.find(params[:id])
    # visibility roles + updated permissions roles
    membership.role_ids = ((membership.role_ids - Role.permission_roles.pluck(:id)) + params[:membership][:role_ids]) if params[:membership]
    membership.save!
    # membership.update_attributes(params[:membership])
    @organization = membership.organization
    @project = membership.project
    render 'organization_memberships/update_roles'
  end

  # Update 'visibility' roles and do NOT modify 'permissions' roles
  def update_visibility_roles_by_organization
    membership = OrganizationMembership.find(params[:id])
    # standard roles + updated visibility roles
    membership.role_ids = ((membership.role_ids - Role.visibility_roles.pluck(:id)) + params[:membership][:role_ids]) if params[:membership]
    membership.save!
    # membership.update_attributes(params[:membership])
    @organization = membership.organization
    @project = membership.project
    render 'organization_memberships/update_roles'
  end

  private
    def redirect_to_settings_in_projects
      redirect_to settings_project_path(@project, :tab => 'visibility')
    end
end
