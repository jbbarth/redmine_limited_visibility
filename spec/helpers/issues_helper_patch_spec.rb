require_relative '../spec_helper'

describe IssuesHelper do

  describe 'show_detail' do

    before(:all) do
      Role.create(name: "Contractors", limit_visibility: true)
      Role.create(name: "Project Office", limit_visibility: true)
      @detail_add = JournalDetail.new(:property => 'attr', :old_value => nil, :value => "|#{Role.find_by_name('Contractors').id}|", :prop_key => 'authorized_viewers')
      @detail_change = JournalDetail.new(:property => 'attr', :old_value => "|#{Role.find_by_name('Contractors').id}|", :value => "|#{Role.find_by_name('Project Office').id}|", :prop_key => 'authorized_viewers')
      @detail_delete = JournalDetail.new(:property => 'attr', :old_value => "|#{Role.find_by_name('Contractors').id}|", :value => "", :prop_key => 'authorized_viewers')
    end

    it 'should display new role with html' do
      show_detail(@detail_add, false).should include "<strong>Involved members</strong> set to <i>Contractors</i>"
    end

    it 'should display changing roles with html' do
      show_detail(@detail_change, false).should include "<strong>Involved members</strong> changed from <i>Contractors</i> to <i>Project Office</i>"
    end

    it 'should display deleted roles with html' do
      show_detail(@detail_delete, false).should include "<strong>Involved members</strong> deleted (<del><i>Contractors</i></del>)"
    end

    it 'should display new role without html' do
      show_detail(@detail_add, true).should include "Involved members set to Contractors"
    end

    it 'should display changing roles without html' do
      show_detail(@detail_change, true).should include "Involved members changed from Contractors to Project Office"
    end

    it 'should display deleted roles without html' do
      show_detail(@detail_delete, true).should include "Involved members deleted (Contractors)"
    end

  end

end
