Deface::Override.new :virtual_path  => 'roles/permissions',
                     :name          => 'override-list-of-roles',
                     :original      => '52718ca0e9b7f8b690d1a1b10f2310bd91c882a8',
                     :insert_before => 'table.list.permissions',
                     :text          => '<% @roles = Role.permission_roles.sorted.all %>'
