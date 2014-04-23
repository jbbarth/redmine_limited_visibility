require_relative '../spec_helper'

describe IssuesHelper do

  describe 'show_detail' do

    before(:all) do
      Role.create(name: "Contractors", limit_visibility: true)
      Role.create(name: "Project Office", limit_visibility: true)
    end

    it 'should display new role with html' do
      detail = JournalDetail.new(:property => 'attr', :old_value => nil, :value => "|#{Role.find_by_name('Contractors').id}|", :prop_key => 'authorized_viewers')
      show_detail(detail, false).should include "<strong>Involved members</strong> set to <i>Contractors</i>"
    end

    it 'should display changing roles with html' do
      detail = JournalDetail.new(:property => 'attr', :old_value => "|#{Role.find_by_name('Contractors').id}|", :value => "|#{Role.find_by_name('Project Office').id}|", :prop_key => 'authorized_viewers')
      show_detail(detail, false).should include "<strong>Involved members</strong> changed from <i>Contractors</i> to <i>Project Office</i>"
    end

    it 'should display deleted roles with html' do
      detail = JournalDetail.new(:property => 'attr', :old_value => "|#{Role.find_by_name('Contractors').id}|", :value => "", :prop_key => 'authorized_viewers')
      show_detail(detail, false).should include "<strong>Involved members</strong> deleted (<del><i>Contractors</i></del>)"
    end

    it 'should display new role without html' do
      detail = JournalDetail.new(:property => 'attr', :old_value => nil, :value => "|#{Role.find_by_name('Contractors').id}|", :prop_key => 'authorized_viewers')
      show_detail(detail, true).should include "Involved members set to Contractors"
    end

    it 'should display changing roles without html' do
      detail = JournalDetail.new(:property => 'attr', :old_value => "|#{Role.find_by_name('Contractors').id}|", :value => "|#{Role.find_by_name('Project Office').id}|", :prop_key => 'authorized_viewers')
      show_detail(detail, true).should include "Involved members changed from Contractors to Project Office"
    end

    it 'should display deleted roles without html' do
      detail = JournalDetail.new(:property => 'attr', :old_value => "|#{Role.find_by_name('Contractors').id}|", :value => nil, :prop_key => 'authorized_viewers')
      show_detail(detail, true).should include "Involved members deleted (Contractors)"
    end

  end

end
