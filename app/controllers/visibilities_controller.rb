class VisibilitiesController < ApplicationController

  # Update 'visibility roles' and do NOT modify 'standard' roles
  # params: member_id (:id) and membership with visibility roles (:role_ids)
  def update_visibility_roles
    @member = Member.find(params[:id]) if params[:id]
    @project = @member.project if @member
    if params[:membership]
      # standard roles + updated visibility roles
      @member.role_ids = @member.role_ids - Role.find_all_visibility_roles.collect(&:id)
      @member.role_ids = @member.role_ids + params[:membership][:role_ids]
    end
    saved = @member.save
    respond_to do |format|
      format.html { redirect_to_settings_in_projects }
      format.js
      format.api {
        if saved
          render_api_ok
        else
          render_validation_errors(@member)
        end
      }
    end
  end

end
