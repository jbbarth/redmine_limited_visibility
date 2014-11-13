if Redmine::Plugin.installed?(:redmine_organizations)
  Deface::Override.new :virtual_path  => 'projects/settings/_members',
                       :original      => 'd1b4a2c2eb5c61a65fad04c1fe810bd8006c2736',
                       :name          => 'replace-technical-roles-title',
                       :replace       => 'th.role',
                       :text          => '<th class="role"><%= l("label_technical_role_plural") %></th>'
  Deface::Override.new :virtual_path  => 'projects/settings/_members',
                       :original      => 'd1b4a2c2eb5c61a65fad04c1fe810bd8006c2736',
                       :name          => 'add-visibility-roles-to-orga',
                       :insert_after  => 'th.role',
                       :text          => '<th class="role"><%= l("label_visibility_roles") %></th>'
end
