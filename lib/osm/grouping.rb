module Osm

  class Grouping

    attr_reader :id, :name, :active, :points
    # @!attribute [r] id
    #   @return [Fixnum] the id for grouping
    # @!attribute [r] name
    #   @return [String] the name of the grouping
    # @!attribute [r] id
    #   @return [Boolean] wether the grouping is active
    # @!attribute [r] points
    #   @return [Fixnum] the points awarded to the grouping

    # Initialize a new Grouping using the hash returned by the API call
    # @param data the hash of data for the object returned by the API
    def initialize(data)
      @id = Osm::to_i_or_nil(data['patrolid'])
      @name = data['name']
      @active = (data['active'] == 1)
      @points = Osm::to_i_or_nil(data['points'])
    end

  end

end
