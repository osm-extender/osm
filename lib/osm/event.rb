module Osm

  class Event

    attr_reader :id, :section_id, :name, :start, :end, :cost, :location, :notes
    # @!attribute [r] id
    #   @return [Fixnum] the id for the event
    # @!attribute [r] section_id
    #   @return [Fixnum] the id for the section
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

    # Initialize a new Event
    # @param [Hash] attributes the hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)
    def initialize(attributes={})
      [:id, :section_id].each do |attribute|
        raise ArgumentError, ":#{attribute} must be nil or a Fixnum > 0" unless attributes[attribute].nil? || (attributes[attribute].is_a?(Fixnum) && attributes[attribute] > 0)
      end
      raise ArgumentError, ':name must be a String' unless attributes[:name].is_a?(String)
      raise ArgumentError, ':start must be nil or a DateTime' unless attributes[:start].nil? || attributes[:start].is_a?(DateTime)
      raise ArgumentError, ':end must be nil or a DateTime' unless attributes[:end].nil? || attributes[:end].is_a?(DateTime)
      [:cost, :location, :notes].each do |attribute|
        raise ArgumentError, ":#{attribute} must be nil or a String" unless attributes[attribute].nil? || attributes[attribute].is_a?(String)
      end

      attributes.each { |k,v| instance_variable_set("@#{k}", v) }
    end


    # Initialize a new Event from api data
    # @param [Hash] data the hash of data provided by the API
    def self.from_api(data)
      new({
        :id => Osm::to_i_or_nil(data['eventid']),
        :section_id => Osm::to_i_or_nil(data['sectionid']),
        :name => data['name'],
        :start => Osm::make_datetime(data['startdate'], data['starttime']),
        :end => Osm::make_datetime(data['enddate'], data['endtime']),
        :cost => data['cost'],
        :location => data['location'],
        :notes => data['notes'],
      })
    end

  end

end
