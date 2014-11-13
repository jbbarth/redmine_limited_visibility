class FunctionsController < ApplicationController
  layout 'admin'

  before_filter :require_admin
  before_filter :find_function, :only => [:edit, :update, :destroy]

  def new
    @function = Function.new(params[:function])
    @functional_roles = Function.sorted.all
  end

  def create
    @function = Function.new(params[:function])
    if request.post? && @function.save
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
    if request.put? and @function.update_attributes(params[:function])
      flash[:notice] = l(:notice_successful_update)
      redirect_to roles_path
    else
      render :action => 'edit'
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

  private

    def find_function
      @function = Function.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render_404
    end

end
