require 'spec_helper'
require 'redmine_limited_visibility/issue_query_patch'

describe IssueQuery do
  describe 'filters and columns' do
    it 'contains a new "mine" operator' do
      expect(IssueQuery.operators).to include 'mine'
    end

    it 'has a new operator by filter type' do
      expect(IssueQuery.operators_by_filter_type).to include :list_visibility
    end

    it 'has a new available column for involved functions' do
      expect(IssueQuery.available_columns.find { |column| column.name == :authorized_viewers }).to_not be_nil
    end

    it 'initialize an "authorized_viewers" filter' do
      query = IssueQuery.new
      expect(query.available_filters).to include 'authorized_viewers'
    end

    it 'initialize an "assigned_to_function_id" filter' do
      query = IssueQuery.new
      expect(query.available_filters).to include 'assigned_to_function_id'
    end
  end
end
