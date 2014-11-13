Deface::Override.new :virtual_path => 'issues/show',
                     :name         => 'show-involved-roles-in-issue-description',
                     :insert_after => '.attributes',
                     :partial      => 'issues/show_involved_roles'
