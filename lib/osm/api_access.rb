module Osm

  class ApiAccess

    attr_reader :id, :name, :permissions
    # @!attribute [r] id
    #   @return [Fixnum] the id for the API
    # @!attribute [r] name
    #   @return [String] the name of the API
    # @!attribute [r] permissions
    #   @return [Hash] the permissions assigned to this API by the user in OSM

    # Initialize a new ApiAccess
    # @param [Hash] attributes the hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)
    def initialize(attributes={})
      raise ArgumentError, ':id must be a Fixnum > 0' unless (attributes[:id].is_a?(Fixnum) && attributes[:id] > 0)
      raise ArgumentError, ':name must be a String' unless attributes[:name].is_a?(String)
      raise ArgumentError, ':permissions must be a Hash' unless attributes[:permissions].is_a?(Hash)

      attributes.each { |k,v| instance_variable_set("@#{k}", v) }
    end


    # Initialize a new ApiAccess from api data
    # @param [Hash] data the hash of data provided by the API
    def self.from_api(data)
      attributes = {}
      attributes[:id] = data['apiid'].to_i
      attributes[:name] = data['name']
      attributes[:permissions] = data['permissions'].is_a?(Hash) ? data['permissions'] : {}

      # Rubyfy permissions hash
      attributes[:permissions].keys.each do |key|
        attributes[:permissions][key] = attributes[:permissions][key].to_i
        attributes[:permissions][(key.to_sym rescue key) || key] = attributes[:permissions].delete(key) # Symbolize key
      end
      attributes[:permissions].freeze

      return new(attributes)
    end

    # Determine if this API has read access for the provided permission
    # @param [Symbol] key the permission being queried
    # @return [Boolean] if this API can read the passed permission
    def can_read?(key)
      return [20, 10].include?(@permissions[key])
    end

    # Determine if this API has write access for the provided permission
    # @param [Symbol] key the permission being queried
    # @return [Boolean] if this API can write the passed permission
    def can_write?(key)
      return [20].include?(@permissions[key])
    end

    # Determine if this API is the API being used to make requests
    # @return [Boolean] if this is the API being used
    def our_api?
      return @id == Osm::Api.api_id.to_i
    end

  end # Class ApiAccess

end # Module
