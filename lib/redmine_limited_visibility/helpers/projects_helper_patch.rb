require_dependency 'projects_helper'

module ProjectsHelper

  unless instance_methods.include?(:project_settings_tabs_with_limited_visibility)
    def project_settings_tabs_with_limited_visibility
      tabs = project_settings_tabs_without_limited_visibility
      available_functions = {name: 'functional_roles', action: :functional_roles, partial: 'projects/settings_functional_roles_tab', label: :label_functional_roles}
      tabs << available_functions if ( User.current.admin? || User.current.allowed_to?(:manage_functional_roles_by_project, @project) )
      tabs
    end
    alias_method_chain :project_settings_tabs, :limited_visibility
  end

end
