# frozen_string_literal: true

require 'spec_helper'

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
           :watchers, :groups_users, :functions

  fixtures :organizations if Redmine::Plugin.installed?(:redmine_organizations)

  let(:contractor_function) { Function.where(name: "Contractors").first_or_create }
  let(:project_office_function) { Function.where(name: "Project Office").first_or_create }

  before do
    @request.session[:user_id] = 1
    User.current = User.find(1)
    @project = Project.first
    @project.enable_module!("limited_visibility")
    @project2 = Project.find(2)
    @project2.enable_module!("limited_visibility")
    @membership = Member.new(user_id: User.current.id, project_id: @project.id)
    @membership.roles << Role.first
    @membership.functions << contractor_function
    @membership.save!
    @membership2 = Member.new(user_id: User.current.id, project_id: @project2.id)
    @membership2.roles << Role.first
    @membership2.functions << project_office_function
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
    q = IssueQuery.create!(name: "new-query", user: User.find(2), visibility: 2, project: @project2)
    @project2.enabled_module_names -= ['limited_visibility']
    expect(q.filters).to_not include 'authorized_viewers'
    get :index, params: { project_id: 2, query_id: q.id }
    expect(response).to be_successful
    expect(assigns(:query)).to_not be_nil
    expect(assigns(:query).filters).to_not include 'authorized_viewers'
  end

  it 'adds an "authorized viewers filter" to requests if module is enable' do
    q = IssueQuery.create!(name: "new-query", user: User.find(2), visibility: 2, project: @project2)
    expect(q.filters).to_not include 'authorized_viewers'
    get :index, params: { project_id: @project2.id, query_id: q.id }
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
    issue1.update_attribute(:authorized_viewers, "|#{contractor_function.id}|") # User visibility role
    issue2.update_attribute(:authorized_viewers, "|#{project_office_function.id}|") # Current user does not match this role
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

    put :update, params: { id: issue.id, issue: { assigned_to_id: "function-#{contractor_function.id}" } }

    issue.reload
    expect(issue.assigned_to_function_id).to eq contractor_function.id
    expect(issue.assigned_to_id).to be_nil
  end

  it 'does NOT assigned the issue to a functional role if module is not enable' do
    issue = Issue.first
    @project.enabled_module_names -= ['limited_visibility']
    expect(issue.assigned_to_id).to be_nil

    put :update, params: { id: issue.id, issue: { assigned_to_id: "function-#{contractor_function.id}" } }

    issue.reload
    expect(issue.assigned_to_function_id).to be_nil
    expect(issue.assigned_to_id).to be_nil
  end

  # TODO: Activate this spec when users permissions are validated before updating visibility
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
    expect do
      put :update, params: { id: issue.id, issue: { authorized_viewers: "|#{contractor_function.id}|" } }
    end.to change {
      issue.reload.authorized_viewer_ids
    }.from([]).to([contractor_function.id])
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
        @issue1.update_attribute(:authorized_viewers, "|#{contractor_function.id}|") # User visibility role
        @issue2.update_attribute(:authorized_viewers, "|#{project_office_function.id}|") # Current user does not match this role
        @query.filters["authorized_viewers"] = { :operator => "mine", :values => [""] }
        @query.save!
      end

      it 'displays issues according to functional roles on secondary projects' do
        get :index, params: { query_id: @query.id }
        expect(assigns(:issues)).to_not be_nil
        expect(assigns(:issues)).to include @issue1
        expect(assigns(:issues)).to include @issue2 # issue2 is now visible because user is member of the secondary project with correct role
      end

      it 'displays no issue when the user has NOT the specific function' do
        @membership2.functions = [contractor_function]
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
        issue4.update_attribute(:authorized_viewers, "|#{project_office_function.id}|")

        issue7.project.enable_module!("limited_visibility")
        issue7.update_attribute(:authorized_viewers, "|#{contractor_function.id}|")

        query.filters["authorized_viewers"] = { :operator => "mine", :values => [""] }
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
                                          role_id: Role.first.id,
                                          project_id: issue7.project_id)
        OrganizationNonMemberFunction.create!(organization_id: 1,
                                              function_id: contractor_function.id,
                                              project_id: issue7.project_id)

        get :index, params: { query_id: query.id }
        expect(assigns(:issues)).to_not be_nil
        expect(assigns(:issues)).to_not be_empty
        expect(assigns(:issues)).to_not include issue4
        expect(assigns(:issues)).to include issue7
      end

      it 'does not shows issues when user has permissions on project but not the right function' do
        User.current.update_attribute(:organization_id, 1)
        OrganizationNonMemberRole.create!(organization_id: 1,
                                          role_id: Role.first.id,
                                          project_id: issue4.project_id)
        OrganizationNonMemberFunction.create!(organization_id: 1,
                                              function_id: project_office_function.id,
                                              project_id: issue7.project_id)

        get :index, params: { query_id: query.id }
        expect(assigns(:issues)).to_not be_nil
        expect(assigns(:issues)).to_not include issue4
        expect(assigns(:issues)).to_not include issue7
      end

      context "non-member exception has a specific function" do
        let!(:function_1) { Function.find_or_create_by!(name: "function_1") }
        let!(:function_2) { Function.find_or_create_by!(name: "function_2") }
        let!(:issue_4) { Issue.find(4) }
        let!(:non_member_user) do
          user = User.new(login: 'non-member.user',
                          firstname: 'non-member',
                          lastname: "user")
          user.mail = "non-member.user@somenet.foo"
          user.organization_id = 3
          user.save!
          user
        end
        let!(:project_onlinestore) { Project.find('onlinestore') }
        let!(:role_reporter) { Role.find(3) }
        let!(:orga_a) { Organization.find(1) }
        let!(:orga_a_team_b) { Organization.find(3) }
        let!(:project_ecookbook) { Project.find(1) }

        before do
          @request.session[:user_id] = non_member_user.id
          User.current = non_member_user
          OrganizationNonMemberRole.find_or_create_by!(organization: orga_a, role: role_reporter, project: project_onlinestore)
          Role.where(id: 4).each { |r| r.permissions.each { |p| r.permissions.delete(p.to_sym) }; r.save!; }

          expect(OrganizationNonMemberRole.count).to eq(1)
          OrganizationNonMemberFunction.find_or_create_by!(organization_id: 3, function: function_1, project: project_onlinestore)
          expect(OrganizationNonMemberRole.count).to eq(1)
          expect(User.current.organization_id).to eq 3

          @query = IssueQuery.create!(name: "new-query", user: User.current, visibility: 2, project: nil)
          # No authorized_viewers on issues
          get :index, params: { query_id: @query.id }
          expect(assigns(:issues)).to_not be_nil
          @query.filters["authorized_viewers"] = { :operator => "mine", :values => [function_1.id.to_s] }
          @query.save!
        end

        it "displays issues which has no specified functions" do
          issue_4.update_attribute(:authorized_viewers, "||")
          get :index, params: { query_id: @query.id }
          expect(assigns(:issues)).to_not be_nil
          expect(assigns(:issues)).to_not be_empty
          expect(assigns(:issues)).to include issue_4
        end

        it "displays a list of issues visible by the specified function" do
          issue_4.update_attribute(:authorized_viewers, "|#{function_1.id}|")
          get :index, params: { query_id: @query.id }
          expect(assigns(:issues)).to_not be_nil
          expect(assigns(:issues)).to_not be_empty
          expect(assigns(:issues)).to include issue_4
        end

        it "DOES NOT display a list of issues not visible by the specified function" do
          issue_4.update_attribute(:authorized_viewers, "|#{function_2.id}|")
          get :index, params: { query_id: @query.id }
          expect(assigns(:issues)).to_not be_nil
          expect(assigns(:issues)).to_not include issue_4
        end
      end
    end
  end

  describe "form/issue" do
    before do
      @request.session[:user_id] = 2
    end

    it 'should issue#new show functions when assigned_to_id is not required' do
      get :new, params: { :project_id => 1, :tracker_id => 1, :status_id => 1 }
      expect(response.body).to include('function-1')
    end

    it 'should issue#edit show functions when assigned_to_id is not required' do
      get :edit, params: { :id => 1 }
      expect(response.body).to include('function-1')
    end

    it 'should not issue#new show functions when assigned_to_id is required' do
      WorkflowPermission.delete_all
      WorkflowPermission.create!(:old_status_id => 1, :tracker_id => 1, :role_id => 1, :field_name => 'assigned_to_id', :rule => 'required')

      get :new, params: { :project_id => 1, :tracker_id => 1, :status_id => 1 }
      expect(response.body).to_not include('function-1')
    end

    it 'should not issue#edit show functions when assigned_to_id is required' do
      WorkflowPermission.delete_all
      WorkflowPermission.create!(:old_status_id => 1, :tracker_id => 1, :role_id => 1, :field_name => 'assigned_to_id', :rule => 'required')

      get :edit, params: { :id => 1 }
      expect(response.body).to_not include('function-1')
    end
  end

  describe "Export/csv" do

    let(:issue) { Issue.find(2) }

    it "displays the full name of the user if assigned to a user" do
      columns = ["subject", "assigned_to"]
      get :index, params: { :project_id => 1,
                            :tracker_id => 2,
                            :set_filter => "1",
                            :c => columns,
                            :format => 'csv' }

      expect(response).to be_successful
      expect(response.content_type).to eq 'text/csv; header=present'

      lines = response.body.chomp.split("\n")
      expect(lines[1].split(',')[2]).to eq issue.assigned_to.name.to_s
    end

    it "displays the name of the function if assigned to a function" do
      function = Function.find(1)
      issue.assigned_to = nil
      issue.assigned_function = Function.find(1)
      issue.save
      columns = ["subject", "assigned_to"]

      get :index, params: { :project_id => 1,
                            :tracker_id => 2,
                            :set_filter => "1",
                            :c => columns,
                            :format => 'csv' }

      expect(response).to be_successful
      expect(response.content_type).to eq 'text/csv; header=present'

      lines = response.body.chomp.split("\n")
      expect(lines[1].split(',')[2]).to eq function.name.to_s
    end
  end
end
