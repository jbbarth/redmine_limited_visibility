Deface::Override.new  :virtual_path  => "queries/new",
                      :name          => "Add-id-to-new-query-form",
                      :replace       => "erb[loud]:contains('form_tag')",
                      :text          => <<eos
<%= form_tag(@project ? project_queries_path(@project) : queries_path, :onsubmit => 'selectAllOptions("selected_columns");', :id=>'query_form') do %>
eos
