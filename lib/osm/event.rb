module Osm

  class Event

    attr_reader :id, :section_id, :name, :start, :end, :cost, :location, :notes
    # @!attribute [r] id
    #   @return [FixNum] the id for the event
    # @!attribute [r] section_id
    #   @return [FixNum] the id for the section
    # @!attribute [r] name
    #   @return [String] the name of the event
    # @!attribute [r] start
    #   @return [DateTime] when the event starts
    # @!attribute [r] end
    #   @return [DateTime] when the event ends
    # @!attribute [r] cost
    #   @return [String] the cost of the event
    # @!attribute [r] location
    #   @return [String] where the event is
    # @!attribute [r] notes
    #   @return [String] notes about the event

    # Initialize a new Event using the hash returned by the API call
    # @param data the hash of data for the object returned by the API
    def initialize(data)
      @id = Osm::to_i_or_nil(data['eventid'])
      @section_id = Osm::to_i_or_nil(data['sectionid'])
      @name = data['name']
      @start = Osm::make_datetime(data['startdate'], data['starttime'])
      @end = Osm::make_datetime(data['enddate'], data['endtime'])
      @cost = data['cost']
      @location = data['location']
      @notes = data['notes']
    end

  end

end
