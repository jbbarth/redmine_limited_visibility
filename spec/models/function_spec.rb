require 'spec_helper'

describe Function do
  it 'can return all functions' do
    contractor_role = Function.where(name: "Contractors").first_or_create
    Function.where(name: "Project Office").first_or_create
    functions = Function.all
    functions.size.should be >= 2
    functions.find { |role| role.name == contractor_role.name }.should_not be_nil
  end

  it 'set default visibility after creation of a new function' do
    function = Function.create(name: "New function", authorized_viewers: "")
    expect(function.authorized_viewers).to include function.id.to_s
  end

  describe "#authorized_viewer_ids" do
    it "returns authorized viewer function ids as an array of integers" do
      function = stub_model(Function, :authorized_viewers => "|3|45|")
      function.authorized_viewer_ids.should == [3,45]
    end

    it "doesn't break if column is blank" do
      function = stub_model(Function, :authorized_viewers => nil)
      function.authorized_viewer_ids.should == []
    end
  end
end
