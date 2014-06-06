if Redmine::Plugin.installed?(:redmine_organizations)
  Deface::Override.new :virtual_path  => 'projects/settings/_members',
                       :original      => 'd1b4a2c2eb5c61a65fad04c1fe810bd8006c2736',
                       :name          => 'add-visibility-roles-to-orga',
                       :insert_after  => 'th.role',
                       :text          => '<th><%= l("label_visibility_by_role") %></th>'
  # Separate two kinds of roles
  Deface::Override.new :virtual_path  => 'projects/settings/_members',
                       :original      => 'd1b4a2c2eb5c61a65fad04c1fe810bd8006c2736',
                       :name          => 're_organise-roles-for-orga',
                       :insert_after  => 'erb[silent]:contains("roles = Role.find_all_givable")',
                       :text          => '<% roles = Role.find_all_permission_roles %>'

  Deface::Override.new :virtual_path  => 'projects/settings/_members',
                       :original      => 'd1b4a2c2eb5c61a65fad04c1fe810bd8006c2736',
                       :name          => 're_organise-visibility-roles-for-orga',
                       :insert_before => 'erb[loud]:contains("submit_tag")',
                       :text          => <<-eos
                                          <% visibility_roles = Role.find_all_visibility_roles %>
                                          <BR>Visibility roles:
                                          <% visibility_roles.each do |role| %>
                                            <label><%= check_box_tag "membership[role_ids][]", role.id %> <%=h role %></label>
                                          <% end %>'
                                          eos
end
