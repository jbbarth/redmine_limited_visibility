class AddVisibilityToIssueTemplates < ActiveRecord::Migration[5.2]
  def change
    if Redmine::Plugin.installed?(:redmine_templates)
      add_column :issue_template_projects, :visibility, :string unless column_exists?(:issue_template_projects, :visibility)
    end
  end
end
