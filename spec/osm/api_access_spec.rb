# encoding: utf-8
require 'spec_helper'


describe "API Access" do

  it "Create" do
    data = {
      :id => 1,
      :name => 'Name',
      :permissions => {:permission => [:read]},
    }
    api_access = Osm::ApiAccess.new(data)

    api_access.id.should == 1
    api_access.name.should == 'Name'
    api_access.permissions.should == {:permission => [:read]}
    api_access.valid?.should be_true
  end


  describe "Using the API" do

    before :each do
      body = {
        'apis' => [
          {
            'apiid' => '1',
            'name' => 'API Name',
            'permissions' => { 'read' => '10', 'readwrite' => '20' }
          }, {
            'apiid' => '2',
            'name' => 'API 2 Name',
            'permissions' => { 'read' => '10', 'readwrite' => '20' }
          }
        ]
      }
      FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/users.php?action=getAPIAccess&sectionid=1", :body => body.to_json)
    end

    it "Get All" do
      api_accesses = Osm::ApiAccess.get_all(@api, 1)

      api_accesses.size.should == 2
      api_access = api_accesses[0]
      api_access.id.should == 1
      api_access.name.should == 'API Name'
      api_access.permissions.should == {:read => [:read], :readwrite => [:read, :write]}
    end

    it "Get One" do
      api_access = Osm::ApiAccess.get(@api, 1, 2)
      api_access.id.should == 2
    end

    it "Get Ours" do
      api_access = Osm::ApiAccess.get_ours(@api, 1)
      api_access.id.should == 1
    end

  end

end
