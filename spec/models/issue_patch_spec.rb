require 'spec_helper'

describe RedmineLimitedVisibility::IssuePatch do

  fixtures :users, :roles, :projects, :members, :member_roles, :issues, :issue_statuses, :trackers, :enumerations, :custom_fields, :enabled_modules

  let(:issue) { Issue.new }
  let(:issue_4) { Issue.find(4) }
  let(:contractor_role) { Function.where(name: "Contractors").first_or_create }
  let(:project_office_role) { Function.where(name: "Project Office").first_or_create }
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
    it 'should notify users if their functions are involved' do
      issue = issue_with_authorized_viewers
      member = Member.where(user_id: 2, project_id: issue.project_id).first
      unless member
        member = Member.new(user_id: 2, project_id: issue.project_id)
      end
      member.functions << contractor_role
      member.save!

      notified = issue.notified_users
      notified.should_not be_nil
      notified.size.should > 0
      notified.should_not include User.anonymous
      notified.should include User.find(2) # member with right function
      notified.should_not include User.find(3) # not a member of the project
      notified.should_not include User.find(8) # member of project 2 but mail_notification = false
    end

    it 'should NOT notify users if their functions are not involved' do
      issue = issue_with_authorized_viewers
      not_involved_function = project_office_role

      member = Member.where(user_id: 2, project_id: issue.project_id).first
      unless member
        member = Member.new(user_id: 2, project_id: issue.project_id)
      end
      member.functions << not_involved_function
      member.save!

      notified = issue.notified_users
      notified.should_not be_nil
      notified.size.should eq 0
      notified.should_not include User.anonymous
      notified.should_not include User.find(2) # member with different function
    end

    it 'should notify users if issue has no specific function' do
      issue = issue_without_authorized_viewers

      notified = issue.notified_users

      notified.should_not be_nil
      notified.size.should eq 1
      notified.should_not include User.anonymous
      notified.should include User.find(2) # member without any functional role
      notified.should_not include User.find(3) # not a member of the project
      notified.should_not include User.find(8) # member of project 2 but mail_notification = false
    end
  end

  describe "#involved_users" do
    let(:issue) { stub_model(Issue) }
    let(:project) { Project.find(1) }

    it "returns users 'involved' in this issue, who have at least one function in the authorized_viewer_ids functions" do
      allow(issue).to receive(:authorized_viewer_ids).and_return([contractor_role.id, project_office_role.id])
      issue.project = Project.find(1)
      members = Member.where(project_id:1, user_id: [2,3,5]).all
      members.each do |member|
        MemberFunction.where(member_id: member.id, function_id: contractor_role.id).first_or_create
      end

      users = issue.involved_users
      users.map(&:class).uniq.should == [User]
      users.map(&:id).should == [2,3,5]
    end
  end

  describe "#authorized_viewer_ids" do
    let(:issue) { stub_model(Issue) }

    it "transforms the #authorized_viewers string into an array of ids" do
      allow(issue).to receive(:authorized_viewers).and_return("|3|5|99|")
      issue.authorized_viewer_ids.should == [3, 5, 99]
    end

    it "returns nil if #authorized_viewers is nil" do
      allow(issue).to receive(:authorized_viewers).and_return(nil)
      issue.authorized_viewer_ids.should == []
    end

    it "removes blank values from the return value" do
      allow(issue).to receive(:authorized_viewers).and_return("||1| |")
      issue.authorized_viewer_ids.should == [1]
    end
  end
end
