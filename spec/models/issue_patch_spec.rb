require_relative '../spec_helper'

describe RedmineLimitedVisibility::IssuePatch do
  describe "#visible?" do
    let(:issue) { Issue.new }
    let(:user) { User.new }

    it "patches Issue#visible?" do
      issue.method(:visible?).should == issue.method(:visible_with_limited_visibility?)
    end

    it "delegates to original Issue#visible? in normal cases" do
      issue.should_receive(:visible_without_limited_visibility?).with(user)
      issue.visible?(user)
    end
  end
end
