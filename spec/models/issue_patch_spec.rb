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
      IssueVisibility.any_instance.stubs(:authorized?).returns(:result) #mocha mock
      issue.visible?(user).should == :result
    end
  end

  describe ".visible_condition" do
    it "patches Issue.visible_condition" do
      # actually this:
      #   Issue.method(:visible_condition).should == Issue.method(:visible_condition_with_limited_visibility)
      # doesn't work since we use alias_method_chain on a class method and it's a bit... quirky
      Issue.method(:visible_condition).to_s.should include ".visible_condition_with_limited_visibility>"
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
  end

  describe "#authorized_viewers" do
    it "has a authorized_viewers column" do
      issue.attributes.should include "authorized_viewers"
    end
  end
end
