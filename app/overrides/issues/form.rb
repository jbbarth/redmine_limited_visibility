Deface::Override.new :virtual_path  => 'issues/_form',
                     :name          => 'add-authorized-viewers-in-issues-new',
                     :insert_before => "erb[silent]:contains(\"if @issue.safe_attribute? 'subject'\")",
                     :partial       => 'issues/authorized_viewers_form'
Deface::Override.new :virtual_path  => 'issues/_form_with_positions',
                     :name          => 'add-authorized-viewers-in-issues-new',
                     :insert_before => "erb[silent]:contains(\"if @issue.safe_attribute? 'subject'\")",
                     :partial       => 'issues/authorized_viewers_form'
