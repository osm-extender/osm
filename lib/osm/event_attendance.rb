module Osm

  class EventAttendance
    include ::ActiveAttr::MassAssignmentSecurity
    include ::ActiveAttr::Model

    # @!attribute [rw] member_id
    #   @return [Fixnum] OSM id for the member
    # @!attribute [rw] grouping__id
    #   @return [Fixnum] OSM id for the grouping the member is in
    # @!attribute [rw] fields
    #   @return [Hash] Keys are the field's id, values are the field values

    attribute :member_id, :type => Integer
    attribute :grouping_id, :type => Integer
    attribute :fields, :default => {}

    attr_accessible :member_id, :grouping_id, :fields

    validates_numericality_of :member_id, :only_integer=>true, :greater_than=>0
    validates_numericality_of :grouping_id, :only_integer=>true, :greater_than_or_equal_to=>-2
    validates :fields, :hash => {:key_type => String}


    # @!method initialize
    #   Initialize a new FlexiRecordData
    #   @param [Hash] attributes the hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)


    # Initialize a new FlexiRecordData from api data
    # @param [Hash] data the hash of data provided by the API
    def self.from_api(data)
      data.merge!({
        'dob' => data['dob'].nil? ? nil : Osm::parse_date(data['dob'], :ignore_epoch => true),
        'attending' => data['attending'].eql?('Yes'),
      })

      new({
        :member_id => Osm::to_i_or_nil(data['scoutid']),
        :grouping_id => Osm::to_i_or_nil(data['patrolid'].eql?('') ? nil : data['patrolid']),
        :fields => data.select { |key, value|
          ['firstname', 'lastname', 'dob', 'attending'].include?(key) || key.to_s.match(/^f_\d+/)
        }
      })
    end

  end # Class EventAttendance

end # Module
