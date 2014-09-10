if Redmine::Plugin.installed?(:redmine_organizations)
  Deface::Override.new :virtual_path    => 'projects/settings/_members_organization',
                       :name            => 'extend-roles-columns',
                       :set_attributes  => 'td#all_roles',
                       :attributes      => {:colspan => '3'}
  Deface::Override.new :virtual_path  => 'projects/settings/_members_organization',
                       :name          => 'add-visibility-roles-to-orga',
                       :insert_after  => 'span.role',
                       :partial       => 'projects/members_organization_visibility_roles'
  Deface::Override.new :virtual_path  => 'projects/settings/_members_organization',
                       :name          => 'add-roles-to-orga',
                       :replace       => 'span.role',
                       :partial       => 'projects/members_organization_roles'
end
