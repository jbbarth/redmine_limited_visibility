require 'spec_helper'

require 'redmine_limited_visibility/models/issue_query_patch'
require 'redmine_limited_visibility/helpers/queries_helper_patch'

describe IssuesController, type: :controller do
  fixtures :users, :roles, :projects, :members, :member_roles, :issues, :issue_statuses, :trackers, :enumerations, :custom_fields, :enabled_modules

  let(:contractor_role) {Function.where(name: "Contractors").first_or_create}
  let(:project_office_role) {Function.where(name: "Project Office").first_or_create}

  before do
    @request.session[:user_id] = 1
    User.current = User.find(1)
    @project = Project.first
    @project.enable_module!("limited_visibility")
    @project2 = Project.find(2)
    @project2.enable_module!("limited_visibility")
    @membership = Member.new(user_id: User.current.id, project_id: @project.id)
    @membership.roles << Role.first
    @membership.functions << contractor_role
    @membership.save!
    @membership2 = Member.new(user_id: User.current.id, project_id: @project2.id)
    @membership2.roles << Role.first
    @membership2.functions << project_office_role
    @membership2.save!
    expect(User.current.member_of?(@project)).to be true
    expect(User.current.member_of?(@project2)).to be true
  end

  it 'adds an "authorized viewers" filter to requests if there is no specific project' do
    q = IssueQuery.create!(name: "new-query", user: User.find(2), visibility: 2, project: nil)
    expect(q.filters).to_not include 'authorized_viewers'
    get :index, params: {query_id: q.id}
    expect(response).to be_successful
    expect(assigns(:query)).to_not be_nil
    expect(assigns(:query).filters).to include 'authorized_viewers'
  end

  it 'do not adds an "authorized viewers filter" to requests if module is not enable for the selected project' do
    q = IssueQuery.create!(name: "new-query", user: User.find(2), visibility: 2, project: @project)
    @project.enabled_module_names -= ['limited_visibility']
    expect(q.filters).to_not include 'authorized_viewers'
    get :index, params: {project_id: 1, query_id: q.id}
    expect(response).to be_successful
    expect(assigns(:query)).to_not be_nil
    expect(assigns(:query).filters).to_not include 'authorized_viewers'
  end

  it 'adds an "authorized viewers filter" to requests if module is enable' do
    project = Project.find(1)
    q = IssueQuery.create!(name: "new-query", user: User.find(2), visibility: 2, project: project)
    expect(q.filters).to_not include 'authorized_viewers'
    get :index, params: {project_id: 1, query_id: q.id}
    expect(response).to be_successful
    expect(assigns(:query)).to_not be_nil
    expect(assigns(:query).filters).to include 'authorized_viewers'
  end

  it 'displays issues according to current functional roles' do
    q = IssueQuery.create!(name: "new-query", user: User.current, visibility: 2, project: nil)

    # No authorized_viewers on issues
    get :index, params: {query_id: q.id}
    expect(assigns(:issues)).to_not be_nil
    expect(assigns(:issues)).to_not be_empty
    issues = assigns(:issues).select {|i| i.project == @project}
    issue1 = issues.first
    issue2 = issues.second
    expect(issue1).to_not be_nil
    expect(issue2).to_not be_nil

    # check if authorized_viewers match user visibility
    issue1.update_attribute(:authorized_viewers, "|#{contractor_role.id}|") # User visibility role
    issue2.update_attribute(:authorized_viewers, "|#{project_office_role.id}|") # Current user does not match this role
    q.filters.merge!({"authorized_viewers" => {:operator => "mine", :values => [""]}})
    q.save!
    get :index, params: {query_id: q.id}
    expect(assigns(:issues)).to_not be_nil
    expect(@project.enabled_module_names).to include "limited_visibility"
    expect(assigns(:issues)).to include issue1
    expect(assigns(:issues)).to_not include issue2

    # displays all issues when the user has no specific function
    @membership.functions = []
    @membership2.functions = []
    get :index, params: {query_id: q.id}
    expect(assigns(:issues)).to_not be_nil
    expect(assigns(:issues)).to include issue1
    expect(assigns(:issues)).to include issue2
  end

  it 'assigned the issue either to a user or to a functional role' do
    issue = Issue.first

    # Assignation to a user
    put :update, params: {id: issue.id, issue: {assigned_to_id: "#{User.current.id}"}}
    issue.reload
    expect(issue.assigned_to_function_id).to be_nil
    expect(issue.assigned_to_id).to eq User.current.id

    # Assignation to a functional role
    put :update, params: {id: issue.id, issue: {assigned_to_id: "function-#{contractor_role.id}"}}
    issue.reload
    expect(issue.assigned_to_function_id).to eq contractor_role.id
    expect(issue.assigned_to_id).to be_nil
  end

  # Test compatibility with the redmine multiprojects_issue plugin
  if Redmine::Plugin.installed?(:redmine_multiprojects_issue)
    describe 'multiprojects_issues' do

      before do
        @query = IssueQuery.create!(name: "new-query", user: User.current, visibility: 2, project: nil)

        # No authorized_viewers on issues
        get :index, params: {query_id: @query.id}
        expect(assigns(:issues)).to_not be_nil
        issues = assigns(:issues).select {|i| i.project == @project}
        @issue1 = issues.first
        @issue2 = issues.second
        @issue2.projects = [@project2] # issue2 becomes multi-project

        # check if authorized_viewers match user visibility
        @issue1.update_attribute(:authorized_viewers, "|#{contractor_role.id}|") # User visibility role
        @issue2.update_attribute(:authorized_viewers, "|#{project_office_role.id}|") # Current user does not match this role
        @query.filters.merge!({"authorized_viewers" => {:operator => "mine", :values => [""]}})
        @query.save!
      end

      it 'displays issues according to functional roles on secondary projects' do
        get :index, params: {query_id: @query.id}
        expect(assigns(:issues)).to_not be_nil
        expect(assigns(:issues)).to include @issue1
        expect(assigns(:issues)).to include @issue2 # issue2 is now visible because user is member of the secondary project with correct role
      end

      it 'displays no issue when the user has NOT the specific function' do
        @membership2.functions = [contractor_role]
        get :index, params: {query_id: @query.id}
        expect(assigns(:issues)).to_not be_nil
        expect(assigns(:issues)).to include @issue1
        expect(assigns(:issues)).to_not include @issue2
      end

      it 'displays all issues when the user has no specific function' do
        @membership2.functions = []
        @issue2.update_attribute(:authorized_viewers, "||")
        @issue2.reload

        get :index, params: {query_id: @query.id}
        expect(assigns(:issues)).to_not be_nil
        expect(assigns(:issues)).to include @issue1
        expect(assigns(:issues)).to include @issue2
      end
    end
  end
end
