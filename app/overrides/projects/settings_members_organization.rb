Deface::Override.new :virtual_path  => 'projects/settings/_members_organization',
                     :name          => 'add-visibility-roles-to-orga',
                     :insert_after  => 'td.role',
                     :partial       => 'projects/members_organization_visibility_roles'

Deface::Override.new :virtual_path  => 'projects/settings/_members_organization',
                     :name          => 'add-roles-to-orga',
                     :replace       => 'td.role',
                     :partial       => 'projects/members_organization_roles'
