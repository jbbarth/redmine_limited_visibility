require_dependency 'roles_controller'

class RolesController < ApplicationController

  def index
    respond_to do |format|
      format.html {
        @functional_roles = Function.sorted
        @role_pages, @roles = paginate Role.sorted, per_page: 25
        render action: "index", layout: false if request.xhr?
      }
      format.api {
        @roles = Role.givable.all
      }
    end
  end
end
