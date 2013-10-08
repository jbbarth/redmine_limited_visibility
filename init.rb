# Plugin registration
Redmine::Plugin.register :redmine_limited_visibility do
  name 'Redmine Limited Visibility plugin'
  author 'Jean-Baptiste BARTH'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url 'https://github.com/jbbarth/redmine_limited_visibility'
  author_url 'jeanbaptiste.barth@gmail.com'
end

# Custom patches
Rails.application.config.to_prepare do
  require_dependency 'redmine_limited_visibility/issue_patch'
end
