# Plugin registration
Redmine::Plugin.register :redmine_limited_visibility do
  name 'Redmine Limited Visibility plugin'
  author 'Jean-Baptiste BARTH'
  description 'This is a plugin for Redmine'
  requires_redmine :version_or_higher => '3.3.0'
  version '4.1.0'
  url 'https://github.com/jbbarth/redmine_limited_visibility'
  author_url 'jeanbaptiste.barth@gmail.com'
  requires_redmine_plugin :redmine_base_rspec, :version_or_higher => '0.0.4' if Rails.env.test?
  requires_redmine_plugin :redmine_base_deface, :version_or_higher => '0.0.1'
  permission :manage_functional_roles_by_project, {:functions => [:available_functions_per_project]}
  project_module :limited_visibility do
    permission :change_issues_visibility, {  }
    permission :see_issues_visibility, {  }
    permission :use_issues_visibility_filter, {  }
  end
  settings :default => { 'must_have_at_least_one_visible_function' => false},
           :partial => 'settings/redmine_plugin_limited_visibility'
end

# Custom patches
require_dependency 'redmine_limited_visibility/hooks'
ActiveSupport::Reloader.to_prepare do
  unless Rails.env.test? #Avoid breaking core tests (specially csv core tests including ALL columns)
    require_dependency 'redmine_limited_visibility/helpers/queries_helper_patch'
    require_dependency 'redmine_limited_visibility/models/issue_query_patch'
    require_dependency 'redmine_limited_visibility/controllers/my_controller_patch'
  end
  require_dependency 'redmine_limited_visibility/models/issue_patch'
  require_dependency 'redmine_limited_visibility/helpers/issues_helper_patch'
  require_dependency 'redmine_limited_visibility/helpers/issues_pdf_helper_patch'
  require_dependency 'redmine_limited_visibility/helpers/projects_helper_patch'
  require_dependency 'redmine_limited_visibility/controllers/roles_controller_patch'

  require_dependency 'redmine_limited_visibility/controllers/issues_controller_patch'

  require_dependency 'redmine_limited_visibility/controllers/members_controller_patch'
  require_dependency 'redmine_limited_visibility/models/member_patch'

  require_dependency 'redmine_limited_visibility/models/user_patch'
  require_dependency 'redmine_limited_visibility/models/role_patch'
  require_dependency 'redmine_limited_visibility/models/project_patch'

  if Redmine::Plugin.installed?(:redmine_organizations)
    require_dependency 'redmine_limited_visibility/models/organization_patch'
    require_dependency 'redmine_limited_visibility/controllers/organizations_memberships_controller_patch'
  end
end
