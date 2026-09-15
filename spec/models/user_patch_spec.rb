require 'spec_helper'

describe User do

  fixtures :users, :roles, :functions, :projects, :members, :member_roles

  if Redmine::Plugin.installed?(:redmine_organizations)
    fixtures :organizations
  end

  let(:user) { User.generate! }
  let(:public_project) { Project.find(1) }
  let(:private_project) { Project.find(2) }
  let(:subproject) { Project.find(3) }

  def add_member(principal, project, function_ids = [])
    member = Member.new(principal: principal, project: project)
    member.roles << Role.find(1)
    function_ids.each { |function_id| member.member_functions.build(function_id: function_id) }
    member.save!
  end

  describe "#project_ids_by_function" do
    it "groups the projects of the user's memberships by function" do
      add_member(user, public_project, [1, 2])
      add_member(user, private_project, [1])

      expect(user.project_ids_by_function.transform_values(&:sort)).to eq(1 => [1, 2], 2 => [1])
    end

    it "includes the functions of the non-member group on public projects only" do
      add_member(Group.non_member, public_project, [3])
      add_member(Group.non_member, private_project, [4])

      expect(user.project_ids_by_function).to eq(3 => [public_project.id])
    end

    it "ignores the non-member group on projects where the user is a member" do
      add_member(Group.non_member, public_project, [3])
      add_member(user, public_project, [1])

      expect(user.project_ids_by_function).to eq(1 => [public_project.id])
    end

    it "uses the anonymous group for the anonymous user" do
      add_member(Group.non_member, public_project, [3])
      add_member(Group.anonymous, public_project, [4])

      expect(User.anonymous.project_ids_by_function).to eq(4 => [public_project.id])
    end

    it "ignores archived projects" do
      add_member(user, public_project, [1])
      public_project.update_column(:status, Project::STATUS_ARCHIVED)

      expect(user.project_ids_by_function).to eq({})
    end

    it "loads the memberships once per user object" do
      add_member(user, public_project, [1])
      user.project_ids_by_function

      queries = 0
      callback = ->(*, payload) { queries += 1 if payload[:sql].include?('members') }
      ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') do
        user.project_ids_by_function
        user.project_ids_without_function
      end
      expect(queries).to eq 0
    end

    it "reloads the memberships with the user" do
      user.project_ids_by_function
      add_member(user, public_project, [1])

      expect(user.reload.project_ids_by_function).to eq(1 => [public_project.id])
    end
  end

  describe "#project_ids_without_function" do
    it "returns the projects where a membership has no function" do
      add_member(user, public_project, [1])
      add_member(user, private_project)

      expect(user.project_ids_without_function).to eq [private_project.id]
    end

    it "includes the non-member group memberships without function on public projects" do
      add_member(Group.non_member, public_project)

      expect(user.project_ids_without_function).to eq [public_project.id]
    end
  end

  describe "organization non-member functions" do
    before do
      skip "requires redmine_organizations" unless Redmine::Plugin.installed?(:redmine_organizations)

      user.update_column(:organization_id, 2)
      # Granted to the parent organization, on the parent project
      OrganizationNonMemberFunction.create!(organization_id: 1, function_id: 5, project_id: public_project.id)
    end

    it "grants the function on the project and its subprojects" do
      expect(user.project_ids_by_function[5]).to match_array public_project.self_and_descendants.ids
    end

    it "removes the project and its subprojects from the projects without function" do
      add_member(user, subproject)
      add_member(user, private_project)

      expect(user.project_ids_without_function).to eq [private_project.id]
    end
  end
end
