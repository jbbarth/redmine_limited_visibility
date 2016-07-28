# Plugin registration
Redmine::Plugin.register :redmine_limited_visibility do
  name 'Redmine Limited Visibility plugin'
  author 'Jean-Baptiste BARTH'
  description 'This is a plugin for Redmine'
  requires_redmine :version_or_higher => '3.3.0'
  version '3.3.0'
  url 'https://github.com/jbbarth/redmine_limited_visibility'
  author_url 'jeanbaptiste.barth@gmail.com'
  requires_redmine_plugin :redmine_base_rspec, :version_or_higher => '0.0.4' if Rails.env.test?
  requires_redmine_plugin :redmine_base_deface, :version_or_higher => '0.0.1'
  project_module :limited_visibility do
    permission :manage_functional_roles_by_project, {:functions => [:available_functions_per_project]}
    permission :limit_issues_visibility, {  }
  end
  settings :default => { 'must_have_at_least_one_visible_function' => false},
           :partial => 'settings/redmine_plugin_limited_visibility'
end

# Custom patches
require_dependency 'redmine_limited_visibility/hooks'
Rails.application.config.to_prepare do
  unless Rails.env.test? #Avoid breaking core tests (specially csv core tests including ALL columns)
    require_dependency 'redmine_limited_visibility/queries_helper_patch'
    require_dependency 'redmine_limited_visibility/issue_query_patch'
    require_dependency 'redmine_limited_visibility/my_controller_patch'
  end
  require_dependency 'redmine_limited_visibility/issue_patch'
  require_dependency 'redmine_limited_visibility/issues_helper_patch'
  require_dependency 'redmine_limited_visibility/issues_pdf_helper_patch'
  require_dependency 'redmine_limited_visibility/roles_controller_patch'
  require_dependency 'redmine_limited_visibility/issues_controller_patch'
  require_dependency 'redmine_limited_visibility/member_patch'
  require_dependency 'redmine_limited_visibility/user_patch'
  if Redmine::Plugin.installed?(:redmine_organizations)
    require_dependency 'redmine_limited_visibility/organization_patch'
    require_dependency 'redmine_limited_visibility/project_patch'
    require_dependency 'redmine_limited_visibility/organizations_controller_patch'
  end
end
