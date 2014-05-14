Deface::Override.new :virtual_path  => 'projects/settings/_members',
                     :name          => 'add-visibility-roles-to-orga',
                     :insert_after  => 'th.role',
                     :text       => '<th><%= l("label_visibility_by_role") %></th>'
