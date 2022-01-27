# empty the code of javascript and copy it again in the view authorized_viewers_form, because of it will be broken by Deface::Override
Deface::Override.new(:virtual_path  => 'issues/_form',
                     :name          => "empty_code_javascript",
                     :remove        => "erb[loud]:contains('javascript_tag')",
                     :closing_selector => "erb[silent]:contains('end')")
Deface::Override.new :virtual_path  => 'issues/_form',
                     :name          => 'add-authorized-viewers-in-issues-new',
                     :insert_before => "erb[silent]:contains(\"if @issue.safe_attribute? 'subject'\")",
                     :partial       => 'issues/authorized_viewers_form'
Deface::Override.new :virtual_path  => 'issues/_form_with_positions',
                     :name          => 'add-authorized-viewers-in-issues-new',
                     :insert_before => "erb[silent]:contains(\"if @issue.safe_attribute? 'subject'\")",
                     :partial       => 'issues/authorized_viewers_form'

Deface::Override.new :virtual_path  => 'issues/_form',
                     :name          => 'change-project-in-issues-new',
                     :replace       => "erb[loud]:contains(\"f.select :project_id,\")",
                     :partial       => "issues/select_project_field"
Deface::Override.new :virtual_path  => 'issues/_form_with_positions',
                     :name          => 'change-project-in-issues-new-with-positions',
                     :replace       => "erb[loud]:contains(\"f.select :project_id,\")",
                     :partial       => 'issues/select_project_field'

Deface::Override.new :virtual_path  => 'issues/_form',
                     :name          => 'change-tracker-in-issues-new',
                     :replace       => "erb[loud]:contains(\"f.select :tracker_id,\")",
                     :partial       => "issues/select_tracker_field"
Deface::Override.new :virtual_path  => 'issues/_form_with_positions',
                     :name          => 'change-tracker-in-issues-new-with-positions',
                     :replace       => "erb[loud]:contains(\"f.select :tracker_id,\")",
                     :partial       => 'issues/select_tracker_field'
