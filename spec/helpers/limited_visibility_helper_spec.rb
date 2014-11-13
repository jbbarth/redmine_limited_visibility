require 'spec_helper'

describe LimitedVisibilityHelper do

  # TODO Add fixtures for member_functions
  fixtures :users, :roles, :projects, :members, :member_roles, :enabled_modules, :issues

  before do
    User.current = User.find(1)
    @project = Project.first
    @membership = Member.new(user_id: User.current.id, project_id: @project.id)
    @membership.functions << contractor_role
    @membership.roles << Role.first
    @membership.save!
    User.current.member_of?(@project).should be true
  end

  let(:contractor_role) { Function.where(name: "Contractors").first_or_create }
  let(:project_office_role) { Function.where(name: "Project Office").first_or_create }

  describe 'functional_roles_for_current_user' do
    it 'should retrieve functional roles for current user' do
      functional_roles_for_current_user(@project).should_not be_nil
      functional_roles_for_current_user(@project).should include contractor_role
      functional_roles_for_current_user(@project).should_not include project_office_role
    end

    it "should return an empty array if current user doesn't have any membership on current project" do
      User.current = User.find(6) #not member of @project
      functional_roles_for_current_user(@project).should == []
    end
  end

  describe "#function_ids_for_current_viewers" do
    context "with a new issue" do
      let(:issue) { Issue.new(:project => @project) }

      it "returns all functional roles if current user cannot see anything" do
        function1 = contractor_role.id
        function2 = project_office_role.id
        allow(self).to receive(:functional_roles_for_current_user).and_return([])
        function_ids_for_current_viewers(issue).should == [function1,function2]
      end

      it "returns functional roles for current user if any" do
        dummy_role = stub_model(Function, :authorized_viewers => "|88|")
        allow(self).to receive(:functional_roles_for_current_user).and_return([dummy_role])
        function_ids_for_current_viewers(issue).should == [88]
      end
    end

    context "with an existing issue" do
      let(:issue) { Issue.first }

      it "returns authorized viewers if any" do
        allow(issue).to receive(:authorized_viewers).and_return("|9|")
        function_ids_for_current_viewers(issue).should == [9]
      end

      it "returns all functional roles if none" do
        function1 = contractor_role.id
        function2 = project_office_role.id
        allow(issue).to receive(:authorized_viewers).and_return(nil)
        function_ids_for_current_viewers(issue).should == [function1,function2]
      end
    end
  end
end
