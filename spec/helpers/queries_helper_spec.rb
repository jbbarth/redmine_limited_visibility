require_relative '../spec_helper'

describe QueriesHelper do

  before(:all) do
    Role.create(name: "Contractors", limit_visibility: true)
    Role.create(name: "Project Office", limit_visibility: true)
  end

  describe 'column_value' do
    it "should return a String with role's names" do
      value = column_value(QueryColumn.new(:authorized_viewers), nil, "|#{Role.find_by_name('Contractors').id}|#{Role.find_by_name('Project Office').id}|")
      value.should be_a_kind_of String
      value.should include "Contractors, Project Office"
    end
  end

end
