require_relative '../spec_helper'

describe RedmineLimitedVisibility::IssuePatch do
  let(:issue) { Issue.new }
  let(:user) { User.new }

  describe "#visible?" do
    it "patches Issue#visible?" do
      issue.method(:visible?).should == issue.method(:visible_with_limited_visibility?)
    end

    it "delegates to original Issue#visible? in normal cases" do
      issue.should_receive(:visible_without_limited_visibility?).with(user)
      issue.visible?(user)
    end

    it "adds additionnal visibility condition" do
      issue.stub(:visible_without_limited_visibility?).and_return(true)
      # Redmine specs can be run within other plugins, which can themselves configure
      # rspec in a form or an other. The fact that redmine comes out of the box with
      # the "mocha" gem for mocking makes it hard to know at 100% if the mocking framework
      # will be mocha or rspec at this point. So the "#any_instance" call could be from
      # mocha or rspec, hence we setup mock expectations on both. Previously we were trying
      # to detect if mocha is activated but it doesn't appear in RSpec.configuration
      # directly it seems...
      # I added some "rescue nil" calls because for whatever fucked reason, "sometimes" I
      # don't get mocha loaded when running tests only for this plugin, and in that case
      # it raises an exception I don't ever want to see... Take that haters :)
      IssueUserVisibility.any_instance.stubs(:authorized?).returns(:result) rescue nil   #mocha mock
      IssueUserVisibility.any_instance.stub(:authorized?).and_return(:result)            #rspec mock
      issue.visible?(user).should == :result
    end
  end

  describe ".visible_condition" do
    it "patches Issue.visible_condition" do
      # actually this:
      #   Issue.method(:visible_condition).should == Issue.method(:visible_condition_with_limited_visibility)
      # doesn't work since we use alias_method_chain on a class method and it's a bit... quirky
      Issue.method(:visible_condition).to_s.should include "visible_condition_with_limited_visibility>"
    end

    it "allows admins to view everything" do
      user.stub(:admin?){ true }
      #ok that's not obvious but it's the base condition, not modified
      #as we don't work with a real, db-backed user, condition is falsy
      #and we can't easily stub everything out cause it's class methods...
      Issue.visible_condition(user).should == Issue.visible_condition_without_limited_visibility(user)
    end

    it "allows to see issues with no restriction" do
      Issue.visible_condition(user).should include "issues.authorized_viewers IS NULL OR issues.authorized_viewers IN ('', '*')"
    end

    it "generates a visible condition based on user_id" do
      user.stub(:id){ 731 }
      Issue.visible_condition(user).should include "issues.authorized_viewers LIKE '%|user=731|%'"
    end

    it "generates a visible condition based on users organization_id if present" do
      user.stub(:id){ 731 }
      user.stub(:organization_id){ 36 }
      Issue.visible_condition(user).should include "issues.authorized_viewers LIKE '%|user=731|%' OR issues.authorized_viewers LIKE '%|organization=36|%'"
    end

    it "generates a visible condition based on groups if present" do
      user.stub(:id){ 731 }
      user.stub(:group_ids){ [5,7] }
      Issue.visible_condition(user).should include "issues.authorized_viewers LIKE '%|group=5|%' OR issues.authorized_viewers LIKE '%|group=7|%'"
    end

    it "generates a visible condition based on roles if any" do
      user.stub(:projects_by_role){
        { double(:role_1, :id => 1).as_null_object => [double(:project_1, :id => 24), double(:project_2, :id => 27)],
          double(:role_2, :id => 7).as_null_object => [double(:project_1bis, :id => 24)] }
      }
      Issue.visible_condition(user).should include "issues.authorized_viewers LIKE '%|role=1/project=24|%'"
      Issue.visible_condition(user).should include "issues.authorized_viewers LIKE '%|role=1/project=27|%'"
      Issue.visible_condition(user).should include "issues.authorized_viewers LIKE '%|role=7/project=24|%'"
    end
  end

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
