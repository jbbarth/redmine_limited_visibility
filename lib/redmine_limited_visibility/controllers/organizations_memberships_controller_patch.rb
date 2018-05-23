require_dependency 'organizations_controller'
require_dependency 'organizations/memberships_controller'

class Organizations::MembershipsController < ApplicationController

  def update_functions
    if params[:membership]
      functions = params[:membership][:function_ids] ? Function.where(id: params[:membership][:function_ids].reject(&:empty?)) : []
    end
    previous_organization_functions = @organization.default_functions_by_project(@project)

    ActiveRecord::Base.transaction do
      @organization.delete_all_organization_functions(@project)
      organization_functions = functions.map{ |function| OrganizationFunction.new(function_id: function.id, project_id: @project.id) }
      organization_functions.each do |of|
        @organization.organization_functions << of
      end

      give_new_organization_functions_to_all_members(project: @project,
                                                     organization: @organization,
                                                     organization_functions: organization_functions.map(&:function),
                                                     previous_organization_functions: previous_organization_functions)
      saved = @organization.save
    end

    respond_to do |format|
      format.html { redirect_to settings_project_path(@project, :tab => 'members') }
      format.js {render :update}
      format.api {
        if saved
          render_api_ok
        else
          render_validation_errors(@member)
        end
      }
    end
  end

  private

  def give_new_organization_functions_to_all_members(project:, organization:, organization_functions:, previous_organization_functions:)
    members = Member.joins(:user).where("project_id = ? AND users.organization_id = ?", project.id, organization.id)
    members.each do |member|
      personal_functions = member.functions - previous_organization_functions
      member.functions = organization_functions | personal_functions
      member.save!
    end
  end

end
