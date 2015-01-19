Deface::Override.new :virtual_path  => "users/_memberships",
                     :name          => "add-functional-roles-to-new-memberships",
                     :insert_before => "erb[loud]:contains('submit_tag')",
                     :text          => <<eos
                      <% functions = Function.sorted.all %>
                      <p><%= l(:label_visibility_roles) %>:
                      <% functions.each do |function| %>
                        <label><%= check_box_tag 'membership[function_ids][]', function.id, false, :id => nil %> <%=h function %></label>
                      <% end %></p>
eos

Deface::Override.new :virtual_path  => "users/_memberships",
                     :name          => "add-table-title-for-functional-roles",
                     :insert_before => "th:last",
                     :original      => '0d5041d1f9ab03cafbc2e51905fdbd13944bfbbe',
                     :text          => '<th><%= l :label_visibility_roles %></th>'
Deface::Override.new :virtual_path  => "users/_memberships",
                     :name          => "add-functional-roles-to-current-memberships",
                     :original      => '0d5041d1f9ab03cafbc2e51905fdbd13944bfbbe',
                     :insert_after  => "td.roles",
                     :partial       => 'users/memberships_functions'
