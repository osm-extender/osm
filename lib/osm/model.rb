# @!macro [new] options_get
#   @param [Hash] options
#   @option options [Boolean] :no_cache (optional) if true then the data will be retreived from OSM not the cache


module Osm

  # This class is expected to be inherited from.
  # It provides the caching and permission handling for model objects.
  class Model
    include ActiveAttr::Model

    SORT_BY = [:id]


    # Configure the options used by all models
    # @param [Class, nil] :cache An instance of a cache class, must provide the methods (exist?, delete, write, read, fetch), for details see Rails.cache. Set to nil to disable caching.
    # @param [Fixnum] :ttl (optional, default = 1800 (30 minutes)) The default TTL value for the cache, note that some items are cached for twice this time and others are cached for half this time (in seconds)
    # @param [String] :prepend_to_cache_key (optional, default = 'OSMAPI') Text to prepend to the key used to store data in the cache
    # @return nil
    def self.configure(cache: nil, prepend_to_cache_key: 'OSMAPI', ttl: 600)
      fail ArgumentError, ":ttl must be a FixNum greater than 0" if ttl && !(ttl.is_a?(Fixnum) && ttl > 0)
      fail ArgumentError, ":prepend_to_cache_key must be a String" if prepend_to_cache_key && !prepend_to_cache_key.is_a?(String)
      if cache
        [:exist?, :delete, :write, :read, :fetch].each do |method|
          fail ArgumentError, ":cache must have a #{method} method" unless cache.methods.include?(method)
        end
      end

      @@cache = cache
      @@prepend_to_cache_key = prepend_to_cache_key
      @@cache_ttl = ttl
      nil
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
    def <=>(another)
      us_values = self.class::SORT_BY.map{ |i| self.try(i) }
      them_values = self.class::SORT_BY.map{ |i| another.try(i) }
      us_values <=> them_values
    end

    def <(another)
      send('<=>', another) < 0
    end
    def <=(another)
      send('<=>', another) <= 0
    end
    def >(another)
      send('<=>', another) > 0
    end
    def >=(another)
      send('<=>', another) >= 0
    end
    def between?(min, max)
      (send('<=>', min) > 0) && (send('<=>', max) < 0)
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
    def self.cache_fetch(api_configuration:, key:, options: {})
      fail ArgumentError, "A block is required" unless block_given?
      return yield if @@cache.nil?
      key = cache_key(api_configuration: api_configuration, key: key)
      options.reverse_merge!(expires_in: @@cache_ttl)
      @@cache.fetch(key, options){ yield }
    end
    def self.cache_read(api_configuration:, key:)
      return nil if @@cache.nil?
      key = cache_key(api_configuration: api_configuration, key: key)
      @@cache.read(key)
    end
    def self.cache_write(api_configuration:, key:, data:, options: {})
      return false if @@cache.nil?
      key = cache_key(api_configuration: api_configuration, key: key)
      options.reverse_merge!(expires_in: @@cache_ttl)
      @@cache.write(key, data, options)
    end
    def self.cache_exist?(api_configuration:, key:)
      return false if @@cache.nil?
      key = cache_key(api_configuration: api_configuration, key: key)
      @@cache.exist?(key)
    end
    def self.cache_delete(api_configuration:, key:)
      return true if @@cache.nil?
      key = cache_key(api_configuration: api_configuration, key: key)
      @@cache.delete(key)
    end
    def self.cache_key(api_configuration:, key:)
      key = key.join('-') if key.is_a?(Array)
      "#{!@@prepend_to_cache_key ? '' : "#{@@prepend_to_cache_key}-"}#{Osm::VERSION}-#{api_configuration.site}-#{key}"
    end


    # Check if the user has access to a section
    # @param [Osm::Api] api The api to use to make the query
    # @param [Osm::Api::Configuration] api_configuration The api configuration to use to make the request
    # @param [Osm::Section, Fixnum, #to_i] section The Section (or its ID) the $
    # @!macro options_get
    # @return [Boolean] If the Api user has access the section
    def self.has_access_to_section?(api:, api_configuration:, section:, **options)
      api.get_user_permissions(api_configuration: api_configuration, **options).keys.include?(section.to_i)
    end

    # Raise an exception if the user does not have access to a section
    # @param [Osm::Api] api The api to use to make the query
    # @param [Osm::Api::Configuration] api_configuration The api configuration to use to make the request
    # @param [Osm::Section, Fixnum, #to_i] section The Section (or its ID) the permission is required on
    # @!macro options_get
    # @raise [Osm::Forbidden] If the Api user can not access the section
    def self.require_access_to_section(api:, api_configuration:, section:, **options)
      unless has_access_to_section?(api: api, api_configuration: api_configuration, section: section, **options)
        fail Osm::Forbidden, "You do not have access to that section"
      end
    end

    # Check if the user has the relevant permission
    # @param [Osm::Api] api The api to use to make the query
    # @param [Osm::Api::Configuration] api_configuration The api configuration to use to make the request
    # @param [Symbol] to What action is required to be done (e.g. :read or :write)
    # @param [Symbol] on What the OSM permission is required on (e.g. :member or :programme)
    # @param [Osm::Section, Fixnum, #to_i] section The Section (or its ID) the permission is required on
    # @!macro options_get
    def self.has_permission?(api:, api_configuration:, to:, on:, section:, **options)
      user_has = user_has_permission?(api: api, api_configuration: api_configuration, to: to, on: on, section: section, **options)
      api_has = api_has_permission?(api_configuration: api_configuration, to: to, on: on, section: section, **options)
      user_has && api_has
    end

    # Check if the user has the relevant permission within OSM
    # @param [Osm::Api] api The api to use to make the query
    # @param [Osm::Api::Configuration] api_configuration The api configuration to use to make the request
    # @param [Symbol] to What action is required to be done (e.g. :read or :write)
    # @param [Symbol] on What the OSM permission is required on (e.g. :member or :programme)
    # @param [Osm::Section, Fixnum, #to_i] section The Section (or its ID) the permission is required on
    # @!macro options_get
    def self.user_has_permission?(api:, api_configuration:, to:, on:, section:, **options)
      section_id = section.to_i
      permissions = api.get_user_permissions(api_configuration: api_configuration, **options)
      permissions = permissions[section_id] || {}
      permissions = permissions[on] || []
      unless permissions.include?(to)
        return false
      end
      return true
    end

    # Check if the user has granted the relevant permission to the API
    # @param [Osm::Api::Configuration] api_configuration The api configuration to use to make the request
    # @param [Symbol] to What action is required to be done (e.g. :read or :write)
    # @param [Symbol] on What the OSM permission is required on (e.g. :member or :programme)
    # @param [Osm::Section, Fixnum, #to_i] section The Section (or its ID) the permission is required on
    # @!macro options_get
    def self.api_has_permission?(api_configuration:, to:, on:, section:, **options)
      access = Osm::ApiAccess.get_ours(api_configuration: api_configuration, section: section, **options)
      return false if access.nil?
      (access.permissions[on] || []).include?(to)
    end

    # Raise an exception if the user does not have the relevant permission
    # @param [Osm::Api::Configuration] api_configuration The api configuration to use to make the request
    # @param [Symbol] to What action is required to be done (e.g. :read or :write)
    # @param [Symbol] on What the OSM permission is required on (e.g. :member or :programme)
    # @param [Osm::Section, Fixnum, #to_i] section The Section (or its ID) the permission is required on
    # @!macro options_get
    # @raise [Osm::Forbidden] If the Api user does not have the required permission
    def self.require_permission(api_configuration:, to:, on:, section:, **options)
      section = Osm::Section.get(api_configuration, section.to_i, **options) unless section.is_a?(Osm::Section)
      section_name = section.try(:name)
      unless user_has_permission?(api_configuration: api_configuration, to: to, on: on, section: section, **options)
        fail Osm::Forbidden, "Your OSM user does not have permission to #{to} on #{on} for #{section_name}."
      end
      unless api_has_permission?(api_configuration: api_configuration, to: to, on: on, section: section, **options)
        fail Osm::Forbidden, "You have not granted the #{to} permissions on #{on} to the #{api_configuration.name} API for #{section_name}."
      end
    end

    # Raise an exception if the user does not have the relevant permission
    # @param [Osm::Api::Configuration] api_configuration The api configuration to use to make the request
    # @param [Symbol, Fixnum] level The OSM subscription level required (:bronze, :silver, :gold, :gold_plus)
    # @param [Osm::Section, Fixnum, #to_i] section The Section (or its ID) the subscription is required on
    # @!macro options_get
    # @raise [Osm::Forbidden] If the Section does not have the required OSM Subscription (or higher)
    def self.require_subscription(api_configuration:, level:, section:, **options)
      section = Osm::Section.get(api_configuration, section, **options) unless section.is_a?(Osm::Section)
      if section.nil? || !section.subscription_at_least?(level)
        fail Osm::Forbidden, "Insufficent OSM subscription level (#{Osm::SUBSCRIPTION_LEVEL_NAMES[level]} required for #{section.name})."
      end
    end

    # Raise an exception if the user does not have the relevant permission
    # @param [Osm::Api::Configuration] api_configuration The api configuration to use to make the request
    # @param [Symbol] to What action is required to be done (e.g. :read or :write)
    # @param [Symbol] on What the OSM permission is required on (e.g. :member or :programme)
    # @param [Osm::Section, Fixnum, #to_i] section The Section (or its ID) the permission is required on
    # @!macro options_get
    def self.require_ability_to(api_configuration:, to:, on:, section:, **options)
      section = Osm::Section.get(api, section, options) unless section.is_a?(Osm::Section)
      require_permission(api_configuration: api_configuration, to: to, on: on, section: section, **options)
      if section.youth_section? && [:register, :contact, :events, :flexi].include?(on)
        require_subscription(api_configuration: api_configuration, level: :silver, section: section, **options)
      end
      if section.youth_section? && [:finance].include?(on)
        require_subscription(api_configuration: api_configuration, level: :gold, section: section, **options)
      end
    end


    # Get a list of items given a list of item IDs
    # @param [Osm::Api::Configuration] api_configuration The api configuration to use to make the request
    # @param [Array<Fixnum>] ids The ids of the items to get
    # @param [String] key_base The base of the key for getting an item from the cache (the key [key_base, id] is generated)
    # @param [Array] arguments The arguments to pass to get_all
    # @param [Symbol] get_all_method The method to get all items (either :get_all or :get_for_section)
    # @!macro options_get
    # @return [Array] An array of the items
    def self.get_from_ids(api_configuration:, ids:, key_base:, arguments: [], get_all_method:, **options)
      fail ArgumentError, "get_all_method is invalid" unless [:get_all, :get_for_section].include?(get_all_method)
      items = Array.new
      ids.each do |id|
        if cache_exist?(api_configuration: api_configuration, key: [*key_base, id])
          items.push cache_read(api_configuration: api_configuration, key: [*key_base, id])
        else
          # At least this one item is not in the cache - we might as well refresh the lot
          return self.send(get_all_method, api_configuration, *arguments, **options.merge(:no_cache => true))
        end
      end
      return items
    end


    # Make selected class methods instance methods too
    %w{
      cache_read cache_write cache_exist? cache_delete cache_fetch require_access_to_section
      can_access_section? has_permission? user_has_permission? api_has_permission?
      require_permission require_subscription require_ability_to
    }.each do |method_name|
      define_method method_name do |*options|
        self.class.send(method_name, *options)
      end
    end


  end # Class Model

end # Module
