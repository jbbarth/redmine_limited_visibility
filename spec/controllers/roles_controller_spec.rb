require_relative '../spec_helper'
require 'redmine_limited_visibility/roles_controller_patch'

describe RolesController do

  fixtures :users

  before { @request.session[:user_id] = 1 }

  describe "creating a role" do
    it "should increment the Role count" do
      expect do
        post :create, role: { name: "NewRole"}
      end.to change(Role, :count).by(1)
    end

    it "should redirect to roles index" do
      post :create, role: { name: "NewRole"}
      response.should redirect_to(roles_path)
    end
  end

  describe "creating or updating a 'standard' role" do
    it "should allow permissions for this Role" do
      post :create, role: { name: "NewRole", permissions: ["edit_project", "manage_members", "create_issue_templates", ""], authorized_viewers: "|17|18|" }
      created_role = Role.find_by_name("NewRole")
      created_role.permissions.should_not eq([])

      put :update, id: created_role.id, role: { name: "UpdatedRole", permissions: ["edit_project", "manage_members", "create_issue_templates", ""], authorized_viewers: "|17|18|" }
      updated_role = Role.find_by_name("UpdatedRole")
      updated_role.permissions.should_not eq([])
    end
  end

  describe "creating or updating a 'visibility' role" do
    it "should cancel all permissions for this Role" do
      post :create, role: { name: "NewRole", limit_visibility: "1", permissions: ["edit_project", "manage_members", "create_issue_templates", ""], authorized_viewers: "|17|18|" }
      created_role = Role.find_by_name("NewRole")
      created_role.permissions.should eq([])

      put :update, id: created_role.id, role: { name: "UpdatedRole", limit_visibility: "1", permissions: ["edit_project", "manage_members", "create_issue_templates", ""], authorized_viewers: "|17|18|" }
      updated_role = Role.find_by_name("UpdatedRole")
      updated_role.permissions.should eq([])
    end
  end

end
