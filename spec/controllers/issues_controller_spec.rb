# require_relative File.expand_path('../../fast_spec_helper', __FILE__)
require "spec_helper"
require 'redmine_limited_visibility/queries_helper_patch'

describe IssuesController do
  fixtures :users, :roles, :projects, :members, :member_roles, :issues, :issue_statuses, :trackers, :enumerations, :custom_fields, :enabled_modules

  let(:contractor_role) { Function.where(name: "Contractors").first_or_create }
  let(:project_office_role) { Function.where(name: "Project Office").first_or_create }

  before do
    @request.session[:user_id] = 1
    User.current = User.find(1)
    @project = Project.first
    @project2 = Project.find(2)
    @membership = Member.new(user_id: User.current.id, project_id: @project.id)
    @membership.roles << Role.first
    @membership.functions << contractor_role
    @membership.save!
    @membership2 = Member.new(user_id: User.current.id, project_id: @project2.id)
    @membership2.roles << Role.first
    @membership2.functions << project_office_role
    @membership2.save!
    User.current.member_of?(@project).should be true
    User.current.member_of?(@project2).should be true
  end

  it 'adds an "authorized viewers filter" to existing requests' do
    q = IssueQuery.create!(name: "new-query", user: User.find(2), visibility: 2, project: nil)
    expect(q.filters).to_not include 'authorized_viewers'
    get :index, query_id: q.id
    response.should be_success
    expect(assigns(:query)).to_not be_nil
    expect(assigns(:query).filters).to include 'authorized_viewers'
  end

  it 'displays issues according to current functional roles' do
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

    # displays all issues when the user has no specific function
    @membership.functions = []
    get :index, query_id: q.id
    expect(assigns(:issues)).to_not be_nil
    expect(assigns(:issues)).to include issue1
    expect(assigns(:issues)).to include issue2
  end

  # Test compatibility with the redmine multiprojects_issue plugin
  if Redmine::Plugin.installed?(:redmine_multiprojects_issue)
    describe 'multiprojects_issues' do

      before do
        @query = IssueQuery.create!(name: "new-query", user: User.current, visibility: 2, project: nil)

        # No authorized_viewers on issues
        get :index, query_id: @query.id
        expect(assigns(:issues)).to_not be_nil
        issues = assigns(:issues).select{ |i| i.project == @project }
        @issue1 = issues.first
        @issue2 = issues.second
        @issue2.projects = [@project2] # issue2 becomes multi-project

        # check if authorized_viewers match user visibility
        @issue1.update_attribute(:authorized_viewers, "|#{contractor_role.id}|") # User visibility role
        @issue2.update_attribute(:authorized_viewers, "|#{project_office_role.id}|") # Current user does not match this role
        @query.filters.merge!({"authorized_viewers" => {:operator=>"mine", :values => [""]}})
        @query.save!
      end

      it 'displays issues according to functional roles on secondary projects' do
        get :index, query_id: @query.id
        expect(assigns(:issues)).to_not be_nil
        expect(assigns(:issues)).to include @issue1
        expect(assigns(:issues)).to include @issue2 # issue2 is now visible because user is member of the secondary project with correct role
      end

      it 'displays no issue when the user has NOT the specific function' do
        @membership2.functions = [contractor_role]
        get :index, query_id: @query.id
        expect(assigns(:issues)).to_not be_nil
        expect(assigns(:issues)).to include @issue1
        expect(assigns(:issues)).to_not include @issue2
      end

      it 'displays all issues when the user has no specific function' do
        @membership2.functions = []
        get :index, query_id: @query.id
        expect(assigns(:issues)).to_not be_nil
        expect(assigns(:issues)).to include @issue1
        expect(assigns(:issues)).to include @issue2
      end
    end
  end
end
