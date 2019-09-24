require File.dirname(__FILE__) + '/../spec_helper'

describe Member do

  fixtures :users, :roles, :functions, :projects, :members, :member_roles

  it 'should return NO function for role without functions_managed' do
    member = Member.new
    member.roles << Role.generate!(:permissions => [:manage_members], :functions_managed => false)
    expect(member.managed_functions).to eq []
  end

  it 'should return all functions for role with all functions managed' do
    member = Member.new
    member.roles << Role.generate!(:permissions => [:manage_members], :all_functions_managed => true)
    expect(member.managed_functions).to match_array Function.all
  end

  it 'should return only projects functions for role with all functions managed' do
    project = Project.first
    member = Member.new(project: project)
    member.roles << Role.generate!(:permissions => [:manage_members], :all_functions_managed => true)
    expect(member.managed_functions).to match_array Function.available_functions_for(project)
  end

  it 'should return all functions for admins' do
    member = Member.new(:user => User.find(1))
    member.roles << Role.generate!
    expect(member.managed_functions).to match_array Function.all
  end

  it 'should return limited functions for role without all functions managed' do
    member = Member.new
    member.roles << Role.generate!(:permissions => [:manage_members], :all_functions_managed => false, :managed_function_ids => [1, 3])
    expect(member.managed_functions.map(&:id)).to match_array [1, 3]
  end

  it 'should combine managed functions from multiple roles' do
    member = Member.new
    member.roles << Role.generate!(:permissions => [:manage_members], :all_functions_managed => false, :managed_function_ids => [3])
    member.roles << Role.generate!(:permissions => [:manage_members], :all_functions_managed => false, :managed_function_ids => [1])
    expect(member.managed_functions.map(&:id)).to match_array [1, 3]
  end

  it 'should return no functions for role without permission' do
    member = Member.new
    member.roles << Role.generate!(:all_functions_managed => true)
    expect(member.managed_functions).to eq []
  end
end
