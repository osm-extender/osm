# @!macro [new] options_get
#   @param [Hash] options
#   @option options [Boolean] :no_cache (optional) if true then the data will be retreived from OSM not the cache

# @!macro [new] options_api_data
#   @param [Hash] api_data
#   @option api_data [String] 'userid' (optional) the OSM userid to make the request as
#   @option api_data [String] 'secret' (optional) the OSM secret belonging to the above user


module Osm

  class Api

    @@default_cache_ttl = 30 * 60     # The default caching time for responses from OSM (in seconds)
                                      # Some things will only be cached for half this time
                                      # Whereas others will be cached for twice this time
                                      # Most items however will be cached for this time

    @@user_access = Hash.new
    @@cache_prepend_to_key = 'OSMAPI'
    @@cache = nil

    # Initialize a new API connection
    # If passing user details then both must be passed
    # @param [String] userid osm userid of the user to act as
    # @param [String] secret osm secret of the user to act as
    # @param [Symbol] site wether to use OSM (:scout) or OGM (:guide), defaults to the value set for the class
    # @return nil
    def initialize(userid=nil, secret=nil, site=@@api_site)
      raise ArgumentError, 'You must pass a secret if you are passing a userid' if secret.nil? && !userid.nil?
      raise ArgumentError, 'You must pass a userid if you are passing a secret' if userid.nil? && !secret.nil?
      raise ArgumentError, 'site is invalid, if passed it should be either :scout or :guide' unless [:scout, :guide].include?(site)

      @base_url = 'https://www.onlinescoutmanager.co.uk' if site == :scout
      @base_url = 'http://www.onlineguidemanager.co.uk' if site == :guide
      set_user(userid, secret)
      nil
    end

    # Configure the API options used by all instances of the class
    # @param [Hash] options
    # @option options [String] :api_id the apiid given to you for using the OSM id
    # @option options [String] :api_token the token which goes with the above api
    # @option options [String] :api_name the name displayed in the External Access tab of OSM
    # @option options [Symbol] :api_sate wether to use OSM (if :scout) or OGM (if :guide)
    # @option options [Class] :cache (optional) An instance of a cache class, must provide the methods (exist?, delete, write, read), for details see Rails.cache. Whilst this is optional you should remember that caching is required to use the OSM API.
    # @option options [Fixnum] :default_cache_ttl (optional, default = 30.minutes) The default TTL value for the cache, note that some items are cached for twice this time and others are cached for half this time (in seconds)
    # @option options [String] :cache_prepend_to_key (optional, default = 'OSMAPI') Text to prepend to the key used to store data in the cache
    # @return nil
    def self.configure(options)
      raise ArgumentError, ':api_id does not exist in options hash' if options[:api_id].nil?
      raise ArgumentError, ':api_token does not exist in options hash' if options[:api_token].nil?
      raise ArgumentError, ':api_name does not exist in options hash' if options[:api_name].nil?
      raise ArgumentError, ':api_site does not exist in options hash or is invalid, this should be set to either :scout or :guide' unless [:scout, :guide].include?(options[:api_site])
      raise ArgumentError, ':default_cache_ttl must be greater than 0' unless (options[:default_cache_ttl].nil? || options[:default_cache_ttl].to_i > 0)
      unless options[:cache].nil?
        [:exist?, :delete, :write, :read].each do |method|
          raise ArgumentError, ":cache must have a #{method} method" unless options[:cache].methods.include?(method)
        end
      end

      @@api_id = options[:api_id].to_s
      @@api_token = options[:api_token].to_s
      @@api_name = options[:api_name].to_s
      @@api_site = options[:api_site]
      @@default_cache_ttl = options[:default_cache_ttl].to_i unless options[:default_cache_ttl].nil?
      @@cache_prepend_to_key = options[:cache_prepend_to_key].to_s unless options[:cache_prepend_to_key].nil?
      @@cache = options[:cache]
      nil
    end

    # Get the API ID used in this class
    # @return [String] the API ID
    def self.api_id
      return @@api_id
    end

    # Get the API name displayed in the External Access tab of OSM
    # @return [String] the API name
    def self.api_name
      return @@api_name
    end

    # Get the userid and secret to be able to act as a certain user on the OSM system
    # Also set's the 'current user'
    # @param [String] email the login email address of the user on OSM
    # @param [String] password the login password of the user on OSM
    # @return [Hash] a hash containing the following keys:
    #   * 'userid' - the userid to use in future requests
    #   * 'secret' - the secret to use in future requests
    def authorize(email, password)
      api_data = {
        'email' => email,
        'password' => password,
      }
      data = perform_query('users.php?action=authorise', api_data)
      set_user(data['userid'], data['secret'])
      return data
    end

    # Get the user's roles
    # @!macro options_get
    # @!macro options_api_data
    # @return [Array<Osm::Role>]
    def get_roles(options={}, api_data={})

      if !options[:no_cache] && cache_exist?("roles-#{api_data[:userid] || @userid}")
        return cache_read("roles-#{api_data[:userid] || @userid}")
      end

      data = perform_query('api.php?action=getUserRoles', api_data)

      result = Array.new
      data.each do |item|
        role = Osm::Role.new(item)
        result.push role
        cache_write("section-#{role.section.id}", role.section, :expires_in => @@default_cache_ttl*2)
        self.user_can_access :section, role.section.id, api_data
      end
      cache_write("roles-#{api_data[:userid] || @userid}", result, :expires_in => @@default_cache_ttl*2)

      return result
    end

    # Get the user's notepads
    # @!macro options_get
    # @!macro options_api_data
    # @return [Hash] a hash (keys are section IDs, values are a string)
    def get_notepads(options={}, api_data={})
      if !options[:no_cache] && cache_exist?("notepads-#{api_data[:userid] || @userid}")
        return cache_read("notepads-#{api_data[:userid] || @userid}")
      end

      notepads = perform_query('api.php?action=getNotepads', api_data)
      return {} unless notepads.is_a?(Hash)

      data = {}
      notepads.each do |key, value|
        data[key.to_i] = value
        cache_write("notepad-#{key}", value, :expires_in => @@default_cache_ttl*2)
      end

      cache_write("notepads-#{api_data[:userid] || @userid}", data, :expires_in => @@default_cache_ttl*2)
      return data
    end

    # Get the notepad for a specified section
    # @param [Osm:Section, Fixnum] section the section (or its ID) to get the notepad for
    # @!macro options_get
    # @!macro options_api_data
    # @return nil if an error occured or the user does not have access to that section
    # @return [String] the content of the notepad otherwise
    def get_notepad(section, options={}, api_data={})
      section_id = id_for_section(section)

      if !options[:no_cache] && cache_exist?("notepad-#{section_id}") && self.user_can_access?(:section, section_id, api_data)
        return cache_read("notepad-#{section_id}")
      end

      notepads = get_notepads(options, api_data)
      return nil unless notepads.is_a? Hash

      notepads.each_key do |key|
        return notepads[key] if key == section_id
      end

      return nil
    end

    # Get the section (and its configuration)
    # @param [Fixnum] section_id the section id of the required section
    # @!macro options_get
    # @!macro options_api_data
    # @return nil if an error occured or the user does not have access to that section
    # @return [Osm::Section]
    def get_section(section_id, options={}, api_data={})
      if !options[:no_cache] && cache_exist?("section-#{section_id}") && self.user_can_access?(:section, section_id, api_data)
        return cache_read("section-#{section_id}")
      end

      roles = get_roles(options, api_data)
      return nil unless roles.is_a? Array

      roles.each do |role|
        return role.section if role.section.id == section_id
      end

      return nil
    end

    # Get the groupings (e.g. patrols, sixes, lodges) for a given section
    # @param [Osm::Section, Fixnum] section the section to get the groupings for
    # @!macro options_get
    # @!macro options_api_data
    # @return [Array<Osm::Grouping>]
    def get_groupings(section, options={}, api_data={})
      section_id = id_for_section(section)

      if !options[:no_cache] && cache_exist?("groupings-#{section_id}") && self.user_can_access?(:section, section_id, api_data)
        return cache_read("groupings-#{section_id}")
      end

      data = perform_query("users.php?action=getPatrols&sectionid=#{section_id}", api_data)

      result = Array.new
      data['patrols'].each do |item|
        grouping = Osm::Grouping.from_api(item)
        result.push grouping
        cache_write("grouping-#{grouping.id}", grouping, :expires_in => @@default_cache_ttl*2)
        self.user_can_access :grouping, grouping.id, api_data
      end
      cache_write("groupings-#{section_id}", result, :expires_in => @@default_cache_ttl*2)

      return result
    end

    # Get the terms that the OSM user can access
    # @!macro options_get
    # @!macro options_api_data
    # @return [Array<Osm::Term>]
    def get_terms(options={}, api_data={})
      if !options[:no_cache] && cache_exist?("terms-#{api_data[:userid] || @userid}")
        return cache_read("terms-#{api_data[:userid] || @userid}")
      end

      data = perform_query('api.php?action=getTerms', api_data)

      result = Array.new
      data.each_key do |key|
        data[key].each do |item|
          term = Osm::Term.new(item)
          result.push term
          cache_write("term-#{term.id}", term, :expires_in => @@default_cache_ttl*2)
          self.user_can_access :term, term.id, api_data
        end
      end

      cache_write("terms-#{api_data[:userid] || @userid}", result, :expires_in => @@default_cache_ttl*2)
      return result
    end

    # Get a term
    # @param [Fixnum] term_id the id of the required term
    # @!macro options_get
    # @!macro options_api_data
    # @return nil if an error occured or the user does not have access to that term
    # @return [Osm::Term]
    def get_term(term_id, options={}, api_data={})
      if !options[:no_cache] && cache_exist?("term-#{term_id}") && self.user_can_access?(:term, term_id, api_data)
        return cache_read("term-#{term_id}")
      end

      terms = get_terms(options)
      return nil unless terms.is_a? Array

      terms.each do |term|
        return term if term.id == term_id
      end

      return nil
    end

    # Get the programme for a given term
    # @param [Osm:Section, Fixnum] section the section (or its ID) to get the programme for
    # @param [Osm:term, Fixnum] term the term (or its ID) to get the programme for, passing nil causes the current term to be used
    # @!macro options_get
    # @!macro options_api_data
    # @return [Array<Osm::Evening>]
    def get_programme(section, term, options={}, api_data={})
      section_id = id_for_section(section)
      term_id = id_for_term(term, section, api_data)

      if !options[:no_cache] && cache_exist?("programme-#{section_id}-#{term_id}") && self.user_can_access?(:programme, section_id, api_data)
        return cache_read("programme-#{section_id}-#{term_id}")
      end

      data = perform_query("programme.php?action=getProgramme&sectionid=#{section_id}&termid=#{term_id}", api_data)

      result = Array.new
      data = {'items'=>[],'activities'=>{}} if data.is_a? Array
      self.user_can_access(:programme, section_id, api_data) unless data.is_a? Array
      items = data['items'] || []
      activities = data['activities'] || {}

      items.each do |item|
        evening = Osm::Evening.from_api(item, activities[item['eveningid']])
        result.push evening
        evening.activities.each do |activity|
          self.user_can_access :activity, activity.activity_id, api_data
        end
      end

      cache_write("programme-#{section_id}-#{term_id}", result, :expires_in => @@default_cache_ttl)
      return result
    end

    # Get activity details
    # @param [Fixnum] activity_id the activity ID
    # @param [Fixnum] version the version of the activity to retreive, if nil the latest version will be assumed
    # @!macro options_get
    # @!macro options_api_data
    # @return [Osm::Activity]
    def get_activity(activity_id, version=nil, options={}, api_data={})
      if !options[:no_cache] && cache_exist?("activity-#{activity_id}-#{version}") && self.user_can_access?(:activity, activity_id, api_data)
        return cache_read("activity-#{activity_id}-#{version}")
      end

      data = nil
      if version.nil?
        data = perform_query("programme.php?action=getActivity&id=#{activity_id}", api_data)
      else
        data = perform_query("programme.php?action=getActivity&id=#{activity_id}&version=#{version}", api_data)
      end

      activity = Osm::Activity.from_api(data)
      cache_write("activity-#{activity_id}-#{nil}", activity, :expires_in => @@default_cache_ttl*2) if version.nil?
      cache_write("activity-#{activity_id}-#{activity.version}", activity, :expires_in => @@default_cache_ttl/2)
      self.user_can_access :activity, activity.id, api_data

      return activity
    end

    # Get members
    # @param [Osm:Section, Fixnum] section the section (or its ID) to get the members for
    # @param [Osm:Term, Fixnum] term the term (or its ID) to get the members for, passing nil causes the current term to be used
    # @!macro options_get
    # @!macro options_api_data
    # @return [Array<Osm::Member>]
    def get_members(section, term=nil, options={}, api_data={})
      section_id = id_for_section(section)
      term_id = id_for_term(term, section, api_data)

      if !options[:no_cache] && cache_exist?("members-#{section_id}-#{term_id}") && self.user_can_access?(:member, section_id, api_data)
        return cache_read("members-#{section_id}-#{term_id}")
      end

      data = perform_query("users.php?action=getUserDetails&sectionid=#{section_id}&termid=#{term_id}", api_data)

      result = Array.new
      data['items'].each do |item|
        result.push Osm::Member.from_api(item)
      end
      self.user_can_access :member, section_id, api_data
      cache_write("members-#{section_id}-#{term_id}", result, :expires_in => @@default_cache_ttl)

      return result
    end

    # Get API access details for a given section
    # @param [Osm:Section, Fixnum] section the section (or its ID) to get the details for
    # @!macro options_get
    # @!macro options_api_data
    # @return [Array<Osm::ApiAccess>]
    def get_api_access(section, options={}, api_data={})
      section_id = id_for_section(section)

      if !options[:no_cache] && cache_exist?("api_access-#{api_data['userid'] || @userid}-#{section_id}")
        return cache_read("api_access-#{api_data['userid'] || @userid}-#{section_id}")
      end

      data = perform_query("users.php?action=getAPIAccess&sectionid=#{section_id}", api_data)

      result = Array.new
      data['apis'].each do |item|
        this_item = Osm::ApiAccess.from_api(item)
        result.push this_item
        self.user_can_access(:programme, section_id, api_data) if this_item.can_read?(:programme)
        self.user_can_access(:member, section_id, api_data) if this_item.can_read?(:member)
        self.user_can_access(:badge, section_id, api_data) if this_item.can_read?(:badge)
        cache_write("api_access-#{api_data['userid'] || @userid}-#{section_id}-#{this_item.id}", this_item, :expires_in => @@default_cache_ttl*2)
      end

      return result
    end

    # Get our API access details for a given section
    # @param [Osm:Section, Fixnum] section the section (or its ID) to get the details for
    # @!macro options_get
    # @!macro options_api_data
    # @return [Osm::ApiAccess]
    def get_our_api_access(section, options={}, api_data={})
      section_id = id_for_section(section)

      if !options[:no_cache] && cache_exist?("api_access-#{api_data['userid'] || @userid}-#{section_id}-#{Osm::Api.api_id}")
        return cache_read("api_access-#{api_data['userid'] || @userid}-#{section_id}-#{Osm::Api.api_id}")
      end

      data = get_api_access(section_id, options)
      found = nil
      data.each do |item|
        found = item if item.our_api?
      end

      return found
    end

    # Get events
    # @param [Osm:Section, Fixnum] section the section (or its ID) to get the events for
    # @!macro options_get
    # @!macro options_api_data
    # @return [Array<Osm::Event>]
    def get_events(section, options={}, api_data={})
      section_id = id_for_section(section)

      if !options[:no_cache] && cache_exist?("events-#{section_id}") && self.user_can_access?(:programme, section_id, api_data)
        return cache_read("events-#{section_id}")
      end

      data = perform_query("events.php?action=getEvents&sectionid=#{section_id}", api_data)

      result = Array.new
      unless data['items'].nil?
        data['items'].each do |item|
          result.push Osm::Event.from_api(item)
        end
      end
      self.user_can_access :programme, section_id, api_data
      cache_write("events-#{section_id}", result, :expires_in => @@default_cache_ttl)

      return result
    end

    # Get due badges
    # @param [Osm:Section, Fixnum] section the section (or its ID) to get the due badges for
    # @!macro options_get
    # @!macro options_api_data
    # @return [Osm::DueBadges]
    def get_due_badges(section, term=nil, options={}, api_data={})
      section_id = id_for_section(section)
      term_id = id_for_term(term, section, api_data)

      if !options[:no_cache] && cache_exist?("due_badges-#{section_id}-#{term_id}") && self.user_can_access?(:badge, section_id, api_data)
        return cache_read("due_badges-#{section_id}-#{term_id}")
      end

      section_type = get_section(section_id, api_data).type.to_s
      data = perform_query("challenges.php?action=outstandingBadges&section=#{section_type}&sectionid=#{section_id}&termid=#{term_id}", api_data)

      data = Osm::DueBadges.from_api(data)
      self.user_can_access :badge, section_id, api_data
      cache_write("due_badges-#{section_id}-#{term_id}", data, :expires_in => @@default_cache_ttl*2)

      return data
    end

    # Get register structure
    # @param [Osm:Section, Fixnum] section the section (or its ID) to get the structure for
    # @param [Osm:Term, Fixnum] section the term (or its ID) to get the structure for, passing nil causes the current term to be used
    # @!macro options_get
    # @!macro options_api_data
    # @return [Array<Hash>] representing the fields of the register
    def get_register_structure(section, term=nil, options={}, api_data={})
      section_id = id_for_section(section)
      term_id = id_for_term(term, section, api_data)

      if !options[:no_cache] && cache_exist?("register_structure-#{section_id}-#{term_id}") && self.user_can_access?(:register, section_id, api_data)
        return cache_read("register_structure-#{section_id}-#{term_id}")
      end

      data = perform_query("users.php?action=registerStructure&sectionid=#{section_id}&termid=#{term_id}", api_data)

      structure = []
      data.each do |item|
        item['rows'].each do |row|
          structure.push Osm::RegisterField.new(row)
        end
      end
      self.user_can_access :register, section_id, api_data
      cache_write("register_structure-#{section_id}-#{term_id}", structure, :expires_in => @@default_cache_ttl/2)

      return structure
    end

    # Get register data
    # @param [Osm:Section, Fixnum] section the section (or its ID) to get the register for
    # @param [Osm:Term, Fixnum] section the term (or its ID) to get the register for, passing nil causes the current term to be used
    # @!macro options_get
    # @!macro options_api_data
    # @return [Array<RegisterData>] representing the attendance of each member
    def get_register_data(section, term=nil, options={}, api_data={})
      section_id = id_for_section(section)
      term_id = id_for_term(term, section, api_data)

      if !options[:no_cache] && cache_exist?("register-#{section_id}-#{term_id}") && self.user_can_access?(:register, section_id, api_data)
        return cache_read("register-#{section_id}-#{term_id}")
      end

      data = perform_query("users.php?action=register&sectionid=#{section_id}&termid=#{term_id}", api_data)

      data = data['items']
      data.each do |item|
        item = Osm::RegisterData.new(item)
      end
      self.user_can_access :register, section_id, api_data
      cache_write("register-#{section_id}-#{term_id}", data, :expires_in => @@default_cache_ttl/2)
      return data
    end

    # Create an evening in OSM
    # @param [Fixnum] section_id the id of the section to add the term to
    # @param [Date] meeting_date the date of the meeting
    # @!macro options_api_data
    # @return [Boolean] if the operation suceeded or not
    def create_evening(section, meeting_date, api_data={})
      section_id = id_for_section(section)
      evening_api_data = {
        'meetingdate' => meeting_date.strftime('%Y-%m-%d'),
        'sectionid' => section_id,
        'activityid' => -1
      }

      data = perform_query("programme.php?action=addActivityToProgramme", api_data.merge(evening_api_data))

      # The cached programmes for the section will be out of date - remove them
      get_terms(api_data).each do |term|
        cache_delete("programme-#{term.section_id}-#{term.id}") if term.section_id == section_id
      end

      return data.is_a?(Hash) && (data['result'] == 0)
    end

    # Update an evening in OSM
    # @param [Osm::Evening] evening the evening to update
    # @!macro options_api_data
    # @return [Boolean] if the operation suceeded or not
    def update_evening(evening, api_data={})
      response = perform_query("programme.php?action=editEvening", api_data.merge(evening.to_api))

      # The cached programmes for the section will be out of date - remove them
      get_terms(api_data).each do |term|
        cache_delete("programme-#{term.section_id}-#{term.id}") if term.section_id == evening.section_id
      end

      return response.is_a?(Hash) && (response['result'] == 0)
    end


    protected
    # Set access permission for the current user on a resource stored in the cache
    # @param [Symbol] resource_type a symbol representing the resource type (:section, :grouping, :term, :activity, :programme, :member, :badge, :register)
    # @param [Fixnum] resource_id the id of the resource being checked
    # @param [Hash] api_data the data hash used in accessing the api
    # @param [Boolean] permission wether the user can access the resource
    # @return [Boolean] the permission which was set
    def user_can_access(resource_type, resource_id, api_data, permission=true)
      user = (api_data['userid'] || @userid).to_i
      resource_id = resource_id.to_i
      resource_type = resource_type.to_sym

      @@user_access[user] = {} if @@user_access[user].nil?
      @@user_access[user][resource_type] = {} if @@user_access[user][resource_type].nil?

      @@user_access[user][resource_type][resource_id] = permission
    end

    # Get access permission for the current user on a resource stored in the cache
    # @param [Symbol] resource_type a symbol representing the resource type (:section, :grouping, :term, :activity, :programme, :member, :badge, :register)
    # @param [Fixnum] resource_id the id of the resource being checked
    # @param [Hash] api_data the data hash used in accessing the api
    # @return nil if the combination of user and resource has not been set
    # @return [Boolean] if the user can access the resource
    def user_can_access?(resource_type, resource_id, api_data)
      user = (api_data['userid'] || @userid).to_i
      resource_id = resource_id.to_i
      resource_type = resource_type.to_sym

      return nil if @@user_access[user].nil?
      return nil if @@user_access[user][resource_type].nil?
      return @@user_access[user][resource_type][resource_id]
    end


    private
    # Set the OSM user to make future requests as
    # @param [String] userid the OSM userid to use (get this using the authorize method)
    # @param [String] secret the OSM secret to use (get this using the authorize method)
    def set_user(userid, secret)
      @userid = userid
      @secret = secret
    end

    # Make the query to the OSM API
    # @param [String] url the script on the remote server to invoke
    # @param [Hash] api_data a hash containing the values to be sent to the server
    # @return [Hash, Array, String] the parsed JSON returned by OSM
    def perform_query(url, api_data={})
      api_data['apiid'] = @@api_id
      api_data['token'] = @@api_token

      if api_data['userid'].nil? && api_data['secret'].nil?
        unless @userid.nil? || @secret.nil?
          api_data['userid'] = @userid
          api_data['secret'] = @secret
        end
      end

      begin
        result = HTTParty.post("#{@base_url}/#{url}", {:body => api_data})
      rescue SocketError, TimeoutError, OpenSSL::SSL::SSLError
        raise ConnectionError, 'A problem occured on the internet.'
      end
      raise ConnectionError, "HTTP Status code was #{result.response.code}" if !result.response.code.eql?('200')

      raise Error, result.response.body unless looks_like_json?(result.response.body)
      decoded = ActiveSupport::JSON.decode(result.response.body)
      osm_error = get_osm_error(decoded)
      raise Error, osm_error if osm_error
      return decoded        
    end

    # Check if text looks like it's JSON
    # @param [String] text what to look at
    # @return [Boolean]
    def looks_like_json?(text)
      (['[', '{'].include?(text[0]))
    end

    # Get the error returned by OSM
    # @param data what OSM gave us
    # @return false if no error message was found
    # @return [String] the error message
    def get_osm_error(data)
      return false unless data.is_a?(Hash)
      to_return = data['error'] || data['err'] || false
      to_return = false if to_return.blank?
      return to_return
    end

    # Wrap cache calls
    def cache_read(key)
      return @@cache.nil? ? nil : @@cache.read("#{@@cache_prepend_to_key}-#{key}")
    end
    def cache_write(key, data, options={})
      return @@cache.nil? ? false : @@cache.write("#{@@cache_prepend_to_key}-#{key}", data, options)
    end
    def cache_exist?(key)
      return @@cache.nil? ? false : @@cache.exist?("#{@@cache_prepend_to_key}-#{key}")
    end
    def cache_delete(key)
      return @@cache.nil? ? true : @@cache.delete("#{@@cache_prepend_to_key}-#{key}")
    end

    # Get the ID from an object or fixnum
    # @param cl the Class being used (e.g. Osm::Section)
    # @param value the value to get the ID from
    # @param [String] error_name the name of the class to use in error messages
    # @param [String, Symbol] id_method the method to call on cl to get the ID
    # @return [Fixnum] the ID
    def id_for(cl, value, error_name, id_method=:id)
      if value.is_a?(cl)
        value = value.send(id_method)
      else
        raise ArgumentError, "Invalid type for #{error_name}" unless value.is_a?(Fixnum)
      end

      raise ArgumentError, "Invalid #{error_name} ID" unless value > 0
      return value
    end

    def id_for_section(section)
      id_for(Osm::Section, section, 'section')
    end
    def id_for_term(term, section, api_data)
      return term.nil? ? Osm::find_current_term_id(self, id_for_section(section), api_data) : id_for(Osm::Term, term, 'term')
    end

  end

end
