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

    # Initialize a new RegisterField using the hash returned by the API call
    # @param data the hash of data for the object returned by the API
    def initialize(data)
      @member_id = Osm::to_i_or_nil(data['scoutid'])
      @grouping_id = Osm::to_i_or_nil(data['patrolid'])
      @section_id = Osm::to_i_or_nil(data['sectionid'])
      @first_name = data['firstname']
      @last_name = data['lastname']
      @total = data['total'].to_i

      @attendance = {}
      data.except('scoutid', 'patrolid', 'sectionid', 'firstname', 'lastname', 'total').keys.each do |key|
        @attendance[Date.strptime(key, '%Y-%m-%d')] = data[key]
      end
    end

  end

end
