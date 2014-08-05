require_relative '../spec_helper'

describe LimitedVisibilityHelper do

  fixtures :users, :roles, :projects, :members, :member_roles, :enabled_modules

  describe 'visibility_roles_for_current_user' do

    let(:contractor_role) { find_or_create(:role, name: "Contractors", limit_visibility: true) }
    let(:project_office_role) { find_or_create(:role, name: "Project Office", limit_visibility: true) }

    before do
      User.current = User.find(1)
      @project = Project.first
      @membership = Member.new(user_id: User.current.id, project_id: @project.id)
      @membership.roles << contractor_role
      @membership.save!
      User.current.member_of?(@project).should be true
    end

    it 'should retrieve visibility roles for current user' do
      visibility_roles_for_current_user(@project).should_not be_nil
      visibility_roles_for_current_user(@project).should include contractor_role
      visibility_roles_for_current_user(@project).should_not include project_office_role
    end

  end
end
