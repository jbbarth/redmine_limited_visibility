require 'spec_helper'
require 'redmine_limited_visibility/queries_helper_patch'

describe QueriesHelper, type: :helper do

  let(:contractor_role) { Function.where(name: "Contractors").first_or_create }
  let(:project_office_role) { Function.where(name: "Project Office").first_or_create }

  describe 'column_value' do
    it "should return a String with function's names" do
      value = column_value(QueryColumn.new(:authorized_viewers), nil, "|#{contractor_role.id}|#{project_office_role.id}|")
      expect(value).to be_a_kind_of String
      expect(value).to include "#{contractor_role.name}, #{project_office_role.name}"
    end
  end

  describe 'column_content' do
    it "should display parent column as a link to a project" do
      query = ProjectQuery.new(:name => '_', :column_names => ["name", "parent"])
      content = column_content(QueryColumn.new(:parent), query.projects.select{|e| e.parent_id == 1}.first)
      expect(content).to have_link("eCookbook")
    end
  end
end
