Deface::Override.new :virtual_path => "projects/show",
                     :name => "add-member-box-by-function",
                     :replace => "erb[loud]:contains('members_box')",
                     :partial => "projects/members_box_by_function"

Deface::Override.new :virtual_path => "projects/show",
                     :insert_bottom => "div.members h3",
                     :name => "show-functions-activated-box",
                     :text => <<EOS
<%= link_to l(:label_open_functions_activated_description), '#', 
        class: 'icon-only icon-help', 
        style: "margin-top: -3px;margin-left: 4px;",
        title: l(:label_open_functions_activated_description),
        onclick: "showModal('functions_description', '500px'); return false;" %>
<%= render partial: 'projects/functions_description', locals: {functions: @project.functions.sorted} %>
EOS
