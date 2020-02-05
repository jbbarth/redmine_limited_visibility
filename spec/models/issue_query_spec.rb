require 'spec_helper'
require 'redmine_limited_visibility/models/issue_query_patch'

def assert_query_result(expected, query)
  expect {
    assert_equal expected.map(&:id).sort, query.issues.map(&:id).sort
    assert_equal expected.size, query.issue_count
  }.to_not raise_error
end

describe IssueQuery do

  fixtures :users, :roles, :functions, :projects, :members, :member_roles, :issues, :issue_statuses, :project_functions, :project_function_trackers,
           :trackers, :enumerations, :custom_fields, :enabled_modules, :organizations, :organization_functions, :organization_roles

  describe 'filters and columns' do
    it 'contains a new "mine" operator' do
      expect(IssueQuery.operators).to include 'mine'
    end

    it 'has a new operator by filter type' do
      expect(IssueQuery.operators_by_filter_type).to include :list_visibility
    end

    it 'has a new available column for involved functions' do
      expect(IssueQuery.available_columns.find { |column| column.name == :authorized_viewers }).to_not be_nil
    end

    it 'initialize an "authorized_viewers" filter' do
      query = IssueQuery.new
      expect(query.available_filters).to include 'authorized_viewers'
    end

    it 'initialize an "assigned_to_function_id" filter' do
      query = IssueQuery.new
      expect(query.available_filters).to include 'assigned_to_function_id'
    end

    it 'has a new has_been_assigned_to column' do
      expect(IssueQuery.available_columns.find { |column| column.name == :has_been_assigned_to }).to_not be_nil
    end

    describe 'assigned_to_member_with_function_id filter' do

      let(:contractor_role) { Function.where(name: "Contractors").first_or_create }
      let(:project_office_role) { Function.where(name: "Project Office").first_or_create }

      before do
        @user = User.find(1)
        @project = Project.first
        @project.enable_module!("limited_visibility")
        @project2 = Project.find(2)
        @project2.enable_module!("limited_visibility")
        @membership = Member.new(user_id: @user.id, project_id: @project.id)
        @membership.roles << Role.first
        @membership.functions << contractor_role
        @membership.save!
        @membership2 = Member.new(user_id: @user.id, project_id: @project2.id)
        @membership2.roles << Role.first
        @membership2.functions << project_office_role
        @membership2.save!
        expect(@user.member_of?(@project)).to be true
        expect(@user.member_of?(@project2)).to be true

        @issue1 = @project.issues.first
        @issue1.assigned_to = @user
        @issue1.save
        @issue2 = @project.issues.second
        @issue3 = @project.issues.third
        @issue4 = Issue.find(4)

        @query = IssueQuery.new(:name => '_', :project => @project)
      end

      it 'initializes an "assigned_to_member_with_function_id" filter' do
        query = IssueQuery.new
        expect(query.available_filters).to include 'assigned_to_member_with_function_id'
        expect(query.available_filters["assigned_to_member_with_function_id"][:type]).to be :list_optional

        expect(query.available_filters["assigned_to_member_with_function_id"][:values]).to include ['function1','1']
        expect(query.available_filters["assigned_to_member_with_function_id"][:values]).to include ['function2','2']
        expect(query.available_filters["assigned_to_member_with_function_id"][:values]).to include ['function3','3']
      end

      it "searches assigned to for users with the Function" do
        @query.add_filter('assigned_to_member_with_function_id', '=', [contractor_role.id.to_s])
        assert_query_result [@issue1], @query
      end

      it "returns an empty set with empty function" do
        empty_function = Function.find_or_create_by(name: 'EmptyFunction')
        @query.add_filter('assigned_to_member_with_function_id', '=', [empty_function.id.to_s])

        assert_query_result [], @query
      end

      it "searches assigned to for users without the Function" do
        @query.add_filter('assigned_to_member_with_function_id', '!', [contractor_role.id.to_s])

        expect(@query.issues).to_not include(@issue1)
      end

      it "searches assigned to for users not assigned to any Function (none)" do
        @query.add_filter('assigned_to_member_with_function_id', '!*', [''])

        expect(@query.issues).to_not include(@issue1)
      end

      it "searches assigned to for users assigned to any Function (all)" do
        @query.add_filter('assigned_to_member_with_function_id', '*', [''])

        assert_query_result [@issue1, @issue2, @issue3], @query
      end

      it "returns issues with ! empty function" do
        empty_function = Function.find_or_create_by(name: 'EmptyFunction')
        @query.add_filter('assigned_to_member_with_function_id', '!', [empty_function.id.to_s])

        expect(@query.issues).to include(@issue1)
        expect(@query.issues).to include(@issue2)
        expect(@query.issues).to include(@issue3)
        expect(@query.issues).to_not include(@issue4)
      end
    end
  end
end
