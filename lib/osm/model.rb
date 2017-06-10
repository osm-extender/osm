# @!macro [new] options_get
#   @param no_read_cache true, false (optional) if true then the data will be retreived from OSM not the cache


module Osm

  # This class is expected to be inherited from.
  # It provides the caching and permission handling for model objects.
  class Model
    include Comparable
    include ActiveAttr::Model

    @@cache = nil
    @@prepend_to_cache_key = 'OSMAPI'
    @@cache_ttl = 600
    

    # Configure the options used by all models
    # @param cache [Class, nil] An instance of a cache class, must provide the methods (exist?, delete, write, read, fetch), for details see Rails.cache. Set to nil to disable caching.
    # @param ttl [Integer] (optional, default = 600 (10 minutes)) The default TTL value for the cache, note that some items are cached for twice this time and others are cached for half this time (in seconds)
    # @param prepend_to_cache_key [String] (optional, default = 'OSMAPI') Text to prepend to the key used to store data in the cache
    # @return nil
    def self.configure(cache: @@cache, prepend_to_cache_key: @@prepend_to_cache_key, cache_ttl: @@cache_ttl)
      self.cache = cache
      self.prepend_to_cache_key = prepend_to_cache_key
      self.cache_ttl = cache_ttl
      nil
    end


    def self.cache=(new_cache)
      unless new_cache.nil?
        [:exist?, :delete, :write, :read, :fetch].each do |method|
          fail ArgumentError, "cache must have a #{method} method" unless new_cache.methods.include?(method)
        end
      end
      @@cache = new_cache
    end
    def self.cache
      @@cache
    end
    def self.cache?
      !@@cache.nil?
    end
    def self.no_cache?
      !cache?
    end

    def self.cache_ttl=(new_cache_ttl)
      fail ArgumentError, 'cache_ttl must be a FixNum greater than 0' if new_cache_ttl && !(new_cache_ttl.is_a?(Integer) && new_cache_ttl > 0)
      @@cache_ttl = new_cache_ttl
    end
    def self.cache_ttl
      @@cache_ttl
    end

    def self.prepend_to_cache_key=(new_prepend_to_cache_key)
      fail ArgumentError, 'prepend_to_cache_key must be a String' if new_prepend_to_cache_key && !new_prepend_to_cache_key.is_a?(String)
      @@prepend_to_cache_key = new_prepend_to_cache_key
    end
    def self.prepend_to_cache_key
      @@prepend_to_cache_key
    end


    # Default to_i conversion is of id
    def to_i
      id.to_i
    end

    # Default to_s conversion is "TYPE number TO_I"
    def to_s
      "#{self.class} with ID: #{id.inspect}"
    end


    # Compare functions
    def <=>(other)
      result = nil
      sort_by.each do |attribute|
        a = b= nil
        if attribute[0].eql?('-')
          # Reverse order
          a = other.try(attribute[1..-1])
          b = try(attribute[1..-1])
        else
          # Forward order
          a = try(attribute)
          b = other.try(attribute)
        end
        result = a <=> b
        if result.nil?
          # Either a or b was nil
          result = -1 if a.nil?
          result = 1 if b.nil?
          result = 0 if a.nil? && b.nil?
        end
        return result unless result.eql?(0)
      end
      result
    end
    protected def sort_by
      ['id']
    end


    # Get a list of attributes which have changed
    # @return Array[String] the names of attributes which have changed
    def changed_attributes
      attributes.keys.select{ |k| attributes[k] != @original_attributes[k] }
    end

    # Reset the list of attributes which have changed
    def reset_changed_attributes
      classes_to_clone = [Array, Hash]
      attributes_now = attributes.map do |k,v|
        [k, (classes_to_clone.include?(v.class) ? v.clone : v)]
      end # Deep(ish) clone
      @original_attributes = attributes_now.to_h
    end


    # Override initialize to set @orig_attributes
    old_initialize = instance_method(:initialize)
    define_method :initialize do |*args|
      ret_val = old_initialize.bind(self).call(*args)
      reset_changed_attributes
      return ret_val
    end


    private
    # Wrap cache calls
    def self.cache_fetch(api:, key:, ttl: @@cache_ttl, no_read_cache: false)
      fail ArgumentError, 'A block is required' unless block_given?
      return yield if no_cache? || no_read_cache
      key = cache_key(api: api, key: key)
      @@cache.fetch(key, { expires_in: ttl }){ yield }
    end
    def self.cache_read(api:, key:, no_read_cache: false)
      return nil if no_cache? || no_read_cache
      key = cache_key(api: api, key: key)
      @@cache.read(key)
    end
    def self.cache_write(api:, key:, data:, ttl: @@cache_ttl)
      return false if no_cache?
      key = cache_key(api: api, key: key)
      @@cache.write(key, data, { expires_in: ttl })
    end
    def self.cache_exist?(api:, key:, no_read_cache: false)
      return false if no_cache? || no_read_cache
      key = cache_key(api: api, key: key)
      @@cache.exist?(key)
    end
    def self.cache_delete(api:, key:)
      return true if no_cache?
      key = cache_key(api: api, key: key)
      @@cache.delete(key)
    end
    def self.cache_key(api:, key:)
      key = key.join('-') if key.is_a?(Array)
      "#{!@@prepend_to_cache_key ? '' : "#{@@prepend_to_cache_key}-"}#{Osm::VERSION}-#{api.site}-#{key}"
    end


    # Check if the user has access to a section
    # @param api [Osm::Api] The api to use to make the query
    # @param section [Osm::Section, Integer, #to_i] The Section (or its ID) the $
    # @!macro options_get
    # @return true, false If the Api user has access the section
    def self.has_access_to_section?(api:, section:, **options)
      api.get_user_permissions(**options).keys.include?(section.to_i)
    end

    # Raise an exception if the user does not have access to a section
    # @param api [Osm::Api] The api to use to make the query
    # @param section [Osm::Section, Integer, #to_i] The Section (or its ID) the permission is required on
    # @!macro options_get
    # @raise [Osm::Forbidden] If the Api user can not access the section
    def self.require_access_to_section(api:, section:, **options)
      unless has_access_to_section?(api: api, section: section, **options)
        fail Osm::Forbidden, 'You do not have access to that section'
      end
    end

    # Check if the user has the relevant permission
    # @param api [Osm::Api] The api to use to make the query
    # @param to [Symbol] What action is required to be done (e.g. :read or :write)
    # @param on [Symbol] What the OSM permission is required on (e.g. :member or :programme)
    # @param section [Osm::Section, Integer, #to_i] The Section (or its ID) the permission is required on
    # @!macro options_get
    def self.has_permission?(api:, to:, on:, section:, **options)
      user_has = user_has_permission?(api: api, to: to, on: on, section: section, **options)
      api_has = api_has_permission?(api: api, to: to, on: on, section: section, **options)
      user_has && api_has
    end

    # Check if the user has the relevant permission within OSM
    # @param api [Osm::Api] The api to use to make the query
    # @param to [Symbol] What action is required to be done (e.g. :read or :write)
    # @param on [Symbol] What the OSM permission is required on (e.g. :member or :programme)
    # @param section [Osm::Section, Integer, #to_i]  The Section (or its ID) the permission is required on
    # @!macro options_get
    def self.user_has_permission?(api:, to:, on:, section:, **options)
      section_id = section.to_i
      permissions = api.get_user_permissions(**options)
      permissions = permissions[section_id] || {}
      permissions = permissions[on] || []
      unless permissions.include?(to)
        return false
      end
      true
    end

    # Check if the user has granted the relevant permission to the API
    # @param api [Osm::Api] The api to use to make the query
    # @param to [Symbol] What action is required to be done (e.g. :read or :write)
    # @param on [Symbol] What the OSM permission is required on (e.g. :member or :programme)
    # @param section [Osm::Section, Integer, #to_i]  The Section (or its ID) the permission is required on
    # @!macro options_get
    def self.api_has_permission?(api:, to:, on:, section:, **options)
      access = Osm::ApiAccess.get_ours(api: api, section: section, **options)
      return false if access.nil?
      (access.permissions[on] || []).include?(to)
    end

    # Raise an exception if the user does not have the relevant permission
    # @param api [Osm::Api] The api to use to make the query
    # @param to [Symbol] What action is required to be done (e.g. :read or :write)
    # @param on [Symbol] What the OSM permission is required on (e.g. :member or :programme)
    # @param section [Osm::Section, Integer, #to_i]  The Section (or its ID) the permission is required on
    # @!macro options_get
    # @raise [Osm::Forbidden] If the Api user does not have the required permission
    def self.require_permission(api:, to:, on:, section:, **options)
      section = Osm::Section.get(api, section.to_i, **options) unless section.is_a?(Osm::Section)
      section_name = section.try(:name)
      unless user_has_permission?(api: api, to: to, on: on, section: section, **options)
        fail Osm::Forbidden, "Your OSM user does not have permission to #{to} on #{on} for #{section_name}."
      end
      unless api_has_permission?(api: api, to: to, on: on, section: section, **options)
        fail Osm::Forbidden, "You have not granted the #{to} permissions on #{on} to the #{api.name} API for #{section_name}."
      end
    end

    # Raise an exception if the user does not have the relevant permission
    # @param api [Osm::Api] The api to use to make the query
    # @param level [Symbol, Integer] The OSM subscription level required (:bronze, :silver, :gold, :gold_plus)
    # @param section [Osm::Section, Integer, #to_i] The Section (or its ID) the subscription is required on
    # @!macro options_get
    # @raise [Osm::Forbidden] If the Section does not have the required OSM Subscription (or higher)
    def self.require_subscription(api:, level:, section:, **options)
      section = Osm::Section.get(api, section, **options) unless section.is_a?(Osm::Section)
      if section.nil? || !section.subscription_at_least?(level)
        fail Osm::Forbidden, "Insufficent OSM subscription level (#{Osm::SUBSCRIPTION_LEVEL_NAMES[level]} required for #{section.name})."
      end
    end

    # Raise an exception if the user does not have the relevant permission
    # @param api [Osm::Api] The api to use to make the query
    # @param to [Symbol] What action is required to be done (e.g. :read or :write)
    # @param on [Symbol] What the OSM permission is required on (e.g. :member or :programme)
    # @param section [Osm::Section, Integer, #to_i] The Section (or its ID) the permission is required on
    # @!macro options_get
    def self.require_ability_to(api:, to:, on:, section:, **options)
      section = Osm::Section.get(api, section, options) unless section.is_a?(Osm::Section)
      require_permission(api: api, to: to, on: on, section: section, **options)
      if section.youth_section? && [:register, :contact, :events, :flexi].include?(on)
        require_subscription(api: api, level: :silver, section: section, **options)
      end
      if section.youth_section? && [:finance].include?(on)
        require_subscription(api: api, level: :gold, section: section, **options)
      end
    end


    # Get a list of items given a list of item IDs
    # @param api [Osm::Api] The api to use to make the query
    # @param ids [Array<Integer>] The ids of the items to get
    # @param key_base [String] The base of the key for getting an item from the cache (the key [key_base, id] is generated)
    # @param method [Symbol] The method to get all items (either :get_all or :get_for_section)
    # @param arguments [Hash] The arguments to pass to get_all
    # @!macro options_get
    # @return [Array] An array of the items
    def self.get_from_ids(api:, ids:, key_base:, method:, no_read_cache: false, arguments: {})
      fail ArgumentError, 'method is invalid' unless [:get_all, :get_for_section].include?(method)
      items = Array.new
      ids.each do |id|
        if cache_exist?(api: api, key: [*key_base, id], no_read_cache: no_read_cache)
          items.push cache_read(api: api, key: [*key_base, id])
        else
          # At least this one item is not in the cache - we might as well refresh the lot
          return send(method, api: api, no_read_cache: true, **arguments)
        end
      end
      items
    end


    # Make selected class methods instance methods too
    %w{
      cache_read cache_write cache_exist? cache_delete require_access_to_section
      has_access_to_section? has_permission? user_has_permission? api_has_permission?
      require_permission require_subscription require_ability_to
    }.each do |method_name|
      define_method method_name do |*options|
        self.class.send(method_name, *options)
      end
    end

    def cache_fetch(**options)
      self.class.cache_fetch(**options){ yield }
    end


  end # Class Model

end # Module
