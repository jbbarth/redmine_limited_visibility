require_relative '../spec_helper'

describe LimitedVisibilityHelper do

  fixtures :users, :roles, :projects, :members, :member_roles, :enabled_modules
  if Redmine::Plugin.installed?(:redmine_organizations)
    fixtures :organizations
  end

  describe 'visibility_roles_for_current_user' do

    before do
      populate_membership
    end

    it 'should retrieve visibility roles for current user' do
      visibility_roles_for_current_user(@project).should_not be_nil
      visibility_roles_for_current_user(@project).should include @role1
      visibility_roles_for_current_user(@project).should_not include @role2
    end

  end
end
