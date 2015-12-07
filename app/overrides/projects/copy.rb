Deface::Override.new  :virtual_path  => "projects/copy",
                      :name          => "include-functions-when-copying",
                      :insert_before => "erb[loud]:contains('hidden_field_tag')",
                      :partial       => "projects/copy_functions"
