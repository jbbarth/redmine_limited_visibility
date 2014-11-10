require 'spec_helper'
require 'redmine_limited_visibility/roles_controller_patch'

describe RolesController do
  fixtures :users

  before { @request.session[:user_id] = 1 }

  describe "GET 'index'" do
    it "should be successful" do
      get 'index'
      response.should be_success
      assigns(:functional_roles).should_not be_nil
      assigns(:roles).should_not be_nil
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
      response.should redirect_to(roles_path)
    end
  end

  describe "creating or updating a role" do
    it "should allow permissions for this Role" do
      post :create, role: { name: "NewRole", permissions: ["edit_project", "manage_members", "create_issue_templates", ""] }
      created_role = Role.find_by_name("NewRole")
      created_role.permissions.should_not eq([])
      put :update, { id: created_role.id, role: { name: "UpdatedRole", permissions: ["edit_project", "manage_members", "create_issue_templates", ""] } }
      updated_role = Role.find_by_name("UpdatedRole")
      updated_role.should_not be_nil
      updated_role.permissions.should_not eq([])
    end
  end

end
