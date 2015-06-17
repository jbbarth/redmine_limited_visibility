Deface::Override.new :virtual_path  => "principal_memberships/_index",
                     :name          => "add-table-title-for-functional-roles",
                     :insert_before => "th:last",
                     :original      => '0d5041d1f9ab03cafbc2e51905fdbd13944bfbbe',
                     :text          => '<th><%= l :label_functional_roles %></th>'

Deface::Override.new :virtual_path  => "principal_memberships/_index",
                     :name          => "add-functional-roles-to-current-memberships",
                     :original      => '0d5041d1f9ab03cafbc2e51905fdbd13944bfbbe',
                     :insert_after  => "td.roles",
                     :partial       => 'principal_memberships/memberships_functions'
