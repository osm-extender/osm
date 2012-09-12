module Osm

  class ApiAccess
    include ::ActiveAttr::MassAssignmentSecurity
    include ::ActiveAttr::Model

    # @!attribute [rw] id
    #   @return [Fixnum] the id for the API
    # @!attribute [rw] name
    #   @return [String] the name of the API
    # @!attribute [rw] permissions
    #   @return [Hash] the permissions assigned to this API by the user in OSM

    attribute :id, :type => Integer
    attribute :name, :type => String
    attribute :permissions, :default => {}

    attr_accessible :id, :name, :permissions

    validates_numericality_of :id, :only_integer=>true, :greater_than=>0
    validates_presence_of :name

    validates :permissions, :hash => {:key_type => Symbol, :value_in => [10, 20]}


    # @!method initialize
    #   Initialize a new Term
    #   @param [Hash] attributes the hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)


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
      return [20, 10].include?(permissions[key])
    end

    # Determine if this API has write access for the provided permission
    # @param [Symbol] key the permission being queried
    # @return [Boolean] if this API can write the passed permission
    def can_write?(key)
      return [20].include?(permissions[key])
    end

    # Determine if this API is the API being used to make requests
    # @return [Boolean] if this is the API being used
    def our_api?
      return id == Osm::Api.api_id.to_i
    end

  end # Class ApiAccess

end # Module
