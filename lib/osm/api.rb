module Osm

  class Api
    
    # Default options
    @@site = nil      # Used as the defult value for api_site in new instances
    @site = nil       # Used to make requests from an instance
    @@debug = false   # Puts helpful information whilst connected to OSM/OGM
    @@api_details = {:osm=>{}, :ogm=>{}} # API details - [:osm | :ogm] [:id | :token | :name]


    BASE_URLS = {
      :osm => 'https://www.onlinescoutmanager.co.uk',
      :ogm => 'http://www.onlineguidemanager.co.uk',
    }


    # Configure the API options used by all instances of the class
    # @param [Hash] options
    # @option options [Symbol] :default_site whether to use OSM (if :osm) or OGM (if :ogm)
    # @option options [Hash] :osm (optional but :osm_api or :ogm_api must be present) the api data for OSM
    # @option options[:osm] [String] :id the apiid given to you for using the OSM id
    # @option options[:osm] [String] :token the token which goes with the above api
    # @option options[:osm] [String] :name the name displayed in the External Access tab of OSM
    # @option options [Hash] :ogm (optional but :osm_api or :ogm_api must be present) the api data for OGM
    # @option options[:ogm] [String] :id the apiid given to you for using the OGM id
    # @option options[:ogm] [String] :token the token which goes with the above api
    # @option options[:ogm] [String] :name the name displayed in the External Access tab of OGM
    # @option options [Boolean] :debug if true debugging info is output (optional, default = false)
    # @return nil
    def self.configure(options)
      raise ArgumentError, ':default_site does not exist in options hash or is invalid, this should be set to either :osm or :ogm' unless [:osm, :ogm].include?(options[:default_site])
      raise ArgumentError, ':osm and/or :ogm must be present' if options[:osm].nil? && options[:ogm].nil?
      [:osm, :ogm].each do |api_key|
        if options[api_key]
          api_data = options[api_key]
          raise ArgumentError, ":#{api_key} must be a Hash" unless api_data.is_a?(Hash)
          [:id, :token, :name].each do |key|
            raise ArgumentError, ":#{api_key} must contain a key :#{key}" if api_data[key].nil?
          end
        end
      end

      @@site = options[:default_site]
      @@debug = !!options[:debug]
      @@api_details = {
        :osm => (options[:osm] || {}),
        :ogm => (options[:ogm] || {}),
      }
      nil
    end

    # Configure the debug option
    # @param [Boolean] debug whether to display debugging information
    # @return nil
    def self.debug=(debug)
      @@debug = !!debug
    end

    # The debug option
    # @return Boolean whether debugging output is enabled
    def self.debug
      @@debug
    end

    # Initialize a new API connection
    # @param [String] user_id OSM userid of the user to act as (get this by using the authorize method)
    # @param [String] secret OSM secret of the user to act as (get this by using the authorize method)
    # @param [Symbol] site Whether to use OSM (:osm) or OGM (:ogm), defaults to the value set for the class
    # @return nil
    def initialize(user_id, secret, site=@@site)
      raise ArgumentError, 'You must pass a secret (get this by using the authorize method)' if secret.nil?
      raise ArgumentError, 'You must pass a user_id (get this by using the authorize method)' if user_id.nil?
      raise ArgumentError, 'site is invalid, if passed it should be either :osm or :ogm, if not passed then you forgot to run Api.configure' unless [:osm, :ogm].include?(site)

      @site = site
      set_user(user_id, secret)
      nil
    end


    # Get the API name
    # @return [String]
    def api_name
      @@api_details[@site][:name]
    end

    # Get the API ID
    # @return [String]
    def api_id
      @@api_details[@site][:id]
    end
    def to_i
      api_id
    end


    # Get the site this Api currently uses
    # @return [Symbol] :osm or :ogm
    def site
      @site
    end


    # Get the current user_id
    # @return [String]
    def user_id
      @user_id
    end


    # Get the userid and secret to be able to act as a certain user on the OSM/OGM system
    # @param [Symbol] site The site to use either :osm or :ogm (defaults to whatever was set in the configure method)
    # @param [String] email The login email address of the user on OSM
    # @param [String] password The login password of the user on OSM
    # @return [Hash] a hash containing the following keys:
    #   * :user_id - the userid to use in future requests
    #   * :secret - the secret to use in future requests
    def self.authorize(site=@@site, email, password)
      api_data = {
        'email' => email,
        'password' => password,
      }
      data = perform_query(site, 'users.php?action=authorise', api_data)
      return {
        :user_id => data['userid'],
        :secret => data['secret'],
      }
    end


    # Set the OSM user to make future requests as
    # @param [String] user_id The OSM userid to use (get this using the authorize method)
    # @param [String] secret The OSM secret to use (get this using the authorize method)
    # @return [Osm::Api] self
    def set_user(user_id, secret)
      @user_id = user_id
      @user_secret = secret
      return self
    end

    # Get the base URL for requests to OSM/OGM
    # @param [Symbol] site For OSM or OGM (:osm or :ogm)
    # @return [String] The base URL for requests
    def self.base_url(site=@@site)
      raise ArgumentError, "Invalid site" unless [:osm, :ogm].include?(site)
      BASE_URLS[site]
    end

    # Get the base URL for requests to OSM.OGM
    # @param site For OSM or OGM (:osm or :ogm), defaults to the default for this api object
    # @return [String] The base URL for requests
    def base_url(site=@site)
      raise ArgumentError, "Invalid site" unless [:osm, :ogm].include?(site)
      self.class.base_url(site)
    end

    # Make a query to the OSM/OGM API
    # @param [String] url The script on the remote server to invoke
    # @param [Hash] api_data A hash containing the values to be sent to the server in the body of the request
    # @return [Hash, Array, String] the parsed JSON returned by OSM
    def perform_query(url, api_data={})
      self.class.perform_query(@site, url, api_data.merge({
        'userid' => @user_id,
        'secret' => @user_secret,
      }))
    end

    # Get API user's permissions
    # @!macro options_get
    # @return nil if an error occured or the user does not have access to that section
    # @return [Hash] {section_id => permissions_hash}
    def get_user_permissions(options={})
      cache_key = ['permissions', user_id]

      if !options[:no_cache] && Osm::Model.cache_exist?(self, cache_key)
        return Osm::Model.cache_read(self, cache_key)
      end

      data = perform_query('api.php?action=getUserRoles')

      all_permissions = Hash.new
      data.each do |item|
        unless item['section'].eql?('discount')  # It's not an actual section
          all_permissions.merge!(Osm::to_i_or_nil(item['sectionid']) => Osm.make_permissions_hash(item['permissions']))
        end
      end
      Osm::Model.cache_write(self, cache_key, all_permissions)

      return all_permissions
    end

    # Set access permission for an API user for a given Section
    # @param [Section, Fixnum] section The Section to set permissions for
    # @param [Hash] permissions The permissions Hash
    def set_user_permissions(section, permissions)
      key = ['permissions', user_id]
      permissions = get_user_permissions.merge(section.to_i => permissions)
      Osm::Model.cache_write(self, key, permissions)
    end


    private
    # Make a query to the OSM/OGM API
    # @param [Symbol] site The site to use either :osm or :ogm
    # @param [String] url The script on the remote server to invoke
    # @param [Hash] api_data A hash containing the values to be sent to the server in the body of the request
    # @return [Hash, Array, String] the parsed JSON returned by OSM
    # @raise [Osm::Error] If an error was returned by OSM
    # @raise [Osm::ConnectionError] If an error occured connecting to OSM
    def self.perform_query(site, url, api_data={})
      raise ArgumentError, 'site is invalid, this should be set to either :osm or :ogm' unless [:osm, :ogm].include?(site)
 
      data = api_data.merge({
        'apiid' => @@api_details[site][:id],
        'token' => @@api_details[site][:token],
      })

      if @@debug
        puts "Making :#{site} API request to #{url}"
        hide_values_for = ['secret', 'token']
        api_data_as_string = api_data.sort.map{ |key, value| "#{key} => #{hide_values_for.include?(key) ? 'PRESENT' : value.inspect}" }.join(', ')
        puts "{#{api_data_as_string}}"
      end

      begin
        result = HTTParty.post("#{BASE_URLS[site]}/#{url}", {:body => data})
      rescue SocketError, TimeoutError, OpenSSL::SSL::SSLError
        raise Osm::ConnectionError, 'A problem occured on the internet.'
      end
      raise Osm::ConnectionError, "HTTP Status code was #{result.response.code}" if !result.response.code.eql?('200')

      if @@debug
        puts "Result from :#{site} request to #{url}"
        puts "#{result.response.content_type}"
        puts result.response.body
      end

      return nil if result.response.body.empty?
      case result.response.content_type
        when 'application/json', 'text/html'
          raise Osm::Error, result.response.body unless looks_like_json?(result.response.body)
          decoded = ActiveSupport::JSON.decode(result.response.body)
          osm_error = get_osm_error(decoded)
          raise Osm::Error, osm_error if osm_error
          return decoded
        when 'image/jpeg'
          return result.response.body
        else
          raise Osm::Error, "Unhandled content-type: #{result.response.content_type}"
      end
    end

    # Check if text looks like it's JSON
    # @param [String] text What to look at
    # @return [Boolean]
    def self.looks_like_json?(text)
      (['[', '{'].include?(text[0]))
    end

    # Get the error returned by OSM
    # @param data what OSM gave us
    # @return false if no error message was found
    # @return [String] the error message
    def self.get_osm_error(data)
      return false unless data.is_a?(Hash)
      to_return = data['error'] || data['err'] || false
      to_return = false if to_return.blank?
      return to_return
    end

  end # Class Api

end # Module
