require_relative '../spec_helper'

describe VisibilitiesController do

  fixtures :roles, :members, :member_roles

  let(:contractor_role) { find_or_create(:role, name: "Contractors", limit_visibility: true) }
  let(:project_office_role) { find_or_create(:role, name: "Project Office", limit_visibility: true) }

  describe "update_visibility_roles" do
    it "should update 'visibility' roles and do NOT modify 'standard' roles" do
      member = Member.first
      current_standard_role = member.roles.first
      put :update_visibility_roles, { id: member.id, membership: {role_ids: [project_office_role.id, contractor_role.id]} }
      expect(assigns(:project)).not_to be nil
      response.should redirect_to settings_project_path(assigns(:project), :tab => 'visibility')
      member.reload
      expect(member.roles).to include project_office_role
      expect(member.roles).to include contractor_role
      expect(member.roles).to include current_standard_role
    end
  end
end
