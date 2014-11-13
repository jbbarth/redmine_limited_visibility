Deface::Override.new :virtual_path  => 'roles/index',
                     :name          => 'replace_technical_roles_title',
                     :replace       => 'h2',
                     :text          => '<h2><%=l(:label_technical_role_plural)%></h2>'
Deface::Override.new :virtual_path  => 'roles/index',
                     :name          => 'surround_index_roles',
                     :insert_after  => '.pagination',
                     :partial       => 'functions/index'
