# encoding: utf-8
require 'spec_helper'


describe "API" do

  it "Create" do
    @api.should_not be_nil
    @api.api_id.should == @CONFIGURATION[:api][:osm][:id]
    @api.api_name.should == @CONFIGURATION[:api][:osm][:name]
  end

  it "Raises errors on trying to configure if abandonment is not acknowledged" do
    expect { Osm::Api.configure default_site: :osm, osm: { id: nil, token: nil, name: nil } }
      .to raise_error Osm::Error, /^The OSM gem is now unsupported. To continue using it append "i_know: :unsupported" to your passed options. See .+ for more details.$/
  end

  it "Raises errors on bad arguments to configure" do
    expect{ Osm::Api.configure(@CONFIGURATION[:api].select{ |k,v| (k != :default_site)}) }.to raise_error(ArgumentError, ':default_site does not exist in options hash or is invalid, this should be set to either :osm or :ogm')
    expect{ Osm::Api.configure(@CONFIGURATION[:api].merge(:default_site => :invalid)) }.to raise_error(ArgumentError, ':default_site does not exist in options hash or is invalid, this should be set to either :osm or :ogm')

    expect{ Osm::Api.configure(@CONFIGURATION[:api].select{ |k,v| (k != :ogm) && (k != :osm)}) }.to raise_error(ArgumentError, ':osm does not exist in options hash')
    expect{ Osm::Api.configure(@CONFIGURATION[:api].merge(:osm => '')) }.to raise_error(ArgumentError, ':osm must be a Hash')
    expect{ Osm::Api.configure(@CONFIGURATION[:api].merge(:osm => @CONFIGURATION[:api][:osm].select{ |k,v| (k != :id)})) }.to raise_error(ArgumentError, ':osm must contain a key :id')
    expect{ Osm::Api.configure(@CONFIGURATION[:api].merge(:osm => @CONFIGURATION[:api][:osm].select{ |k,v| (k != :token)})) }.to raise_error(ArgumentError, ':osm must contain a key :token')
    expect{ Osm::Api.configure(@CONFIGURATION[:api].merge(:osm => @CONFIGURATION[:api][:osm].select{ |k,v| (k != :name)})) }.to raise_error(ArgumentError, ':osm must contain a key :name')
    expect{ Osm::Api.configure(@CONFIGURATION[:api].merge(:ogm => '')) }.to raise_error(ArgumentError, ':ogm must be a Hash')
    expect{ Osm::Api.configure(@CONFIGURATION[:api].merge(:ogm => @CONFIGURATION[:api][:ogm].select{ |k,v| (k != :id)})) }.to raise_error(ArgumentError, ':ogm must contain a key :id')
    expect{ Osm::Api.configure(@CONFIGURATION[:api].merge(:ogm => @CONFIGURATION[:api][:ogm].select{ |k,v| (k != :token)})) }.to raise_error(ArgumentError, ':ogm must contain a key :token')
    expect{ Osm::Api.configure(@CONFIGURATION[:api].merge(:ogm => @CONFIGURATION[:api][:ogm].select{ |k,v| (k != :name)})) }.to raise_error(ArgumentError, ':ogm must contain a key :name')
  end

  it "Exposes the debug option seperatly too" do
    Osm::Api.debug.should == false
    Osm::Api.debug = true
    Osm::Api.debug.should == true
    Osm::Api.debug = false
    Osm::Api.debug.should == false
  end


  it "Raises errors on bad arguments to create" do
    # Both userid and secret must be passed
    expect{ Osm::Api.new('1', nil) }.to raise_error(ArgumentError, 'You must pass a secret (get this by using the authorize method)')
    expect{ Osm::Api.new(nil, '1') }.to raise_error(ArgumentError, 'You must pass a user_id (get this by using the authorize method)')

    expect{ Osm::Api.new('1', '2', :invalid_site) }.to raise_error(ArgumentError, 'site is invalid, if passed it should be either :osm or :ogm, if not passed then you forgot to run Api.configure')
  end


  it "authorizes a user to use the OSM API" do
    user_email = 'alice@example.com'
    user_password = 'alice'

    url = 'https://www.onlinescoutmanager.co.uk/users.php?action=authorise'
    post_data = {
      'apiid' => @CONFIGURATION[:api][:osm][:id],
      'token' => @CONFIGURATION[:api][:osm][:token],
      'email' => user_email,
      'password' => user_password,
    }
    HTTParty.should_receive(:post).with(url, {:body => post_data}) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>'{"userid":"id","secret":"secret"}'}) }

    Osm::Api.authorize(user_email, user_password).should == {:user_id => 'id', :secret => 'secret'}
  end

  it "sets a new API user" do
    @api.set_user('1', '2').is_a?(Osm::Api).should == true

    HTTParty.should_receive(:post).with("https://www.onlinescoutmanager.co.uk/test", {:body => {
      'apiid' => @CONFIGURATION[:api][:osm][:id],
      'token' => @CONFIGURATION[:api][:osm][:token],
      'userid' => '1',
      'secret' => '2',
    }}) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>'[]'}) }
    @api.perform_query('test')
  end


  describe "Get user roles" do

    before :each do
      @api = Osm::Api.new(3, 4)
    end

    it "Returns what OSM gives on success" do
      @api.stub(:perform_query).with('api.php?action=getUserRoles'){ ['a', 'b'] }
      @api.get_user_roles.should == ['a', 'b']
    end

    it "User has no roles in OSM" do
      @api.stub(:perform_query).with('api.php?action=getUserRoles'){ false }
      expect{ @api.get_user_roles! }.to raise_error(Osm::NoActiveRoles)
      @api.get_user_roles.should == []
    end

    it "Reraises any other Osm::Error" do
      @api.stub(:perform_query).with('api.php?action=getUserRoles'){ raise Osm::Error, 'Test' }
      expect{ @api.get_user_roles }.to raise_error(Osm::Error, 'Test')
    end

  end


  describe "User Permissions" do

    it "Get from API" do
      body = [
        {"sectionid"=>"1", "permissions"=>{"badge"=>20}},
        {"sectionid"=>"2", "permissions"=>{"badge"=>10}}
      ]
      FakeWeb.register_uri(:post, "https://www.onlinescoutmanager.co.uk/api.php?action=getUserRoles", :body => body.to_json, :content_type => 'application/json')

      permissions = {1 => {:badge => [:read, :write]}, 2 => {:badge => [:read]}}
      OsmTest::Cache.should_not_receive('read')
      @api.get_user_permissions.should == permissions
    end

    it "Get from cache" do
      permissions = {1 => {:a => [:read, :write]}, 2 => {:a => [:read]}}
      OsmTest::Cache.should_receive('exist?').with("OSMAPI-#{Osm::VERSION}-osm-permissions-user_id") { true }
      OsmTest::Cache.should_receive('read').with("OSMAPI-#{Osm::VERSION}-osm-permissions-user_id") { permissions }
      @api.get_user_permissions.should == permissions
    end

    it "Get ignoring cache" do
      data = [
        {"sectionid"=>"1", "permissions"=>{"badge"=>10}},
      ]
      body = {
        'apiid' => @CONFIGURATION[:api][:osm][:id],
        'token' => @CONFIGURATION[:api][:osm][:token],
        'userid' => 'user_id',
        'secret' => 'secret',
      }
      url = 'https://www.onlinescoutmanager.co.uk/api.php?action=getUserRoles'

      OsmTest::Cache.should_not_receive('exist?').with("OSMAPI-#{Osm::VERSION}-osm-permissions-user_id")
      OsmTest::Cache.should_not_receive('read').with("OSMAPI-#{Osm::VERSION}-osm-permissions-user_id")
      HTTParty.should_receive(:post).with(url, {:body=>body}) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>data.to_json}) }
      @api.get_user_permissions(:no_cache => true).should == {1 => {:badge => [:read]}}
    end

    it "Set" do
      permissions = {1 => {:a => [:read, :write]}, 2 => {:a => [:read]}}
      OsmTest::Cache.should_receive('exist?').with("OSMAPI-#{Osm::VERSION}-osm-permissions-user_id") { true }
      OsmTest::Cache.should_receive('read').with("OSMAPI-#{Osm::VERSION}-osm-permissions-user_id") { permissions }
      OsmTest::Cache.should_receive('write').with("OSMAPI-#{Osm::VERSION}-osm-permissions-user_id", permissions.merge(3 => {:a => [:read]}), {:expires_in=>600}) { true }
      @api.set_user_permissions(3, {:a => [:read]})
    end

  end


  describe "Get base URL" do
    it "For the class" do
      Osm::Api.base_url(:osm).should == 'https://www.onlinescoutmanager.co.uk'
      Osm::Api.base_url(:ogm).should == 'http://www.onlineguidemanager.co.uk'
    end

    it "For an instance" do
      @api.base_url.should == 'https://www.onlinescoutmanager.co.uk'
      @api.base_url(:osm).should == 'https://www.onlinescoutmanager.co.uk'
      @api.base_url(:ogm).should == 'http://www.onlineguidemanager.co.uk'
    end
  end


  describe "OSM and Internet error conditions:" do
    it "Raises a connection error if the HTTP status code was not 'OK'" do
      HTTParty.stub(:post) { OsmTest::DummyHttpResult.new(:response=>{:code=>'500'}) }
      expect{ Osm::Api.authorize('email@example.com', 'password') }.to raise_error(Osm::ConnectionError, 'HTTP Status code was 500')
    end


    it "Raises a connection error if it can't connect to OSM" do
      HTTParty.stub(:post) { raise SocketError }
      expect{ Osm::Api.authorize('email@example.com', 'password') }.to raise_error(Osm::ConnectionError, 'A problem occured on the internet.')
    end


    it "Raises an error if OSM returns an error (as a hash)" do
      HTTParty.stub(:post) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>'{"error":"Error message"}'}) }
      expect{ Osm::Api.authorize('email@example.com', 'password') }.to raise_error(Osm::Error, 'Error message')
    end

    it "Raises an error if OSM returns an error (as a hash in a hash)" do
      HTTParty.stub(:post) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>'{"error":{"message":"Error message"}}'}) }
      expect{ Osm::Api.authorize('email@example.com', 'password') }.to raise_error(Osm::Error, 'Error message')
    end

    it "Raises an error if OSM returns an error (as a plain string)" do
      HTTParty.stub(:post) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>'Error message'}) }
      expect{ Osm::Api.authorize('email@example.com', 'password') }.to raise_error(Osm::Error, 'Error message')
    end
  end

end
