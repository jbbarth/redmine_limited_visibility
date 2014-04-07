require_dependency 'roles_controller'

class RolesController < ApplicationController

  before_filter :no_permissions_if_visibility_role, :only => [:create, :update]

  def index
    respond_to do |format|
      format.html {
        @visibility_roles = Role.where(:limit_visibility => true).sorted
        @role_pages, @roles = paginate Role.where('limit_visibility IS NULL OR limit_visibility != ?', true).sorted, :per_page => 25
        render :action => "index", :layout => false if request.xhr?
      }
      format.api {
        @roles = Role.givable.all
      }
    end
  end

  private

    def no_permissions_if_visibility_role
      params[:role][:permissions] = [] if params[:role][:limit_visibility]=='1'
    end

end
