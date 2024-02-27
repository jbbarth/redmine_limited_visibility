# frozen_string_literal: true

require 'spec_helper'

describe Redmine::Export::PDF::IssuesPdfHelper, type: :helper do

  fixtures :users, :projects, :roles, :members, :member_roles,
           :enabled_modules, :issues, :trackers, :enumerations, :functions

  let(:issue) { Issue.find(2) }

  it "displays the full name of the assigned_to user" do
    query = IssueQuery.new(project: Project.find(1), name: '_')
    query.column_names = [:subject, :assigned_to]
    issue = Issue.find(2)

    results = fetch_row_values(issue, query, 0)

    expect(results).to eq [issue.id.to_s, issue.subject, issue.assigned_to.name.to_s]
  end

  it "displays the name of the function if assigned to a function" do
    function = Function.find(1)
    query = IssueQuery.new(project: Project.find(1), name: '_')
    query.column_names = [:subject, :assigned_to]

    issue = Issue.find(2)
    issue.assigned_to = nil
    issue.assigned_function = Function.find(1)
    issue.save

    results = fetch_row_values(issue, query, 0)

    expect(results).to eq [issue.id.to_s, issue.subject, function.name.to_s]
  end
end
