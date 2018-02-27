require File.dirname(__FILE__) + '/../spec_helper'

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
end
