# Custom patches
require_relative 'lib/redmine_limited_visibility/hooks'

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
