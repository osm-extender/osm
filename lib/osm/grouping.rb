module Osm

  class Grouping

    attr_reader :id, :name, :active, :points
    # @!attribute [r] id
    #   @return [Fixnum] the id for grouping
    # @!attribute [r] name
    #   @return [String] the name of the grouping
    # @!attribute [r] active
    #   @return [Boolean] wether the grouping is active
    # @!attribute [r] points
    #   @return [Fixnum] the points awarded to the grouping

    # Initialize a new Grouping
    # @param [Hash] attributes the hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)
    def initialize(attributes={})
      raise ArgumentError, ':id must be a Fixnum >= -2' unless (attributes[:id].is_a?(Fixnum) && attributes[:id] >= -2)
      raise ArgumentError, ':name must be a String' unless attributes[:name].is_a?(String)
      raise ArgumentError, ':active must be nil or a Boolean' unless attributes[:active].nil? || [true, false].include?(attributes[:active])
      raise ArgumentError, ':points must be nil or a Fixnum >= 0' unless attributes[:points].nil? || (attributes[:points].is_a?(Fixnum) && attributes[:points] >= 0)

      attributes.each { |k,v| instance_variable_set("@#{k}", v) }
    end


    # Initialize a new Grouping from api data
    # @param [Hash] data the hash of data provided by the API
    def self.from_api(data)
      new({
        :id => Osm::to_i_or_nil(data['patrolid']),
        :name => data['name'],
        :active => (data['active'] == 1),
        :points => Osm::to_i_or_nil(data['points']),
      })
    end

  end # Class Grouping

end # Module
