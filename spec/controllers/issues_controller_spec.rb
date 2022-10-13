require 'spec_helper'

require 'redmine_limited_visibility/models/issue_query_patch'
require 'redmine_limited_visibility/helpers/queries_helper_patch'

describe IssuesController, type: :controller do
  render_views

  fixtures :projects,
           :users, :email_addresses, :user_preferences,
           :roles,
           :members,
           :member_roles,
           :issues,
           :issue_statuses,
           :issue_relations,
           :versions,
           :trackers,
           :projects_trackers,
           :issue_categories,
           :enabled_modules,
           :enumerations,
           :attachments,
           :workflows,
           :custom_fields,
           :custom_values,
           :custom_fields_projects,
           :custom_fields_trackers,
           :time_entries,
           :journals,
           :journal_details,
           :queries,
           :repositories,
           :changesets,
           :watchers, :groups_users

  fixtures :organizations if Redmine::Plugin.installed?(:redmine_organizations)

  let(:contractor_role) { Function.where(name: "Contractors").first_or_create }
  let(:project_office_role) { Function.where(name: "Project Office").first_or_create }

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
    get :index, params: { query_id: q.id }
    expect(response).to be_successful
    expect(assigns(:query)).to_not be_nil
    expect(assigns(:query).filters).to include 'authorized_viewers'
  end

  it 'does not add an "authorized viewers filter" to requests if module is not enable for the selected project' do
    q = IssueQuery.create!(name: "new-query", user: User.find(2), visibility: 2, project: @project)
    @project.enabled_module_names -= ['limited_visibility']
    expect(q.filters).to_not include 'authorized_viewers'
    get :index, params: { project_id: 1, query_id: q.id }
    expect(response).to be_successful
    expect(assigns(:query)).to_not be_nil
    expect(assigns(:query).filters).to_not include 'authorized_viewers'
  end

  it 'adds an "authorized viewers filter" to requests if module is enable' do
    project = Project.find(1)
    q = IssueQuery.create!(name: "new-query", user: User.find(2), visibility: 2, project: project)
    expect(q.filters).to_not include 'authorized_viewers'
    get :index, params: { project_id: 1, query_id: q.id }
    expect(response).to be_successful
    expect(assigns(:query)).to_not be_nil
    expect(assigns(:query).filters).to include 'authorized_viewers'
  end

  it 'displays issues according to current functional roles' do
    q = IssueQuery.create!(name: "new-query", user: User.current, visibility: 2, project: nil)

    # No authorized_viewers on issues
    get :index, params: { query_id: q.id }
    expect(assigns(:issues)).to_not be_nil
    expect(assigns(:issues)).to_not be_empty
    issues = assigns(:issues).select { |i| i.project == @project }
    issue1 = issues.first
    issue2 = issues.second
    expect(issue1).to_not be_nil
    expect(issue2).to_not be_nil

    # check if authorized_viewers match user visibility
    issue1.update_attribute(:authorized_viewers, "|#{contractor_role.id}|") # User visibility role
    issue2.update_attribute(:authorized_viewers, "|#{project_office_role.id}|") # Current user does not match this role
    q.filters.merge!({ "authorized_viewers" => { :operator => "mine", :values => [""] } })
    q.save!
    get :index, params: { query_id: q.id }
    expect(assigns(:issues)).to_not be_nil
    expect(@project.enabled_module_names).to include "limited_visibility"
    expect(assigns(:issues)).to include issue1
    expect(assigns(:issues)).to_not include issue2

    # displays all issues when the user has no specific function
    @membership.functions = []
    @membership2.functions = []
    get :index, params: { query_id: q.id }
    expect(assigns(:issues)).to_not be_nil
    expect(assigns(:issues)).to include issue1
    expect(assigns(:issues)).to include issue2
  end

  it 'assigned the issue to a user' do
    issue = Issue.first

    put :update, params: { id: issue.id, issue: { assigned_to_id: User.current.id } }

    issue.reload
    expect(issue.assigned_to_function_id).to be_nil
    expect(issue.assigned_to_id).to eq User.current.id
  end

  it 'assigned the issue to a functional role' do
    issue = Issue.first

    put :update, params: { id: issue.id, issue: { assigned_to_id: "function-#{contractor_role.id}" } }

    issue.reload
    expect(issue.assigned_to_function_id).to eq contractor_role.id
    expect(issue.assigned_to_id).to be_nil
  end

  it 'does NOT assigned the issue to a functional role if module is not enable' do
    issue = Issue.first
    @project.enabled_module_names -= ['limited_visibility']
    expect(issue.assigned_to_id).to be_nil

    put :update, params: { id: issue.id, issue: { assigned_to_id: "function-#{contractor_role.id}" } }

    issue.reload
    expect(issue.assigned_to_function_id).to be_nil
    expect(issue.assigned_to_id).to be_nil
  end

  # TODO Activate this spec when users permissions are validated before updating visibility
  pending 'requires :change_issue_visibility permission when changing issue visibility' do
    @request.session[:user_id] = 2 # jsmith - Manager (no change_issue_visibility permission)
    user = User.current = User.find(2)
    issue = Issue.first
    project = issue.project
    issue.update!(authorized_viewers: "|10|12|")

    expect(user.allowed_to?(:change_issues_visibility, project)).to be_falsey
    expect {
      put :update, params: { id: issue.id, issue: { authorized_viewers: "|12|13|" } }
    }.not_to change {
      issue.reload.authorized_viewer_ids
    }

    Role.find_by_name("Manager").add_permission!(:change_issues_visibility)
    user.allowed_to?(:change_issues_visibility, project)

    expect(user.reload.allowed_to?(:change_issues_visibility, project)).to be_truthy
    expect {
      put :update, params: { id: issue.id, issue: { authorized_viewers: "|12|13|" } }
    }.to change {
      issue.reload.authorized_viewer_ids
    }.from([10, 12]).to([12, 13])
  end

  it 'requires no extra permission when changing authorized viewers as an admin' do
    issue = Issue.first
    project = issue.project

    expect(User.current.reload.allowed_to?(:change_issues_visibility, project)).to be_truthy
    expect {
      put :update, params: { id: issue.id, issue: { authorized_viewers: "|#{contractor_role.id}|" } }
    }.to change {
      issue.reload.authorized_viewer_ids
    }.from([]).to([contractor_role.id])
  end

  # Test compatibility with the redmine multiprojects_issue plugin
  if Redmine::Plugin.installed?(:redmine_multiprojects_issue)
    describe 'multiprojects_issues' do

      before do
        @query = IssueQuery.create!(name: "new-query", user: User.current, visibility: 2, project: nil)

        # No authorized_viewers on issues
        get :index, params: { query_id: @query.id }
        expect(assigns(:issues)).to_not be_nil
        issues = assigns(:issues).select { |i| i.project == @project }
        @issue1 = issues.first
        @issue2 = issues.second
        @issue2.projects = [@project2] # issue2 becomes multi-project

        # check if authorized_viewers match user visibility
        @issue1.update_attribute(:authorized_viewers, "|#{contractor_role.id}|") # User visibility role
        @issue2.update_attribute(:authorized_viewers, "|#{project_office_role.id}|") # Current user does not match this role
        @query.filters.merge!({ "authorized_viewers" => { :operator => "mine", :values => [""] } })
        @query.save!
      end

      it 'displays issues according to functional roles on secondary projects' do
        get :index, params: { query_id: @query.id }
        expect(assigns(:issues)).to_not be_nil
        expect(assigns(:issues)).to include @issue1
        expect(assigns(:issues)).to include @issue2 # issue2 is now visible because user is member of the secondary project with correct role
      end

      it 'displays no issue when the user has NOT the specific function' do
        @membership2.functions = [contractor_role]
        get :index, params: { query_id: @query.id }
        expect(assigns(:issues)).to_not be_nil
        expect(assigns(:issues)).to include @issue1
        expect(assigns(:issues)).to_not include @issue2
      end

      it 'displays all issues when the user has no specific function' do
        @membership2.functions = []
        @issue2.update_attribute(:authorized_viewers, "||")
        @issue2.reload

        get :index, params: { query_id: @query.id }
        expect(assigns(:issues)).to_not be_nil
        expect(assigns(:issues)).to include @issue1
        expect(assigns(:issues)).to include @issue2
      end
    end
  end

  describe "GET /issues" do
    it 'should issue#show show icon of popup modal of all roles on the project per tracker' do
      get :show, params: { id: 1 }
      expect(response.body).to include("icon-only icon-help")
      assert_select "a[class='icon-only icon-help']"
    end
  end

  describe "GET /issues" do
    it 'should issue#new show icon of popup modal of all roles on the project per tracker' do
      get :new
      expect(response.body).to include("icon-only icon-help")
      assert_select "a[class='icon-only icon-help']"
    end
  end

  if Redmine::Plugin.installed?(:redmine_organizations)
    describe 'issues visibility through OrganizationNonMemberFunctions' do

      # User 7 does not belongs to any project
      let!(:query) { IssueQuery.create!(name: "new-query",
                                        user: User.find(7),
                                        visibility: 2,
                                        project: nil) }
      let!(:issue4) { Issue.find(4) }
      let!(:issue7) { Issue.find(7) }

      before do
        @request.session[:user_id] = 7
        User.current = User.find(7)

        issue4.project.enable_module!("limited_visibility")
        issue4.update_attribute(:authorized_viewers, "|#{project_office_role.id}|")

        issue7.project.enable_module!("limited_visibility")
        issue7.update_attribute(:authorized_viewers, "|#{contractor_role.id}|")

        query.filters.merge!({ "authorized_viewers" => { :operator => "mine", :values => [""] } })
        query.save!
      end

      it 'does not show issues when user has not the right function' do
        get :index, params: { query_id: query.id }
        expect(assigns(:issues)).to_not be_nil
        expect(assigns(:issues)).to_not be_empty
        expect(assigns(:issues)).to_not include issue4
        expect(assigns(:issues)).to_not include issue7
      end

      it 'shows issues when user is non member with correct function' do
        User.current.update_attribute(:organization_id, 1)
        OrganizationNonMemberRole.create!(organization_id: 1,
                                          role_id: contractor_role.id,
                                          project_id: issue7.project_id)
        OrganizationNonMemberFunction.create!(organization_id: 1,
                                              function_id: contractor_role.id,
                                              project_id: issue7.project_id)

        get :index, params: { query_id: query.id }
        expect(assigns(:issues)).to_not be_nil
        expect(assigns(:issues)).to_not be_empty
        expect(assigns(:issues)).to_not include issue4
        expect(assigns(:issues)).to include issue7
      end
    end
  end

end
