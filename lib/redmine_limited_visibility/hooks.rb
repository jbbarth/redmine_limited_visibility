require File.dirname(__FILE__) + '/../../app/helpers/limited_visibility_helper'
include LimitedVisibilityHelper

module RedmineLimitedVisibility
  class Hooks < Redmine::Hook::ViewListener

    # Add our css/js on each page
    def view_layouts_base_html_head(context)
      stylesheet_link_tag("limited_visibility", plugin: "redmine_limited_visibility") +
        stylesheet_link_tag("font-awesome.min.css", :plugin => "redmine_limited_visibility") +
        javascript_include_tag('limited_visibility.js', plugin: 'redmine_limited_visibility')
    end

  end

  class ModelHook < Redmine::Hook::Listener
    def after_plugins_loaded(_context = {})

      require_relative 'helpers/queries_helper_patch'
      require_relative 'controllers/my_controller_patch'
      require_relative 'models/issue_query_patch'

      require_relative 'helpers/issues_helper_patch'
      require_relative 'helpers/issues_pdf_helper_patch'
      require_relative 'helpers/projects_helper_patch'

      require_relative 'controllers/roles_controller_patch'
      require_relative 'controllers/users_controller_patch'
      require_relative 'controllers/issues_controller_patch'
      require_relative 'controllers/members_controller_patch'

      require_relative 'models/member_patch'
      require_relative 'models/user_patch'
      require_relative 'models/role_patch'
      require_relative 'models/project_patch'
      require_relative 'models/tracker_patch'
      require_relative 'models/issue_patch'

      if Redmine::Plugin.installed?(:redmine_organizations)
        require_relative 'models/organization_patch'
        require_relative 'controllers/organizations_memberships_controller_patch'
      end

      require_relative 'tests/test_helper_patch' if Rails.env.test?

    end
  end

end
