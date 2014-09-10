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
      format.html do
        redirect_to settings_project_path(@project, :tab => 'visibility')
      end
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
end
