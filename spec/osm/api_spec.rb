# encoding: utf-8
require 'spec_helper'


describe "API" do

  it "Create" do
    expect($api).not_to be_nil
    expect($api.site).to eq(:osm)
    expect($api.name).to eq("API NAME")
    expect($api.api_id).to eq("1")
    expect($api.api_secret).to eq("API-SECRET")
    expect($api.user_id).to eq("2")
    expect($api.user_secret).to eq("USER-SECRET")
    expect($api.debug).to eq(false)
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
    expect($api.debug?).to eq(false)

    $api.debug = true
    expect($api.debug?).to eq(true)
  end


  describe "Cloning" do
    it "With changes" do
      clone = $api.clone_with_changes

      expect(clone.debug).to eq(false)
      expect(clone.site).to eq(:osm)
      expect(clone.name).to eq('API NAME')
      expect(clone.api_id).to eq('1')
      expect(clone.api_secret).to eq('API-SECRET')
      expect(clone.user_id).to eq('2')
      expect(clone.user_secret).to eq('USER-SECRET')

      expect(clone.name.object_id).not_to eq($api.name.object_id)
      expect(clone.api_id.object_id).not_to eq($api.api_id.object_id)
      expect(clone.api_secret.object_id).not_to eq($api.api_secret.object_id)
      expect(clone.user_id.object_id).not_to eq($api.user_id.object_id)
      expect(clone.user_secret.object_id).not_to eq($api.user_secret.object_id)
    end

    it "With a different user" do
      clone = $api.clone_with_different_user(id: '3', secret: 'NEW USER SECRET')
      expect(clone.user_id).to eq('3')
      expect(clone.user_secret).to eq('NEW USER SECRET')
    end
  end # describe CLoning


  describe "Checks for valid/invalid user" do
    it "Has a valid user" do
      expect($api.has_valid_user?).to eq(true)
      expect($api.has_invalid_user?).to eq(false)
    end

    describe "Has an invalid user" do
      it "Bad id" do
        api = $api.clone_with_different_user(id: nil, secret: 'NEW USER SECRET')
        expect(api.has_valid_user?).to eq(false)
        expect(api.has_invalid_user?).to eq(true)
      end

      it "Bad secret" do
        api = $api.clone_with_different_user(id: '3', secret: nil)
        expect(api.has_valid_user?).to eq(false)
        expect(api.has_invalid_user?).to eq(true)
      end
    end
  end # describe Checks for valid/invalid user


  describe "Requires a valid user" do
    it "User is valid" do
      allow($api).to receive(:has_valid_user?){ true }
      expect($api.require_valid_user!).to eq(nil)
    end

    it "User is invalid" do
      allow($api).to receive(:has_valid_user?){ false }
      expect{ $api.require_valid_user! }.to raise_error(Osm::Api::UserInvalid, 'id: "2", secret: "USER-SECRET"')
    end
  end # describe Requires a valid user


  describe "Performs the query" do

    before :each do
      $response = Net::HTTPOK.new(1, 200, '')
      allow($response).to receive(:content_type){ 'application/json' }
      allow($response).to receive(:body) { '{}' }
      uri = URI('https://www.onlinescoutmanager.co.uk/path/to/load')
      $request = Net::HTTP::Post.new(uri)
      $http = Net::HTTP.new(uri)
      expect(Net::HTTP::Post).to receive(:new).with(uri).and_return($request)
      expect(Net::HTTP).to receive(:new).with('www.onlinescoutmanager.co.uk', 443).and_return($http)
      expect($http).to receive(:use_ssl=).with(true).and_return(true)
    end

    it "Without user credentials" do
      expect($request).to receive(:set_form_data).with({"apiid" => "1", "token" => "API-SECRET"}).and_return(nil)
      expect($http).to receive(:request).with($request).and_return($response)
      api = Osm::Api.new(name: 'name', api_id: '1', api_secret: 'API-SECRET')
      expect(api.post_query('path/to/load')).to eq({})
    end

    it "With user credentials" do
      expect($request).to receive(:set_form_data).with({"apiid" => "1", "token" => "API-SECRET", "userid" => "2", "secret" => "USER-SECRET"}).and_return(nil)
      expect($http).to receive(:request).with($request).and_return($response)
      expect($api.post_query('path/to/load')).to eq({})
    end

    it "Using passed post attributes" do
      expect($request).to receive(:set_form_data).with({"apiid" => "1", "token" => "API-SECRET", "userid" => "2", "secret" => "USER-SECRET", "attribute" => "value"}).and_return(nil)
      expect($http).to receive(:request).with($request).and_return($response)
      expect($api.post_query('path/to/load', post_data: {'attribute' => 'value'})).to eq({})
    end

    it "Returns nil if body is empty" do
        response = Net::HTTPOK.new('1.1', '200', 'OK')
        response.content_type = 'text/html'
        allow(response).to receive(:body).and_return('')
        expect($http).to receive(:request).with($request).and_return(response)
        expect($api.post_query('path/to/load')).to eq(nil)
      end

    describe "Handles different content types" do
      it "application/json" do
        response = Net::HTTPOK.new('1.1', '200', 'OK')
        response.content_type = 'application/json'
        allow(response).to receive(:body).and_return('[{}]')
        expect($http).to receive(:request).with($request).and_return(response)
        expect($api.post_query('path/to/load')).to eq([{}])
      end

      it "text/html" do
        response = Net::HTTPOK.new('1.1', '200', 'OK')
        response.content_type = 'text/html'
        allow(response).to receive(:body).and_return('[{}]')
        expect($http).to receive(:request).with($request).and_return(response)
        expect($api.post_query('path/to/load')).to eq([{}])
      end

      it "image/jpeg" do
        response = Net::HTTPOK.new('1.1', '200', 'OK')
        response.content_type = 'image/jpeg'
        allow(response).to receive(:body).and_return('image data')
        expect($http).to receive(:request).with($request).and_return(response)
        expect($api.post_query('path/to/load')).to eq('image data')
      end

      it "Other types" do
        response = Net::HTTPOK.new('1.1', '200', 'OK')
        response.content_type = 'giberish/nothing-meaningful'
        allow(response).to receive(:body).and_return('body')
        expect($http).to receive(:request).with($request).and_return(response)
        expect{$api.post_query('path/to/load')}.to raise_error(Osm::Error, 'Unhandled content-type: giberish/nothing-meaningful')
      end
    end

    describe "User-Agent header" do

      it "Default" do
        api = Osm::Api.new(name: 'name', api_id: '1', api_secret: 'API-SECRET')
        expect($request).to receive('[]=').with('User-Agent', "name (using osm gem version #{Osm::VERSION})").and_return(nil)
        expect($http).to receive(:request).with($request).and_return($response)
        api.post_query('path/to/load')
      end

      it "User set" do
        expect($request).to receive('[]=').with('User-Agent', "HTTP-USER-AGENT").and_return(nil)
        expect($http).to receive(:request).with($request).and_return($response)
        $api.post_query('path/to/load')
      end

    end # describe User-Agent header


    describe "Handles network errors" do

      it "Raises a connection error if the HTTP status code was not 'OK'" do
        response = Net::HTTPInternalServerError.new(1, 500, '')
        expect($http).to receive(:request).with($request).and_return(response)
        expect{ $api.post_query('path/to/load') }.to raise_error(Osm::ConnectionError, 'HTTP Status code was 500')
      end

      it "Raises a connection error if it can't connect to OSM" do
        expect($http).to receive(:request).with($request){ raise Errno::ENETUNREACH, 'Failed to open TCP connection to 2.127.245.223:80 (Network is unreachable - connect(2) for "2.127.245.223" port 80)' }
        expect{ $api.post_query('path/to/load') }.to raise_error(Osm::ConnectionError, 'Errno::ENETUNREACH: Network is unreachable - Failed to open TCP connection to 2.127.245.223:80 (Network is unreachable - connect(2) for "2.127.245.223" port 80)')
      end

      it "Raises a connection error if an SSL error occurs" do
        expect($http).to receive(:request).with($request){ raise OpenSSL::SSL::SSLError, 'hostname "2.127.245.223" does not match the server certificate' }
        expect{ $api.post_query('path/to/load') }.to raise_error(Osm::ConnectionError, 'OpenSSL::SSL::SSLError: hostname "2.127.245.223" does not match the server certificate')
      end

    end # Handles network errors

    describe "Handles OSM errors" do

      it "Raises an error if OSM returns an error (as a hash)" do
        expect($request).to receive(:set_form_data).with({"apiid" => "1", "token" => "API-SECRET", "userid" => "2", "secret" => "USER-SECRET"}).and_return(nil)
        allow($response).to receive(:body){ '{"error":"Error message"}' }
        expect($http).to receive(:request).with($request).and_return($response)
        expect{ $api.post_query('path/to/load') }.to raise_error(Osm::Error, 'Error message')
      end

      it "Raises an error if OSM returns an error (as a hash in a hash)" do
        expect($request).to receive(:set_form_data).with({"apiid" => "1", "token" => "API-SECRET", "userid" => "2", "secret" => "USER-SECRET"}).and_return(nil)
        allow($response).to receive(:body){ '{"error":{"message":"Error message"}}' }
        expect($http).to receive(:request).with($request).and_return($response)
        expect{ $api.post_query('path/to/load') }.to raise_error(Osm::Error, 'Error message')
      end

      it "Raises an error if OSM returns an error (as a plain string)" do
        expect($request).to receive(:set_form_data).with({"apiid" => "1", "token" => "API-SECRET", "userid" => "2", "secret" => "USER-SECRET"}).and_return(nil)
        allow($response).to receive(:body){ 'Error message' }
        expect($http).to receive(:request).with($request).and_return($response)
        expect{ $api.post_query('path/to/load') }.to raise_error(Osm::Error, 'Error message')
      end

    end # Handles OSM errors
  end # Performs queries


  it "Authorizes a user to use the OSM API" do
    user_email = 'alice@example.com'
    user_password = 'alice'
    expect($api).to receive(:post_query).with('users.php?action=authorise', post_attributes: {'email' => user_email, 'password' => user_password}) { {'userid' => '100', 'secret' => 'secret'} }
    expect($api.authorize_user(email_address: user_email, password: user_password)).to eq({user_id: '100', user_secret: 'secret'})
  end


  describe "Get user roles" do

    it "Returns what OSM gives on success" do
      expect($api).to receive(:post_query).with('api.php?action=getUserRoles'){ ['a', 'b'] }
      expect($api.get_user_roles).to eq(['a', 'b'])
    end

    describe "User has no roles in OSM" do
      it "OSM returns false" do
        expect($api).to receive(:post_query).with('api.php?action=getUserRoles').twice{ false }
        expect{ $api.get_user_roles! }.to raise_error(Osm::NoActiveRoles)
        expect($api.get_user_roles).to eq([])
      end
      it "OSM causes an exception to be raised" do
        expect($api).to receive(:post_query).with('api.php?action=getUserRoles').twice{ fail Osm::Error, 'false' }
        expect{ $api.get_user_roles! }.to raise_error(Osm::NoActiveRoles)
        expect($api.get_user_roles).to eq([])
      end
    end

    it "Reraises any other Osm::Error" do
      expect($api).to receive(:post_query).with('api.php?action=getUserRoles'){ raise Osm::Error, 'Test' }
      expect{ $api.get_user_roles }.to raise_error(Osm::Error, 'Test')
    end

  end


  describe "User Permissions" do

    it "Get from cache" do
      permissions = {1 => {a: [:read, :write]}, 2 => {a: [:read]}}
      expect(OsmTest::Cache).to receive('fetch').and_return(permissions)
      expect($api.get_user_permissions).to eq(permissions)
    end

    it "Get ignoring cache" do
      data = [
        {"sectionid"=>"1", "permissions"=>{"badge"=>10}},
      ]

      expect(OsmTest::Cache).not_to receive('exist?').with("OSMAPI-#{Osm::VERSION}-osm-permissions-2")
      expect(OsmTest::Cache).not_to receive('read').with("OSMAPI-#{Osm::VERSION}-osm-permissions-2")
      expect($api).to receive(:post_query).with('api.php?action=getUserRoles') { data }
      expect($api.get_user_permissions(no_read_cache: true)).to eq({1 => {badge: [:read]}})
    end

    it "Set" do
      permissions = {1 => {a: [:read, :write]}, 2 => {a: [:read]}}
      expect($api).to receive('get_user_permissions').and_return(permissions)
      expect(OsmTest::Cache).to receive('write').with("OSMAPI-#{Osm::VERSION}-osm-permissions-2", permissions.merge(3 => {a: [:read]}), {expires_in:600}) { true }
      $api.set_user_permissions(section: 3, permissions: {a: [:read]})
    end

  end # describe User Permissions


  describe "Converters" do
    describe "to_s" do
      it "Has a user" do
        allow($api).to receive(:has_valid_user?){ true }
        expect($api.to_s).to eq("osm - 1 - API NAME - 2")
      end

      it "Doesn't have a user" do
        allow($api).to receive(:has_valid_user?){ false }
        expect($api.to_s).to eq("osm - 1 - API NAME")
      end

    end

    it "to_i" do
      expect($api.to_i).to eq(1)
    end

    it "to_h" do
      hash = $api.to_h

      expect(hash).to eq({
        api_id:       '1',
        api_secret:   'API-SECRET',
        name:         'API NAME',
        debug:        false,
        site:         :osm,
        user_id:      '2',
        user_secret:  'USER-SECRET'
      })

      expect(hash[:name].object_id).not_to eq($api.name.object_id)
      expect(hash[:api_id].object_id).not_to eq($api.api_id.object_id)
      expect(hash[:api_secret].object_id).not_to eq($api.api_secret.object_id)
      expect(hash[:user_id].object_id).not_to eq($api.user_id.object_id)
      expect(hash[:user_secret].object_id).not_to eq($api.user_secret.object_id)
    end

  end # describe Converters


end
