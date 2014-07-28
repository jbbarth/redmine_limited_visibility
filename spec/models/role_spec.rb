require_relative '../spec_helper'

describe Role do
  before(:all) do
    find_or_create(:role, name: "Contractors", limit_visibility: true)
    find_or_create(:role, name: "Project Office", limit_visibility: true)
  end

  it 'can return all visibility roles' do
    roles = Role.visibility_roles.all
    roles.size.should be >= 2
    roles.find { |role| role.name == 'Contractors' }.should_not be_nil
    roles.find { |role| role.limit_visibility == false }.should be_nil
  end

  it 'set default visibility after creation of a new visibility role' do
    role = Role.create(name: "New role", limit_visibility: true, authorized_viewers: "")
    expect(role.authorized_viewers).to include role.id.to_s
  end
end
