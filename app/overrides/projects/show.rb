Deface::Override.new :virtual_path => "projects/show",
                     :name => "add-member-box-by-function",
                     :replace => "erb[loud]:contains('members_box')",
                     :partial => "projects/members_box_by_function"
