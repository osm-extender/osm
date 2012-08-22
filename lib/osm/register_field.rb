module Osm

  class RegisterField

    attr_reader :id, :name, :tooltip
    # @!attribute [r] id
    #   @return [String] OSM identifier for the field
    # @!attribute [r] name
    #   @return [String] Human readable name for the field
    # @!attribute [r] tooltip
    #   @return [String] Tooltip for the field

    # Initialize a new RegisterField using the hash returned by the API call
    # @param data the hash of data for the object returned by the API
    def initialize(data)
      @id = data['field']
      @name = data['name']
      @tooltip = data['tooltip']
    end

  end

end
