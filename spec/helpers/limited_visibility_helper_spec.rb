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
    expect(User.current.member_of?(@project)).to be true
  end

  let(:contractor_role) { Function.where(name: "Contractors").first_or_create }
  let(:project_office_role) { Function.where(name: "Project Office").first_or_create }

  describe 'functional_roles_for_current_user' do
    it 'should retrieve functional roles for current user' do
      expect(functional_roles_for_current_user(@project)).to_not be_nil
      expect(functional_roles_for_current_user(@project)).to include contractor_role
      expect(functional_roles_for_current_user(@project)).to_not include project_office_role
    end

    it "should return an empty array if current user doesn't have any membership on current project" do
      User.current = User.find(6) #not member of @project
      expect(functional_roles_for_current_user(@project)).to eq []
    end
  end

  describe "#function_ids_for_current_viewers" do
    context "with a new issue" do
      let(:issue) { Issue.new(:project => @project) }

      it "returns functional roles for current user if any" do
        expect(function_ids_for_current_viewers(issue)).to eq [contractor_role.id]
      end

      it "returns all functional roles if current user cannot see anything" do
        function1 = contractor_role.id
        function2 = project_office_role.id
        allow(self).to receive(:functional_roles_for_current_user).and_return([])
        expect(function_ids_for_current_viewers(issue)).to eq [function1,function2]
      end
    end

    context "with an existing issue" do
      let(:issue) { Issue.first }

      it "returns authorized viewers if any" do
        allow(issue).to receive(:authorized_viewers).and_return("|9|")
        expect(function_ids_for_current_viewers(issue)).to eq [9]
      end

      it "returns all functional roles if none" do
        function1 = contractor_role.id
        function2 = project_office_role.id
        allow(issue).to receive(:authorized_viewers).and_return(nil)
        expect(function_ids_for_current_viewers(issue)).to eq [function1,function2]
      end
    end
  end
end
