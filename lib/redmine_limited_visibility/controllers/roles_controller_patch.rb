require_dependency 'roles_controller'

module RedmineLimitedVisibility
  module Controllers
    module RolesControllerPatch
      extend ActiveSupport::Concern

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
  end
end

class RolesController < ApplicationController

  prepend RedmineLimitedVisibility::Controllers::RolesControllerPatch

end
