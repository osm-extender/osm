# @!macro [new] options_get
#   @param [Hash] options
#   @option options [Boolean] :no_cache (optional) if true then the data will be retreived from OSM not the cache

# @!macro [new] options_api_data
#   @param [Hash] api_data - DEPRECATED (DO NOT USE THIS OPTION)
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
    @@debug = false

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
    # @option options [Boolean] :debug if true debugging info is output (options, default = false)
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
      @@debug = !!options[:debug]
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

    # Set the OSM user to make future requests as
    # @param [String] userid the OSM userid to use (get this using the authorize method)
    # @param [String] secret the OSM secret to use (get this using the authorize method)
    def set_user(userid, secret)
      @userid = userid
      @secret = secret
    end


    # Get the user's roles
    # @!macro options_get
    # @!macro options_api_data
    # @return [Array<Osm::Role>]
    def get_roles(options={}, api_data={})
      warn "[DEPRECATION OF OPTION] use of the api_data option is deprecated." unless api_data == {}
      cache_key = "roles-#{api_data[:userid] || @userid}"

      if !options[:no_cache] && cache_exist?(cache_key)
        return cache_read(cache_key)
      end

      data = perform_query('api.php?action=getUserRoles', api_data)

      result = Array.new
      data.each do |item|
        role = Osm::Role.from_api(item)
        result.push role
        cache_write("section-#{role.section.id}", role.section, :expires_in => @@default_cache_ttl*2)
        self.user_can_access :section, role.section.id, api_data
      end
      cache_write(cache_key, result, :expires_in => @@default_cache_ttl*2)

      return result
    end

    # Get the user's notepads
    # @!macro options_get
    # @!macro options_api_data
    # @return [Hash] a hash (keys are section IDs, values are a string)
    def get_notepads(options={}, api_data={})
      warn "[DEPRECATION OF OPTION] use of the api_data option is deprecated." unless api_data == {}
      cache_key = "notepads-#{api_data[:userid] || @userid}"

      if !options[:no_cache] && cache_exist?(cache_key)
        return cache_read(cache_key)
      end

      notepads = perform_query('api.php?action=getNotepads', api_data)
      return {} unless notepads.is_a?(Hash)

      data = {}
      notepads.each do |key, value|
        data[key.to_i] = value
        cache_write("notepad-#{key}", value, :expires_in => @@default_cache_ttl*2)
      end

      cache_write(cache_key, data, :expires_in => @@default_cache_ttl*2)
      return data
    end

    # Get the notepad for a specified section
    # @param [Osm::Section, Fixnum] section the section (or its ID) to get the notepad for
    # @!macro options_get
    # @!macro options_api_data
    # @return nil if an error occured or the user does not have access to that section
    # @return [String] the content of the notepad otherwise
    def get_notepad(section, options={}, api_data={})
      warn "[DEPRECATION OF OPTION] use of the api_data option is deprecated." unless api_data == {}
      section_id = id_for_section(section)
      cache_key = "notepad-#{section_id}"

      if !options[:no_cache] && cache_exist?(cache_key) && self.user_can_access?(:section, section_id, api_data)
        return cache_read(cache_key)
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
      warn "[DEPRECATION OF OPTION] use of the api_data option is deprecated." unless api_data == {}
      cache_key = "section-#{section_id}"

      if !options[:no_cache] && cache_exist?(cache_key) && self.user_can_access?(:section, section_id, api_data)
        return cache_read(cache_key)
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
      warn "[DEPRECATION OF OPTION] use of the api_data option is deprecated." unless api_data == {}
      section_id = id_for_section(section)
      cache_key = "groupings-#{section_id}"

      if !options[:no_cache] && cache_exist?(cache_key) && self.user_can_access?(:section, section_id, api_data)
        return cache_read(cache_key)
      end

      data = perform_query("users.php?action=getPatrols&sectionid=#{section_id}", api_data)

      result = Array.new
      data['patrols'].each do |item|
        grouping = Osm::Grouping.from_api(item)
        result.push grouping
        self.user_can_access :grouping, grouping.id, api_data
      end
      cache_write(cache_key, result, :expires_in => @@default_cache_ttl*2)

      return result
    end

    # Get the terms that the OSM user can access
    # @!macro options_get
    # @!macro options_api_data
    # @return [Array<Osm::Term>]
    def get_terms(options={}, api_data={})
      warn "[DEPRECATION OF OPTION] use of the api_data option is deprecated." unless api_data == {}
      cache_key = "terms-#{api_data[:userid] || @userid}"

      if !options[:no_cache] && cache_exist?(cache_key)
        return cache_read(cache_key)
      end

      data = perform_query('api.php?action=getTerms', api_data)

      result = Array.new
      data.each_key do |key|
        data[key].each do |item|
          term = Osm::Term.from_api(item)
          result.push term
          cache_write("term-#{term.id}", term, :expires_in => @@default_cache_ttl*2)
          self.user_can_access :term, term.id, api_data
        end
      end

      cache_write(cache_key, result, :expires_in => @@default_cache_ttl*2)
      return result
    end

    # Get a term
    # @param [Fixnum] term_id the id of the required term
    # @!macro options_get
    # @!macro options_api_data
    # @return nil if an error occured or the user does not have access to that term
    # @return [Osm::Term]
    def get_term(term_id, options={}, api_data={})
      warn "[DEPRECATION OF OPTION] use of the api_data option is deprecated." unless api_data == {}
      cache_key = "term-#{term_id}"

      if !options[:no_cache] && cache_exist?(cache_key) && self.user_can_access?(:term, term_id, api_data)
        return cache_read(cache_key)
      end

      terms = get_terms(options)
      return nil unless terms.is_a? Array

      terms.each do |term|
        return term if term.id == term_id
      end

      return nil
    end

    # Get the programme for a given term
    # @param [Osm::Section, Fixnum] section the section (or its ID) to get the programme for
    # @param [Osm::term, Fixnum, nil] term the term (or its ID) to get the programme for, passing nil causes the current term to be used
    # @!macro options_get
    # @!macro options_api_data
    # @return [Array<Osm::Evening>]
    def get_programme(section, term, options={}, api_data={})
      warn "[DEPRECATION OF OPTION] use of the api_data option is deprecated." unless api_data == {}
      section_id = id_for_section(section)
      term_id = id_for_term(term, section, api_data)
      cache_key = "programme-#{section_id}-#{term_id}"

      if !options[:no_cache] && cache_exist?(cache_key) && self.user_can_access?(:programme, section_id, api_data)
        return cache_read(cache_key)
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

      cache_write(cache_key, result, :expires_in => @@default_cache_ttl)
      return result
    end

    # Get activity details
    # @param [Fixnum] activity_id the activity ID
    # @param [Fixnum] version the version of the activity to retreive, if nil the latest version will be assumed
    # @!macro options_get
    # @!macro options_api_data
    # @return [Osm::Activity]
    def get_activity(activity_id, version=nil, options={}, api_data={})
      warn "[DEPRECATION OF OPTION] use of the api_data option is deprecated." unless api_data == {}
      cache_key = "activity-#{activity_id}-"

      if !options[:no_cache] && cache_exist?("#{cache_key}-#{version}") && self.user_can_access?(:activity, activity_id, api_data)
        return cache_read("#{cache_key}-#{version}")
      end

      data = nil
      if version.nil?
        data = perform_query("programme.php?action=getActivity&id=#{activity_id}", api_data)
      else
        data = perform_query("programme.php?action=getActivity&id=#{activity_id}&version=#{version}", api_data)
      end

      activity = Osm::Activity.from_api(data)
      cache_write("#{cache_key}-#{nil}", activity, :expires_in => @@default_cache_ttl*2) if version.nil?
      cache_write("#{cache_key}-#{activity.version}", activity, :expires_in => @@default_cache_ttl/2)
      self.user_can_access :activity, activity.id, api_data

      return activity
    end

    # Get members
    # @param [Osm::Section, Fixnum] section the section (or its ID) to get the members for
    # @param [Osm::Term, Fixnum, nil] term the term (or its ID) to get the members for, passing nil causes the current term to be used
    # @!macro options_get
    # @!macro options_api_data
    # @return [Array<Osm::Member>]
    def get_members(section, term=nil, options={}, api_data={})
      warn "[DEPRECATION OF OPTION] use of the api_data option is deprecated." unless api_data == {}
      section_id = id_for_section(section)
      term_id = id_for_term(term, section, api_data)
      cache_key = "members-#{section_id}-#{term_id}"

      if !options[:no_cache] && cache_exist?(cache_key) && self.user_can_access?(:member, section_id, api_data)
        return cache_read(cache_key)
      end

      data = perform_query("users.php?action=getUserDetails&sectionid=#{section_id}&termid=#{term_id}", api_data)

      result = Array.new
      data['items'].each do |item|
        result.push Osm::Member.from_api(item, section_id)
      end
      self.user_can_access :member, section_id, api_data
      cache_write(cache_key, result, :expires_in => @@default_cache_ttl)

      return result
    end

    # Get API access details for a given section
    # @param [Osm::Section, Fixnum] section the section (or its ID) to get the details for
    # @!macro options_get
    # @!macro options_api_data
    # @return [Array<Osm::ApiAccess>]
    def get_api_access(section, options={}, api_data={})
      warn "[DEPRECATION OF OPTION] use of the api_data option is deprecated." unless api_data == {}
      section_id = id_for_section(section)
      cache_key = "api_access-#{api_data['userid'] || @userid}-#{section_id}"

      if !options[:no_cache] && cache_exist?(cache_key)
        return cache_read(cache_key)
      end

      data = perform_query("users.php?action=getAPIAccess&sectionid=#{section_id}", api_data)

      result = Array.new
      data['apis'].each do |item|
        this_item = Osm::ApiAccess.from_api(item)
        result.push this_item
        self.user_can_access(:programme, section_id, api_data) if this_item.can_read?(:programme)
        self.user_can_access(:member, section_id, api_data) if this_item.can_read?(:member)
        self.user_can_access(:badge, section_id, api_data) if this_item.can_read?(:badge)
        cache_write("#{cache_key}-#{this_item.id}", this_item, :expires_in => @@default_cache_ttl*2)
      end
      cache_write(cache_key, result, :expires_in => @@default_cache_ttl*2)

      return result
    end

    # Get our API access details for a given section
    # @param [Osm::Section, Fixnum] section the section (or its ID) to get the details for
    # @!macro options_get
    # @!macro options_api_data
    # @return [Osm::ApiAccess]
    def get_our_api_access(section, options={}, api_data={})
      warn "[DEPRECATION OF OPTION] use of the api_data option is deprecated." unless api_data == {}
      section_id = id_for_section(section)
      cache_key = "api_access-#{api_data['userid'] || @userid}-#{section_id}-#{Osm::Api.api_id}"

      if !options[:no_cache] && cache_exist?(cache_key)
        return cache_read(cache_key)
      end

      data = get_api_access(section_id, options)
      found = nil
      data.each do |item|
        found = item if item.our_api?
      end

      return found
    end

    # Get events
    # @param [Osm::Section, Fixnum] section the section (or its ID) to get the events for
    # @!macro options_get
    # @option options [Boolean] :include_archived (optional) if true then archived activities will also be returned
    # @!macro options_api_data
    # @return [Array<Osm::Event>]
    def get_events(section, options={}, api_data={})
      warn "[DEPRECATION OF OPTION] use of the api_data option is deprecated." unless api_data == {}
      section_id = id_for_section(section)
      cache_key = "events-#{section_id}"
      events = nil

      if !options[:no_cache] && cache_exist?(cache_key) && self.user_can_access?(:programme, section_id, api_data)
        events = cache_read(cache_key)
      else

        data = perform_query("events.php?action=getEvents&sectionid=#{section_id}&showArchived=true", api_data)

        events = Array.new
        unless data['items'].nil?
          data['items'].each do |item|
            events.push Osm::Event.from_api(item)
          end
        end
        self.user_can_access :programme, section_id, api_data
        cache_write(cache_key, events, :expires_in => @@default_cache_ttl)
      end

      return events if options[:include_archived]
      return events.reject do |event|
        event.archived?
      end
    end

    # Get due badges
    # @param [Osm::Section, Fixnum] section the section (or its ID) to get the due badges for
    # @param [Osm::Term, Fixnum, nil] term the term (or its ID) to get the due badges for, passing nil causes the current term to be used
    # @!macro options_get
    # @!macro options_api_data
    # @return [Osm::DueBadges]
    def get_due_badges(section, term=nil, options={}, api_data={})
      warn "[DEPRECATION OF OPTION] use of the api_data option is deprecated." unless api_data == {}
      section_id = id_for_section(section)
      section_type = type_for_section(section, api_data)
      term_id = id_for_term(term, section, api_data)
      cache_key = "due_badges-#{section_id}-#{term_id}"

      if !options[:no_cache] && cache_exist?(cache_key) && self.user_can_access?(:badge, section_id, api_data)
        return cache_read(cache_key)
      end

      data = perform_query("challenges.php?action=outstandingBadges&section=#{section_type}&sectionid=#{section_id}&termid=#{term_id}", api_data)

      data = Osm::DueBadges.from_api(data)
      self.user_can_access :badge, section_id, api_data
      cache_write(cache_key, data, :expires_in => @@default_cache_ttl*2)

      return data
    end

    # Get register structure
    # @param [Osm::Section, Fixnum] section the section (or its ID) to get the structure for
    # @param [Osm::Term, Fixnum, nil] section the term (or its ID) to get the structure for, passing nil causes the current term to be used
    # @!macro options_get
    # @!macro options_api_data
    # @return [Array<Osm::RegisterField>] representing the fields of the register
    def get_register_structure(section, term=nil, options={}, api_data={})
      warn "[DEPRECATION OF OPTION] use of the api_data option is deprecated." unless api_data == {}
      section_id = id_for_section(section)
      term_id = id_for_term(term, section, api_data)
      cache_key = "register_structure-#{section_id}-#{term_id}"

      if !options[:no_cache] && cache_exist?(cache_key) && self.user_can_access?(:register, section_id, api_data)
        return cache_read(cache_key)
      end

      data = perform_query("users.php?action=registerStructure&sectionid=#{section_id}&termid=#{term_id}", api_data)

      structure = []
      data.each do |item|
        item['rows'].each do |row|
          structure.push Osm::RegisterField.from_api(row)
        end
      end
      self.user_can_access :register, section_id, api_data
      cache_write(cache_key, structure, :expires_in => @@default_cache_ttl/2)

      return structure
    end

    # Get register data
    # @param [Osm::Section, Fixnum] section the section (or its ID) to get the register for
    # @param [Osm::Term, Fixnum, nil] section the term (or its ID) to get the register for, passing nil causes the current term to be used
    # @!macro options_get
    # @!macro options_api_data
    # @return [Array<RegisterData>] representing the attendance of each member
    def get_register_data(section, term=nil, options={}, api_data={})
      warn "[DEPRECATION OF OPTION] use of the api_data option is deprecated." unless api_data == {}
      section_id = id_for_section(section)
      term_id = id_for_term(term, section, api_data)
      cache_key = "register-#{section_id}-#{term_id}"

      if !options[:no_cache] && cache_exist?(cache_key) && self.user_can_access?(:register, section_id, api_data)
        return cache_read(cache_key)
      end

      data = perform_query("users.php?action=register&sectionid=#{section_id}&termid=#{term_id}", api_data)

      data = data['items']
      to_return = []
      data.each do |item|
        to_return.push Osm::RegisterData.from_api(item)
      end
      self.user_can_access :register, section_id, api_data
      cache_write(cache_key, to_return, :expires_in => @@default_cache_ttl/2)
      return to_return
    end

    # Get flexirecord structure
    # @param [Osm::Section, Fixnum] section the section (or its ID) to get the structure for
    # @param [Fixnum] the id of the Flexi Record
    # @!macro options_get
    # @!macro options_api_data
    # @return [Array<Osm::FlexiRecordField>] representing the fields of the flexi record
    def get_flexi_record_fields(section, id, options={}, api_data={})
      warn "[DEPRECATION OF OPTION] use of the api_data option is deprecated." unless api_data == {}
      section_id = id_for_section(section)
      cache_key = "flexi_record_structure-#{section_id}-#{id}"

      if !options[:no_cache] && cache_exist?(cache_key) && self.user_can_access?(:flexi, section_id, api_data)
        return cache_read(cache_key)
      end

      data = perform_query("extras.php?action=getExtra&sectionid=#{section_id}&extraid=#{id}", api_data)

      structure = []
      data['structure'].each do |item|
        item['rows'].each do |row|
          structure.push Osm::FlexiRecordField.from_api(row)
        end
      end
      self.user_can_access :flexi, section_id, api_data
      cache_write(cache_key, structure, :expires_in => @@default_cache_ttl/2)

      return structure
    end

    # Get flexi record data
    # @param [Osm:Section, Fixnum] section the section (or its ID) to get the register for
    # @param [Fixnum] the id of the Flexi Record
    # @param [Osm:Term, Fixnum, nil] section the term (or its ID) to get the register for, passing nil causes the current term to be used
    # @!macro options_get
    # @!macro options_api_data
    # @return [Array<FlexiRecordData>]
    def get_flexi_record_data(section, id, term=nil, options={}, api_data={})
      warn "[DEPRECATION OF OPTION] use of the api_data option is deprecated." unless api_data == {}
      section_id = id_for_section(section)
      section_type = type_for_section(section, api_data)
      term_id = id_for_term(term, section, api_data)
      cache_key = "flexi_record_data-#{section_id}-#{term_id}-#{id}"

      if !options[:no_cache] && cache_exist?(cache_key) && self.user_can_access?(:flexi, section_id, api_data)
        return cache_read(cache_key)
      end

      data = perform_query("extras.php?action=getExtraRecords&sectionid=#{section_id}&extraid=#{id}&termid=#{term_id}&section=#{section_type}", api_data)

      to_return = []
      data['items'].each do |item|
        to_return.push Osm::FlexiRecordData.from_api(item)
      end
      self.user_can_access :flexi, section_id, api_data
      cache_write(cache_key, to_return, :expires_in => @@default_cache_ttl/2)
      return to_return
    end

    # Get badge stock levels
    # @param [Osm::Section, Fixnum] section the section (or its ID) to get the stock levels for
    # @param [Osm::Term, Fixnum, nil] section the term (or its ID) to get the stock levels for, passing nil causes the current term to be used
    # @!macro options_get
    # @return Hash
    def get_badge_stock_levels(section, term=nil, options={})
      section_id = id_for_section(section)
      section_type = type_for_section(section)
      term_id = id_for_term(term, section)
      cache_key = "badge_stock-#{section_id}-#{term_id}"

      if !options[:no_cache] && cache_exist?(cache_key) && self.user_can_access?(:badge, section_id)
        return cache_read(cache_key)
      end

      data = perform_query("challenges.php?action=getInitialBadges&type=core&sectionid=#{section_id}&section=#{section_type}&termid=#{term_id}")
      data = (data['stock'] || {}).select{ |k,v| !k.eql?('sectionid') }.
                                   inject({}){ |new_hash,(badge, level)| new_hash[badge] = level.to_i; new_hash }

      self.user_can_access :badge, section_id
      cache_write(cache_key, data, :expires_in => @@default_cache_ttl)
      return data
    end


    # Create an evening in OSM
    # @param [Osm::Section, Fixnum] section or section_id to add the evening to
    # @param [Date] meeting_date the date of the meeting
    # @!macro options_api_data
    # @return [Boolean] if the operation suceeded or not
    def create_evening(section, meeting_date, api_data={})
      warn "[DEPRECATION OF OPTION] use of the api_data option is deprecated." unless api_data == {}
      section_id = id_for_section(section)
      evening_api_data = {
        'meetingdate' => meeting_date.strftime(Osm::OSM_DATE_FORMAT),
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

    # Create a term in OSM
    # @param [Hash] options - the configuration of the new term
    #   @option options [Osm::Section, Fixnum] :section (required) section or section_id to add the term to
    #   @option options [String] :name (required) the name for the term
    #   @option options [Date] :start (required) the date for the start of term
    #   @option options [Date] :finish (required) the date for the finish of term
    # @return [Boolean] if the operation suceeded or not
    def create_term(options={})
      raise ArgumentError, ":section can't be nil" if options[:section].nil?
      raise ArgumentError, ":name can't be nil" if options[:name].nil?
      raise ArgumentError, ":start can't be nil" if options[:start].nil?
      raise ArgumentError, ":finish can't be nil" if options[:finish].nil?

      section_id = id_for_section(options[:section])
      api_data = {
        'term' => options[:name],
        'start' => options[:start].strftime(Osm::OSM_DATE_FORMAT),
        'end' => options[:finish].strftime(Osm::OSM_DATE_FORMAT),
        'termid' => '0'
      }

      data = perform_query("users.php?action=addTerm&sectionid=#{section_id}", api_data)

      # The cached terms for the section will be out of date - remove them
      get_terms.each do |term|
        cache_delete("term-#{term.id}") if term.section_id == section_id
      end
      cache_delete("terms-#{@userid}")

      return data.is_a?(Hash) && data['terms'].is_a?(Hash)
    end


    # Update an evening in OSM
    # @param [Osm::Evening] evening the evening to update
    # @!macro options_api_data
    # @return [Boolean] if the operation suceeded or not
    def update_evening(evening, api_data={})
      warn "[DEPRECATION OF OPTION] use of the api_data option is deprecated." unless api_data == {}
      raise ArgumentIsInvalid, 'evening is invalid' unless evening.valid?
      response = perform_query("programme.php?action=editEvening", api_data.merge(evening.to_api))

      # The cached programmes for the section will be out of date - remove them
      get_terms(api_data).each do |term|
        cache_delete("programme-#{term.section_id}-#{term.id}") if term.section_id == evening.section_id
      end

      return response.is_a?(Hash) && (response['result'] == 0)
    end

    # Update a term in OSM
    # @param [Osm::Term] term the term to update
    # @return [Boolean] if the operation suceeded or not
    def update_term(term)
      raise ArgumentIsInvalid, 'term is invalid' unless term.valid?

      data = perform_query("users.php?action=addTerm&sectionid=#{term.section_id}", term.to_api)

      # The cached terms for the section will be out of date - remove them
      cache_delete("term-#{term.id}")
      cache_delete("terms-#{@userid}")

      return data.is_a?(Hash) && data['terms'].is_a?(Hash)
    end
  
  

    protected
    # Set access permission for the current user on a resource stored in the cache
    # @param [Symbol] resource_type a symbol representing the resource type (:section, :grouping, :term, :activity, :programme, :member, :badge, :register)
    # @param [Fixnum] resource_id the id of the resource being checked
    # @param [Hash] api_data the data hash used in accessing the api
    # @param [Boolean] permission wether the user can access the resource
    # @return [Boolean] the permission which was set
    def user_can_access(resource_type, resource_id, api_data={}, permission=true)
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
    def user_can_access?(resource_type, resource_id, api_data={})
      user = (api_data['userid'] || @userid).to_i
      resource_id = resource_id.to_i
      resource_type = resource_type.to_sym

      return nil if @@user_access[user].nil?
      return nil if @@user_access[user][resource_type].nil?
      return @@user_access[user][resource_type][resource_id]
    end


    private
    # Make the query to the OSM API
    # @param [String] url the script on the remote server to invoke
    # @param [Hash] api_data a hash containing the values to be sent to the server
    #   @option api_data [String] 'userid' (optional) the OSM userid to make the request as
    #   @option api_data [String] 'secret' (optional) the OSM secret belonging to the above user
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

      if @@debug
        puts "Making OSM API request to #{url}"
        hide_values_for = ['secret', 'token']
        api_data_as_string = api_data.sort.map{ |key, value| "#{key} => #{hide_values_for.include?(key) ? 'PRESENT' : value.inspect}" }.join(', ')
        puts "{#{api_data_as_string}}"
      end

      begin
        result = HTTParty.post("#{@base_url}/#{url}", {:body => api_data})
      rescue SocketError, TimeoutError, OpenSSL::SSL::SSLError
        raise ConnectionError, 'A problem occured on the internet.'
      end
      raise ConnectionError, "HTTP Status code was #{result.response.code}" if !result.response.code.eql?('200')

      if @@debug
        puts "Result from OSM request to #{url}"
        puts result.response.body
      end

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

    def type_for_section(section, api_data={})
      (section.is_a?(Osm::Section) ? section : get_section(section, api_data)).type.to_s
    end

    def id_for_term(term, section, api_data={})
      return term.nil? ? Osm::find_current_term_id(self, id_for_section(section), api_data) : id_for(Osm::Term, term, 'term')
    end

  end # Class Api

end # Module
