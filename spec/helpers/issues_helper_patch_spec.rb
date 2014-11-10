require 'spec_helper'

describe IssuesHelper do

  let(:contractor_role) { Function.where(name: "Contractors").first_or_create }
  let(:project_office_role) { Function.where(name: "Project Office").first_or_create }
  let (:detail_add) { JournalDetail.new(property: 'attr', old_value: nil, value: "|#{contractor_role.id}|", prop_key: 'authorized_viewers') }
  let (:detail_change) { JournalDetail.new(property: 'attr', old_value: "|#{contractor_role.id}|", value: "|#{project_office_role.id}|", prop_key: 'authorized_viewers') }
  let (:detail_delete) { JournalDetail.new(property: 'attr', old_value: "|#{contractor_role.id}|", value: "", prop_key: 'authorized_viewers') }

  describe 'show_detail' do

    it 'should display new function with html' do
      show_detail(detail_add, false).should include "<strong>Involved members</strong> set to <i>#{contractor_role.name}</i>"
    end

    it 'should display new function with html if old_value is just "||"' do
      detail_add.stub(:old_value).and_return("||")
      show_detail(detail_add, false).should include "<strong>Involved members</strong> set to <i>#{contractor_role.name}</i>"
    end

    it 'should display changing functions with html' do
      show_detail(detail_change, false).should include "<strong>Involved members</strong> changed from <i>#{contractor_role.name}</i> to <i>#{project_office_role.name}</i>"
    end

    it 'should display deleted functions with html' do
      show_detail(detail_delete, false).should include "<strong>Involved members</strong> deleted (<del><i>#{contractor_role.name}</i></del>)"
    end

    it 'should display new function without html' do
      show_detail(detail_add, true).should include "Involved members set to #{contractor_role.name}"
    end

    it 'should display changing functions without html' do
      show_detail(detail_change, true).should include "Involved members changed from #{contractor_role.name} to #{project_office_role.name}"
    end

    it 'should display deleted functions without html' do
      show_detail(detail_delete, true).should include "Involved members deleted (#{contractor_role.name})"
    end
  end

  describe "functions_from_authorized_viewers" do
    it "returns a list of functions from an authorized_viewers string" do
      roles = functions_from_authorized_viewers("|#{contractor_role.id}|")
      roles.map(&:class).uniq.should == [Function]
      roles.map(&:id).should == [contractor_role.id]
    end

    it "returns an empty array if no authorized_viewer given" do
      functions_from_authorized_viewers("").should == []
      functions_from_authorized_viewers(nil).should == []
    end

    it "doesn't break if function doesn't exist anymore" do
      functions_from_authorized_viewers("99999").should == []
    end

    it "doesn't break if data is completely invalid" do
      functions_from_authorized_viewers("   |foo|bar=1||").should == []
    end
  end
end
