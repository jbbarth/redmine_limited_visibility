Deface::Override.new :virtual_path  => 'roles/_form',
                     :name          => 'surround_permissions_title',
                     :surround      => 'h3',
                     :text          => '<div id="permissions_tab_title" class="permissions_tab"> <%= render_original %> </div>'
Deface::Override.new :virtual_path  => 'roles/_form',
                     :name          => 'surround_permissions_form',
                     :surround      => '#permissions',
                     :text          => '<div id="permissions_tab_form" class="permissions_tab"> <%= render_original %> </div>'
Deface::Override.new :virtual_path  => 'roles/_form',
                     :name          => 'add_managed_functions_selection',
                     :replace       => 'p.manage_members_shown',
                     :partial       => 'roles/managed_roles_and_functions'
