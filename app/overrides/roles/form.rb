Deface::Override.new :virtual_path  => 'roles/_form',
                     :name          => 'surround_permissions_title',
                     :surround      => 'h3',
                     :text          => '<div id="permissions_tab_title" class="permissions_tab"> <%= render_original %> </div>'
Deface::Override.new :virtual_path  => 'roles/_form',
                     :name          => 'surround_permissions_form',
                     :surround      => '#permissions',
                     :text          => '<div id="permissions_tab_form" class="permissions_tab"> <%= render_original %> </div>'

Deface::Override.new :virtual_path  => 'roles/_form',
                     :name          => 'add_checkbox_to_set_limit_visibility_role',
                     :insert_bottom => '.box.tabular:not([id*=permissions])',
                     :text          => '<p><%= f.check_box :limit_visibility, :checked => (@role.limit_visibility || params[:type]=="visibility") %></p>'

Deface::Override.new :virtual_path  => 'roles/_form',
                     :name          => 'add-role-default-behaviour-regarding-issue-visibility',
                     :insert_after  => '#permissions_tab_form',
                     :partial       => 'roles/limited_visibility'
