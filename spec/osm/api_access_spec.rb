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
    api_access.valid?.should == true
  end

  it "Sorts by id" do
    a1 = Osm::ApiAccess.new(:id => 1)
    a2 = Osm::ApiAccess.new(:id => 2)

    data = [a2, a1]
    data.sort.should == [a1, a2]
  end


  describe "Using the API" do

    before :each do
      body = {
        'apis' => [
          {
            'apiid' => '1',
            'name' => 'API Name',
            'permissions' => { 'read' => '10', 'readwrite' => '20', 'administer' => '100' }
          }, {
            'apiid' => '2',
            'name' => 'API 2 Name',
            'permissions' => { 'read' => '10', 'readwrite' => '20' }
          }
        ]
      }
      $api.should_receive(:post_query).with('ext/settings/access/?action=getAPIAccess&sectionid=1').and_return(body)
    end

    describe "Get All" do
      it "From OSM" do
        api_accesses = Osm::ApiAccess.get_all(api: $api, section: 1)
  
        api_accesses.size.should == 2
        api_access = api_accesses[0]
        api_access.id.should == 1
        api_access.name.should == 'API Name'
        api_access.permissions.should == {:read => [:read], :readwrite => [:read, :write], :administer => [:read, :write, :administer]}
      end

      it "From cache" do
        api_accesses = Osm::ApiAccess.get_all(api: $api, section: 1)
        $api.should_not_receive(:post_query)
        Osm::ApiAccess.get_all(api: $api, section: 1).should == api_accesses
      end
    end

    it "Get One" do
      api_access = Osm::ApiAccess.get(api: $api, section: 1, for_api: 2)
      api_access.id.should == 2
    end

    it "Get Ours" do
      api_access = Osm::ApiAccess.get_ours(api: $api, section: 1)
      api_access.id.should == 1
    end

  end

end
