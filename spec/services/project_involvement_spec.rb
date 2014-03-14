require_relative "../spec_helper"
require_relative '../../app/services/project_involvement'

describe ProjectInvolvement do
  subject { ProjectInvolvement.new(project.id) }

  let(:project) { double :project, id: 37 }

  describe "#new" do
    it "stores project_id as an instance variable" do
      subject.project_id.should == 37
    end
  end

  describe "#potential_involved_teams" do
    # it's hard to simply test that kind of AR queries, but at least we can
    # verify # this part of the code doesn't break in unexpected ways, so it
    # protects us against schema changes or stuff like that..
    it "returns a set of unique, non null organization ids" do
      subject.potential_involved_teams.should be_an Array
    end
  end

  describe "#issuers_user_ids" do
    # same as above
    it "returns an array" do
      subject.issuers_user_ids.should be_an Array
    end
  end

  describe "#issuers_roles" do
    # same as above
    it "returns an array" do
      subject.issuers_roles.should be_an Array
    end
  end
end
