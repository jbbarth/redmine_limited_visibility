require "spec_helper"

describe ProjectsController, :type => :controller do

  render_views

  fixtures :projects, :versions, :users, :email_addresses, :roles, :members,
           :member_roles, :issues, :journals, :journal_details,
           :trackers, :projects_trackers, :issue_statuses,
           :enabled_modules, :enumerations, :boards, :messages,
           :attachments, :custom_fields, :custom_values, :time_entries,
           :wikis, :wiki_pages, :wiki_contents, :wiki_content_versions,
           :functions

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

    expect { post :create, :params => {:project => {
        :name => 'inherited',
        :identifier => 'inherited',
        :parent_id => parent_project.id,
        :inherit_members => '1'}}
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

end
