require_relative '../spec_helper'

describe RedmineLimitedVisibility::IssuePatch do

  fixtures :users, :roles, :projects, :members, :member_roles, :issues, :issue_statuses, :trackers, :enumerations, :custom_fields, :enabled_modules

  let(:issue) { Issue.new }
  let(:issue_4) { Issue.find(4) }
  let(:contractor_role) { find_or_create(:role, name: "Contractors", limit_visibility: true) }
  let(:project_office_role) { find_or_create(:role, name: "Project Office", limit_visibility: true) }
  let(:issue_with_authorized_viewers) { issue_4.update_attributes!(:authorized_viewers => "|#{contractor_role.id}|"); issue_4 }
  let(:issue_without_authorized_viewers) { issue_4.update_attributes!(:authorized_viewers => "||"); issue_4 }

  describe "#authorized_viewers" do
    it "has a authorized_viewers column" do
      issue.attributes.should include "authorized_viewers"
    end

    it "is a safe attribute" do
      # avoid loading too many dependencies
      issue.stub(:new_statuses_allowed_to) { [true] }
      issue.safe_attributes = { "authorized_viewers" => "All of them" }
      issue.authorized_viewers.should == "All of them"
    end
  end

  describe 'notified_users' do
    it 'should notify users if their roles are involved' do
      issue = issue_with_authorized_viewers
      member = Member.where(user_id: 2, project_id: issue.project_id).first
      unless member
        member = Member.new(user_id: 2, project_id: issue.project_id)
      end
      member.roles << contractor_role
      member.save!

      notified = issue.notified_users
      notified.should_not be_nil
      notified.size.should > 0
      notified.should_not include User.anonymous
      notified.should include User.find(2) # member with right role
      notified.should_not include User.find(3) # not a member of the project
      notified.should_not include User.find(8) # member of project 2 but mail_notification = false
    end

    it 'should NOT notify users if their roles are not involved' do
      issue = issue_with_authorized_viewers
      not_involved_role = project_office_role

      member = Member.where(user_id: 2, project_id: issue.project_id).first
      unless member
        member = Member.new(user_id: 2, project_id: issue.project_id)
      end
      member.roles << not_involved_role
      member.save!

      notified = issue.notified_users
      notified.should_not be_nil
      notified.size.should eq 0
      notified.should_not include User.anonymous
      notified.should_not include User.find(2) # member with different role
    end

    it 'should notify users if issue has no specific roles' do
      issue = issue_without_authorized_viewers

      notified = issue.notified_users

      notified.should_not be_nil
      notified.size.should eq 1
      notified.should_not include User.anonymous
      notified.should include User.find(2) # member without any visibility role
      notified.should_not include User.find(3) # not a member of the project
      notified.should_not include User.find(8) # member of project 2 but mail_notification = false
    end
  end

  describe "#involved_users" do
    it "should be tested"
  end

  describe "#authorized_viewer_ids" do
    let(:issue) { stub_model(Issue) }

    it "transforms the #authorized_viewers string into an array of ids" do
      allow(issue).to receive(:authorized_viewers).and_return("|3|5|99|")
      issue.authorized_viewer_ids.should == ["3","5","99"]
    end

    it "returns nil if #authorized_viewers is nil" do
      allow(issue).to receive(:authorized_viewers).and_return(nil)
      issue.authorized_viewer_ids.should == nil
    end

    it "removes blank values from the return value" do
      allow(issue).to receive(:authorized_viewers).and_return("||1| |")
      issue.authorized_viewer_ids.should == ["1"]
    end
  end
end
