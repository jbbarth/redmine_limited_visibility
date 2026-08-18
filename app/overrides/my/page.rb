override =   %(
    <%= if params[:limited_visibility].present? && params[:limited_visibility] == 'false'
          link_to sprite_icon('eye', l(:label_my_page_my_roles), plugin: 'redmine_limited_visibility'), my_page_path,
                :class => "icon icon-visibility",
                :id => "show_all_roles"
        else
          link_to sprite_icon('eye', l(:label_my_page_all_roles), plugin: 'redmine_limited_visibility'), my_page_path(:limited_visibility => false),
                :class => "icon icon-visibility",
                :id => "show_all_roles"
        end %>
  )

Deface::Override.new :virtual_path  => "my/page",
                     :name          => "add-roles_selection-to-my-page",
                     :insert_top    => "div.contextual",
                     :text          => override

Deface::Override.new :virtual_path  => "my/custom_page",
                     :name          => "add-roles_selection-to-my-custom-page",
                     :insert_top    => "div.contextual",
                     :text          => override
