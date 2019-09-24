FIELDSET_WITH_FUNCTIONS = <<FIELDSET_WITH_FUNCTIONS
<fieldset class="box">
<legend><%= toggle_checkboxes_link('.functions-selection input') %><%= l(:label_functional_roles) %></legend>
  <div class="functions-selection">
    <% User.current.managed_functions(@project).each do |function| %>
      <label><%= check_box_tag 'membership[function_ids][]', function.id, false, :id => nil %> <%= function %></label>
    <% end %>
  </div>
</fieldset>
FIELDSET_WITH_FUNCTIONS

Deface::Override.new :virtual_path  => 'members/_new_form',
                     :name          => 'add-functions-to-new-members-form',
                     :insert_after  => "fieldset:contains('membership[role_ids][]')",
                     :text       => FIELDSET_WITH_FUNCTIONS

Deface::Override.new :virtual_path  => 'organizations/memberships/_new_form',
                     :name          => 'add-functions-to-new-orga-members-form',
                     :insert_after  => "fieldset:contains('membership[role_ids][]')",
                     :text       => FIELDSET_WITH_FUNCTIONS

Deface::Override.new :virtual_path => 'members/_new_form',
                     :name => "filter_new_members_by_organization",
                     :replace => "erb[loud]:contains(\"render_principals_for_new_members(@project)\")",
                     :text => <<EOF
<%
   if User.current.managed_only_his_organization?(@project)
     organization = User.current.organization
   else
     organization = nil
   end
%>
<%= render_principals_for_new_members(@project, 100, organization) %>
EOF
