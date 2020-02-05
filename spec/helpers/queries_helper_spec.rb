require 'spec_helper'
require 'redmine_limited_visibility/helpers/queries_helper_patch'

describe QueriesHelper, type: :helper do

  let(:contractor_role) { Function.where(name: "Contractors").first_or_create }
  let(:project_office_role) { Function.where(name: "Project Office").first_or_create }

  describe 'column_value' do
    it "should return a String with function's names" do
      value = column_value(QueryColumn.new(:authorized_viewers), nil, "|#{contractor_role.id}|#{project_office_role.id}|")
      expect(value).to be_a_kind_of String
      expect(value).to include contractor_role.name
      expect(value).to include project_office_role.name
    end

    it "should return a String with assigned users and functions" do
      user = User.first
      user2 = User.second

      value = column_value(QueryColumn.new(:has_been_assigned_to), nil, user)
      expect(value).to be_a_kind_of ActiveSupport::SafeBuffer
      expect(value).to eq link_to_user(user)

      value = column_value(QueryColumn.new(:has_been_assigned_to), nil, [user, user2])
      expect(value).to include link_to_user(user)
      expect(value).to include link_to_user(user2)

      value = column_value(QueryColumn.new(:has_been_assigned_to), nil, contractor_role)
      expect(value).to eq contractor_role.name
    end
  end
end
