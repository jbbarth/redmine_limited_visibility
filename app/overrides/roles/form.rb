Deface::Override.new :virtual_path  => "roles/_form",
                     :name          => "add-role-default-behaviour-regarding-issue-visibility",
                     :insert_after  => "#permissions",
                     :partial       => "roles/limited_visibility"
