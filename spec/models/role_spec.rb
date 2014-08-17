require_relative '../spec_helper'

describe Role do
  it 'can return all visibility roles' do
    contractor_role = find_or_create(:role, name: "Contractors", limit_visibility: true)
    find_or_create(:role, name: "Project Office", limit_visibility: true)
    roles = Role.visibility_roles.all
    roles.size.should be >= 2
    roles.find { |role| role.name == contractor_role.name }.should_not be_nil
    roles.find { |role| role.limit_visibility == false }.should be_nil
  end

  it 'set default visibility after creation of a new visibility role' do
    role = Role.create(name: "New role", limit_visibility: true, authorized_viewers: "")
    expect(role.authorized_viewers).to include role.id.to_s
  end

  describe "#authorized_viewer_ids" do
    it "returns authorized viewer role ids as an array of integers" do
      role = stub_model(Role, :authorized_viewers => "|3|45|")
      role.authorized_viewer_ids.should == [3,45]
    end

    it "doesn't break if column is blank" do
      role = stub_model(Role, :authorized_viewers => nil)
      role.authorized_viewer_ids.should == []
    end
  end
end
