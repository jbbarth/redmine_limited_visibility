require 'spec_helper'

describe Function do
  it 'can return all functions' do
    contractor_role = Function.where(name: "Contractors").first_or_create
    Function.where(name: "Project Office").first_or_create
    functions = Function.all
    expect(functions.size).to be >= 2
    expect(functions.find { |role| role.name == contractor_role.name }).to_not be_nil
  end

  it 'set default visibility after creation of a new function' do
    function = Function.create(name: "New function", authorized_viewers: "")
    expect(function.authorized_viewers).to include function.id.to_s
  end

  describe "#authorized_viewer_ids" do
    it "returns authorized viewer function ids as an array of integers" do
      function = Function.new(:authorized_viewers => "|3|45|")
      expect(function.authorized_viewer_ids).to eq [3,45]
    end

    it "doesn't break if column is blank" do
      function = Function.new(:authorized_viewers => nil)
      expect(function.authorized_viewer_ids).to eq []
    end
  end

  it "can create a function with a long name (> 30 chars)" do
    name = "Security manager and executive director"
    function = Function.new(name: name)
    expect(function.valid?).to be true
    expect(function.save).to be true
    expect(function.reload.name).to eq name
  end

  describe "functions_from_authorized_viewers" do
    it "returns a list of functions from an authorized_viewers string" do
      contractor_role = Function.where(name: "Contractors").first_or_create
      roles = Function.functions_from_authorized_viewers("|#{contractor_role.id}|")
      expect(roles.map(&:class).uniq).to eq [Function]
      expect(roles.map(&:id)).to eq [contractor_role.id]
    end

    it "returns an empty array if no authorized_viewer given" do
      expect(Function.functions_from_authorized_viewers("")).to eq []
      expect(Function.functions_from_authorized_viewers(nil)).to eq []
    end

    it "doesn't break if function doesn't exist anymore" do
      expect(Function.functions_from_authorized_viewers("99999")).to eq []
    end

    it "doesn't break if data is completely invalid" do
      expect(Function.functions_from_authorized_viewers("   |foo|bar=1||")).to eq []
    end
  end

  if Redmine::Plugin.installed?(:redmine_comments)
    it "Update the PrivateNotesGroup table, when update_private_notes_group" do
      function = Function.first
      group1 = Function.find(2)
      group2 = Function.find(3)
      group3 = Function.find(4)

      PrivateNotesGroup.create(group_id: group1.id, function_id: function.id)
      PrivateNotesGroup.create(group_id: group2.id, function_id: function.id)
      PrivateNotesGroup.create(group_id: function.id, function_id: group1.id)
      PrivateNotesGroup.create(group_id: group2.id, function_id: group1.id)
      PrivateNotesGroup.create(group_id: function.id, function_id: group2.id)
      PrivateNotesGroup.create(group_id: group1.id, function_id: group2.id)

      expect do
        function.update_private_notes_group([group3.id, group2.id])
      end.not_to change { PrivateNotesGroup.count }
    end
  end
end
