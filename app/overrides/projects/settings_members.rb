if Redmine::Plugin.installed?(:redmine_organizations)

  # TABLE HEADERS
  Deface::Override.new :virtual_path => 'projects/settings/_members',
                       :original => 'd1b4a2c2eb5c61a65fad04c1fe810bd8006c2736',
                       :name => 'replace-technical-roles-title',
                       :replace => 'erb[loud]:contains("l(:label_role_plural)")',
                       :text => '<%= l("label_technical_role_plural") %>'
  Deface::Override.new :virtual_path => 'projects/settings/_members',
                       :original => 'd1b4a2c2eb5c61a65fad04c1fe810bd8006c2736',
                       :name => 'add-visibility-roles-header',
                       :insert_after => 'th.roles',
                       :text => '<th class="visibility_roles"><%= l("label_functional_roles") %></th>'
  Deface::Override.new :virtual_path  => 'projects/settings/_members',
                       :insert_after  => "erb[loud]:contains('delete_link membership_path')",
                       :name          => "show-functions-activated-box",
                       :text          => <<EOS
<%= content_tag 'a', l(:label_open_functions_activated_description), :class => 'icon-only icon-help', :title => l(:label_open_functions_activated_description), :onclick => "showModal('functions_description', '500px'); return false;", :href => '#' %>
<%= render partial: 'projects/functions_description', locals: {functions: @project.functions.sort_by(&:name)} %>
EOS
 
  # Members roles
  Deface::Override.new :virtual_path => 'projects/settings/_members',
                       :name => 'add-visibility-roles-to-members',
                       :insert_after => 'td.roles',
                       :text => <<FUNCTIONS
<% if defined?(member) && member %>
  <td class="visibility_roles member-<%= member.id %>-roles">
    <% user_functions = member.functions.sorted.uniq %>
    <% if user_functions.any? %>
      <%= user_functions.collect(&:to_s).join(", ") %>
    <% else %>
      <span class="undefined"><%= l("undefined") %></span>
    <% end %>
  </td>
<% else %>
  <td class="visibility_roles organization-<%= organization.id %>-roles">
    <% organization_functions = organization.default_functions_by_project(@project) %>
    <% if organization_functions.any? %>
      <%= organization_functions.collect(&:to_s).join(", ") %>
    <% else %>
      <span class="see_everything"><%= l("see_everything") %></span>
    <% end %>
  </td>
<% end %>
FUNCTIONS

end
