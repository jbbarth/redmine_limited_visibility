Deface::Override.new  :virtual_path  => "projects/copy",
                      :name          => "include-functions-when-copying",
                      :insert_after  => ".block:contains('@source_project.wiki.nil?')",
                      :text          => <<EOS
<label class="block"><%= check_box_tag 'only[]', 'functions', true, :id => nil %> <%= l(:label_functional_roles) %> (<%= @source_project.functions.count %>)</label>
<script>
  //disable it when member option not selected
  $("input[value='members']").change(function() {
    if ($(this).is(':checked')) {
      $("input[value='functions_organizations_of_members']").prop( "disabled", false );
    } else {
      $("input[value='functions_organizations_of_members']").prop( "disabled", true );
      $("input[value='functions_organizations_of_members']").prop( "checked", false );
    }
  });
</script>
EOS
if Redmine::Plugin.installed?(:redmine_organizations)
  Deface::Override.new  :virtual_path  => "projects/copy",
                      :name          => "copy-projects-functions_organizations_of_members",
                      :insert_after  => ".block:contains('@source_project.members.count')",
                      :text          => <<EOS
    <label class="block"><%= check_box_tag 'only[]', 'functions_organizations_of_members', true, :id => nil %> <%= l(:label_functions_organizations_of_members) %></label>
EOS
else
  Deface::Override.new  :virtual_path  => "projects/copy",
                    :name          => "copy-projects-functions_organizations_of_members",
                    :insert_after  => ".block:contains('@source_project.members.count')",
                    :text          => <<EOS
  <label class="block"><%= check_box_tag 'only[]', 'functions_organizations_of_members', true, :id => nil %> <%= l(:label_functions_of_members) %></label>
EOS
end

