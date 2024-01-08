require 'spec_helper'

describe RedmineLimitedVisibility::Models::IssuePatch do

  fixtures :users, :roles, :projects, :members, :member_roles, :issues, :issue_statuses, :trackers, :enumerations, :custom_fields, :enabled_modules

  let(:issue) {Issue.new}
  let(:issue_4) {Issue.find(4)}
  let(:contractor_role) {Function.where(name: "Contractors").first_or_create}
  let(:project_office_role) {Function.where(name: "Project Office").first_or_create}
  let(:issue_with_authorized_viewers) {issue_4.update_attributes!(:authorized_viewers => "|#{contractor_role.id}|"); issue_4}
  let(:issue_without_authorized_viewers) {issue_4.update_attributes!(:authorized_viewers => "||"); issue_4}

  describe "#authorized_viewers" do
    it "has a authorized_viewers column" do
      expect(issue.attributes).to include "authorized_viewers"
    end

    it "is a safe attribute" do
      # avoid loading too many dependencies
      allow(issue).to receive(:new_statuses_allowed_to).and_return(IssueStatus.all)
      issue.safe_attributes = {"authorized_viewers" => "All of them"}
      expect(issue.authorized_viewers).to eq "All of them"
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
      expect(notified).to_not be_nil
      expect(notified.size).to be > 0
      expect(notified).to_not include User.anonymous
      expect(notified).to include User.find(2) # member with right function
      expect(notified).to_not include User.find(3) # not a member of the project
      expect(notified).to_not include User.find(8) # member of project 2 but mail_notification = false
    end

    it 'should NOT notify users if their functions are not involved AND module is enabled for the project' do
      issue = issue_with_authorized_viewers
      issue.project.enable_module!('limited_visibility')
      not_involved_function = project_office_role

      member2 = Member.find_or_new(issue.project, User.find(2))
      member2.functions << not_involved_function
      member2.save!

      member3 = Member.find_or_new(issue.project, User.find(3))
      member3.roles << Role.find(2)
      member3.functions << not_involved_function
      member3.save!

      notified = issue.notified_users
      expect(notified).to_not be_nil
      expect(notified.size).to eq 1 # Only the author is notified
      expect(notified).to include issue.author
      expect(notified).to_not include User.anonymous
      expect(notified).to include User.find(2) # member with different function, but author
      expect(notified).to_not include User.find(3) # member with different function
    end

    it 'SHOULD notify users if their functions are not involved BUT module is DISABLED for the project' do
      issue = issue_with_authorized_viewers
      issue.project.disable_module!('limited_visibility')
      not_involved_function = project_office_role

      member = Member.where(user_id: 2, project_id: issue.project_id).first
      unless member
        member = Member.new(user_id: 2, project_id: issue.project_id)
      end
      member.functions << not_involved_function
      member.save!

      notified = issue.notified_users
      expect(notified).to_not be_nil
      expect(notified.size).to be > 0
      expect(notified).to_not include User.anonymous
      expect(notified).to include User.find(2) # member with different function
    end

    it 'should notify users if issue has no specific function' do
      issue = issue_without_authorized_viewers

      notified = issue.notified_users

      expect(notified).to_not be_nil
      expect(notified.size).to eq 1
      expect(notified).to_not include User.anonymous
      expect(notified).to include User.find(2) # member without any functional role
      expect(notified).to_not include User.find(3) # not a member of the project
      expect(notified).to_not include User.find(8) # member of project 2 but mail_notification = false
    end

  end

  # Test compatibility with the redmine multiprojects_issue plugin
  if Redmine::Plugin.installed?(:redmine_multiprojects_issue)
    describe 'multiprojects_issues' do
      it 'should NOT notify users if their functions are not involved in secondary project' do

        # SETUP
        Project.find(2).enable_module!('limited_visibility')
        Project.find(5).enable_module!('limited_visibility')
        multiproject_issue = issue_with_authorized_viewers # issue_id: 4 & project_id: 2 & authorized_viewers: "|#{contractor_role.id}|"
        multiproject_issue.projects = [multiproject_issue.project, Project.find(5)] #other project id = 5
        multiproject_issue.save!
        new_member = Member.new(:project_id => 5, :user_id => 4) #only member of secondary project
        new_member.roles = [Role.find(2)]
        new_member.save!

        # it should notified users from other projects if the issue has no specific visibility
        notified_users_from_other_projects = multiproject_issue.notified_users_from_other_projects
        refute_nil notified_users_from_other_projects
        expect(notified_users_from_other_projects).to_not include User.anonymous
        expect(notified_users_from_other_projects).to include User.find(1) # member of project 5 only, but admin
        expect(notified_users_from_other_projects).to_not include User.find(3) # not a member
        expect(Member.where(user_id: 4, project_id: 5).first.functions).to eq []
        expect(notified_users_from_other_projects).to include User.find(4) # member of project 5 only, not admin, no functional role specified
        expect(notified_users_from_other_projects).to_not include User.find(8) # member of project 2 and 5 but mail_notification = only_my_events

        # it should NOT notified users from other projects if the issue has a specific visibility and the user is not involved
        not_involved_function = project_office_role
        member = Member.find_or_create_by(user_id: 4, project_id: 5)
        member.functions << not_involved_function
        member.save!

        notified = multiproject_issue.notified_users

        expect(notified).to_not be_nil
        expect(notified).to_not include User.anonymous
        expect(notified).to_not include User.find(4) # member of project 5 only, not admin, with a different functional role
      end
    end
  end

  describe "#involved_users" do
    let(:issue) {Issue.new}
    let(:project) {Project.find(1)}

    it "returns users 'involved' in this issue, who have at least one function in the authorized_viewer_ids functions" do
      allow(issue).to receive(:authorized_viewer_ids).and_return([contractor_role.id, project_office_role.id])
      issue.project = Project.find(1)
      members = Member.where(project_id: 1, user_id: [2, 3, 5]).all
      members.each do |member|
        MemberFunction.where(member_id: member.id, function_id: contractor_role.id).first_or_create
      end

      users = issue.involved_users(issue.project)
      expect(users.map(&:class).uniq).to eq [User]
      expect(users.map(&:id)).to eq [2, 3, 5]
    end
  end

  describe "#authorized_viewer_ids" do
    let(:issue) {Issue.new}

    it "transforms the #authorized_viewers string into an array of ids" do
      allow(issue).to receive(:authorized_viewers).and_return("|3|5|99|")
      expect(issue.authorized_viewer_ids).to eq [3, 5, 99]
    end

    it "returns nil if #authorized_viewers is nil" do
      allow(issue).to receive(:authorized_viewers).and_return(nil)
      expect(issue.authorized_viewer_ids).to eq []
    end

    it "removes blank values from the return value" do
      allow(issue).to receive(:authorized_viewers).and_return("||1| |")
      expect(issue.authorized_viewer_ids).to eq [1]
    end
  end
end
