Deface::Override.new :virtual_path => 'issues/show',
                     :name         => 'show-involved-roles-in-issue-description',
                     :insert_after => '.attributes',
                     :partial      => 'issues/show_involved_roles'

Deface::Override.new :virtual_path => 'issues/show',
                     :name => "add-assign-to-function-field",
                     :insert_before => "erb[loud]:contains(\"rows.left l(:field_assigned_to)\")",
                     :text => <<EOF
<%=
issue_fields_rows do |rows|
  if @issue.assigned_to_function_id.present?
    rows.left l(:field_assigned_to_function), Function.where("id = ?", @issue.assigned_to_function_id).first.name, :class => 'assigned-to'
  end
end
%>
EOF
