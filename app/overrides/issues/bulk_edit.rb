Deface::Override.new :virtual_path  => 'issues/bulk_edit',
                     :name          => 'add-authorized-viewers-to-issues-bulk-edit-form',
                     :insert_after  => ".splitcontent",
                     :partial       => 'issues/authorized_viewers_bulk_edit_form'
