Deface::Override.new :virtual_path  => "my/page",
                     :name          => "add-roles_selection-to-my-page",
                     :original      => "bc6ae6262eef79aab70c151bfacde1eb8e66512f",
                     :insert_top    => "div.contextual" do
  %(
    <%= if params[:limited_visibility].present? && params[:limited_visibility] == 'false'
          link_to l(:label_my_page_my_roles), my_page_path,
                :class => "icon icon-roles",
                :id => "show_all_roles"
        else
          link_to l(:label_my_page_all_roles), my_page_path(:limited_visibility => false),
                :class => "icon icon-roles",
                :id => "show_all_roles"
        end %>
  )
end
