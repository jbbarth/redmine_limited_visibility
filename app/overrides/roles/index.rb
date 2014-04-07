Deface::Override.new :virtual_path  => "roles/index",
                     :name          => "surround_index_roles",
                     :insert_after  => ".pagination",
                     :partial       => "roles/index"
