module Osm

  class FlexiRecordField
    include ::ActiveAttr::MassAssignmentSecurity
    include ::ActiveAttr::Model

    # @!attribute [rw] id
    #   @return [String] OSM identifier for the field. Special ones are 'dob', 'total', 'completed', 'age', 'firstname' and 'lastname', user ones are of the format 'f\_NUMBER'
    # @!attribute [rw] name
    #   @return [String] Human readable name for the field
    # @!attribute [rw] editable
    #   @return [Boolean] Wether the field can be edited

    attribute :id, :type => String
    attribute :name, :type => String
    attribute :editable, :type => Boolean, :default => false

    attr_accessible :id, :name, :editable

    validates_presence_of :id
    validates_presence_of :name


    # @!method initialize
    #   Initialize a new FlexiRecordField
    #   @param [Hash] attributes the hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)


    # Initialize a new FlexiRecordField from api data
    # @param [Hash] data the hash of data provided by the API
    def self.from_api(data)
      new({
        :id => data['field'],
        :name => data['name'],
        :editable => data['editable'],
      })
    end

  end # Class FlexiRecordField

end # Module
