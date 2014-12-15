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
