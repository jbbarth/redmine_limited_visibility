require_relative '../spec_helper'

describe RedmineLimitedVisibility::IssuePatch do

  let(:issue) { Issue.new }

  describe "#authorized_viewers" do
    it "has a authorized_viewers column" do
      issue.attributes.should include "authorized_viewers"
    end

    it "is a safe attribute" do
      #avoid loading too many dependencies
      issue.stub(:new_statuses_allowed_to) { [true] }
      issue.safe_attributes = { "authorized_viewers" => "All of them" }
      issue.authorized_viewers.should == "All of them"
    end
  end


  describe 'notified_users' do

    before(:all) do
      Role.create(name: "Contractors", limit_visibility: true)
      Role.create(name: "Project Office", limit_visibility: true)
      issue_with_authorized_viewers = Issue.find(4)
      issue_with_authorized_viewers.safe_attributes = { "authorized_viewers" => "|#{Role.find_by_name('Contractors').id}|" }
      issue_with_authorized_viewers.save!
    end

    it 'should notified users if there roles are involved' do
      issue = Issue.find(4)
      members = Member.where(user_id: 2, project_id: issue.project_id)
      role = Role.find_by_name('Contractors')
      MemberRole.create(member_id: members.first.id, role_id: role.id) if members && role

      notified = issue.notified_users

      notified.should_not be_nil
      notified.size.should eq 1
      notified.should_not include User.anonymous
      notified.should include User.find(2) # member with right role
      notified.should_not include User.find(3) # not a member of the project
      notified.should_not include User.find(8) # member of project 2 but mail_notification = false
    end

    it 'should NOT notified users if there roles are not involved' do
      issue = Issue.find(4)
      member = Member.where(user_id: 2, project_id: issue.project_id).first
      MemberRole.create(member_id: member.id, role_id: Role.find_by_name('Project Office').id)

      notified = issue.notified_users

      notified.should_not be_nil
      notified.size.should eq 0
      notified.should_not include User.anonymous
      notified.should_not include User.find(2) # member with different role
    end

    it 'should notified users if issue has no specific roles' do
      issue = Issue.find(4)
      issue.safe_attributes = { "authorized_viewers" => "||" }
      issue.save!
      issue.reload

      notified = issue.notified_users

      notified.should_not be_nil
      notified.size.should eq 1
      notified.should_not include User.anonymous
      notified.should include User.find(2) # member without any visibility role
      notified.should_not include User.find(3) # not a member of the project
      notified.should_not include User.find(8) # member of project 2 but mail_notification = false
    end
  end

end
