Deface::Override.new  :virtual_path  => "projects/copy",
                      :name          => "include-functions-when-copying",
                      :insert_after  => ".block:contains('@source_project.wiki.nil?')",
                      :text          => <<EOS
<label class="block"><%= check_box_tag 'only[]', 'functions', true, :id => nil %> <%= l(:label_functional_roles) %> (<%= @source_project.functions.count %>)</label>
EOS
