class FunctionsController < ApplicationController
  layout 'admin'

  before_action :require_admin, :except => [:index, :available_functions_per_project, :visible_functions_per_tracker, :activated_functions_per_tracker]
  before_action :find_function, :only => [:edit, :update, :destroy]

  def index    
    @issue = Issue.find(params[:issue_id])
    @project = @issue.project
    @functions = Function.all_functions_for(@project)
  end
  def new
    @function = Function.new
    @function.safe_attributes = params[:function]
    @functional_roles = Function.sorted.all
  end

  def create
    @function = Function.new
    @function.safe_attributes = params[:function]
    if request.post? && @function.save
      @function.update_private_notes_group(params[:function][:private_notes_group]) if params[:function][:private_notes_group].present?
      flash[:notice] = l(:notice_successful_create)
      redirect_to roles_path
    else
      @functional_roles = Function.sorted.all
      render :action => 'new'
    end
  end

  def edit
  end

  def update
    @function.safe_attributes = params[:function]
    if @function.save
      @function.update_private_notes_group(params[:function][:private_notes_group]) if Redmine::Plugin.installed?(:redmine_comments)
      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_update)
          redirect_to edit_function_path(@function)
        }
        format.js { head 200 }
      end
    else
      respond_to do |format|
        format.html { render :action => 'edit' }
        format.js { head 422 }
      end
    end
  end

  def destroy
    @function.destroy
    redirect_to roles_path
  rescue
    flash[:error] =  l(:error_can_not_remove_role)
    redirect_to roles_path
  end

  def visibilities
    @functional_roles = Function.sorted.all
    if request.post?
      @functional_roles.each do |role|
        viewers = '|'
        viewers = "#{viewers}#{params[:visibilities][role.id.to_s].join('|')}|" if params[:visibilities][role.id.to_s].present?
        role.update_attribute(:authorized_viewers, "#{viewers}#{role.id}|")
      end
      flash[:notice] = l(:notice_successful_update)
      redirect_to roles_path
    end
  end

  def copy_functions_settings_from_project
    current_project = Project.find(params[:project_id])
    project_from = Project.find(params[:project_from])

    current_project.project_functions = []
    project_from.project_functions.each do |pf|
      new_pf = ProjectFunction.new
      new_pf.attributes = pf.attributes.dup.except("id", "project_id")
      pf.project_function_trackers.each do |pft|
        new_pft = ProjectFunctionTracker.new
        new_pft.attributes = pft.attributes.dup.except("id", "project_function_id")
        new_pf.project_function_trackers << new_pft
      end
      current_project.project_functions << new_pf
    end
    current_project.autochecked_functions_mode = project_from.autochecked_functions_mode
    current_project.save
    respond_to do |format|
      format.html { redirect_to :controller => 'projects', :action => 'settings', :id => current_project.id, :tab => 'functional_roles' }
      format.js
    end
  end

  def available_functions_per_project
    project = Project.find(params[:project_id])
    if params[:function_ids].present?
      functions = Function.where(id: params[:function_ids])
      project.functions = functions    
    end
    project.autochecked_functions_mode = params[:autocheck_mode] if params[:autocheck_mode]
    project.save
    respond_to do |format|
      format.html { redirect_to :controller => 'projects', :action => 'settings', :id => project.id, :tab => 'functional_roles', nav: params[:nav] }
      format.js
    end
  end

  def visible_functions_per_tracker    
    context = :visibility
    project = Project.find(params[:project_id])    
    set_function_params_per_project_and_tracker(context, project, params)
    respond_to do |format|
      format.html { redirect_to :controller => 'projects', :action => 'settings', :id => project.id, :tab => 'functional_roles', nav: params[:nav] }
      format.js
    end
  end

  def activated_functions_per_tracker
    context = :autochecked
    project = Project.find(params[:project_id])
    set_function_params_per_project_and_tracker(context, project, params)
    respond_to do |format|
      format.html { redirect_to :controller => 'projects', :action => 'settings', :id => project.id, :tab => 'functional_roles', nav: params[:nav] }
      format.js
    end
  end

  private

    def find_function
      @function = Function.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render_404
    end

    def set_function_params_per_project_and_tracker(context, project, params)
      tracker_ids = project.tracker_ids
      function_ids = project.function_ids
      tracker_ids.each do |tracker_id|
        function_ids.each do |function_id|
          project_function = ProjectFunction.where(function_id: function_id, project_id: project.id).first
          if project_function.present?
            project_function_tracker = ProjectFunctionTracker.find_or_create_by(tracker_id: tracker_id, project_function_id: project_function.id)
            project_function_tracker.visible = true if project_function_tracker.visible.nil? # Set default value
            if context == :visibility
              project_function_tracker.visible = params["function_visibility"].present? && params["function_visibility"][tracker_id.to_s].present? && params["function_visibility"][tracker_id.to_s].include?(function_id.to_s)
            end

            if context == :autochecked
              project_function_tracker.checked = params["function_activation_per_tracker"].present? && params["function_activation_per_tracker"][tracker_id.to_s].present? && params["function_activation_per_tracker"][tracker_id.to_s].include?(function_id.to_s)
            end
            project_function_tracker.save

            if context == :autochecked
              project_function.authorized_viewers = '|'+params["function_activation_per_user_function"][function_id.to_s].join('|')+'|'
              project_function.save
            end
          end
        end
      end
    end

end
