require_relative '../fast_spec_helper'
require_relative '../../app/services/issue_visibility'

describe IssueVisibility do
  let(:user) { stub :user }
  let(:issue) { stub :issue }

  describe "#new" do
    it "sets instance variables" do
      service = IssueVisibility.new(user, issue)
      service.user.should == user
      service.issue.should == issue
    end
  end

  describe "#authorized?" do
    it "uses Issue#authorized_viewers" do
      issue.should_receive(:authorized_viewers)
      IssueVisibility.new(user, issue).authorized?
    end
  end
end
