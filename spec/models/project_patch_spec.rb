require 'spec_helper'

describe Project do

  fixtures :users, :roles, :projects, :members, :member_roles, :issues, :issue_statuses,
            :trackers, :enumerations, :custom_fields, :enabled_modules, :project_functions,
            :organization_functions, :project_function_trackers

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

      @project.memberships.each do |membership|
        assert membership
        assert_equal @project, membership.project
      end
    end

  end

  describe "Update the relationship tables in case of cascade deleting" do
    let(:project) { Project.find(1) }
    let(:function) { Function.find(1) }
    let(:member) { Member.find(1) }
    let(:tracker) { Tracker.find(1) }

    before do
      fun_mem = MemberFunction.new
      fun_mem.member = project.members.first
      fun_mem.function = project.functions.first
      fun_mem.save
      fun_mem = MemberFunction.new
      fun_mem.member = project.members.first
      fun_mem.function = project.functions.second
      fun_mem.save
    end

    it "when deleting a project" do
      expect do
        project.destroy
      end.to change { OrganizationFunction.count }.by(-2)
      .and change { OrganizationRole.count }.by(-2)
      .and change { MemberFunction.count }.by(-2)
      .and change { ProjectFunction.count }.by(-2)
      .and change { ProjectFunctionTracker.count }.by(-4)
    end

    it "when deleting a function" do
      expect do
        function.destroy
      end.to change { OrganizationFunction.count }.by(-1)
      .and change { ProjectFunction.count }.by(-1)
      .and change { MemberFunction.count }.by(-1)
      .and change { ProjectFunctionTracker.count }.by(-2)
    end

    it "when deleting a tracker" do
      # Create tracker without issue, so we delete it
      tracker_test = Tracker.create(name: 'Tracker test', position: 4, default_status_id: 1)
      ProjectFunctionTracker.create(project_function_id: 1,  tracker_id:tracker_test.id, visible: false, checked: false)
      ProjectFunctionTracker.create(project_function_id: 2,  tracker_id:tracker_test.id, visible: false, checked: false)
      expect do
        tracker_test.destroy
      end.to change { ProjectFunctionTracker.count }.by(-2)
    end

    it "when deleting a member" do
      expect do
        member.destroy
      end.to change { MemberFunction.count }.by(-2)
    end

    if Redmine::Plugin.installed?(:redmine_organizations)
      it "when deleting a organization" do
        organization =  Organization.find(1)
        expect do
          organization.destroy
        end.to change { OrganizationFunction.count }.by(-1)
        .and change { OrganizationRole.count }.by(-1)
      end
    end
  end
end
