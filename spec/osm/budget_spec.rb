# encoding: utf-8
require 'spec_helper'


describe "Budget" do

  it "Create Budget" do
    b = Osm::Budget.new(
      :id => 1,
      :section_id => 2,
      :name => 'Name',
    )

    b.id.should == 1
    b.section_id.should == 2
    b.name.should == 'Name'
    b.valid?.should == true
  end

  it "Sorts Budget by section ID then name" do
    b1 = Osm::Budget.new(:section_id => 1, :name => 'a')
    b2 = Osm::Budget.new(:section_id => 2, :name => 'a')
    b3 = Osm::Budget.new(:section_id => 2, :name => 'b')

    data = [b2, b3, b1]
    data.sort.should == [b1, b2, b3]
  end


  describe "Using the API" do

    it "Get budgets for section" do
      data = {
        "identifier" => "categoryid",
        "items" => [
          {
            "categoryid" => "2",
            "sectionid" => "3",
            "name" => "Name",
            "archived" => "1"
          }
        ]
      }
      FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/finances.php?action=getCategories&sectionid=3", :body => data.to_json, :content_type => 'application/json')

      budgets = Osm::Budget.get_for_section(@api, 3)
      budgets.should == [Osm::Budget.new(:id => 2, :section_id => 3, :name => 'Name')]
    end

    it "Create budget (success)" do
      budget = Osm::Budget.new(
        :section_id => 2,
        :name => 'Budget Name',
      )

      url = "https://www.onlinescoutmanager.co.uk/finances.php?action=addCategory&sectionid=2"
      HTTParty.should_receive(:post).with(url, :body => {
        'apiid' => @CONFIGURATION[:api][:osm][:id],
        'token' => @CONFIGURATION[:api][:osm][:token],
        'userid' => 'user_id',
        'secret' => 'secret',
      }) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body => '{"ok":true}'}) }
      Osm::Budget.should_receive(:get_for_section).with(@api, 2, {:no_cache=>true}) { [Osm::Budget.new(:id => 3, :section_id => 2, :name => 'Existing budget'), Osm::Budget.new(:id => 4, :section_id => 2, :name => '** Unnamed **')] }
      url = "https://www.onlinescoutmanager.co.uk/finances.php?action=updateCategory&sectionid=2"
      HTTParty.should_receive(:post).with(url, :body => {
        'apiid' => @CONFIGURATION[:api][:osm][:id],
        'token' => @CONFIGURATION[:api][:osm][:token],
        'userid' => 'user_id',
        'secret' => 'secret',
        'categoryid' => 4,
        'column' => 'name',
        'value' => 'Budget Name',
        'section_id' => 2,
        'row' => 0,
      }) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body => '{"ok":true}'}) }

      budget.create(@api).should == true
      budget.id.should == 4
    end

    it "Create budget (failure (not created))" do
      budget = Osm::Budget.new(
        :section_id => 2,
        :name => 'Budget Name',
      )
    
      url = "https://www.onlinescoutmanager.co.uk/finances.php?action=addCategory&sectionid=2"
      HTTParty.should_receive(:post).with(url, :body => {
        'apiid' => @CONFIGURATION[:api][:osm][:id],
        'token' => @CONFIGURATION[:api][:osm][:token],
        'userid' => 'user_id',
        'secret' => 'secret',
      }) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body => '{"ok":true}'}) }
      Osm::Budget.should_receive(:get_for_section).with(@api, 2, {:no_cache=>true}) { [Osm::Budget.new(:id => 3, :section_id => 2, :name => 'Existing budget')] }

      budget.create(@api).should == false
    end
    
    it "Create budget (failure (not updated))" do
      budget = Osm::Budget.new(
        :section_id => 2,
        :name => 'Budget Name',
      )
    
      url = "https://www.onlinescoutmanager.co.uk/finances.php?action=addCategory&sectionid=2"
      HTTParty.should_receive(:post).with(url, :body => {
        'apiid' => @CONFIGURATION[:api][:osm][:id],
        'token' => @CONFIGURATION[:api][:osm][:token],
        'userid' => 'user_id',
        'secret' => 'secret',
      }) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body => '{"ok":true}'}) }
      Osm::Budget.should_receive(:get_for_section).with(@api, 2, {:no_cache=>true}) { [Osm::Budget.new(:id => 3, :section_id => 2, :name => '** Unnamed **')] }
      url = "https://www.onlinescoutmanager.co.uk/finances.php?action=updateCategory&sectionid=2"
      HTTParty.should_receive(:post).with(url, :body => {
        'apiid' => @CONFIGURATION[:api][:osm][:id],
        'token' => @CONFIGURATION[:api][:osm][:token],
        'userid' => 'user_id',
        'secret' => 'secret',
        'categoryid' => 3,
        'column' => 'name',
        'value' => 'Budget Name',
        'section_id' => 2,
        'row' => 0,
      }) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body => '{"ok":false}'}) }

      budget.create(@api).should == false
    end
    
    it "Update budget (success)" do
      budget = Osm::Budget.new(
        :id => 1,
        :section_id => 2,
        :name => 'Budget Name',
      )
    
      url = "https://www.onlinescoutmanager.co.uk/finances.php?action=updateCategory&sectionid=2"
      HTTParty.should_receive(:post).with(url, :body => {
        'apiid' => @CONFIGURATION[:api][:osm][:id],
        'token' => @CONFIGURATION[:api][:osm][:token],
        'userid' => 'user_id',
        'secret' => 'secret',
        'categoryid' => 1,
        'column' => 'name',
        'value' => 'Budget Name',
        'section_id' => 2,
        'row' => 0,
      }) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body => '{"ok":true}'}) }
    
      budget.update(@api).should == true
    end
    
    it "Update budget (failure)" do
      budget = Osm::Budget.new(
        :id => 1,
        :section_id => 2,
        :name => 'Budget Name',
      )

      HTTParty.should_receive(:post) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body => '{"ok":false}'}) }
    
      budget.update(@api).should == false
    end
    
    it "Delete budget (success)" do
      budget = Osm::Budget.new(
        :id => 1,
        :section_id => 2,
        :name => 'Budget Name',
      )
    
      url = "https://www.onlinescoutmanager.co.uk/finances.php?action=deleteCategory&sectionid=2"
      HTTParty.should_receive(:post).with(url, :body => {
        'apiid' => @CONFIGURATION[:api][:osm][:id],
        'token' => @CONFIGURATION[:api][:osm][:token],
        'userid' => 'user_id',
        'secret' => 'secret',
        'categoryid' => 1,
      }) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body => '{"ok":true}'}) }
    
      budget.delete(@api).should == true
    end
    
    it "Delete budget (failure)" do
      budget = Osm::Budget.new(
        :id => 1,
        :section_id => 2,
        :name => 'Budget Name',
      )
    
      url = "https://www.onlinescoutmanager.co.uk/finances.php?action=deleteCategory&sectionid=2"
      HTTParty.should_receive(:post).with(url, :body => {
        'apiid' => @CONFIGURATION[:api][:osm][:id],
        'token' => @CONFIGURATION[:api][:osm][:token],
        'userid' => 'user_id',
        'secret' => 'secret',
        'categoryid' => 1,
      }) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body => '{"ok":false}'}) }
    
      budget.delete(@api).should == false
    end
    
  end


end
