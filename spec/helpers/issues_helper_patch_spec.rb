require_relative '../spec_helper'

describe IssuesHelper do

  let (:contractor_role) { find_or_create(:role, name: "Contractors", limit_visibility: true) }
  let (:project_office_role) { find_or_create(:role, name: "Project Office", limit_visibility: true) }
  let (:detail_add) { JournalDetail.new(property: 'attr', old_value: nil, value: "|#{contractor_role.id}|", prop_key: 'authorized_viewers') }
  let (:detail_change) { JournalDetail.new(property: 'attr', old_value: "|#{contractor_role.id}|", value: "|#{project_office_role.id}|", prop_key: 'authorized_viewers') }
  let (:detail_delete) { JournalDetail.new(property: 'attr', old_value: "|#{contractor_role.id}|", value: "", prop_key: 'authorized_viewers') }

  describe 'show_detail' do

    it 'should display new role with html' do
      show_detail(detail_add, false).should include "<strong>Involved members</strong> set to <i>#{contractor_role.name}</i>"
    end

    it 'should display new role with html if old_value is just "||"' do
      detail_add.stub(:old_value).and_return("||")
      show_detail(detail_add, false).should include "<strong>Involved members</strong> set to <i>#{contractor_role.name}</i>"
    end

    it 'should display changing roles with html' do
      show_detail(detail_change, false).should include "<strong>Involved members</strong> changed from <i>#{contractor_role.name}</i> to <i>#{project_office_role.name}</i>"
    end

    it 'should display deleted roles with html' do
      show_detail(detail_delete, false).should include "<strong>Involved members</strong> deleted (<del><i>#{contractor_role.name}</i></del>)"
    end

    it 'should display new role without html' do
      show_detail(detail_add, true).should include "Involved members set to #{contractor_role.name}"
    end

    it 'should display changing roles without html' do
      show_detail(detail_change, true).should include "Involved members changed from #{contractor_role.name} to #{project_office_role.name}"
    end

    it 'should display deleted roles without html' do
      show_detail(detail_delete, true).should include "Involved members deleted (#{contractor_role.name})"
    end
  end

  describe "roles_from_authorized_viewers" do
    it "returns a list of roles from an authorized_viewers string" do
      roles = roles_from_authorized_viewers("|1|2|3|")
      roles.map(&:class).uniq.should == [Role]
      roles.map(&:id).should == [1,2,3]
    end
  end
end
