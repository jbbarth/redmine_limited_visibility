require_dependency 'my_controller'
require 'redmine_limited_visibility/models/issue_query_patch'

class MyController < ApplicationController

  # Show user's page with limited visibility
  def page
    @user = User.current
    @groups = @user.pref.my_page_groups
    @blocks = @user.pref.my_page_layout
    @visibility_condition = IssueQuery.new.sql_conditions_for_functions_per_projects('authorized_viewers') unless params[:limited_visibility] == 'false'
    if params[:limited_visibility] == 'false'
      @visibility = '*'
    else
      @visibility = 'mine'
    end
    @my_team = @user.organization
    @my_team_user_ids = @my_team.present? ? @my_team.users.pluck(:id) : []
  end

end
