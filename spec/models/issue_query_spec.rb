require_relative '../spec_helper'
require 'redmine_limited_visibility/issue_query_patch'

describe IssueQuery do

  describe 'filters and columns' do
    it 'contains a new "mine" operator' do
      IssueQuery.operators.should include 'mine'
    end

    it 'has a new operator by filter type' do
      IssueQuery.operators_by_filter_type.should include :list_visibility
    end

    it 'has a new available column for involved roles' do
      IssueQuery.available_columns.find { |column| column.name == :authorized_viewers }.should_not be_nil
    end

    it 'initialize an "authorized_viewers" filter' do
      query = IssueQuery.new
      query.available_filters.should include 'authorized_viewers'
    end

    it 'adds an "authorized viewers filter" to existing requests'

  end

end
