require_dependency 'my_controller'
require 'redmine_limited_visibility/issue_query_patch'

class MyController < ApplicationController

  # Show user's page with limited visibility
  def page
    @user = User.current
    @blocks = @user.pref[:my_page_layout] || DEFAULT_LAYOUT
    @visibility_condition = IssueQuery.new.sql_conditions_for_roles_per_projects('authorized_viewers') unless params[:limited_visibility].present? && params[:limited_visibility] == 'false'
  end
end
