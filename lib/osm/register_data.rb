module Osm

  class RegisterData
    include ::ActiveAttr::MassAssignmentSecurity
    include ::ActiveAttr::Model

    # @!attribute [rw] member_id
    #   @return [Fixnum] The OSM ID for the member
    # @!attribute [rw] grouping_id
    #   @return [Fixnum] The OSM ID for the member's grouping
    # @!attribute [rw] section_id
    #   @return [Fixnum] The OSM ID for the member's section
    # @!attribute [rw] first_name
    #   @return [String] The member's first name
    # @!attribute [rw] last_name
    #   @return [String] The member's last name
    # @!attribute [rw] total
    #   @return [FixNum] Total
    # @!attribute [rw] attendance
    #   @return [Hash] The data for each field - keys are the date, values one of 'Yes' (present), 'No' (known absence) or nil (absent)

    attribute :member_id, :type => Integer
    attribute :grouping_id, :type => Integer
    attribute :section_id, :type => Integer
    attribute :first_name, :type => String
    attribute :last_name, :type => String
    attribute :total, :type => Integer
    attribute :attendance, :default => {}

    attr_accessible :member_id, :first_name, :last_name, :section_id, :grouping_id, :total, :attendance

    validates_numericality_of :member_id, :only_integer=>true, :greater_than=>0
    validates_numericality_of :grouping_id, :only_integer=>true, :greater_than_or_equal_to=>-2
    validates_numericality_of :section_id, :only_integer=>true, :greater_than=>0
    validates_numericality_of :total, :only_integer=>true, :greater_than_or_equal_to=>0
    validates_presence_of :first_name
    validates_presence_of :last_name

    validates_each :attendance do |record, attr, value|
      record.errors.add(attr, 'must be a Hash') unless value.is_a?(Hash)
      value.each do |k, v|
        record.errors.add(attr, 'keys must be a Date') unless k.is_a?(Date)
        record.errors.add(attr, 'values must be Strings') unless ['Yes', 'No', nil].include?(v)
      end
    end


    # @!method initialize
    #   Initialize a new registerData
    #   @param [Hash] attributes the hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)


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
        attributes[:attendance][Date.strptime(key, Osm::OSM_DATE_FORMAT)] = data[key]
      end

      new(attributes)
    end

  end # Class RegisterData

end # Module
