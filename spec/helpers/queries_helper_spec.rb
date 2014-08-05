require_relative '../spec_helper'
require 'redmine_limited_visibility/queries_helper_patch'

describe QueriesHelper do

  let(:contractor_role) { find_or_create(:role, name: "Contractors", limit_visibility: true) }
  let(:project_office_role) { find_or_create(:role, name: "Project Office", limit_visibility: true) }

  describe 'column_value' do
    it "should return a String with role's names" do
      value = column_value(QueryColumn.new(:authorized_viewers), nil, "|#{contractor_role.id}|#{project_office_role.id}|")
      value.should be_a_kind_of String
      value.should include "#{contractor_role.name}, #{project_office_role.name}"
    end
  end
end
