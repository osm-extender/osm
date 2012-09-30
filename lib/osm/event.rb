module Osm

  class Event
    include ::ActiveAttr::MassAssignmentSecurity
    include ::ActiveAttr::Model

    # @!attribute [rw] id
    #   @return [Fixnum] the id for the event
    # @!attribute [rw] section_id
    #   @return [Fixnum] the id for the section
    # @!attribute [rw] name
    #   @return [String] the name of the event
    # @!attribute [rw] start
    #   @return [DateTime] when the event starts
    # @!attribute [rw] finish
    #   @return [DateTime] when the event ends
    # @!attribute [rw] cost
    #   @return [String] the cost of the event
    # @!attribute [rw] location
    #   @return [String] where the event is
    # @!attribute [rw] notes
    #   @return [String] notes about the event
    # @!attribute [rw] archived
    #   @return [Boolean] if the event has been archived

    attribute :id, :type => Integer
    attribute :section_id, :type => Integer
    attribute :name, :type => String
    attribute :start, :type => DateTime
    attribute :finish, :type => DateTime
    attribute :cost, :type => String, :default => ''
    attribute :location, :type => String, :default => ''
    attribute :notes, :type => String, :default => ''
    attribute :archived, :type => Boolean, :default => false

    attr_accessible :id, :section_id, :name, :start, :finish, :cost, :location, :notes, :archived

    validates_numericality_of :id, :only_integer=>true, :greater_than=>0, :allow_nil => true
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
        :archived => data['archived'].eql?('1'),
      })
    end

  end # Class Event

end # Module
