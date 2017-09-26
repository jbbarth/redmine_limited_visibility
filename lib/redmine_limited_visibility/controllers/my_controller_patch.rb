require_dependency 'my_controller'
require 'redmine_limited_visibility/models/issue_query_patch'

class MyController < ApplicationController

  # Show user's page with limited visibility
  def page
    @user = User.current
    @groups = @user.pref.my_page_groups
    @blocks = @user.pref.my_page_layout
    @visibility_condition = IssueQuery.new.sql_conditions_for_functions_per_projects('authorized_viewers') unless params[:limited_visibility] == 'false'
  end

end
