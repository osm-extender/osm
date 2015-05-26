# @!macro [new] options_get
#   @param [Hash] options
#   @option options [Boolean] :no_cache (optional) if true then the data will be retreived from OSM not the cache


module Osm

  # This class is expected to be inherited from.
  # It provides the caching and permission handling for model objects.
  class Model
    include ActiveModel::MassAssignmentSecurity if ActiveModel::VERSION::MAJOR < 4
    include ActiveAttr::Model

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


    # Default to_i conversion is of id
    def to_i
      id.to_i
    end

    # Default compare based on id
    def <=>(another)
      return self.id <=> another.try(:id)
    end

    # Add other compare functions
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
      @original_attributes = Hash[attributes_now]
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
    def self.cache_read(api, key)
      return nil if @@cache.nil?
      @@cache.read(cache_key(api, key))
    end
    def self.cache_write(api, key, data, options={})
      return false if @@cache.nil?
      options.reverse_merge!(expires_in: @@cache_ttl)
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
      "#{@@cache_prepend.empty? ? '' : "#{@@cache_prepend}-"}#{Osm::VERSION}-#{api.site}-#{key}"
    end


    # Check if the user has access to a section
    # @param [Osm::Api] api The api to use to make the request
    # @param [Osm::Section, Fixnum, #to_i] section The Section (or its ID) the $
    # @!macro options_get
    # @return [Boolean] If the Api user has access the section
    def self.has_access_to_section?(api, section, options={})
      api.get_user_permissions(options).keys.include?(section.to_i)
    end

    # Raise an exception if the user does not have access to a section
    # @param [Osm::Api] api The api to use to make the request
    # @param [Osm::Section, Fixnum, #to_i] section The Section (or its ID) the permission is required on
    # @!macro options_get
    # @raise [Osm::Forbidden] If the Api user can not access the section
    def self.require_access_to_section(api, section, options={})
      unless has_access_to_section?(api, section, options)
        raise Osm::Forbidden, "You do not have access to that section"
      end
    end

    # Check if the user has access to a section
    # @param [Osm::Api] api The api to use to make the request
    # @param [Osm::Section, Fixnum, #to_i] section The Section (or its ID) the permission is required on
    # @!macro options_get
    def self.can_access_section?(api, section, options={})
      api.get_user_permissions(options).keys.include?(section.to_i)
    end

    # Check if the user has the relevant permission
    # @param [Osm::Api] api The api to use to make the request
    # @param [Symbol] to What action is required to be done (e.g. :read or :write)
    # @param [Symbol] on What the OSM permission is required on (e.g. :member or :programme)
    # @param [Osm::Section, Fixnum, #to_i] section The Section (or its ID) the permission is required on
    # @!macro options_get
    def self.has_permission?(api, to, on, section, options={})
      user_has_permission?(api, to, on, section, options) && api_has_permission?(api, to, on, section, options)
    end

    # Check if the user has the relevant permission within OSM
    # @param [Osm::Api] api The api to use to make the request
    # @param [Symbol] to What action is required to be done (e.g. :read or :write)
    # @param [Symbol] on What the OSM permission is required on (e.g. :member or :programme)
    # @param [Osm::Section, Fixnum, #to_i] section The Section (or its ID) the permission is required on
    # @!macro options_get
    def self.user_has_permission?(api, to, on, section, options={})
      section_id = section.to_i
      permissions = api.get_user_permissions(options)
      permissions = permissions[section_id] || {}
      permissions = permissions[on] || []
      unless permissions.include?(to)
        return false
      end
      return true
    end

    # Check if the user has granted the relevant permission to the API
    # @param [Osm::Api] api The api to use to make the request
    # @param [Symbol] to What action is required to be done (e.g. :read or :write)
    # @param [Symbol] on What the OSM permission is required on (e.g. :member or :programme)
    # @param [Osm::Section, Fixnum, #to_i] section The Section (or its ID) the permission is required on
    # @!macro options_get
    def self.api_has_permission?(api, to, on, section, options={})
      access = Osm::ApiAccess.get_ours(api, section, options)
      return false if access.nil?
      (access.permissions[on] || []).include?(to)
    end

    # Raise an exception if the user does not have the relevant permission
    # @param [Osm::Api] api The api to use to make the request
    # @param [Symbol] to What action is required to be done (e.g. :read or :write)
    # @param [Symbol] on What the OSM permission is required on (e.g. :member or :programme)
    # @param [Osm::Section, Fixnum, #to_i] section The Section (or its ID) the permission is required on
    # @!macro options_get
    # @raise [Osm::Forbidden] If the Api user does not have the required permission
    def self.require_permission(api, to, on, section, options={})
      section = Osm::Section.get(api, section.to_i, options) unless section.is_a?(Osm::Section)
      section_name = section.try(:name)
      unless user_has_permission?(api, to, on, section, options)
        raise Osm::Forbidden, "Your OSM user does not have permission to #{to} on #{on} for #{section_name}."
      end
      unless api_has_permission?(api, to, on, section, options)
        raise Osm::Forbidden, "You have not granted the #{to} permissions on #{on} to the #{api.api_name} API for #{section_name}."
      end
    end

    # Raise an exception if the user does not have the relevant permission
    # @param [Osm::Api] api The api to use to make the request
    # @param [Symbol, Fixnum] level The OSM subscription level required (:bronze, :silver, :gold, :gold_plus)
    # @param [Osm::Section, Fixnum, #to_i] section The Section (or its ID) the subscription is required on
    # @!macro options_get
    # @raise [Osm::Forbidden] If the Section does not have the required OSM Subscription (or higher)
    def self.require_subscription(api, level, section, options={})
      section = Osm::Section.get(api, section, options) unless section.is_a?(Osm::Section)
      if section.nil? || !section.subscription_at_least?(level)
        raise Osm::Forbidden, "Insufficent OSM subscription level (#{Osm::SUBSCRIPTION_LEVEL_NAMES[level]} required for #{section.name})."
      end
    end

    # Raise an exception if the user does not have the relevant permission
    # @param [Osm::Api] api The api to use to make the request
    # @param [Symbol] to What action is required to be done (e.g. :read or :write)
    # @param [Symbol] on What the OSM permission is required on (e.g. :member or :programme)
    # @param [Osm::Section, Fixnum, #to_i] section The Section (or its ID) the permission is required on
    # @!macro options_get
    def self.require_ability_to(api, to, on, section, options={})
      section = Osm::Section.get(api, section, options) unless section.is_a?(Osm::Section)
      require_permission(api, to, on, section, options)
      if section.youth_section? && [:register, :contact, :events, :flexi].include?(on)
        require_subscription(api, :silver, section, options)
      end
      if section.youth_section? && [:finance].include?(on)
        require_subscription(api, :gold, section, options)
      end
    end


    # Get a list of items given a list of item IDs
    # @param [Osm::Api] api The api to use to make the request
    # @param [Array<Fixnum>] ids The ids of the items to get
    # @param [String] key The key for getting an item from the cache (the key [key, id] is generated)
    # @param [Array] argumentss The arguments to pass to get_all
    # @!macro options_get
    # @param [Symbol] get_all_method The method to get all items (either :get_all or :get_for_section)
    # @return [Array] An array of the items
    def self.get_from_ids(api, ids, key, arguments=[], options, get_all_method)
      raise ArgumentError, "get_all_method is invalid" unless [:get_all, :get_for_section].include?(get_all_method)
      items = Array.new
      ids.each do |id|
        if cache_exist?(api, [key, id])
          items.push cache_read(api, [*key, id])
        else
          # At least this one item is not in the cache - we might as well refresh the lot
          return self.send(get_all_method, api, *arguments, options.merge(:no_cache => true))
        end
      end
      return items
    end


    # Make selected class methods instance methods too
    %w{
      cache_read cache_write cache_exist? cache_delete require_access_to_section
      can_access_section? has_permission? user_has_permission? api_has_permission?
      require_permission require_subscription require_ability_to
    }.each do |method_name|
      define_method method_name do |*options|
        self.class.send(method_name, *options)
      end
    end


  end # Class Model

end # Module
