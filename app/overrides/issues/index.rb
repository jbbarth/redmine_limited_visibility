Deface::Override.new :virtual_path  => "issues/index",
                     :name          => "hide-authorized-viewers-filter",
                     :insert_after  => "erb[loud]:contains('view_issues_index_bottom')",
                     :partial       => "issues/hide_authorized_viewers_filter"
