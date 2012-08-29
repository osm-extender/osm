module Osm

  class RegisterData

    attr_reader :member_id, :first_name, :last_name, :section_id, :grouping_id, :total, :attendance
    # @!attribute [r] member_id
    #   @return [Fixnum] The OSM ID for the member
    # @!attribute [r] grouping_id
    #   @return [Fixnum] The OSM ID for the member's grouping
    # @!attribute [r] section_id
    #   @return [Fixnum] The OSM ID for the member's section
    # @!attribute [r] first_name
    #   @return [String] The member's first name
    # @!attribute [r] last_name
    #   @return [String] The member's last name
    # @!attribute [r] total
    #   @return [FixNum] Tooltip for the field
    # @!attribute [r] attendance
    #   @return [Hash] The data for each field - keys are the date, values one of 'Yes' (present), 'No' (known absence) or nil (absent)

    # Initialize a new RegisterData
    # @param [Hash] attributes the hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)
    def initialize(attributes={})
      [:member_id, :grouping_id, :section_id].each do |attribute|
        raise ArgumentError, ":#{attribute} must be nil or a Fixnum > 0" unless attributes[attribute].nil? || (attributes[attribute].is_a?(Fixnum) && attributes[attribute] > 0)
      end
      raise ArgumentError, ':total must be a Fixnum >= 0' unless (attributes[:total].is_a?(Fixnum) && attributes[:total] >= 0)
      [:first_name, :last_name].each do |attribute|
        raise ArgumentError, "#{attribute} must be nil or a String" unless attributes[attribute].nil? || attributes[attribute].is_a?(String)
      end
      raise ArgumentError, ':attendance must be a Hash' unless attributes[:attendance].is_a?(Hash)

      attributes.each { |k,v| instance_variable_set("@#{k}", v) }
    end


    # Initialize a new RegisterData from api data
    # @param [Hash] data the hash of data provided by the API
    def self.from_api(data)
      attributes = {}
      attributes[:member_id] = Osm::to_i_or_nil(data['scoutid'])
      attributes[:grouping_id] = Osm::to_i_or_nil(data['patrolid'])
      attributes[:section_id] = Osm::to_i_or_nil(data['sectionid'])
      attributes[:first_name] = data['firstname']
      attributes[:last_name] = data['lastname']
      attributes[:total] = data['total'].to_i

      attributes[:attendance] = {}
      data.except('scoutid', 'patrolid', 'sectionid', 'firstname', 'lastname', 'total').keys.each do |key|
        attributes[:attendance][Date.strptime(key, '%Y-%m-%d')] = data[key]
      end

      new(attributes)
    end

  end

end
