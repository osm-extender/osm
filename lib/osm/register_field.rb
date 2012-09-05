module Osm

  class RegisterField

    attr_reader :id, :name, :tooltip
    # @!attribute [r] id
    #   @return [String] OSM identifier for the field
    # @!attribute [r] name
    #   @return [String] Human readable name for the field
    # @!attribute [r] tooltip
    #   @return [String] Tooltip for the field

    # Initialize a new RegisterField
    # @param [Hash] attributes the hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)
    def initialize(attributes={})
      [:id, :name].each do |attribute|
        raise ArgumentError, "#{attribute} must be a String" unless attributes[attribute].is_a?(String)
      end
      raise ArgumentError, ':tooltip must be a String' unless attributes[:tooltip].nil? || attributes[:tooltip].is_a?(String)

      attributes.each { |k,v| instance_variable_set("@#{k}", v) }

      @tooltip ||= ''
    end


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
