require_relative '../fast_spec_helper'
require_relative '../../app/services/issue_user_visibility'

describe IssueUserVisibility do
  let(:user) { double :user, :id => 37, :group_ids => [14, 17], :admin? => false }
  let(:issue) { double :issue }

  describe "#new" do
    it "sets instance variables" do
      service = IssueUserVisibility.new(user, issue)
      service.user.should == user
      service.issue.should == issue
    end

    it "provide a default user if user is nil" do
      service = IssueUserVisibility.new(nil, issue)
      service.stub(:default_user) { :user }
      service.user.should == :user
    end
  end

  describe "#authorized?" do
    subject do
      service = IssueUserVisibility.new(user, issue)
      service.stub(:role_ids) { [] }
      service
    end

    it "passes if authorized_viewers is nil" do
      issue.stub(:authorized_viewers) { nil }
      subject.should be_authorized
    end

    it "passes if authorized_viewers is blank" do
      issue.stub(:authorized_viewers) { "" }
      subject.should be_authorized
    end

    it "passes if authorized_viewers is '*'" do
      issue.stub(:authorized_viewers) { "*" }
      subject.should be_authorized
    end

    it "blocks if authorized_viewers is a list and user is not in the list" do
      issue.stub(:authorized_viewers) { "||" }
      subject.should_not be_authorized
    end

    it "passes if user_id is explicitly in authorizations list" do
      issue.stub(:authorized_viewers) { "|user=37|" }
      subject.should be_authorized
    end

    it "passes if user's organization_id is in authorizations list" do
      user.stub(:organization_id) { 353 }
      issue.stub(:authorized_viewers) { "|organization=353|" }
      subject.should be_authorized
    end

    it "passes if user has a group in authorizations" do
      issue.stub(:authorized_viewers) { "|group=17|" }
      subject.should be_authorized
    end

    it "blocks if no criteria match" do
      issue.stub(:authorized_viewers) { "|user=3|group=19|group=45|" }
      subject.should_not be_authorized
    end

    it "passes if no rule matches but user is admin" do
      issue.stub(:authorized_viewers) { "||" }
      user.stub(:admin?) { true }
      subject.should be_authorized
    end

    it "passes if user has a role on this project in authorizations" do
      issue.stub(:authorized_viewers) { "|role=1|" }
      subject.stub(:role_ids) { [1, 2, 3] }
      subject.should be_authorized
    end

    it "blocks if no role id matches" do
      issue.stub(:authorized_viewers) { "|role=4|" }
      subject.stub(:role_ids) { [1, 2, 3] }
      subject.should_not be_authorized
    end
  end
end
