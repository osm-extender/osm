# encoding: utf-8
require 'spec_helper'


describe "API" do

  it "Create" do
    $api.should_not be_nil
    $api.site.should == :osm
    $api.name.should == "API NAME"
    $api.api_id.should == "1"
    $api.api_secret.should == "API-SECRET"
    $api.user_id.should == "2"
    $api.user_secret.should == "USER-SECRET"
    $api.debug.should == false
  end

  describe "Initialize requires a" do

    it "API ID" do
      expect{ Osm::Api.new(api_secret: 'secret', name: 'name') }.to raise_error(ArgumentError, "missing keyword: api_id")
      expect{ Osm::Api.new(api_id: '', api_secret: 'secret', name: 'name') }.to raise_error(ArgumentError, "You must provide an api_id (get this by requesting one from OSM)")
    end

    it "API secret" do
      expect{ Osm::Api.new(api_id: '1', name: 'name') }.to raise_error(ArgumentError, "missing keyword: api_secret")
      expect{ Osm::Api.new(api_id: '1', api_secret: '', name: 'name') }.to raise_error(ArgumentError, "You must provide an api_secret (get this by requesting one from OSM)")
    end

    it "Name" do
      expect{ Osm::Api.new(api_id: '1', api_secret: 'secret') }.to raise_error(ArgumentError, "missing keyword: name")
      expect{ Osm::Api.new(api_id: '1', api_secret: 'secret', name: '') }.to raise_error(ArgumentError, "You must provide a name for your API (this should be what appears in OSM)")
    end

    it "Valid site" do
      expect{ Osm::Api.new(site: :invalid, api_id: '1', api_secret: 'secret', name: 'name') }.to raise_error(ArgumentError, ":invalid is not a valid site (must be one of :osm, :osm_staging, :osm_migration)")
    end

  end # initialize requires a


  it "Checks the debug property" do
    $api.debug?.should == false

    $api.debug = true
    $api.debug?.should == true
  end


  describe "Cloning" do
    it "With changes" do
      clone = $api.clone_with_changes

      clone.debug.should == false
      clone.site.should == :osm
      clone.name.should == 'API NAME'
      clone.api_id.should == '1'
      clone.api_secret.should == 'API-SECRET'
      clone.user_id.should == '2'
      clone.user_secret.should == 'USER-SECRET'

      clone.name.object_id.should_not == $api.name.object_id
      clone.api_id.object_id.should_not == $api.api_id.object_id
      clone.api_secret.object_id.should_not == $api.api_secret.object_id
      clone.user_id.object_id.should_not == $api.user_id.object_id
      clone.user_secret.object_id.should_not == $api.user_secret.object_id
    end

    it "With a different user" do
      clone = $api.clone_with_different_user(id: '3', secret: 'NEW USER SECRET')
      clone.user_id.should == '3'
      clone.user_secret.should == 'NEW USER SECRET'
    end
  end # describe CLoning


  describe "Checks for valid/invalid user" do
    it "Has a valid user" do
      $api.has_valid_user?.should == true
      $api.has_invalid_user?.should == false
    end

    describe "Has an invalid user" do
      it "Bad id" do
        api = $api.clone_with_different_user(id: nil, secret: 'NEW USER SECRET')
        api.has_valid_user?.should == false
        api.has_invalid_user?.should == true
      end

      it "Bad secret" do
        api = $api.clone_with_different_user(id: '3', secret: nil)
        api.has_valid_user?.should == false
        api.has_invalid_user?.should == true
      end
    end
  end # describe Checks for valid/invalid user


  describe "Requires a valid user" do
    it "User is valid" do
      $api.stub(:has_valid_user?){ true }
      $api.require_valid_user!.should == nil
    end

    it "User is invalid" do
      $api.stub(:has_valid_user?){ false }
      expect{ $api.require_valid_user! }.to raise_error(Osm::Api::UserInvalid, 'id: "2", secret: "USER-SECRET"')
    end
  end # describe Requires a valid user


  describe "Performs the query" do

    before :each do
      $response = Net::HTTPOK.new(1, 200, '')
      $response.stub(:content_type){ 'application/json' }
      $response.stub(:body) { '{}' }
      uri = URI('https://www.onlinescoutmanager.co.uk/path/to/load')
      $request = Net::HTTP::Post.new(uri)
      $http = Net::HTTP.new(uri)
      Net::HTTP::Post.should_receive(:new).with(uri).and_return($request)
      Net::HTTP.should_receive(:new).with('www.onlinescoutmanager.co.uk', 443).and_return($http)
      $http.should_receive(:use_ssl=).with(true).and_return(true)
    end

    it "Without user credentials" do
      $request.should_receive(:set_form_data).with({"apiid" => "1", "token" => "API-SECRET"}).and_return(nil)
      $http.should_receive(:request).with($request).and_return($response)
      api = Osm::Api.new(name: 'name', api_id: '1', api_secret: 'API-SECRET')
      api.post_query('path/to/load').should == {}
    end

    it "With user credentials" do
      $request.should_receive(:set_form_data).with({"apiid" => "1", "token" => "API-SECRET", "userid" => "2", "secret" => "USER-SECRET"}).and_return(nil)
      $http.should_receive(:request).with($request).and_return($response)
      $api.post_query('path/to/load').should == {}
    end

    it "Using passed post attributes" do
      $request.should_receive(:set_form_data).with({"apiid" => "1", "token" => "API-SECRET", "userid" => "2", "secret" => "USER-SECRET", "attribute" => "value"}).and_return(nil)
      $http.should_receive(:request).with($request).and_return($response)
      $api.post_query('path/to/load', post_data: {'attribute' => 'value'}).should == {}
    end


    describe "User-Agent header" do

      it "Default" do
        api = Osm::Api.new(name: 'name', api_id: '1', api_secret: 'API-SECRET')
        $request.should_receive('[]=').with('User-Agent', "name (using osm gem version #{Osm::VERSION})").and_return(nil)
        $http.should_receive(:request).with($request).and_return($response)
        api.post_query('path/to/load')
      end

      it "User set" do
        $request.should_receive('[]=').with('User-Agent', "HTTP-USER-AGENT").and_return(nil)
        $http.should_receive(:request).with($request).and_return($response)
        $api.post_query('path/to/load')
      end

    end # describe User-Agent header


    describe "Handles network errors" do

      it "Raises a connection error if the HTTP status code was not 'OK'" do
        response = Net::HTTPInternalServerError.new(1, 500, '')
        $http.should_receive(:request).with($request).and_return(response)
        expect{ $api.post_query('path/to/load') }.to raise_error(Osm::ConnectionError, 'HTTP Status code was 500')
      end

      it "Raises a connection error if it can't connect to OSM" do
        $http.should_receive(:request).with($request){ raise Errno::ENETUNREACH, 'Failed to open TCP connection to 2.127.245.223:80 (Network is unreachable - connect(2) for "2.127.245.223" port 80)' }
        expect{ $api.post_query('path/to/load') }.to raise_error(Osm::ConnectionError, 'Errno::ENETUNREACH: Network is unreachable - Failed to open TCP connection to 2.127.245.223:80 (Network is unreachable - connect(2) for "2.127.245.223" port 80)')
      end

      it "Raises a connection error if an SSL error occurs" do
        $http.should_receive(:request).with($request){ raise OpenSSL::SSL::SSLError, 'hostname "2.127.245.223" does not match the server certificate' }
        expect{ $api.post_query('path/to/load') }.to raise_error(Osm::ConnectionError, 'OpenSSL::SSL::SSLError: hostname "2.127.245.223" does not match the server certificate')
      end

    end # Handles network errors

    describe "Handles OSM errors" do

      it "Raises an error if OSM returns an error (as a hash)" do
        $request.should_receive(:set_form_data).with({"apiid" => "1", "token" => "API-SECRET", "userid" => "2", "secret" => "USER-SECRET"}).and_return(nil)
        $response.stub(:body){ '{"error":"Error message"}' }
        $http.should_receive(:request).with($request).and_return($response)
        expect{ $api.post_query('path/to/load') }.to raise_error(Osm::Error, 'Error message')
      end

      it "Raises an error if OSM returns an error (as a hash in a hash)" do
        $request.should_receive(:set_form_data).with({"apiid" => "1", "token" => "API-SECRET", "userid" => "2", "secret" => "USER-SECRET"}).and_return(nil)
        $response.stub(:body){ '{"error":{"message":"Error message"}}' }
        $http.should_receive(:request).with($request).and_return($response)
        expect{ $api.post_query('path/to/load') }.to raise_error(Osm::Error, 'Error message')
      end

      it "Raises an error if OSM returns an error (as a plain string)" do
        $request.should_receive(:set_form_data).with({"apiid" => "1", "token" => "API-SECRET", "userid" => "2", "secret" => "USER-SECRET"}).and_return(nil)
        $response.stub(:body){ 'Error message' }
        $http.should_receive(:request).with($request).and_return($response)
        expect{ $api.post_query('path/to/load') }.to raise_error(Osm::Error, 'Error message')
      end

    end # Handles OSM errors
  end # Performs queries


  it "Authorizes a user to use the OSM API" do
    user_email = 'alice@example.com'
    user_password = 'alice'
    $api.should_receive(:post_query).with('users.php?action=authorise', post_attributes: {'email' => user_email, 'password' => user_password}) { {'userid' => '100', 'secret' => 'secret'} }
    $api.authorize_user(email_address: user_email, password: user_password).should == {user_id: '100', user_secret: 'secret'}
  end


  describe "Get user roles" do

    it "Returns what OSM gives on success" do
      $api.should_receive(:post_query).with('api.php?action=getUserRoles'){ ['a', 'b'] }
      $api.get_user_roles.should == ['a', 'b']
    end

    it "User has no roles in OSM" do
      $api.should_receive(:post_query).with('api.php?action=getUserRoles').twice{ false }
      expect{ $api.get_user_roles! }.to raise_error(Osm::NoActiveRoles)
      $api.get_user_roles.should == []
    end

    it "Reraises any other Osm::Error" do
      $api.should_receive(:post_query).with('api.php?action=getUserRoles'){ raise Osm::Error, 'Test' }
      expect{ $api.get_user_roles }.to raise_error(Osm::Error, 'Test')
    end

  end


  describe "User Permissions" do

    it "Get from cache" do
      permissions = {1 => {a: [:read, :write]}, 2 => {a: [:read]}}
      OsmTest::Cache.should_receive('fetch').and_return(permissions)
      $api.get_user_permissions.should == permissions
    end

    it "Get ignoring cache" do
      data = [
        {"sectionid"=>"1", "permissions"=>{"badge"=>10}},
      ]

      OsmTest::Cache.should_not_receive('exist?').with("OSMAPI-#{Osm::VERSION}-osm-permissions-2")
      OsmTest::Cache.should_not_receive('read').with("OSMAPI-#{Osm::VERSION}-osm-permissions-2")
      $api.should_receive(:post_query).with('api.php?action=getUserRoles') { data }
      $api.get_user_permissions(no_read_cache: true).should == {1 => {badge: [:read]}}
    end

    it "Set" do
      permissions = {1 => {a: [:read, :write]}, 2 => {a: [:read]}}
      $api.should_receive('get_user_permissions').and_return(permissions)
      OsmTest::Cache.should_receive('write').with("OSMAPI-#{Osm::VERSION}-osm-permissions-2", permissions.merge(3 => {a: [:read]}), {expires_in:600}) { true }
      $api.set_user_permissions(section: 3, permissions: {a: [:read]})
    end

  end # describe User Permissions


  describe "Converters" do
    describe "to_s" do
      it "Has a user" do
        $api.stub(:has_valid_user?){ true }
        $api.to_s.should == "osm - 1 - API NAME - 2"
      end

      it "Doesn't have a user" do
        $api.stub(:has_valid_user?){ false }
        $api.to_s.should == "osm - 1 - API NAME"
      end

    end

    it "to_i" do
      $api.to_i.should == 1
    end

    it "to_h" do
      hash = $api.to_h

      hash.should == {
        api_id:       '1',
        api_secret:   'API-SECRET',
        name:         'API NAME',
        debug:        false,
        site:         :osm,
        user_id:      '2',
        user_secret:  'USER-SECRET'
      }

      hash[:name].object_id.should_not == $api.name.object_id
      hash[:api_id].object_id.should_not == $api.api_id.object_id
      hash[:api_secret].object_id.should_not == $api.api_secret.object_id
      hash[:user_id].object_id.should_not == $api.user_id.object_id
      hash[:user_secret].object_id.should_not == $api.user_secret.object_id
    end

  end # describe Converters


end
