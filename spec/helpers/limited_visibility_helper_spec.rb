require_relative '../spec_helper'

describe LimitedVisibilityHelper do

  fixtures :users, :roles, :projects, :members, :member_roles, :enabled_modules, :issues

  before do
    User.current = User.find(1)
    @project = Project.first
    @membership = Member.new(user_id: User.current.id, project_id: @project.id)
    @membership.roles << contractor_role
    @membership.save!
    User.current.member_of?(@project).should be true
  end


  let!(:contractor_role) { find_or_create(:role, name: "Contractors", limit_visibility: true) }
  let!(:project_office_role) { find_or_create(:role, name: "Project Office", limit_visibility: true) }

  describe 'visibility_roles_for_current_user' do
    it 'should retrieve visibility roles for current user' do
      visibility_roles_for_current_user(@project).should_not be_nil
      visibility_roles_for_current_user(@project).should include contractor_role
      visibility_roles_for_current_user(@project).should_not include project_office_role
    end

    it "should return an empty array if current user doesn't have any membership on current project" do
      User.current = User.find(6) #not member of @project
      visibility_roles_for_current_user(@project).should == []
    end
  end

  describe "#role_ids_for_current_viewers" do
    context "with a new issue" do
      let(:issue) { Issue.new(:project => @project) }

      it "returns all visibility roles if current user cannot see anything" do
        allow(self).to receive(:visibility_roles_for_current_user).and_return([])
        role_ids_for_current_viewers(issue).should == [6,7]
      end

      it "returns visibility roles for current user if any" do
        dummy_role = stub_model(Role, :authorized_viewers => "|88|")
        allow(self).to receive(:visibility_roles_for_current_user).and_return([dummy_role])
        role_ids_for_current_viewers(issue).should == [88]
      end
    end

    context "with an existing issue" do
      let(:issue) { Issue.first }

      it "returns authorized viewers if any" do
        allow(issue).to receive(:authorized_viewers).and_return("|9|")
        role_ids_for_current_viewers(issue).should == [9]
      end

      it "returns all visibility roles if none" do
        allow(issue).to receive(:authorized_viewers).and_return(nil)
        role_ids_for_current_viewers(issue).should == [6,7]
      end
    end
  end
end
