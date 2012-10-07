# encoding: utf-8
require 'spec_helper'


class DummyHttpResult
  def initialize(options={})
    @response = DummyHttpResponse.new(options[:response])
  end
  def response
    @response
  end
end
class DummyHttpResponse
  def initialize(options={})
    @options = options
  end
  def code
    @options[:code]
  end
  def body
    @options[:body]
  end
end


describe "API" do


  it "Create" do
    @api.should_not be_nil
    @api.api_id.should == @CONFIGURATION[:api][:osm][:id]
    @api.api_name.should == @CONFIGURATION[:api][:osm][:name]
  end

  it "Raises errors on bad arguments to configure" do
    expect{ Osm::Api.configure(@CONFIGURATION[:api].select{ |k,v| (k != :default_site)}) }.to raise_error(ArgumentError, ':default_site does not exist in options hash or is invalid, this should be set to either :osm or :ogm')
    expect{ Osm::Api.configure(@CONFIGURATION[:api].merge(:default_site => :invalid)) }.to raise_error(ArgumentError, ':default_site does not exist in options hash or is invalid, this should be set to either :osm or :ogm')

    expect{ Osm::Api.configure(@CONFIGURATION[:api].select{ |k,v| (k != :ogm) && (k != :osm)}) }.to raise_error(ArgumentError, ':osm and/or :ogm must be present')
    expect{ Osm::Api.configure(@CONFIGURATION[:api].merge(:osm => '')) }.to raise_error(ArgumentError, ':osm must be a Hash')
    expect{ Osm::Api.configure(@CONFIGURATION[:api].merge(:osm => @CONFIGURATION[:api][:osm].select{ |k,v| (k != :id)})) }.to raise_error(ArgumentError, ':osm must contain a key :id')
    expect{ Osm::Api.configure(@CONFIGURATION[:api].merge(:osm => @CONFIGURATION[:api][:osm].select{ |k,v| (k != :token)})) }.to raise_error(ArgumentError, ':osm must contain a key :token')
    expect{ Osm::Api.configure(@CONFIGURATION[:api].merge(:osm => @CONFIGURATION[:api][:osm].select{ |k,v| (k != :name)})) }.to raise_error(ArgumentError, ':osm must contain a key :name')
    expect{ Osm::Api.configure(@CONFIGURATION[:api].merge(:ogm => '')) }.to raise_error(ArgumentError, ':ogm must be a Hash')
    expect{ Osm::Api.configure(@CONFIGURATION[:api].merge(:ogm => @CONFIGURATION[:api][:ogm].select{ |k,v| (k != :id)})) }.to raise_error(ArgumentError, ':ogm must contain a key :id')
    expect{ Osm::Api.configure(@CONFIGURATION[:api].merge(:ogm => @CONFIGURATION[:api][:ogm].select{ |k,v| (k != :token)})) }.to raise_error(ArgumentError, ':ogm must contain a key :token')
    expect{ Osm::Api.configure(@CONFIGURATION[:api].merge(:ogm => @CONFIGURATION[:api][:ogm].select{ |k,v| (k != :name)})) }.to raise_error(ArgumentError, ':ogm must contain a key :name')
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
    HTTParty.should_receive(:post).with(url, {:body => post_data}) { DummyHttpResult.new(:response=>{:code=>'200', :body=>'{"userid":"id","secret":"secret"}'}) }

    Osm::Api.authorize(user_email, user_password).should == {:user_id => 'id', :secret => 'secret'}
  end

  it "sets a new API user" do
    @api.set_user('1', '2').is_a?(Osm::Api).should be_true

    HTTParty.should_receive(:post).with("https://www.onlinescoutmanager.co.uk/test", {:body => {
      'apiid' => @CONFIGURATION[:api][:osm][:id],
      'token' => @CONFIGURATION[:api][:osm][:token],
      'userid' => '1',
      'secret' => '2',
    }}) { DummyHttpResult.new(:response=>{:code=>'200', :body=>'[]'}) }
    @api.perform_query('test')
  end



  describe "OSM and Internet error conditions:" do
    it "Raises a connection error if the HTTP status code was not 'OK'" do
      HTTParty.stub(:post) { DummyHttpResult.new(:response=>{:code=>'500'}) }
      expect{ Osm::Api.authorize('email@example.com', 'password') }.to raise_error(Osm::ConnectionError, 'HTTP Status code was 500')
    end


    it "Raises a connection error if it can't connect to OSM" do
      HTTParty.stub(:post) { raise SocketError }
      expect{ Osm::Api.authorize('email@example.com', 'password') }.to raise_error(Osm::ConnectionError, 'A problem occured on the internet.')
    end


    it "Raises an error if OSM returns an error (as a hash)" do
      HTTParty.stub(:post) { DummyHttpResult.new(:response=>{:code=>'200', :body=>'{"error":"Error message"}'}) }
      expect{ Osm::Api.authorize('email@example.com', 'password') }.to raise_error(Osm::Error, 'Error message')
    end

    it "Raises an error if OSM returns an error (as a plain string)" do
      HTTParty.stub(:post) { DummyHttpResult.new(:response=>{:code=>'200', :body=>'Error message'}) }
      expect{ Osm::Api.authorize('email@example.com', 'password') }.to raise_error(Osm::Error, 'Error message')
    end
  end

end