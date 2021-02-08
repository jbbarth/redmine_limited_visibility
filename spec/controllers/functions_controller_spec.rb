require 'spec_helper'

describe FunctionsController, type: :controller do
  include ApplicationHelper  
  render_views

  fixtures :users, :functions, :projects, :trackers, :projects_trackers, :project_functions, :project_function_trackers, :issues,
  :members 
  before do
    set_language_if_valid('en')
    @request.session[:user_id] = 1
  end

  describe "creating a function" do
    it "should increment the Function count" do
      expect do
        post :create, params: {function: {name: "NewFunction"}}
      end.to change(Function, :count).by(1)
    end

    it "should redirect to roles index" do
      post :create, params: {function: {name: "NewFunction"}}
      expect(response).to redirect_to(roles_path)
    end
  end

  describe "creating or updating a 'functional' role" do
    it "should save  a new function" do
      post :create, params: {function: {name: "newFunction", description: "testDescription", authorized_viewers: "|17|18|", hidden_on_overview: false}}
      created_function = Function.all.last
      expect(created_function.name).to eq("newFunction")
      expect(created_function.description).to eq("testDescription")      
    end

    it "should save or update a new function" do
      post :create, params: {function: {name: "NewFunction", description: "NewDescription", authorized_viewers: "|17|18|", hidden_on_overview: false}}
      created_function = Function.find_by_name("NewFunction")
      #test put method
      put :update, params: {id: created_function.id, function: {name: "UpdatedFunction", description: "UpdatedDescription", authorized_viewers: "|17|18|"}}
      expect(created_function.reload.name).to eq "UpdatedFunction"
      expect(created_function.reload.description).to eq "UpdatedDescription"
      #test patch method (new default method used by Rails to update)
      patch :update, params: {id: created_function.id, function: {name: "UpdatedFunctionViaPatchMethod", description: "UpdatedDesViaPatchMethod", hidden_on_overview: true, active_by_default: false}}
      expect(created_function.reload.name).to eq "UpdatedFunctionViaPatchMethod"
      expect(created_function.reload.description).to eq "UpdatedDesViaPatchMethod"
      expect(created_function.hidden_on_overview).to eq true
      expect(created_function.active_by_default).to eq false
    end
  end

  describe "modify the available functions per project" do
    it "should save or update project_function relations" do
      # create
      expect do
        put :available_functions_per_project, params: {project_id: 2, autocheck_mode: "1", function_ids: ["1", "2", "3", "4"]}
      end.to change(ProjectFunction, :count).by(4)
      created_relation = ProjectFunction.last
      expect(created_relation.reload.authorized_viewers).to be nil
      expect(created_relation.project.autochecked_functions_mode).to eq "1"
      # update
      expect do
        put :available_functions_per_project, params: {project_id: 2, autocheck_mode: "2", function_ids: ["1", "2", "4"]}
      end.to change(ProjectFunction, :count).by(-1)
      created_relation = ProjectFunction.last
      expect(created_relation.reload.authorized_viewers).to be nil
      expect(created_relation.project.autochecked_functions_mode).to eq "2"
    end
  end

  describe "visible_functions_per_tracker" do
    it "should save the visible functions per project" do
      pfts = Project.find(1).project_function_trackers
      expect(pfts.map(&:visible).uniq).to eq [false]
      put :visible_functions_per_tracker, params: {project_id: 1, function_visibility: {'1' => [1, 2], '2' => [1, 2], '3' => [1, 2]}}
      expect(pfts.reload.map(&:visible).uniq).to eq [true]
    end

    it "should save the automatically checked functions per function" do
      expect(
          put :activated_functions_per_tracker, params: {project_id: 2, function_activation_per_user_function: {'1' => [1, 2], '2' => [1, 2]}}
      ).to redirect_to(:controller => 'projects', :action => 'settings', :id => 2, :tab => 'functional_roles')
    end

    it "should save the automatically checked functions per trackers" do
      expect(
          put :activated_functions_per_tracker, params: {project_id: 2, function_activation_per_tracker: {'2' => [1, 2], '3' => [1, 2]}}
      ).to redirect_to(:controller => 'projects', :action => 'settings', :id => 2, :tab => 'functional_roles')
    end
  end

  describe "copy_functions_settings_from_project" do
    it "should test the copy of all settings" do
      current_available_functions = Project.find(2).functions
      expect(current_available_functions.count).to eq 0
      expect do
        put :copy_functions_settings_from_project, params: {project_id: 2, project_from: "1"}
      end.to change(current_available_functions.reload, :count).by(2)
    end
  end

  describe "popup modal of all roles on the project per tracker" do
    it "should return content_type javascript" do     
      get :index, :params => {:project_id => 1, :tracker_id => 1}, :xhr => true
      assert_response :success
      expect(response).to render_template("functions/index")
      expect(response.content_type).to eq("text/javascript")
      assert_match /ajax-modal/, response.body
    end

    it "should listing all the descriptions of the roles" do
      #set a description in the first two functions 
      Function.find(1).update_attribute :description , 'desforfunction1'
      Function.find(2).update_attribute :description , 'desforfunction2'
      get :index, :params => {:project_id => 1, :tracker_id => 1}, :xhr => true
      expect(response.body).to include("function1")
      expect(response.body).to include("function2")
      expect(response.body).to include("desforfunction1")
      expect(response.body).to include("desforfunction2")
    end

    it "should show a legend on the color codes " do
      get :index, :params => {:project_id => 1, :tracker_id => 1}, :xhr => true
      assert_response :success     
      expect(response.body).to include("<i class=fa-icon-ok>")
      expect(response.body).to include("<i class=fa-icon-remove>")
      expect(response.body).to include("Active role in this project with members")
      expect(response.body).to include("Active role in this project without members")
      expect(response.body).to include("Silent role for this tracker")
      expect(response.body).to include("Inactive role in this project with members")
      expect(response.body).to include("Inactive role in this project with members")
    end

    it "should appear functions with the appropriate color  " do
      get :index, :params => {:project_id => 1, :tracker_id => 1}, :xhr => true
      assert_response :success     
      #here, we use data-role-id, To avoid confusion between style of the color codes and style span of function
      expect(response.body).to include('class=\"role disabled involved no-member\" data-role-id=')
      expect(response.body).to include('class=\"role disabled quiet no-member\" data-role-id=')
    end

     it "should appear functions with the appropriate color when member_function existed" do
      fun_mem = MemberFunction.new
      fun_mem.member = Project.find(1).members.first
      fun_mem.function = Project.find(1).functions.first
      fun_mem.save
      fun_mem = MemberFunction.new
      fun_mem.member = Project.find(1).members.first
      fun_mem.function = Project.find(1).functions.second
      fun_mem.save
      get :index, :params => {:project_id => 1, :tracker_id => 1}, :xhr => true
      assert_response :success    
      #here, we use data-role-id, To avoid confusion between style of the color codes and style span of function
      expect(response.body).not_to include('class=\"role disabled involved no-member\" data-role-id=')
      expect(response.body).not_to include('class=\"role disabled quiet no-member\" data-role-id=')
    end

    it "should appear functions with the appropriate color when member_function existed and silent role not existed" do
      fun_mem = MemberFunction.new
      fun_mem.member = Project.find(1).members.first
      fun_mem.function = Project.find(1).functions.first
      fun_mem.save
      fun_mem = MemberFunction.new
      fun_mem.member = Project.find(1).members.first
      fun_mem.function = Project.find(1).functions.second
      fun_mem.save
      
      ProjectFunctionTracker.all.first.update_attribute :visible , true
      get :index, :params => {:project_id => 1, :tracker_id => 1}, :xhr => true
      assert_response :success      
      expect(response.body).not_to include('class=\"role disabled quiet\" data-role-id=')
    end
     
  end

end
