class AddVisibilityToIssueTemplates < ActiveRecord::Migration[5.2]
  def change
    if Redmine::Plugin.installed?(:redmine_templates) &&
      table_exists?(:issue_template_projects) &&
      !column_exists?(:issue_template_projects, :visibility)

      add_column :issue_template_projects, :visibility, :string

    end
  end
end
