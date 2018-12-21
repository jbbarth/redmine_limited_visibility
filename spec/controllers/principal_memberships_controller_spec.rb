require File.dirname(__FILE__) + '/../spec_helper'

require 'redmine_limited_visibility/models/member_patch'

describe PrincipalMembershipsController, type: :controller do

  render_views

  include ActiveSupport::Testing::Assertions

  let(:contractor_role) {Function.where(name: "Contractors").first_or_create}
  let(:project_office_role) {Function.where(name: "Project Office").first_or_create}

  before do
    User.current = User.find(1)
    @request.session[:user_id] = 1 # admin
    # Setting.default_language = 'en'
  end

  it "should create user memberships with functions" do
    assert_difference 'Member.count', 2 do
      post :create, params: {:user_id => 7, :membership => {:project_ids => [3, 4], :role_ids => [2, 3], :function_ids => [contractor_role.id, project_office_role.id]}, :format => 'js'}, xhr: true
      expect(response).to be_successful
      assert_template 'create'
      assert_equal 'text/javascript', response.content_type
    end
    memberships = Member.order('id DESC').limit(2)
    expect(memberships[0].principal).to eq User.find(7)
    expect(memberships[0].role_ids).to eq [2, 3]
    expect(memberships[0].function_ids).to eq [contractor_role.id, project_office_role.id]
    expect(memberships[0].project_id).to eq 4
    expect(response.body).to include('tab-content-memberships')
  end

  it "should create user memberships with functions (with strings as params)" do
    assert_difference 'Member.count', 2 do
      post :create, params: {:user_id => 7, :membership => {:project_ids => [3, 4], :role_ids => ["2"], :function_ids => [contractor_role.id.to_s]}, :format => 'js'}, xhr: true
      expect(response).to be_successful
      assert_template 'create'
      assert_equal 'text/javascript', response.content_type
    end
    memberships = Member.order('id DESC').limit(2)
    expect(memberships[0].principal).to eq User.find(7)
    expect(memberships[0].role_ids).to eq [2]
    expect(memberships[0].function_ids).to eq [contractor_role.id]
    expect(memberships[0].project_id).to eq 4
    expect(response.body).to include('tab-content-memberships')
  end

  it "should create user memberships with failure" do
    assert_no_difference 'Member.count' do
      post :create, params: {:user_id => 7, :membership => {:project_ids => [3]}, :format => 'js'}, xhr: true
      expect(response).to be_successful
      assert_template 'create'
      assert_equal 'text/javascript', response.content_type
    end
    expect(response.body).to include('alert')
    expect(response.body).to include('Role cannot be empty')
  end

end





