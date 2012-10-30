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


    # Get access permission for an API user
    # @param [Osm::Api] The api to use to make the request
    # @param [Fixnum, nil] section_id to get permissions for, if nil a Hash of all section's permissions is returned
    # @!macro options_get
    # @return [Hash] the permissions Hash
    def self.get_user_permissions(api, section_id=nil, options={})
      key = ['permissions', api.user_id]
      permissions = (!options[:no_cache] && cache_exist?(api, key)) ? cache_read(api, key) : Osm::Section.fetch_user_permissions(api)
      permissions ||= {}
      return section_id.nil? ? (permissions || {}) : (permissions[section_id] || {})
    end

    # Get an access permission for an API user
    # @param [Osm::Api] The api to use to make the request
    # @param [Fixnum, nil] section_id to get permissions for, if nil a Hash of all section's permissions is returned
    # @param [Symbol] permission
    # @!macro options_get
    # @return [Array<Symbol>] the actions the user can perform for the provided permission
    def self.get_user_permission(api, section_id, permission, options={})
      permissions = get_user_permissions(api, section_id, options)[permission]
      return (permissions || [])
    end


    # Set access permission for an API user
    # @param [Osm::Api] The api to use to make the request
    # @param [Fixnum, nil] section_id to set permissions for, if nil the Hash of all section's permissions is set
    # @param [Hash] permissions the permissions Hash
    def self.set_user_permissions(api, section_id=nil, permissions)
      key = ['permissions', api.user_id]
      if section_id
        permissions = get_user_permissions(api).merge(section_id => permissions)
      end
      cache_write(api, key, permissions)
    end


    # Make selected class methods instance methods too
    %w{
      cache_read cache_write cache_exist? cache_delete
      get_user_permissions get_user_permission set_user_permission
    }.each do |method_name|
      define_method method_name do |*options|
        self.class.send(method_name, *options)
      end
    end


  end # Class Model

end # Module
