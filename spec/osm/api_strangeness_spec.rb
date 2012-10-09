# encoding: utf-8
require 'spec_helper'


describe "Online Scout Manager API Strangeness" do

  before(:each) do
    Osm::Api.configure({:api_id=>'1234', :api_token=>'12345678', :api_name=>'API', :api_site=>:scout})
    @api = Osm::Api.new('2345', 'abcd')
  end


  it "handles an empty array representing no notepads" do
    FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/api.php?action=getNotepads", :body => '[]')
    @api.get_notepad(1).should == nil
  end


  it "handles a non existant array when no events" do
    data = '{"identifier":"eventid","label":"name"}'
    FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/events.php?action=getEvents&sectionid=1&showArchived=true", :body => data)

    @api.get_events(1).should == []
  end

end
