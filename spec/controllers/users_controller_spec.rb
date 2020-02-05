require 'spec_helper'

describe UsersController, type: :controller do

  include ActionView::Helpers::TranslationHelper

  fixtures :users

  render_views

  let(:user) { User.find(1) } #member of project(5)

  before do
    @request.session[:user_id] = 1
  end

  describe "GET 'edit'" do
    it "should display the user functional roles per project" do
      get 'edit', params: {id: user.id} # , tab: 'memberships'
      expect(response).to be_successful
      assert_select "#tab-content-memberships table.memberships"
      assert_select "#tab-content-memberships table.memberships th", {text: 'Roles'}
      assert_select "#tab-content-memberships table.memberships th", {text: translate(:label_functional_roles)}
    end
  end

end
