require 'spec_helper'

describe FunctionsController, type: :controller do
  fixtures :users

  before { @request.session[:user_id] = 1 }

  describe "creating a function" do
    it "should increment the Function count" do
      expect do
        post :create, function: { name: "NewFunction" }
      end.to change(Function, :count).by(1)
    end

    it "should redirect to roles index" do
      post :create, function: { name: "NewFunction" }
      expect(response).to redirect_to(roles_path)
    end
  end

  describe "creating or updating a 'functional' role" do
    it "should save or update a new function" do
      post :create, function: { name: "NewFunction", authorized_viewers: "|17|18|" }
      created_function = Function.find_by_name("NewFunction")
      put :update, id: created_function.id, function: { name: "UpdatedFunction", authorized_viewers: "|17|18|" }
      updated_function = Function.find_by_name("UpdatedFunction")
    end
  end
end
