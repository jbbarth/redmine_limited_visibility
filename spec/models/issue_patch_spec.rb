require_relative '../spec_helper'

describe RedmineLimitedVisibility::IssuePatch do

  fixtures :users, :roles, :projects, :members, :member_roles, :issues, :issue_statuses, :trackers, :enumerations, :custom_fields, :enabled_modules
  if Redmine::Plugin.installed?(:redmine_organizations)
    fixtures :organizations, :organization_memberships, :organization_involvements, :organization_roles
  end

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

      if Redmine::Plugin.installed?(:redmine_organizations)
        orga = Organization.find(1)
        membership = orga.memberships.where(project_id: issue.project_id).first
        membership.roles << contractor_role
        membership.save!
      else
        member = Member.where(user_id: 2, project_id: issue.project_id).first
        unless member
          member = Member.new(user_id: 2, project_id: issue.project_id)
        end
        member.roles << contractor_role
        member.save!
      end

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

      if Redmine::Plugin.installed?(:redmine_organizations)
        orga = Organization.find(1)
        membership = orga.memberships.where(project_id: issue.project_id).first
        membership.roles << not_involved_role
        membership.save!
      else
        member = Member.where(user_id: 2, project_id: issue.project_id).first
        MemberRole.create(member_id: member.id, role_id: not_involved_role.id)
      end

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
end
