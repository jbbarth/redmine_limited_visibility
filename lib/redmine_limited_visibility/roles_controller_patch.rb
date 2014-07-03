require_dependency 'roles_controller'

class RolesController < ApplicationController
  before_filter :no_permissions_if_visibility_role, only: [:create, :update]

  def index
    respond_to do |format|
      format.html {
        @visibility_roles = Role.visibility_roles.sorted
        @role_pages, @roles = paginate Role.permission_roles.sorted, per_page: 25
        render action: "index", layout: false if request.xhr?
      }
      format.api {
        @roles = Role.givable.all
      }
    end
  end

  def visibilities
    @roles = Role.visibility_roles.sorted.all
    if request.post?
      @roles.each do |role|
        viewers = '|'
        viewers = "#{viewers}#{params[:visibilities][role.id.to_s].join('|')}|" if params[:visibilities][role.id.to_s].present?
        role.update_attribute(:authorized_viewers, "#{viewers}#{role.id}|")
      end
      flash[:notice] = l(:notice_successful_update)
      redirect_to roles_path
    end
  end

  private

    def no_permissions_if_visibility_role
      params[:role][:permissions] = [] if params[:role][:limit_visibility] == '1'
    end
end
