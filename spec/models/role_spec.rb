require_relative '../spec_helper'
require 'redmine_limited_visibility/role'

describe Role do

  before(:all) do
    find_or_create(:role, name: "Contractors", limit_visibility: true)
    find_or_create(:role, name: "Project Office", limit_visibility: true)
  end

  it 'can return all visibility roles' do
    IssueQuery.available_columns.find { |column| column.name == :authorized_viewers }.should_not be_nil
  end

  it 'set default visibility after creation of a new visibility role'

end
