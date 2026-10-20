require 'spec_helper'
# require 'redmine_limited_visibility/helpers/queries_helper_patch'

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

  describe "functional role names" do
    let(:malicious_role) { Function.create!(name: '<img src=x onerror=alert(1)>') }
    let(:issue) { Issue.find(1) }
    let(:escaped_name) { '&lt;img src=x onerror=alert(1)&gt;' }

    before do
      issue.update_columns(assigned_to_id: nil, assigned_to_function_id: malicious_role.id,
                           authorized_viewers: "|#{malicious_role.id}|")
    end

    after { malicious_role.destroy }

    it "escapes the function assigned to an issue" do
      value = column_value(QueryColumn.new(:assigned_to), issue, nil)
      expect(value).to eq "&#10148; #{escaped_name}"
    end

    it "escapes the functions an issue has been assigned to" do
      value = column_content(QueryColumn.new(:has_been_assigned_to), issue)
      expect(value).to include escaped_name
      expect(value).not_to include '<img'
    end

    it "escapes the functions an issue has been visible by" do
      value = column_content(QueryColumn.new(:has_been_visible_by), issue)
      expect(value).to include escaped_name
      expect(value).not_to include '<img'
    end

    it "keeps raw function names in the csv export" do
      expect(csv_content(QueryColumn.new(:has_been_assigned_to), issue)).to include malicious_role.name
      expect(csv_content(QueryColumn.new(:has_been_visible_by), issue)).to include malicious_role.name
    end
  end
end
