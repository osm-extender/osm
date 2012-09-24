module Osm

  class FlexiRecordData
    include ::ActiveAttr::MassAssignmentSecurity
    include ::ActiveAttr::Model

    # @!attribute [rw] member_id
    #   @return [Fixnum] OSM id for the member
    # @!attribute [rw] first_name
    #   @return [String] Member's first name
    # @!attribute [rw] last_name
    #   @return [String] Member's last name
    # @!attribute [rw] grouping__id
    #   @return [Fixnum] OSM id for the grouping the member is in
    # @!attribute [rw] fields
    #   @return [Hash] Keys are the field'd id, values are the field values
    # @!attribute [rw] total
    #   @return [Fixnum, nil] The total of the field values, nil if the flexi record does not have this column type
    # @!attribute [rw] completed
    #   @return [Fixnum, nil] The count of completed fields, nil if the flexi record does not have this column type
    # @!attribute [rw] date_of_birth
    #   @return [Date, nil] The member's date of birth, nil if the flexi record does not have this column type
    # @!attribute [rw] age
    #   @return [String, nil] The member's age (yy/mm), nil if the flexi record does not have this column type

    attribute :member_id, :type => Integer
    attribute :first_name, :type => String
    attribute :last_name, :type => String
    attribute :grouping_id, :type => Integer
    attribute :date_of_birth, :type => Date
    attribute :total, :type => Integer
    attribute :completed, :type => Integer
    attribute :age, :type => String
    attribute :fields, :default => {}

    attr_accessible :member_id, :first_name, :last_name, :date_of_birth, :grouping_id, :total, :completed, :age, :fields

    validates_presence_of :first_name
    validates_presence_of :last_name
    validates_numericality_of :grouping_id, :only_integer=>true, :greater_than_or_equal_to=>-2
    validates_format_of :age, :with => /\A[0-9]{2}\/(0[0-9]|1[012])\Z/, :message => 'age is not in the correct format (yy/mm)', :allow_nil => true
    validates :fields, :hash => {:key_type => String, :value_type => String}


    # @!method initialize
    #   Initialize a new FlexiRecordData
    #   @param [Hash] attributes the hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)


    # Initialize a new FlexiRecordData from api data
    # @param [Hash] data the hash of data provided by the API
    def self.from_api(data)
      new({
        :member_id => Osm::to_i_or_nil(data['scoutid']),
        :first_name => data['firstname'],
        :last_name => data['lastname'],
        :grouping_id => Osm::to_i_or_nil(data['patrolid'].eql?('') ? nil : data['patrolid']),
        :date_of_birth => data['dob'].nil? ? nil : Osm::parse_date(data['dob'], :ignore_epoch => true),
        :total => Osm::to_i_or_nil(data['total'].eql?('') ? nil : data['total']),
        :completed => Osm::to_i_or_nil(data['completed'].eql?('') ? nil : data['completed']),
        :age => data['age'].eql?('') ? nil : data['age'],
        :fields => data.select { |key, value| key.to_s.match(/^f_\d+/) }
      })
    end

  end # Class FlexiRecordData

end # Module
