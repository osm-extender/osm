# @!macro [new] options_get
#   @param [Hash] options
#   @option options [Boolean] :no_cache (optional) if true then the data will be retreived from OSM not the cache


module Osm

  # This class is expected to be inherited from.
  # It provides the caching and permission handling for model objects.
  class Model
    include ::ActiveAttr::MassAssignmentSecurity
    include ::ActiveAttr::Model

    @@cache = nil               # Class to use for caching
    @@cache_prepend = 'OSMAPI'  # Prepended to the key
    @@cache_ttl = 600           # 10 minutes


    # Configure the options used by all models
    # @param [Hash] options
    # @option options [Class, nil] :cache An instance of a cache class, must provide the methods (exist?, delete, write, read), for details see Rails.cache. Set to nil to disable caching.
    # @option options [Fixnum] :ttl (optional, default = 1800 (30 minutes)) The default TTL value for the cache, note that some items are cached for twice this time and others are cached for half this time (in seconds)
    # @option options [String] :prepend_to_key (optional, default = 'OSMAPI') Text to prepend to the key used to store data in the cache
    # @return nil
    def self.configure(options)
      raise ArgumentError, ":ttl must be a FixNum greater than 0" if options[:ttl] && !(options[:ttl].is_a?(Fixnum) && options[:ttl] > 0)
      raise ArgumentError, ":prepend_to_key must be a String" if options[:prepend_to_key] && !options[:prepend_to_key].is_a?(String)
      if options[:cache]
        [:exist?, :delete, :write, :read].each do |method|
          raise ArgumentError, ":cache must have a #{method} method" unless options[:cache].methods.include?(method)
        end
      end

      @@cache = options[:cache]
      @@cache_prepend = options[:prepend_to_key] || 'OSMAPI'
      @@cache_ttl = options[:ttl] || 600
      nil
    end


    def to_i
      id
    end

    private
    # Wrap cache calls
    def self.cache_read(api, key)
      return nil if @@cache.nil?
      @@cache.read(cache_key(api, key))
    end
    def self.cache_write(api, key, data, options={})
      return false if @@cache.nil?
      options.merge!(:expires_in => @@cache_ttl)
      @@cache.write(cache_key(api, key), data, options)
    end
    def self.cache_exist?(api, key)
      return false if @@cache.nil?
      @@cache.exist?(cache_key(api, key))
    end
    def self.cache_delete(api, key)
      return true if @@cache.nil?
      @@cache.delete(cache_key(api, key))
    end
    def self.cache_key(api, key)
      key = key.join('-') if key.is_a?(Array)
      "#{@@cache_prepend.empty? ? '' : "#{@@cache_prepend}-"}#{api.site}-#{key}"
    end

    # Raise an exception if the user does not have access to a section
    # @param [Osm::Api] The api to use to make the request
    # @param [Osm::Section, Fixnum] section the Section (or its ID) the permission is required on
    # @!macro options_get
    def self.require_access_to_section(api, section, options={})
      unless api.get_user_permissions(options).keys.include?(section.to_i)
        raise Forbidden, "You do not have access to that section"
      end
    end

    # Check if the user dhas access to a section
    # @param [Osm::Api] The api to use to make the request
    # @param [Osm::Section, Fixnum] section the Section (or its ID) the permission is required on
    # @!macro options_get
    def self.can_access_section?(api, section, options={})
      api.get_user_permissions(options).keys.include?(section.to_i)
    end

    # Raise an exception if the user does not have the relevant permission
    # @param [Osm::Api] The api to use to make the request
    # @param [Symbol] to what action is required to be done (e.g. :read or :write)
    # @param [Symbol] on what the OSM permission is required on (e.g. :member or :programme)
    # @param [Osm::Section, Fixnum] section the Section (or its ID) the permission is required on
    # @!macro options_get
    def self.require_permission(api, to, on, section, options={})
      section_id = section.to_i

      # Check user's permissions in OSM
      permissions = api.get_user_permissions(options)
      permissions = permissions[section_id] || {}
      permissions = permissions[on] || []
      unless permissions.include?(to)
        raise Forbidden, "Your OSM user does not have permission to #{to} on #{on} for #{Osm::Section.get(api, section_id, options).try(:name)}"
      end

      # Check what the user gave our API
      permissions = Osm::ApiAccess.get_ours(api, section_id, options).permissions
      unless permissions[on].include?(to)
        raise Forbidden, "You have not granted the #{to} permissions on #{on} to the #{api.name} API for #{Osm::Section.get(api, section_id, options).try(:name)}"
      end
    end

    # Raise an exception if the user does not have the relevant permission
    # @param [Osm::Api] The api to use to make the request
    # @param [Symbol] level the OSM subscription level required (e.g. :gold)
    # @param [Osm::Section, Fixnum] section the Section (or its ID) the subscription is required on
    # @!macro options_get
    def self.require_subscription(api, level, section, options={})
      section = Osm::Section.get(api, section, options) if section.is_a?(Fixnum)
      level = ([:bronze, :silver, :gold].find(level) || -1) + 1 if level.is_a?(Symbol)
      if section.nil? || section.subscription_level < level
        raise Forbidden, "Insufficent OSM subscription level (#{level} required for #{section.name})"
      end
    end

    # Raise an exception if the user does not have the relevant permission
    # @param [Osm::Api] The api to use to make the request
    # @param [Symbol] to what action is required to be done (e.g. :read or :write)
    # @param [Symbol] on what the OSM permission is required on (e.g. :member or :programme)
    # @param [Osm::Section, Fixnum] section the Section (or its ID) the permission is required on
    # @!macro options_get
    def self.require_ability_to(api, to, on, section, options={})
      require_permission(api, to, on, section, options)
      require_subscription(api, :silver, section, options) if [:register, :contact, :events, :flexi].include?(on)
      require_subscription(api, :gold, section, options) if [:finance].include?(on)
    end


    # Make selected class methods instance methods too
    %w{
      cache_read cache_write cache_exist? cache_delete require_access_to_section
      can_access_section? require_permission require_subscription require_ability_to
    }.each do |method_name|
      define_method method_name do |*options|
        self.class.send(method_name, *options)
      end
    end


  end # Class Model

end # Module
