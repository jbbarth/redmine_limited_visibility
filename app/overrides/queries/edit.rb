Deface::Override.new  :virtual_path  => "queries/edit",
                      :name          => "Add-id-to-edit-query-form",
                      :replace       => "erb[loud]:contains('form_tag')",
                      :text          => <<eos
<%= form_tag(query_path(@query), :onsubmit => 'selectAllOptions("selected_columns");', :method => :put, :id=>'query_form') do %>
eos
