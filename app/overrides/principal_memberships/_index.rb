Deface::Override.new :virtual_path  => "principal_memberships/_index",
                     :name          => "add-table-title-for-functional-roles",
                     :insert_before => "th:last",
                     :text          => '<th><%= l :label_functional_roles %></th>'

Deface::Override.new :virtual_path  => "principal_memberships/_index",
                     :name          => "add-functional-roles-to-current-memberships",
                     :insert_after  => "td.roles",
                     :partial       => 'principal_memberships/memberships_functions'
