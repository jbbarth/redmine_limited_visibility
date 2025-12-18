require_dependency 'members_controller'

module RedmineLimitedVisibility
  module Controllers
    module MembersControllerPatch
      extend ActiveSupport::Concern

      def index
        scope = @project.memberships.active # Limit results to active users
        @offset, @limit = api_offset_and_limit
        @member_count = scope.count
        @member_pages = Redmine::Pagination::Paginator.new @member_count, @limit, params['page']
        @offset ||= @member_pages.offset
        @members = scope.includes(:principal, :roles, :functions, :member_functions).order(:id).limit(@limit).offset(@offset).to_a

        respond_to do |format|
          format.html {head :not_acceptable}
          format.api
        end
      end

      def edit
        @roles = Role.givable.to_a
        @functions = Function.available_functions_for(@project).sorted
        if @functions.blank?
          @functions = Function.active_by_default.sorted
        end
      end

      def create
        members = []
        if params[:membership]
          user_ids = Array.wrap(params[:membership][:user_id] || params[:membership][:user_ids])
          user_ids << nil if user_ids.empty?
          user_ids.each do |user_id|
            member = Member.new(:project => @project, :user_id => user_id)
            member.set_editable_role_ids(params[:membership][:role_ids])

            ## START PATCH
            member.set_functional_roles(params[:membership][:function_ids])
            ## END PATCH

            members << member
          end
          @project.members << members
        end

        respond_to do |format|
          format.html { redirect_to_settings_in_projects }
          format.js {
            @members = members
            @member = Member.new
          }
          format.api {
            @member = members.first
            if @member.valid?
              render :action => 'show', :status => :created, :location => membership_url(@member)
            else
              render_validation_errors(@member)
            end
          }
        end
      end

      def update
        if params[:membership]
          @member.set_editable_role_ids(params[:membership][:role_ids])

          ## START PATCH
          @member.set_functional_roles(params[:membership][:function_ids])
          ## END PATCH

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
  end
end

class MembersController

  prepend RedmineLimitedVisibility::Controllers::MembersControllerPatch

end
