module Osm

  class Term

    attr_reader :id, :section_id, :name, :start, :end
    # @!attribute [r] id
    #   @return [Fixnum] the id for the term
    # @!attribute [r] section_id
    #   @return [Fixnum] the section the term belongs to
    # @!attribute [r] name
    #   @return [Fixnum] the name of the term
    # @!attribute [r] start
    #   @return [Date] when the term starts
    # @!attribute [r] end
    #   @return [Date] when the term ends

    # Initialize a new Term
    # @param [Hash] attributes the hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)
    def initialize(attributes={})
      raise ArgumentError, ':id must be nil or a Fixnum > 0' unless attributes[:id].nil? || (attributes[:id].is_a?(Fixnum) && attributes[:id] > 0)
      raise ArgumentError, ':section_id must be nil or a Fixnum > 0' unless attributes[:section_id].nil? || (attributes[:section_id].is_a?(Fixnum) && attributes[:section_id] > 0)
      raise ArgumentError, ':name must be nil or a String' unless attributes[:name].nil? || attributes[:name].is_a?(String)
      raise ArgumentError, ':start must be nil or a Date' unless attributes[:start].nil? || attributes[:start].is_a?(Date)
      raise ArgumentError, ':end must be nil or a Date' unless attributes[:end].nil? || attributes[:end].is_a?(Date)

      attributes.each { |k,v| instance_variable_set("@#{k}", v) }
    end


    # Initialize a new Term from api data
    # @param [Hash] data the hash of data provided by the API
    def self.from_api(data)
      new(
        :id => Osm::to_i_or_nil(data['termid']),
        :section_id => Osm::to_i_or_nil(data['sectionid']),
        :name => data['name'],
        :start => Osm::parse_date(data['startdate']),
        :end => Osm::parse_date(data['enddate']),
      )
    end

    # Determine if the term is completly before the passed date
    # @param [Date] date
    # @return [Boolean] if the term is completly before the passed date
    def before?(date)
      return @end < date.to_date
    end

    # Determine if the term is completly after the passed date
    # @param [Date] date
    # @return [Boolean] if the term is completly after the passed date
    def after?(date)
      return @start > date.to_date
    end

    # Determine if the term is in the future
    # @return [Boolean] if the term starts after today
    def future?
      return @start > Date.today
    end

    # Determine if the term is in the past
    # @return [Boolean] if the term finished before today
    def past?
      return @end < Date.today
    end

    # Determine if the term is current
    # @return [Boolean] if the term started before today and finishes after today
    def current?
      return (@start <= Date.today) && (@end >= Date.today)
    end

    # Determine if the provided date is within the term
    # @param [Date] date the date to test
    # @return [Boolean] if the term started before the date and finishes after the date
    def contains_date?(date)
      return (@start <= date) && (@end >= date)
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

  end

end
