Deface::Override.new :virtual_path  => "my/page",
                     :name          => "add-roles_selection-to-my-page",
                     :original      => "bc6ae6262eef79aab70c151bfacde1eb8e66512f",
                     :insert_top    => "div.contextual" do
  %(
    <%= link_to l(:label_my_page_all_roles), new_reminder_path(:back_url => my_page_path),
                :class => "icon icon-roles",
                :id => "show_all_roles" %>
  )
end
