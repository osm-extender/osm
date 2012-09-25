module Osm

  class Term
    include ::ActiveAttr::MassAssignmentSecurity
    include ::ActiveAttr::Model

    # @!attribute [rw] id
    #   @return [Fixnum] the id for the term
    # @!attribute [rw] section_id
    #   @return [Fixnum] the section the term belongs to
    # @!attribute [rw] name
    #   @return [Fixnum] the name of the term
    # @!attribute [rw] start
    #   @return [Date] when the term starts
    # @!attribute [rw] finish
    #   @return [Date] when the term finishes

    attribute :id, :type => Integer
    attribute :section_id, :type => Integer
    attribute :name, :type => String
    attribute :start, :type => Date
    attribute :finish, :type => Date

    attr_accessible :id, :section_id, :name, :start, :finish

    validates_numericality_of :id, :only_integer=>true, :greater_than=>0
    validates_numericality_of :section_id, :only_integer=>true, :greater_than=>0
    validates_presence_of :name
    validates_presence_of :start
    validates_presence_of :finish


    # @!method initialize
    #   Initialize a new Term
    #   @param [Hash] attributes the hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)


    # Initialize a new Term from api data
    # @param [Hash] data the hash of data provided by the API
    def self.from_api(data)
      new(
        :id => Osm::to_i_or_nil(data['termid']),
        :section_id => Osm::to_i_or_nil(data['sectionid']),
        :name => data['name'],
        :start => Osm::parse_date(data['startdate']),
        :finish => Osm::parse_date(data['enddate']),
      )
    end

    # Get the term's data for use with the API
    # @return [Hash]
    def to_api
      {
        'term' => name,
        'start' => start.strftime(Osm::OSM_DATE_FORMAT),
        'end' => finish.strftime(Osm::OSM_DATE_FORMAT),
        'termid' => id
      }
    end

    # Determine if the term is completly before the passed date
    # @param [Date] date
    # @return [Boolean] if the term is completly before the passed date
    def before?(date)
      return finish < date.to_date
    end

    # Determine if the term is completly after the passed date
    # @param [Date] date
    # @return [Boolean] if the term is completly after the passed date
    def after?(date)
      return start > date.to_date
    end

    # Determine if the term is in the future
    # @return [Boolean] if the term starts after today
    def future?
      return start > Date.today
    end

    # Determine if the term is in the past
    # @return [Boolean] if the term finished before today
    def past?
      return finish < Date.today
    end

    # Determine if the term is current
    # @return [Boolean] if the term started before today and finishes after today
    def current?
      return (start <= Date.today) && (finish >= Date.today)
    end

    # Determine if the provided date is within the term
    # @param [Date] date the date to test
    # @return [Boolean] if the term started before the date and finishes after the date
    def contains_date?(date)
      return (start <= date) && (finish >= date)
    end

    def <=>(another_term)
      begin
        compare = self.section_id <=> another_term.section_id
        return compare unless compare == 0
  
        compare = self.start <=> another_term.start
        return compare unless compare == 0
  
        return self.id <=> another_term.id
      rescue NoMethodError
        return false
      end
    end

    def ==(another_term)
      begin
        return self.id == another_term.id
      rescue NoMethodError
        return false
      end
    end

  end # Class Term

end # Module
