require_dependency 'organizations_controller'

class OrganizationsController < ApplicationController

  def update_roles
    new_members = User.find(params[:membership][:user_ids].reject(&:empty?))
    new_roles = Role.find(params[:membership][:role_ids].reject(&:empty?))

    if params[:membership][:function_ids].present?
      new_functions = Function.find(params[:membership][:function_ids].reject(&:empty?))
    else
      new_functions = []
    end
    @organization = Organization.find(params[:organization_id])
    old_organization_roles = @organization.default_roles_by_project(@project)
    old_organization_functions = @organization.default_functions_by_project(@project)

    @organization.delete_all_organization_roles(@project)
    organization_roles = new_roles.map{ |role| OrganizationRole.new(role_id: role.id, project_id: @project.id) }
    organization_roles.each do |r|
      @organization.organization_roles << r
    end

    @organization.delete_all_organization_functions(@project)
    organization_functions = new_functions.map{ |function| OrganizationFunction.new(function_id: function.id, project_id: @project.id) }
    organization_functions.each do |f|
      @organization.organization_functions << f
    end

    @organization.update_project_members_with_roles_and_functions(params[:project_id], new_members, new_roles, old_organization_roles, new_functions, old_organization_functions)
    respond_to do |format|
      format.html { redirect_to :controller => 'projects', :action => 'settings', :id => @project.id, :tab => 'members' }
      format.js
    end
  end

  def update_user_roles
    new_roles = Role.find(params[:membership][:role_ids].reject(&:empty?))
    if params[:member_id]
      new_functions = Function.find_by_id(params[:membership][:function_ids]).reject!(&:empty?)
      @member = Member.find(params[:member_id])
      if @member.principal.organization_id.present?
        @member.roles = new_roles | @member.principal.organization.default_roles_by_project(@project)
        @member.functions = new_functions | @member.principal.organization.default_functions_by_project(@project)
      end
    end

    if params[:group_id] # TODO Modify this hack - create a different action to make it cleaner
      group = GroupBuiltin.find(params[:group_id])
      membership = Member.where(user_id: group.id, project_id: @project.id).first_or_initialize
      if new_roles.present?
        membership.roles = new_roles
        membership.save
      else
        membership.try(:destroy)
      end
    end

    if @member
      unless @member.save
        flash[:error] = @member.errors.full_messages.join(', ')
      end
    end
    respond_to do |format|
      format.html { redirect_to :controller => 'projects', :action => 'settings', :id => @project.id, :tab => 'members' }
      format.js
    end
  end

end
