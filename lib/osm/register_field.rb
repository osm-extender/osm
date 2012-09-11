module Osm

  class RegisterField
    include ::ActiveAttr::MassAssignmentSecurity
    include ::ActiveAttr::Model

    # @!attribute [rw] id
    #   @return [String] OSM identifier for the field
    # @!attribute [rw] name
    #   @return [String] Human readable name for the field
    # @!attribute [rw] tooltip
    #   @return [String] Tooltip for the field

    attribute :id, :type => String
    attribute :name, :type => String
    attribute :tooltip, :type => String, :default => ''

    attr_accessible :id, :name, :tooltip

    validates_presence_of :id
    validates_presence_of :name
    validates_presence_of :tooltip, :allow_blank => true


    # @!method initialize
    #   Initialize a new RegisterField
    #   @param [Hash] attributes the hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)


    # Initialize a new RegisterField from api data
    # @param [Hash] data the hash of data provided by the API
    def self.from_api(data)
      new({
        :id => data['field'],
        :name => data['name'],
        :tooltip => data['tooltip'],
      })
    end

  end # Class RegisterField

end # Module
