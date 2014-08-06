require_relative '../spec_helper'
require 'redmine_limited_visibility/queries_helper_patch'

describe IssuesController do
  fixtures :users, :roles, :projects, :members, :member_roles, :issues, :issue_statuses, :trackers, :enumerations, :custom_fields, :enabled_modules

  let(:contractor_role) { find_or_create(:role, name: "Contractors", limit_visibility: true) }
  let(:project_office_role) { find_or_create(:role, name: "Project Office", limit_visibility: true) }

  before do
    @request.session[:user_id] = 1
    User.current = User.find(1)
    @project = Project.first
    @membership = Member.new(user_id: User.current.id, project_id: @project.id)
    @membership.roles << contractor_role
    @membership.save!
    User.current.member_of?(@project).should be true
  end

  it 'adds an "authorized viewers filter" to existing requests' do
    q = IssueQuery.create!(name: "new-query", user: User.find(2), visibility: 2, project: nil)
    expect(q.filters).to_not include 'authorized_viewers'
    get :index, query_id: q.id
    response.should be_success
    expect(assigns(:query)).to_not be_nil
    expect(assigns(:query).filters).to include 'authorized_viewers'
  end

  it 'displays issues according to current visibility roles' do
    q = IssueQuery.create!(name: "new-query", user: User.current, visibility: 2, project: nil)

    # No authorized_viewers on issues
    get :index, query_id: q.id
    expect(assigns(:issues)).to_not be_nil
    issues = assigns(:issues).select{ |i| i.project == @project }
    issue1 = issues.first
    issue2 = issues.second

    # check if authorized_viewers match user visibility
    issue1.update_attribute(:authorized_viewers, "|#{contractor_role.id}|") # User visibility role
    issue2.update_attribute(:authorized_viewers, "|#{project_office_role.id}|") # Current user does not match this role
    q.filters.merge!({"authorized_viewers" => {:operator=>"mine", :values => [""]}})
    q.save!
    get :index, query_id: q.id
    expect(assigns(:issues)).to_not be_nil
    expect(assigns(:issues)).to include issue1
    expect(assigns(:issues)).to_not include issue2
  end
end
