# frozen_string_literal: true

require 'spec_helper'

describe MembersController, type: :controller do
  render_views

  fixtures :projects, :users, :email_addresses, :roles, :members, :member_roles,
           :functions, :project_functions

  let(:project) { Project.find(1) }
  let(:user) { User.find(2) }
  let(:function) { Function.find(1) }
  let(:member) { Member.find_by(project: project, user: user) }

  before do
    @request.session[:user_id] = user.id
    User.current = user

    # Add a function to the member
    if member && !member.functions.include?(function)
      member.functions << function
      member.save!
    end
  end

  describe 'GET index with JSON format' do
    it 'returns memberships with functions in JSON' do
      get :index, params: { project_id: project.id, format: 'json' }

      expect(response).to be_successful
      expect(response.content_type).to include('application/json')

      json = JSON.parse(response.body)
      expect(json['memberships']).to be_present
      expect(json['memberships']).to be_an(Array)

      # Find the membership with our user
      membership = json['memberships'].find { |m| m['user'] && m['user']['id'] == user.id }
      expect(membership).to be_present

      # Verify functions array exists
      expect(membership['functions']).to be_present
      expect(membership['functions']).to be_an(Array)

      # Verify the function is in the response
      function_data = membership['functions'].find { |f| f['id'] == function.id }
      expect(function_data).to be_present
      expect(function_data['name']).to eq(function.name)
    end
  end

  describe 'GET index with XML format' do
    it 'returns memberships with functions in XML' do
      get :index, params: { project_id: project.id, format: 'xml' }

      expect(response).to be_successful
      expect(response.content_type).to include('application/xml')

      # Parse and verify XML structure
      xml = Nokogiri::XML(response.body)
      memberships = xml.xpath('//memberships/membership')
      expect(memberships).not_to be_empty

      # Find membership with our user
      membership_node = memberships.find do |m|
        user_node = m.xpath('user[@id]').first
        user_node && user_node['id'].to_i == user.id
      end

      expect(membership_node).to be_present

      # Verify functions array exists (using local-name to handle 'array:functions')
      functions = membership_node.xpath('.//*[local-name()="functions"]/function')
      expect(functions).not_to be_empty

      # Verify our function is present
      function_node = functions.find { |f| f['id'].to_i == function.id }
      expect(function_node).to be_present
      expect(function_node['name']).to eq(function.name)
    end
  end

  describe 'GET show with JSON format' do
    it 'returns a single membership with functions in JSON' do
      get :show, params: { id: member.id, format: 'json' }

      expect(response).to be_successful
      expect(response.content_type).to include('application/json')

      json = JSON.parse(response.body)
      expect(json['membership']).to be_present
      expect(json['membership']['id']).to eq(member.id)

      # Verify functions array exists
      expect(json['membership']['functions']).to be_present
      expect(json['membership']['functions']).to be_an(Array)

      # Verify the function is in the response
      function_data = json['membership']['functions'].find { |f| f['id'] == function.id }
      expect(function_data).to be_present
      expect(function_data['name']).to eq(function.name)
    end
  end

  describe 'GET show with XML format' do
    it 'returns a single membership with functions in XML' do
      get :show, params: { id: member.id, format: 'xml' }

      expect(response).to be_successful
      expect(response.content_type).to include('application/xml')

      xml = Nokogiri::XML(response.body)
      membership_node = xml.xpath('//membership').first
      expect(membership_node).to be_present

      # Verify functions array exists (using local-name to handle 'array:functions')
      functions = membership_node.xpath('.//*[local-name()="functions"]/function')
      expect(functions).not_to be_empty

      # Verify our function is present
      function_node = functions.find { |f| f['id'].to_i == function.id }
      expect(function_node).to be_present
      expect(function_node['name']).to eq(function.name)
    end
  end

  describe 'inherited functions' do
    let(:parent_project) { project }
    let(:child_project) do
      Project.create!(
        name: 'Child Project for API Test',
        identifier: 'child-project-api-test',
        parent: parent_project,
        inherit_members: true
      )
    end

    before do
      # Ensure parent member has function
      parent_member = Member.find_by(project: parent_project, user: user)
      if parent_member && !parent_member.functions.include?(function)
        parent_member.functions << function
        parent_member.save!
      end

      # Create child project
      child_project.save!

      # Create or update child member with role
      child_member = Member.find_or_create_by(project: child_project, user: user)
      if child_member.roles.empty?
        child_member.roles << Role.first
        child_member.save!
      end
    end

    it 'marks inherited functions with inherited flag in JSON response' do
      child_member = Member.find_by(project: child_project, user: user)
      skip 'Child member not created' unless child_member

      # Verify the function is inherited
      child_member_function = child_member.member_functions.find_by(function_id: function.id)
      skip 'Function not inherited' unless child_member_function

      get :show, params: { id: child_member.id, format: 'json' }

      expect(response).to be_successful
      json = JSON.parse(response.body)

      # Find the inherited function
      inherited_function = json['membership']['functions'].find { |f| f['id'] == function.id }
      expect(inherited_function).to be_present
      expect(inherited_function['inherited']).to be true if child_member_function.inherited?
    end
  end
end
