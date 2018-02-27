require File.dirname(__FILE__) + '/../spec_helper'

require 'redmine_limited_visibility/controllers/roles_controller_patch'

describe RolesController, type: :controller do
  fixtures :users

  before { @request.session[:user_id] = 1 }

  describe "GET 'index'" do
    it "should be successful" do
      get 'index'
      expect(response).to be_success
      expect(assigns(:functional_roles)).to_not be_nil
      expect(assigns(:roles)).to_not be_nil
    end
  end

  describe "creating a role" do
    it "should increment the Role count" do
      expect do
        post :create, role: { name: "NewRole" }
      end.to change(Role, :count).by(1)
    end

    it "should redirect to roles index" do
      post :create, role: { name: "NewRole" }
      expect(response).to redirect_to(roles_path)
    end
  end

  describe "creating or updating a role" do
    it "should allow permissions for this Role" do
      post :create, role: { name: "NewRole", permissions: ["edit_project", "manage_members", "create_issue_templates", ""] }
      created_role = Role.find_by_name("NewRole")
      expect(created_role.permissions).to_not eq([])
      put :update, { id: created_role.id, role: { name: "UpdatedRole", permissions: ["edit_project", "manage_members", "create_issue_templates", ""] } }
      updated_role = Role.find_by_name("UpdatedRole")
      expect(updated_role).to_not be_nil
      expect(updated_role.permissions).to_not eq([])
    end
  end

end
