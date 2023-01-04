require "spec_helper"

describe ProjectsController, :type => :controller do

  render_views

  fixtures :projects, :versions, :users, :email_addresses, :roles, :members,
           :member_roles, :issues, :journals, :journal_details,
           :trackers, :projects_trackers, :issue_statuses,
           :enabled_modules, :enumerations, :boards, :messages,
           :attachments, :custom_fields, :custom_values, :time_entries,
           :wikis, :wiki_pages, :wiki_contents, :wiki_content_versions,
           :functions, :project_functions, :project_function_trackers

  if Redmine::Plugin.installed?(:redmine_organizations)
    fixtures :organizations, :organization_functions, :organization_roles
  end

  let(:parent_project) { Project.find(1) }
  let(:function_1) { Function.find(1) }
  # let(:first_parent_member) { parent_project.memberships.first }

  before do
    @request.session[:user_id] = 2
    Role.find_by_name('Manager').add_permission! :add_subprojects
    parent_project.members.each do |member|
      member.functions << function_1
      member.save
    end
  end

  it "creates subproject with inherited member's functions" do
    expect(parent_project.memberships.first.functions).to_not be_empty

    expect { post :create, :params => { :project => {
      :name => 'inherited',
      :identifier => 'inherited',
      :parent_id => parent_project.id,
      :inherit_members => '1' } }
    }.to change(Project, :count)

    project = Project.order('id desc').first
    expect(project.name).to eq 'inherited'
    expect(project.parent).to eq parent_project
    expect(project.memberships.count).to be > 0
    expect(project.memberships.count).to eq parent_project.memberships.count

    expect(project.memberships.first.roles).to_not be_empty
    expect(project.memberships.first.roles).to eq parent_project.memberships.first.roles
    expect(project.memberships.first.functions).to_not be_empty
    expect(project.memberships.first.functions).to eq parent_project.memberships.first.functions
  end

  describe "GET /projects" do
    it "should project#show show icon View all functions activated description" do
      @request.session[:user_id] = 1
      # set a description in the first two functions
      Function.find(1).update_attribute :description, 'desforfunction1'
      Function.find(2).update_attribute :description, 'desforfunction2'

      get :show, :params => {
        :id => 1,
        :tab => "members"
      }
      assert_select "a[class='icon-only icon-help']"
      expect(response.body).to include('showModal')
      expect(response.body).to include("function1")
      expect(response.body).to include("function2")
      expect(response.body).to include("desforfunction1")
      expect(response.body).to include("desforfunction2")
    end

    it "Should contain two links check all and uncheck everything in setting tab functional_roles" do
      @request.session[:user_id] = 1
      get :settings, :params => {
        :id => 1,
        :tab => "functional_roles",
        :nav => "general",
      }

      assert_select 'a[href=?][onclick=?]', '#', "checkAll('functions-form', true); return false;"
      assert_select 'a[href=?][onclick=?]', '#', "checkAll('functions-form', false); return false;"
    end
  end

  describe "copy a project" do
    let(:source_project) { Project.find(1) }

    it "copy all members" do
      @request.session[:user_id] = 1 # admin
      post :copy, :params => {
        :id => source_project.id,
        :project => {
          :name => 'test project',
          :identifier => 'test-project'
        },
        :only => %w(members)
      }
      new_pro = Project.last

      expect(new_pro.members.count).to eq(source_project.members.count)
      expect(new_pro.project_functions.count).to eq(0)
      if Redmine::Plugin.installed?(:redmine_organizations)
        expect(new_pro.organization_functions.count).to eq(0)
      end
    end

    it "copy all functions and organizations of members" do
      @request.session[:user_id] = 1 # admin
      pft = source_project.project_function_trackers.where(tracker_id: 1).first
      pft.visible = true
      pft.save
      post :copy, :params => {
        :id => source_project.id,
        :project => {
          :name => 'test project',
          :identifier => 'test-project'
        },
        :only => %w(members functions functions_organizations_of_members)
      }

      new_project = Project.last
      expect(new_project.project_function_trackers.where(tracker_id: 1).first.visible).to eq(true)
      expect(new_project.members.count).to eq(source_project.members.count)
      expect(new_project.project_functions.count).to eq(source_project.project_functions.count)
      expect(new_project.project_functions.first.authorized_viewers).to eq('|1|2|')
      expect(new_project.project_functions.second.authorized_viewers).to eq('|2|')
      if Redmine::Plugin.installed?(:redmine_organizations)
        expect(new_project.organization_functions.count).to eq(source_project.organization_functions.count)
      end
    end
  end
end
