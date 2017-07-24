module OSM
  class Api

    # @!attribute [r] site
    #   @return [Symbol] the 'flavour' of OSM to use - :osm, :osm_staging or :osm_migration (default :osm)
    # @!attribute [r] name
    #   @return [String, #to_s] the name of the API as displayed in OSM
    # @!attribute [r] api_id
    #   @return [String, #to_s] the apiid given to you by OSM
    # @!attribute [r] api_secret
    #   @return [String, #to_s] the token given to you by OSM
    # @!attribute [r] user_id
    #   @return [String, #to_s, nil] the id for the user given by OSM
    # @!attribute [r] user_secret
    #   @return [String, #to_s, nil] the secret for the user given by OSM
    # @!attribute [rw] debug
    #   @return true, false whether debugging output should be displayed (default false)
    # @!attribute [rw] http_user_agent
    #   @return [String, #to_s, nil] what to send as the user-agent when making requests to OSM (default "#{name} (using osm gem version #{OSM::VERSION})")

    attr_reader :api_id, :api_secret, :name, :site, :debug, :user_id, :user_secret

    BASE_URLS = {
      osm: 'https://www.onlinescoutmanager.co.uk',
      osm_staging: 'http://staging.onlinescoutmanager.co.uk',
      osm_migration: 'https://migration.onlinescoutmanager.co.uk'
    }.freeze


    # Initialize a new API connection
    def initialize(api_id:, api_secret:, name:, site: :osm, debug: false, user_id: nil, user_secret: nil, http_user_agent: nil)
      fail ArgumentError, 'You must provide an api_id (get this by requesting one from OSM)' if api_id.to_s.empty?
      fail ArgumentError, 'You must provide an api_secret (get this by requesting one from OSM)' if api_secret.to_s.empty?
      fail ArgumentError, 'You must provide a name for your API (this should be what appears in OSM)' if name.to_s.empty?
      fail ArgumentError, "#{site.inspect} is not a valid site (must be one of #{BASE_URLS.keys.map(&:inspect).join(', ')})" unless BASE_URLS.keys.include?(site)

      @api_id = api_id.to_s.clone
      @api_secret = api_secret.to_s.clone
      @name = name.to_s.clone
      @site = site
      self.debug = !!debug
      self.http_user_agent = http_user_agent
      @user_id = user_id.to_s.clone unless user_id.nil?
      @user_secret = user_secret.to_s.clone unless user_secret.nil?
    end

    # Create a new OSM::Api based on the current one but with a different user
    # @param id [String] The ID of the user, given by OSM
    # @param secret [String] The secret for the user, given by OSM
    # @return [OSM::Api]
    def clone_with_different_user(id:, secret:)
      clone_with_changes(user_id: id, user_secret: secret)
    end

    # Create a new OSM::Api based on the current
    # @param attributes [Hash] the attributes to set differently in the clone
    # @return [OSM::Api]
    def clone_with_changes(**attributes)
      attributes = {
        api_id:       api_id.clone,
        api_secret:   api_secret.clone,
        name:         name.clone,
        site:         site,
        debug:        debug,
        user_id:      user_id.clone,
        user_secret:  user_secret.clone
      }.merge(attributes)
      OSM::Api.new(attributes)
    end


    # Checks if this API has valid looking user credentials
    # @return true, false
    def valid_user?
      !user_id.nil? && !user_secret.nil?
    end

    # Checks if this API has invalid looking user credentials
    # @return true, false
    def invalid_user?
      !valid_user?
    end

    # Requires the API to have valid looking user credentials
    # @raise [OSM::Api::UserInvalid]
    # @return [nil]
    def require_valid_user!
      fail APIError::InvalidUser, "id: #{user_id.inspect}, secret: #{user_secret.inspect}" if invalid_user?
    end


    # Get the userid and secret to be able to act as a certain user on the OSM system
    # @param email_address [String] The login email address of the user on OSM
    # @param password [String]password The login password of the user on OSM
    # @return [Hash] a hash containing the following keys (ready to pass to {#clone_with_different_user}):
    #   * :id - the userid to use in future requests
    #   * :secret - the secret to use in future requests
    # @return [nil] if the email address and password combination was incorrect
    def authorize_user(email_address:, password:)
      api_data = {
        'email' => email_address.to_s,
        'password' => password.to_s
      }
      data = post_query('users.php?action=authorise', post_attributes: api_data)

      return nil unless data.is_a?(Hash)

      return nil unless data['userid'] && ['secret']
      return {
        user_id: data['userid'],
        user_secret: data['secret']
      }
    end


    # Make a query to the OSM API
    # @param path [String] The path on the remote server to invoke
    # @param post_attributes [Hash] A hash containing the values to be sent to the server in the body of the request
    # @return [Hash, Array, String] the parsed JSON returned by OSM
    def post_query(path, post_data: {})
      # Add required attributes for API authentication
      post_data = post_data.merge(
        'apiid' => api_id,
        'token' => api_secret
      )

      # Add required attributes for user authentication
      if valid_user?
        post_data['userid'] = user_id
        post_data['secret'] = user_secret
      end

      uri = URI("#{BASE_URLS[site]}/#{path}")

      if debug?
        puts "Making #{'RAW' if raw} :#{site} API post request to #{uri}"
        hide_values_for = ['secret', 'token']
        post_data_as_string = post_data.sort.map { |key, value| "#{key} => #{hide_values_for.include?(key) ? 'PRESENT' : value.inspect}" }.join(', ')
        puts "{#{post_data_as_string}}"
      end

      begin
        request = Net::HTTP::Post.new(uri)
        request['User-Agent'] = http_user_agent
        request.set_form_data post_data
        http = Net::HTTP.new(uri.hostname, uri.port)
        http.use_ssl = uri.scheme.eql?('https')
        response = http.request(request)
      rescue => e
        raise OSM::APIError::ConnectionError, "#{e.class}: #{e.message}"
      end
      unless response.is_a?(Net::HTTPOK)
        # Connection error occured
        fail OSM::APIError::ConnectionError, "HTTP Status code was #{response.code}"
      end

      if debug?
        puts "Result from :#{site} request to #{url}"
        puts "#{response.code}\t#{response.class}\t#{response.content_type}"
        puts response.body
      end

      return nil if response.body.empty?
      case response.content_type
      when 'application/json', 'text/html'
        begin
          decoded = JSON.parse(response.body)
          if osm_error = get_osm_error(decoded)
            fail OSM::OSMError, osm_error if osm_error
          end
          return decoded
        rescue JSON::ParserError
          fail OSM::OSMError, response.body
        end
      when 'image/jpeg'
        return response.body
      else
        fail OSM::APIError::UnexpectedType, "Got a: #{response.content_type}"
      end
    end


    # Get API user's roles in OSM
    # @!macro options_get
    # @return [Array<Hash>] data returned by OSM
    def get_user_roles(**args)
      get_user_roles!(**args)
      rescue OSMError::NoActiveRoles
        return []
    end

    # Get API user's roles in OSM
    # @!macro options_get
    # @return [Array<Hash>] data returned by OSM
    # @raises OSM::NoActiveRoles
    def get_user_roles!(no_read_cache: false)
      cache_key = ['user_roles', user_id]

      OSM::Model.cache_fetch(api: self, key: cache_key, no_read_cache: no_read_cache) do
        user_roles = {}
        begin
          user_roles = post_query('api.php?action=getUserRoles')
          if user_roles.eql?(false)
            # false equates to no roles
            fail OSMError::NoActiveRoles, 'You do not have any active roles in OSM.'
          end
        rescue OSM::OSMError => e
          if e.message.eql?('false')
            fail OSMError::NoActiveRoles, 'You do not have any active roles in OSM.'
          else
            raise e
          end
        end
        user_roles
      end # cache fetch
    end # def get_user_roles!


    # Get API user's permissions
    # @!macro options_get
    # @return nil if an error occured or the user does not have access to that section
    # @return [Hash] {section_id => permissions_hash}
    def get_user_permissions(no_read_cache: false)
      cache_key = ['permissions', user_id]

      OSM::Model.cache_fetch(api: self, key: cache_key, no_read_cache: no_read_cache) do
        all_permissions = {}
        get_user_roles(no_read_cache: no_read_cache).each do |item|
          unless item['section'].eql?('discount')  # It's not an actual section
            all_permissions.merge!(OSM.to_i_or_nil(item['sectionid']) => OSM.make_permissions_hash(item['permissions']))
          end
        end
        all_permissions
      end # cache fetch
    end

    # Set access permission for an API user for a given Section
    # @param [OSM::Api::Configuration] configuration The configuration detailing how to talk to OSM
    # @param [Section, Integer] section The Section to set permissions for
    # @param [Hash] permissions The permissions Hash
    def set_user_permissions(section:, permissions:)
      key = ['permissions', user_id]
      permissions = get_user_permissions.merge(section.to_i => permissions)
      OSM::Model.cache_write(api: self, key: key, data: permissions)
    end


    def to_s
      if has_valid_user?
        "#{site} - #{api_id} - #{name} - #{user_id}"
      else
        "#{site} - #{api_id} - #{name}"
      end
    end

    def to_i
      api_id.to_i
    end

    def to_h
      attributes = {
        site:       @site,
        name:       @name.clone,
        api_id:     @api_id.clone,
        api_secret: @api_secret.clone,
        debug:      @debug
      }
      if valid_user?
        attributes.merge!(
          user_id: @user_id.clone,
          user_secret: @user_secret.clone
        )
      end
    end


    def debug=(value)
      @debug = !!value
    end
    def debug?
      debug
    end

    def http_user_agent=(value)
      value = value.to_s.clone
      @http_user_agent = value.empty? ? nil : value
    end
    def http_user_agent
      @http_user_agent || "#{name} (using osm gem version #{OSM::VERSION})"
    end


    # Get the error returned by OSM
    # @param data what OSM gave us
    # @return false if no error message was found
    # @return [String] the error message
    private def get_osm_error(data)
      return false unless data.is_a?(Hash)
      return false if data['ok']
      to_return = data['error'] || data['err'] || false
      if to_return.is_a?(Hash)
        to_return = to_return['message'] unless to_return['message'].blank?
      end
      to_return = false if to_return.blank?
      to_return
    end

  end # class Api
end # Module
