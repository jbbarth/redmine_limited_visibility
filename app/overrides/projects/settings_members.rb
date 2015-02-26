if Redmine::Plugin.installed?(:redmine_organizations)
  Deface::Override.new :virtual_path  => 'projects/settings/_members',
                       :original      => 'd1b4a2c2eb5c61a65fad04c1fe810bd8006c2736',
                       :name          => 'replace-technical-roles-title',
                       :replace       => 'th.role',
                       :text          => '<th class="permission_roles"><%= l("label_technical_role_plural") %></th>'
  Deface::Override.new :virtual_path  => 'projects/settings/_members',
                       :original      => 'd1b4a2c2eb5c61a65fad04c1fe810bd8006c2736',
                       :name          => 'add-visibility-roles-to-orga',
                       :replace       => 'th.buttons',
                       :text          => '<th class="visibility_roles"><%= l("label_functional_roles") %></th><th class="users"> </th><th class="visibility_buttons"> </th>'
end
