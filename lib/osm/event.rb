module Osm

  class Event
    include ::ActiveAttr::MassAssignmentSecurity
    include ::ActiveAttr::Model

    # @!attribute [r] id
    #   @return [Fixnum] the id for the event
    # @!attribute [r] section_id
    #   @return [Fixnum] the id for the section
    # @!attribute [r] name
    #   @return [String] the name of the event
    # @!attribute [r] start
    #   @return [DateTime] when the event starts
    # @!attribute [r] finish
    #   @return [DateTime] when the event ends
    # @!attribute [r] cost
    #   @return [String] the cost of the event
    # @!attribute [r] location
    #   @return [String] where the event is
    # @!attribute [r] notes
    #   @return [String] notes about the event

    attribute :id, :type => Integer
    attribute :section_id, :type => Integer
    attribute :name, :type => String
    attribute :start, :type => DateTime
    attribute :finish, :type => DateTime
    attribute :cost, :type => String, :default => ''
    attribute :location, :type => String, :default => ''
    attribute :notes, :type => String, :default => ''

    attr_accessible :id, :section_id, :name, :start, :finish, :cost, :location, :notes

    validates_numericality_of :id, :only_integer=>true, :greater_than=>0
    validates_numericality_of :section_id, :only_integer=>true, :greater_than=>0
    validates_presence_of :name


    # @!method initialize
    #   Initialize a new Term
    #   @param [Hash] attributes the hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)

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

  end # Class Event

end # Module
