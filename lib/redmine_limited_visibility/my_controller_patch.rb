require_dependency 'my_controller'

class MyController < ApplicationController

  # Show user's page with limited visibility
  def page
    @user = User.current
    @blocks = @user.pref[:my_page_layout] || DEFAULT_LAYOUT
    @visibility_condition = IssueQuery.new.sql_conditions_for_roles_per_projects('authorized_viewers')
  end
end
