Deface::Override.new :virtual_path      => 'issues/_attributes',
                     :name              => 'show-functional-roles-in-assignable-select',
                     :replace           => "erb[silent]:contains(\"if @issue.safe_attribute? 'assigned_to_id'\")",
                     :closing_selector  => "erb[silent]:contains(\"end\")",
                     :partial           => 'issues/assign_to_select_box'
