module Osm

  class Grouping
    include ::ActiveAttr::MassAssignmentSecurity
    include ::ActiveAttr::Model

    # @!attribute [rw] id
    #   @return [Fixnum] the id for grouping
    # @!attribute [rw] name
    #   @return [String] the name of the grouping
    # @!attribute [rw] active
    #   @return [Boolean] wether the grouping is active
    # @!attribute [rw] points
    #   @return [Fixnum] the points awarded to the grouping

    attribute :id, :type => Integer
    attribute :name, :type => String
    attribute :active, :type => Boolean
    attribute :points, :type => Integer

    attr_accessible :id, :name, :active, :points

    validates_numericality_of :id, :only_integer=>true, :greater_than_or_equal_to=>-2
    validates_presence_of :name
    validates_numericality_of :points, :only_integer=>true
    validates_presence_of :active


    # @!method initialize
    #   Initialize a new Term
    #   @param [Hash] attributes the hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)


    # Initialize a new Grouping from api data
    # @param [Hash] data the hash of data provided by the API
    def self.from_api(data)
      new({
        :id => Osm::to_i_or_nil(data['patrolid']),
        :name => data['name'],
        :active => (data['active'] == 1),
        :points => Osm::to_i_or_nil(data['points']),
      })
    end

  end # Class Grouping

end # Module
