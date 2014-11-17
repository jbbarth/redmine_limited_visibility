if Redmine::Plugin.installed?(:redmine_organizations)
  Deface::Override.new :virtual_path    => 'projects/settings/_members_user',
                       :name            => 'extend-roles-columns',
                       :set_attributes  => 'td#all_roles',
                       :attributes      => {:colspan => '3'}
  Deface::Override.new :virtual_path  => 'projects/settings/_members_user',
                       :name          => 'add-visibility-roles-to-orga',
                       :insert_after  => 'div.role',
                       :partial       => 'projects/user/members_organization_visibility_roles'
  Deface::Override.new :virtual_path  => 'projects/settings/_members_user',
                       :name          => 'add-roles-to-orga',
                       :replace       => 'div.role',
                       :partial       => 'projects/user/members_organization_roles'
  Deface::Override.new :virtual_path  => 'projects/settings/_members_user',
                       :name          => 'refactor_list_of_roles_in_form',
                       :replace       => 'div.roles_checkboxes',
                       :partial       => 'projects/user/form_members_roles'
end
