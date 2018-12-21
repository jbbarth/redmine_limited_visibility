require "spec_helper"

describe ProjectsHelper, :type => :controller do

  render_views

  before do
    @controller = ProjectsController.new
    @request    = ActionDispatch::TestRequest.create
    @response   = ActionDispatch::TestResponse.new
    User.current = nil
    @request.session[:user_id] = 1 # admin
  end

  it "should display project_settings_tabs_with_functional_roles" do
    get :settings, params: {:id => 1}
    assert_select "a[href='/projects/1/settings/functional_roles']"
  end
end
