require 'spec_helper'

describe IssuesHelper, type: :helper do

  let(:contractor_role) { Function.where(name: "Contractors").first_or_create }
  let(:project_office_role) { Function.where(name: "Project Office").first_or_create }
  let (:detail_add) { JournalDetail.new(property: 'attr', old_value: nil, value: "|#{contractor_role.id}|", prop_key: 'authorized_viewers') }
  let (:detail_change) { JournalDetail.new(property: 'attr', old_value: "|#{contractor_role.id}|", value: "|#{project_office_role.id}|", prop_key: 'authorized_viewers') }
  let (:detail_delete) { JournalDetail.new(property: 'attr', old_value: "|#{contractor_role.id}|", value: "", prop_key: 'authorized_viewers') }

  describe 'show_detail' do

    it 'should display new function with html' do
      expect(show_detail(detail_add, false)).to include "<strong>Involved members</strong> set to <i>#{contractor_role.name}</i>"
    end

    it 'should display new function with html if old_value is just "||"' do
      allow(detail_add).to receive(:old_value).and_return("||")
      expect(show_detail(detail_add, false)).to include "<strong>Involved members</strong> set to <i>#{contractor_role.name}</i>"
    end

    it 'should display changing functions with html' do
      expect(show_detail(detail_change, false)).to include "<strong>Involved members</strong> changed from <i>#{contractor_role.name}</i> to <i>#{project_office_role.name}</i>"
    end

    it 'should display deleted functions with html' do
      expect(show_detail(detail_delete, false)).to include "<strong>Involved members</strong> deleted (<del><i>#{contractor_role.name}</i></del>)"
    end

    it 'should display new function without html' do
      expect(show_detail(detail_add, true)).to include "Involved members set to #{contractor_role.name}"
    end

    it 'should display changing functions without html' do
      expect(show_detail(detail_change, true)).to include "Involved members changed from #{contractor_role.name} to #{project_office_role.name}"
    end

    it 'should display deleted functions without html' do
      expect(show_detail(detail_delete, true)).to include "Involved members deleted (#{contractor_role.name})"
    end
  end
end
