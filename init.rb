# Plugin registration
Redmine::Plugin.register :redmine_limited_visibility do
  name 'Redmine Limited Visibility plugin'
  author 'Jean-Baptiste BARTH'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url 'https://github.com/jbbarth/redmine_limited_visibility'
  author_url 'jeanbaptiste.barth@gmail.com'
  requires_redmine_plugin :redmine_base_rspec, :version_or_higher => '0.0.1' if Rails.env.test?
  requires_redmine_plugin :redmine_base_deface, :version_or_higher => '0.0.1'
end

# Custom patches
require_dependency 'redmine_limited_visibility/hooks'
Rails.application.config.to_prepare do
  require_dependency 'redmine_limited_visibility/issue_patch'
  require_dependency 'redmine_limited_visibility/queries_helper_patch' unless Rails.env.test?
  require_dependency 'redmine_limited_visibility/issue_query_patch' unless Rails.env.test?
  require_dependency 'redmine_limited_visibility/issues_helper_patch'
  require_dependency 'redmine_limited_visibility/roles_controller_patch'
  require_dependency 'redmine_limited_visibility/my_controller_patch'
  require_dependency 'redmine_limited_visibility/member_patch'
  require_dependency 'redmine_limited_visibility/user_patch'
  if Redmine::Plugin.installed?(:redmine_organizations)
    require_dependency 'redmine_limited_visibility/organizations_controller_patch'
  end
end
