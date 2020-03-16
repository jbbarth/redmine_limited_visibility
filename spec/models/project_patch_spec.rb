require 'spec_helper'

describe Project do

  fixtures :users, :roles, :projects, :members, :member_roles, :issues, :issue_statuses,
           :trackers, :enumerations, :custom_fields, :enabled_modules

  if Redmine::Plugin.installed?(:redmine_organizations)
    fixtures :organizations, :organization_functions, :organization_roles


    it 'copy_members with organizations' do
      @source_project = Project.find(1)
      expect(@source_project.organization_functions).to_not be_empty
      @project = Project.new(:name => 'Copy Test', :identifier => 'copy-test')

      expect(@project.valid?).to be true
      expect(@project.members).to be_empty
      expect(@project.organization_functions).to be_empty

      # COPY!
      expect(@project.copy(@source_project)).to be true

      expect(@project.memberships.size).to eq @source_project.memberships.size
      expect(@project.organization_functions.size).to eq @source_project.organization_functions.size
      expect(@project.organization_roles.size).to eq @source_project.organization_roles.size

      @project.memberships.each do |membership|
        assert membership
        assert_equal @project, membership.project
      end
    end

  end
end
