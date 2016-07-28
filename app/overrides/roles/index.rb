# Deface is not working well with double quoted erb strings inside double quoted HTML strings... Had to replace "builtin" by 'builtin' in this piece of code from core file
Deface::Override.new :virtual_path  => 'roles/index',
                     :name          => 'replace_technical_roles_double_quotes',
                     :replace_contents       => "tbody",
                     :text => <<COPY_FROM_CORE_INDEX_VIEW
<% for role in @roles %>
  <tr class="<%= cycle("odd", "even") %> <%= role.builtin? ? 'builtin' : 'givable' %>">
    <td class="name"><%= content_tag(role.builtin? ? 'em' : 'span', link_to(role.name, edit_role_path(role))) %></td>
    <td class="buttons">
      <%= reorder_handle(role) unless role.builtin? %>
      <%= link_to l(:button_copy), new_role_path(:copy => role), :class => 'icon icon-copy' %>
      <%= delete_link role_path(role) unless role.builtin? %>
    </td>
  </tr>
<% end %>
COPY_FROM_CORE_INDEX_VIEW

Deface::Override.new :virtual_path  => 'roles/index',
                     :name          => 'replace_technical_roles_title',
                     :replace       => 'h2',
                     :text          => '<h2><%=l(:label_technical_role_plural)%></h2>'
Deface::Override.new :virtual_path  => 'roles/index',
                     :name          => 'surround_index_roles',
                     :insert_before  => "erb[silent]:contains('html_title')",
                     :partial       => 'functions/index'
