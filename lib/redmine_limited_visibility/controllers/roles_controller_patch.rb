require_dependency 'roles_controller'

class RolesController < ApplicationController

  def index
    respond_to do |format|
      format.html {
        @functional_roles = Function.sorted.to_a
        @roles = Role.sorted.to_a
        render action: "index", layout: false if request.xhr?
      }
      format.api {
        @roles = Role.givable.to_a
      }
    end
  end
end
