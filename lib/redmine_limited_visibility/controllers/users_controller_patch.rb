require_dependency 'users_controller'

module RedmineLimitedVisibility
  module Controllers
    module UsersControllerPatch
      extend ActiveSupport::Concern

      def show
        unless @user.visible?
          render_404
          return
        end

        # show projects based on current user visibility
        # #### START PATCH ####
        # Preload functions to avoid N+1 queries
        @memberships = @user.memberships
                            .preload(:project, :functions, :member_roles => :role)
                            .where(Project.visible_condition(User.current, { :skip_pre_condition => true })).to_a
        # #### END PATCH ####

        @issue_counts = {}
        @issue_counts[:assigned] = {
          :total => Issue.visible.assigned_to(@user).count,
          :open => Issue.visible.open.assigned_to(@user).count
        }
        @issue_counts[:reported] = {
          :total => Issue.visible.where(:author_id => @user.id).count,
          :open => Issue.visible.open.where(:author_id => @user.id).count
        }

        respond_to do |format|
          format.html do
            events = Redmine::Activity::Fetcher.new(User.current, :author => @user).events(nil, nil, :limit => 10)
            @events_by_day = events.group_by { |event| User.current.time_to_date(event.event_datetime) }
            render :layout => 'base'
          end
          format.api
        end
      end

    end
  end
end

class UsersController < ApplicationController

  prepend RedmineLimitedVisibility::Controllers::UsersControllerPatch

end
