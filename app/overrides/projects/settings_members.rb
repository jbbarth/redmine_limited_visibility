if Redmine::Plugin.installed?(:redmine_organizations)

  # TABLE HEADERS
  Deface::Override.new :virtual_path  => 'projects/settings/_members',
                       :original      => 'd1b4a2c2eb5c61a65fad04c1fe810bd8006c2736',
                       :name          => 'replace-technical-roles-title',
                       :replace       => 'erb[loud]:contains("l(:label_role_plural)")',
                       :text          => '<%= l("label_technical_role_plural") %>'
  Deface::Override.new :virtual_path  => 'projects/settings/_members',
                       :original      => 'd1b4a2c2eb5c61a65fad04c1fe810bd8006c2736',
                       :name          => 'add-visibility-roles-header',
                       :insert_before => 'table.list.members th:last',
                       :text          => '<th class="visibility_roles"><%= l("label_functional_roles") %></th>'

  # Members roles
  Deface::Override.new :virtual_path  => 'projects/settings/_members',
                       :name          => 'add-visibility-roles-to-members',
                       :insert_after  => 'td.roles',
                       :text       => '<td class="visibility_roles">
                                        <% if defined?(member) && member %>
                                          <span class="member-<%= member.id %>-roles">
                                            <% user_functions = member.functions.sorted.uniq %>
                                            <% if user_functions.any? %>
                                              <%= user_functions.collect(&:to_s).join(", ") %>
                                            <% else %>
                                              <span class="undefined"><%= l("undefined") %></span>
                                            <% end %>
                                          </span>
                                          <div id="member-<%= member.id %>-visibility-form"></div>
                                        <% elsif organization %>
                                          <% organization_functions = organization.default_functions_by_project(@project) %>
                                          <span class="organization-<%= organization.id %>-roles">
                                            <% if organization_functions.any? %>
                                              <%= organization_functions.collect(&:to_s).join(", ") %>
                                            <% else %>
                                              <span class="see_everything"><%= l("see_everything") %></span>
                                            <% end %>
                                          </span>
                                          <div id="organization-<%= organization.id %>-visibility-form"></div>
                                        <% end %>
                                      </td>'
end
