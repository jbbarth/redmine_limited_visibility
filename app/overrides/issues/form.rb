Deface::Override.new :virtual_path  => 'issues/_form',
                     :name          => 'add-authorized-viewers-in-issues-new',
                     :insert_after  => '.attributes',
                     :partial       => 'issues/authorized_viewers_form'
