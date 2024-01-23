require 'spec_helper'

describe "ProjectMembersInheritance" do

  fixtures :functions, :users, :roles,
           :projects, :trackers, :issue_statuses

  let!(:parent_project) { Project.generate! }
  let!(:parent_member) { Member.create!(principal: User.find(2),
                                        project: parent_project,
                                        role_ids: [1, 2],
                                        function_ids: [1, 2]).reload }

  before do
    User.current = nil
    expect(parent_member.roles.size).to eq 2
    expect(parent_member.functions.size).to eq 2
  end

  it "creates project with inherited members" do
    expect {
      project = Project.generate_with_parent!(parent_project, :inherit_members => true)
      project.reload
      expect(project.memberships.count).to eq 1
      member = project.memberships.first
      expect(member.principal).to eq parent_member.principal
      expect(member.roles.sort).to eq parent_member.roles.sort
      expect(member.functions.sort).to eq parent_member.functions.sort
    }.to change { Member.count }.by(1)
  end

  it "inherits members when turning on project setting" do
    Project.generate_with_parent!(parent_project, :inherit_members => false)

    expect {
      project = Project.order('id desc').first
      project.inherit_members = true
      project.save!
      project.reload

      expect(project.memberships.count).to eq 1
      member = project.memberships.first
      expect(member.principal).to eq parent_member.principal
      expect(member.roles.sort).to eq parent_member.roles.sort
      expect(member.functions.sort).to eq parent_member.functions.sort
    }.to change { Member.count }.by(1)
  end

  it "propagate when adding a member" do
    project = Project.generate_with_parent!(parent_project, :inherit_members => true)
    expect {
      member = Member.create(:principal => User.find(4),
                             :project => parent_project,
                             :role_ids => [1, 3],
                             :function_ids => [1, 3])
      member.reload

      inherited_member = project.memberships.order('id desc').first
      expect(inherited_member.principal).to eq member.principal
      expect(inherited_member.roles.sort).to eq member.roles.sort
      expect(inherited_member.functions.sort).to eq member.functions.sort
    }.to change { Member.count }.by(2)
  end

  it "merges functions when adding to parent project a user who is already a member" do
    project = Project.generate_with_parent!(parent_project, :inherit_members => true)
    user = User.find(4)
    Member.create!(:principal => user, :project => project,
                   :role_ids => [1, 2], :function_ids => [1, 2])

    expect {
      Member.create!(:principal => User.find(4), :project => parent_project.reload,
                     :role_ids => [1, 2], :function_ids => [1, 3])

      member = project.reload.memberships.detect { |m| m.principal == user }
      expect(member).to_not be_nil
      expect(member.roles.map(&:id).uniq.sort).to eq [1, 2]
      expect(member.functions.map(&:id).uniq.sort).to eq [1, 2, 3]
    }.to change { Member.count }.by(1)
  end

end

