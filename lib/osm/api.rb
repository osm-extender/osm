module Osm

  class Api

    class Configuration
      # @!attribute [r] site
      #   @return [Symbol] the 'flavour' of OSM to use - :osm, :osm_staging or :osm_migration
      # @!attribute [r] name
      #   @return [String] the name of the API as displayed in OSM
      # @!attribute [r] id
      #   @return [String] the apiid given to you by OSM
      # @!attribute [r] token
      #   @return [String] the token given to you by OSM
      # @!attribute [rw] debug
      #   @return [Boolean] whether debugging output should be displayed

      attr_reader :id, :token, :name, :site, :debug

      BASE_URLS = {
        :osm => 'https://www.onlinescoutmanager.co.uk',
        :osm_staging => 'http://staging.onlinescoutmanager.co.uk',
        :osm_migration => 'https://migration.onlinescoutmanager.co.uk'
      }

      private_constant :BASE_URLS


      # Initialize a new configuration for an API
      # @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)
      def initialize(id:, token:, name:, site: :osm, debug: false)
        fail ArgumentError, "#{site.inspect} is not a valid site (must be one of #{BASE_URLS.keys.map{ |i| i.inspect }.join(', ')})." unless BASE_URLS.keys.include?(site)

        local_variables.each do |k|
          v = eval(k.to_s)
          instance_variable_set("@#{k}", v) unless v.nil?
        end

        @debug = !!debug
      end

      # Get base URL for the site this configuration applies to
      # @return [String] e.g. "https://www.onlinescoutmanager.co.uk"
      def base_url
        BASE_URLS[site]
      end

      # Get base URL for the site this configuration applies to
      # @param [String] path The path to build the URL for e.g. "path/users.php"
      # @return [String] e.g. "https://www.onlinescoutmanager.co.uk/path/users.php"
      def build_url(path)
        "#{BASE_URLS[site]}/#{path}"
      end

      # Items required in the post attributes for API authentication
      # @return [Hash]
      def post_attributes
        {
          'apiid' => self.id,
          'token' => self.token,
        }
      end

      # Check if debugging output should be displayed
      def debug?
        @debug
      end

      # Set whether debugging output should be displayed
      # @param [Boolean] new_debug
      def debug=(new_debug)
        @debug = !!new_debug
      end

    end # class Osm::Api::Configuration


    # @!attribute [rw] default_configuration
    #   @return [Osm::Api::Configuration] the default configuration to use for new api instances. Can only be written once.


    def self.default_configuration=(new_default_configuration)
      fail "default_configuration has already been set:\n#{default_configuration.inspect}" unless default_configuration.nil?
      @@default_configuration = new_default_configuration
    end

    def self.default_configuration
      defined?(@@default_configuration) ? @@default_configuration : nil
    end

    # Build a new configuration for an API based on the current default
    # @param [Osm::Api::Configuration] base_configuration The configuration to build off of
    # @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)
    # @return [Osm::Api::Configuration] the default configuration to use for new api instances. Can only be written once.
    def self.build_configuration(base_configuration=default_configuration, attributes)
      base_configuration = base_configuration.nil? ? {} : base_configuration.attributes
      Osm::Api::Configuration.new(base_configuration.merge(options))
    end


    # Initialize a new API connection
    # @param [Osm::Api::Configuration] configuration The configuration to use
    # @param [String] user_id OSM userid of the user to act as (get this by using the authorize method)
    # @param [String] secret OSM secret of the user to act as (get this by using the authorize method)
    def initialize(configuration: self.default_configuration, user_id: nil, secret: nil)
      fail ArgumentError, 'You must pass a configuration' if configuration.nil?
      fail ArgumentError, 'You must pass a secret (get this by using the authorize method)' if secret.nil?
      fail ArgumentError, 'You must pass a user_id (get this by using the authorize method)' if user_id.nil?

      @configuration = configuration
      @user_id = user_id
      @secret = secret
    end


    # Make a query to the OSM/OGM API
    # @param [String] path The path on the remote server to invoke
    # @param [Hash] post_attributes A hash containing the values to be sent to the server in the body of the request
    # @param [Boolean] raw When true the data returned by OSM is not parsed
    # @return [Hash, Array, String] the parsed JSON returned by OSM
    def perform_query(path:, post_attributes: {}, raw: false)
      # Add required attrinbutes for user authentication and pass on responsabillity
      self.class.perform_query(configuration: @configuration, path: path, post_attributes: post_attributes.merge('userid' => @user_id, 'secret' => @secret), raw: raw)
    end

    # Make a query to the OSM/OGM API
    # @param [Osm::Api::Configuration, nil] configuration The configuration to use
    # @param [String] path The path on the remote server to invoke
    # @param [Hash] post_attributes A hash containing the values to be sent to the server in the body of the request
    # @param [Boolean] raw When true the data returned by OSM is not parsed
    # @return [Hash, Array, String] the parsed JSON returned by OSM
    def self.perform_query(configuration: self.default_configuration, path:, post_attributes: {}, raw: false)
      post_attributes.merge!(configuration.post_attributes)  # Add required attributes for API authentication

      url = configuration.build_url(path)

      if configuration.debug?
        puts "Making #{'RAW' if raw} :#{configuration.site} API request to #{url}"
        hide_values_for = ['secret', 'token']
        api_data_as_string = api_data.sort.map{ |key, value| "#{key} => #{hide_values_for.include?(key) ? 'PRESENT' : value.inspect}" }.join(', ')
        puts "{#{api_data_as_string}}"
      end

      begin
        result = HTTParty.post(url, {:body => post_attributes})
      rescue SocketError, TimeoutError, OpenSSL::SSL::SSLError
        fail Osm::ConnectionError, 'A problem occured on the internet.'
      end
      fail Osm::ConnectionError, "HTTP Status code was #{result.response.code}" if !result.response.code.eql?('200')

      if configuration.debug?
        puts "Result from :#{site} request to #{url}"
        puts "#{result.response.content_type}"
        puts result.response.body
      end

      return result.response.body if raw
      return nil if result.response.body.empty?
      case result.response.content_type
        when 'application/json', 'text/html'
          begin
            decoded = ActiveSupport::JSON.decode(result.response.body)
            if osm_error = get_osm_error(decoded)
              fail Osm::Error, osm_error if osm_error
            end
            return decoded
          rescue JSON::ParserError
            fail Osm::Error, result.response.body
          end
        when 'image/jpeg'
          return result.response.body
        else
          fail Osm::Error, "Unhandled content-type: #{result.response.content_type}"
      end
    end


    # Get the userid and secret to be able to act as a certain user on the OSM/OGM system
    # @param [Osm::Api::Configuration] configuration The configuration detailing how to talk to OSM
    # @param [String] email_address The login email address of the user on OSM
    # @param [String] password The login password of the user on OSM
    # @return [Hash] a hash containing the following keys:
    #   * :user_id - the userid to use in future requests
    #   * :secret - the secret to use in future requests
    def self.authorize(configuration: default_configuration, email_address:, password:)
      api_data = {
        'email' => email_address,
        'password' => password,
      }
      data = perform_query(configuration: configuration, path: 'users.php?action=authorise', post_attributes: api_data)
      return {
        user_id: data['userid'],
        secret: data['secret'],
      }
    end



    # Get API user's roles in OSM
    # @param [Osm::Api::Configuration] configuration The configuration detailing how to talk to OSM
    # @!macro options_get
    # @return [Array<Hash>] data returned by OSM
    def get_user_roles(**args)
      begin
        get_user_roles!(**args)
      rescue Osm::NoActiveRoles
        return []
      end
    end


    # Get API user's roles in OSM
    # @param [Osm::Api::Configuration] configuration The configuration detailing how to talk to OSM
    # @!macro options_get
    # @return [Array<Hash>] data returned by OSM
    # @raises Osm::NoActiveRoles
    def get_user_roles!(configuration: self.class.default_configuration, **options)
      cache_key = ['user_roles', @user_id]

      if !options[:no_cache] && Osm::Model.cache_exist?(configuration, cache_key)
        return Osm::Model.cache_read(configuration, cache_key)
      end

      begin
        data = perform_query(path: 'api.php?action=getUserRoles')
        unless data.eql?(false)
          # false equates to no roles
          Osm::Model.cache_write(configuration, cache_key, data)
          return data
        end
        fail Osm::NoActiveRoles, "You do not have any active roles in OSM."

      rescue Osm::Error => e
        if e.message.eql?('false')
          fail Osm::NoActiveRoles, "You do not have any active roles in OSM."
        else
          raise e
        end
      end

    end

    # Get API user's permissions
    # @param [Osm::Api::Configuration] configuration The configuration detailing how to talk to OSM
    # @!macro options_get
    # @return nil if an error occured or the user does not have access to that section
    # @return [Hash] {section_id => permissions_hash}
    def get_user_permissions(configuration: self.class.default_configuration, **options)
      cache_key = ['permissions', @user_id]

      if !options[:no_cache] && Osm::Model.cache_exist?(configuration, cache_key)
        return Osm::Model.cache_read(configuration, cache_key)
      end

      all_permissions = Hash.new
      get_user_roles(configuration: configuration, **options).each do |item|
        unless item['section'].eql?('discount')  # It's not an actual section
          all_permissions.merge!(Osm::to_i_or_nil(item['sectionid']) => Osm.make_permissions_hash(item['permissions']))
        end
      end
      Osm::Model.cache_write(configuration, cache_key, all_permissions)

      return all_permissions
    end

    # Set access permission for an API user for a given Section
    # @param [Osm::Api::Configuration] configuration The configuration detailing how to talk to OSM
    # @param [Section, Fixnum] section The Section to set permissions for
    # @param [Hash] permissions The permissions Hash
    def set_user_permissions(configuration: self.class.default_configuration, section:, permissions:)
      key = ['permissions', @user_id]
      permissions = get_user_permissions.merge(section.to_i => permissions)
      Osm::Model.cache_write(configuration, key, permissions)
    end


    private

    # Get the error returned by OSM
    # @param data what OSM gave us
    # @return false if no error message was found
    # @return [String] the error message
    def self.get_osm_error(data)
      return false unless data.is_a?(Hash)
      return false if data['ok']
      to_return = data['error'] || data['err'] || false
      if to_return.is_a?(Hash)
        to_return = to_return['message'] unless to_return['message'].blank?
      end
      to_return = false if to_return.blank?
      return to_return
    end

  end # Class Api

end # Module
