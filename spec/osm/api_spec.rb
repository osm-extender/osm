# encoding: utf-8
require 'spec_helper'


describe "API" do

  describe "Configuration" do

    it "Create" do
      $api_configuration.should_not be_nil
      $api_configuration.site.should == :osm
      $api_configuration.name.should == "API NAME"
      $api_configuration.id.should == "1"
      $api_configuration.token.should == "API TOKEN"
    end

    it "Reports debug option" do
      $api_configuration.debug.should == false
      $api_configuration.debug?.should == false

      api_configuration_2 = Osm::Api::Configuration.new(
        site:  :osm,
        id:    '1',
        token: 'API TOKEN',
        name:  'API NAME',
        debug: true,
      )
      api_configuration_2.debug.should == true
      api_configuration_2.debug?.should == true

      api_configuration_3 = Osm::Api::Configuration.new(
        site:  :osm,
        id:    '1',
        token: 'API TOKEN',
        name:  'API NAME',
        debug: 'apples',
      )
      api_configuration_3.debug.should == true
      api_configuration_3.debug?.should == true
    end

    describe "Create checks for required attributes" do

      let(:attributes) { {id: 10, token: 'token', name: 'name', } }

      [:id, :token, :name].each do |attribute|
        it attribute do
          attributes.delete(attribute)
          expect{ Osm::Api::Configuration.new(attributes) }.to raise_error(ArgumentError, "missing keyword: #{attribute}")
        end
      end

    end

    describe "Create checks that site is valid" do

      let(:attributes) { {id: 10, token: 'token', name: 'name', } }

      it "Valid" do
        attributes[:site] = :osm_staging
        expect{ Osm::Api::Configuration.new(attributes) }.not_to raise_error
      end

      it "Invalid" do
        attributes[:site] = :invalid
        expect{ Osm::Api::Configuration.new(attributes) }.to raise_error(ArgumentError, ":invalid is not a valid site (must be one of :osm, :osm_staging, :osm_migration).")
      end

    end


    it "Gets the base url for queries" do
      Osm::Api::Configuration.new(site: :osm, id: 1, token: 't', name: 'n').base_url.should == 'https://www.onlinescoutmanager.co.uk'
      Osm::Api::Configuration.new(site: :osm_staging, id: 1, token: 't', name: 'n').base_url.should == 'http://staging.onlinescoutmanager.co.uk'
      Osm::Api::Configuration.new(site: :osm_migration, id: 1, token: 't', name: 'n').base_url.should == 'https://migration.onlinescoutmanager.co.uk'
    end

    it "Builds a url from a path" do
      Osm::Api::Configuration.new(site: :osm, id: 1, token: 't', name: 'n').build_url('path').should == 'https://www.onlinescoutmanager.co.uk/path'
      Osm::Api::Configuration.new(site: :osm_staging, id: 1, token: 't', name: 'n').build_url('path/path1').should == 'http://staging.onlinescoutmanager.co.uk/path/path1'
      Osm::Api::Configuration.new(site: :osm_migration, id: 1, token: 't', name: 'n').build_url('another/path').should == 'https://migration.onlinescoutmanager.co.uk/another/path'
    end

    it "Creates the post attributes for queries" do
      $api_configuration.post_attributes.should == {"apiid"=>"1", "token"=>"API TOKEN"}
    end

  end # describe Configuration


  it "Create" do
    $api.should_not be_nil
    $api.class.default_configuration.should == $api_configuration
  end

  describe "Create requires a" do
    it "User ID" do
      expect{ Osm::Api.new(configuration: $api_configuration, secret: 'secret') }.to raise_error(ArgumentError, "You must pass a user_id (get this by using the authorize method)")
    end

    it "Secret" do
      expect{ Osm::Api.new(configuration: $api_configuration, user_id: 'user_id') }.to raise_error(ArgumentError, "You must pass a secret (get this by using the authorize method)")
    end

    it "Configuration" do
      expect{ Osm::Api.new(configuration: nil, user_id: 'user_id', secret: 'secret') }.to raise_error(ArgumentError, "You must pass a configuration")
    end

  end

  describe "Performs queries" do
    it "Instance adds authentication details" do
      Osm::Api.should_receive(:perform_query).with(configuration: $api_configuration, path: 'path/to.php', post_attributes: {'post' => 'attributes', 'userid' => 'user_id', 'secret' => 'secret'}, raw: true) { :a }
      $api.perform_query(path: 'path/to.php', post_attributes: {'post' => 'attributes'}, raw: true).should == :a
    end

    describe "Class performs the query" do

      it "Using default configuration" do
        HTTParty.should_receive(:post).with('https://www.onlinescoutmanager.co.uk/path/to/load', {:body => {"apiid" => "1", "token" => "API TOKEN"}}){ OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>'"1"'}) }
        Osm::Api.perform_query(path: 'path/to/load').should == "1"
      end

      it "Using passed configuration" do
        configuration = Osm::Api::Configuration.new(id: '2', token: '345', name: 'name')
        HTTParty.should_receive(:post).with('https://www.onlinescoutmanager.co.uk/path/to/load', {:body => {"apiid" => "2", "token" => "345"}}){ OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>'"1"'}) }
        Osm::Api.perform_query(configuration: configuration, path: 'path/to/load').should == "1"
      end

      it "Using passed post attributes" do
        HTTParty.should_receive(:post).with('https://www.onlinescoutmanager.co.uk/path/to/load', {:body => {"apiid" => "1", "token" => "API TOKEN", 'attribute' => 'value'}}){ OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>'"1"'}) }
        Osm::Api.perform_query(path: 'path/to/load', post_attributes: {'attribute' => 'value'}).should == "1"
      end

      it "Doesn't parse when raw option is true" do
        HTTParty.should_receive(:post).with('https://www.onlinescoutmanager.co.uk/path/to/load', {:body => {"apiid" => "1", "token" => "API TOKEN"}}){ OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>'"1"'}) }
        Osm::Api.perform_query(path: 'path/to/load', raw: true).should == '"1"'
      end

    end # Class performs the query

    describe "Handles network errors" do

      it "Raises a connection error if the HTTP status code was not 'OK'" do
        HTTParty.stub(:post) { OsmTest::DummyHttpResult.new(:response=>{:code=>'500'}) }
        expect{ Osm::Api.perform_query(path: 'path') }.to raise_error(Osm::ConnectionError, 'HTTP Status code was 500')
      end

      it "Raises a connection error if it can't connect to OSM" do
        HTTParty.stub(:post) { raise SocketError }
        expect{ Osm::Api.perform_query(path: 'path') }.to raise_error(Osm::ConnectionError, 'A problem occured on the internet.')
      end

    end # Handles network errors

    describe "Handles OSM errors" do

      it "Raises an error if OSM returns an error (as a hash)" do
        HTTParty.stub(:post) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>'{"error":"Error message"}'}) }
        expect{ Osm::Api.perform_query(path: 'path') }.to raise_error(Osm::Error, 'Error message')
      end

      it "Raises an error if OSM returns an error (as a hash in a hash)" do
        HTTParty.stub(:post) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>'{"error":{"message":"Error message"}}'}) }
        expect{ Osm::Api.perform_query(path: 'path') }.to raise_error(Osm::Error, 'Error message')
      end

      it "Raises an error if OSM returns an error (as a plain string)" do
        HTTParty.stub(:post) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>'Error message'}) }
        expect{ Osm::Api.perform_query(path: 'path') }.to raise_error(Osm::Error, 'Error message')
      end

    end # Handles OSM errors

  end # Performs queries


  describe "Authorizes a user to use the OSM API" do
    it "Using the default configuration" do
      user_email = 'alice@example.com'
      user_password = 'alice'
      Osm::Api.should_receive(:perform_query).with(configuration: $api_configuration, path: 'users.php?action=authorise', post_attributes: {'email' => user_email, 'password' => user_password}) { {'userid' => 'id', 'secret' => 'secret'} }
      Osm::Api.authorize(email_address: user_email, password: user_password).should == {:user_id => 'id', :secret => 'secret'}
    end
    it "Using a custom configuration" do
      user_email = 'alice@example.com'
      user_password = 'alice'
      configuration = Osm::Api::Configuration.new(id: 1, token: 'token', name: 'name')
      Osm::Api.should_receive(:perform_query).with(configuration: configuration, path: 'users.php?action=authorise', post_attributes: {'email' => user_email, 'password' => user_password}) { {'userid' => 'id', 'secret' => 'secret'} }
      Osm::Api.authorize(configuration: configuration, email_address: user_email, password: user_password).should == {:user_id => 'id', :secret => 'secret'}
    end
  end


  describe "Get user roles" do

    it "Returns what OSM gives on success" do
      $api.should_receive(:perform_query).with(path: 'api.php?action=getUserRoles'){ ['a', 'b'] }
      $api.get_user_roles.should == ['a', 'b']
    end

    it "User has no roles in OSM" do
      $api.should_receive(:perform_query).with(path: 'api.php?action=getUserRoles').twice{ false }
      expect{ $api.get_user_roles! }.to raise_error(Osm::NoActiveRoles)
      $api.get_user_roles.should == []
    end

    it "Reraises any other Osm::Error" do
      $api.should_receive(:perform_query).with(path: 'api.php?action=getUserRoles'){ raise Osm::Error, 'Test' }
      expect{ $api.get_user_roles }.to raise_error(Osm::Error, 'Test')
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
      $api.get_user_permissions.should == permissions
    end

    it "Get from cache" do
      permissions = {1 => {:a => [:read, :write]}, 2 => {:a => [:read]}}
      OsmTest::Cache.should_receive('exist?').with("OSMAPI-#{Osm::VERSION}-osm-permissions-user_id") { true }
      OsmTest::Cache.should_receive('read').with("OSMAPI-#{Osm::VERSION}-osm-permissions-user_id") { permissions }
      $api.get_user_permissions.should == permissions
    end

    it "Get ignoring cache" do
      data = [
        {"sectionid"=>"1", "permissions"=>{"badge"=>10}},
      ]
      body = {
        'apiid' => '1',
        'token' => 'API TOKEN',
        'userid' => 'user_id',
        'secret' => 'secret',
      }
      url = 'https://www.onlinescoutmanager.co.uk/api.php?action=getUserRoles'

      OsmTest::Cache.should_not_receive('exist?').with("OSMAPI-#{Osm::VERSION}-osm-permissions-user_id")
      OsmTest::Cache.should_not_receive('read').with("OSMAPI-#{Osm::VERSION}-osm-permissions-user_id")
      HTTParty.should_receive(:post).with(url, {:body=>body}) { OsmTest::DummyHttpResult.new(:response=>{:code=>'200', :body=>data.to_json}) }
      $api.get_user_permissions(:no_cache => true).should == {1 => {:badge => [:read]}}
    end

    it "Set" do
      permissions = {1 => {:a => [:read, :write]}, 2 => {:a => [:read]}}
      OsmTest::Cache.should_receive('exist?').with("OSMAPI-#{Osm::VERSION}-osm-permissions-user_id") { true }
      OsmTest::Cache.should_receive('read').with("OSMAPI-#{Osm::VERSION}-osm-permissions-user_id") { permissions }
      OsmTest::Cache.should_receive('write').with("OSMAPI-#{Osm::VERSION}-osm-permissions-user_id", permissions.merge(3 => {:a => [:read]}), {:expires_in=>600}) { true }
      $api.set_user_permissions(section: 3, permissions: {:a => [:read]})
    end

  end


end
