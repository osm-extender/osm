module Osm

  class Member

    attr_reader :id, :section_id, :type, :first_name, :last_name, :email1, :email2, :email3, :email4, :phone1, :phone2, :phone3, :phone4, :address, :address2, :date_of_birth, :started, :joining_in_years, :parents, :notes, :medical, :religion, :school, :ethnicity, :subs, :grouping_id, :grouping_leader, :joined, :age, :joined_years
    # @!attribute [r] id
    #   @return [Fixnum] the id for the member
    # @!attribute [r] section_id
    #   @return [Fixnum] the section the member belongs to
    # @!attribute [r] type
    #   @return [?] ?
    # @!attribute [r] first_name
    #   @return [String] the member's first name
    # @!attribute [r] last_name
    #   @return [String] the member's last name
    # @!attribute [r] email1
    #   @return [String] the 1st email address for the member
    # @!attribute [r] email2
    #   @return [String] the 2nd email address for the member
    # @!attribute [r] email3
    #   @return [String] the 3rd email address for the member
    # @!attribute [r] email4
    #   @return [String] the 4th email address for the member
    # @!attribute [r] phone1
    #   @return [String] the 1st phone number for the member
    # @!attribute [r] phone2
    #   @return [String] the 2nd phone number for the member
    # @!attribute [r] phone3
    #   @return [String] the 3rd phone number for the member
    # @!attribute [r] phone4
    #   @return [String] the 4th phone number for the member
    # @!attribute [r] address
    #   @return [String] the member's address
    # @!attribute [r] address2
    #   @return [String] the member's 2nd address
    # @!attribute [r] date_of_birth
    #   @return [Date] the member's date of birth
    # @!attribute [r] started
    #   @return [Date] when the member started Scouting
    # @!attribute [r] joining_in_years
    #   @return [Fixnum] ?
    # @!attribute [r] parents
    #   @return [String] the member's parent's names
    # @!attribute [r] notes
    #   @return [String] notes relating to the member
    # @!attribute [r] medical
    #   @return [String] the member's key medical details
    # @!attribute [r] religion
    #   @return [String] the member's religion
    # @!attribute [r] school
    #   @return [String] the school the member attends
    # @!attribute [r] ethnicity
    #   @return [String] the member's ethnicity
    # @!attribute [r] subs
    #   @return [String] details about the member's subs
    # @!attribute [r] grouping_id
    #   @return [Fixnum] the grouping within the section that the member belongs to
    # @!attribute [r] grouping_leader
    #   @return [Fixnum] wether the member is the grouping leader (0=no, 1=seconder/APL, 2=sixer/PL)
    # @!attribute [r] joined
    #   @return [Date] when the member joined the section
    # @!attribute [r] age
    #   @return [String] the member's current age (yy/mm)
    # @!attribute [r] joining_years
    #   @return [Fixnum] how many years the member has been in Scouting


    # Initialize a new Member
    # @param [Hash] attributes the hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)
    def initialize(attributes={})
      [:id, :section_id, :grouping_leader].each do |attribute|
        raise ArgumentError, ":#{attribute} must be nil or a Fixnum >= 0" unless attributes[attribute].nil? || (attributes[attribute].is_a?(Fixnum) && attributes[attribute] >= 0)
      end
      raise ArgumentError, ':grouping_id must be nil or a Fixnum >= -2' unless attributes[:grouping_id].nil? || (attributes[:grouping_id].is_a?(Fixnum) && attributes[:grouping_id] >= -2)
      raise ArgumentError, ':joined_years must be nil or a Fixnum >= -1' unless attributes[:joined_years].nil? || (attributes[:joined_years].is_a?(Fixnum) && attributes[:joined_years] >= -1)
      raise ArgumentError, ':joining_in_years must be nil or a Fixnum' unless attributes[:joining_in_years].nil? || attributes[:joining_in_years].is_a?(Fixnum)
      [:type, :first_name, :last_name, :email1, :email2, :email3, :email4, :phone1, :phone2, :phone3, :phone4, :address, :address2, :parents, :notes, :medical, :religion, :school, :ethnicity, :subs, :age].each do |attribute|
        raise ArgumentError, ":#{attribute} must be nil or a String" unless attributes[attribute].nil? || attributes[attribute].is_a?(String)
      end
      [:date_of_birth, :started, :joined].each do |attribute|
        raise ArgumentError, ":#{attribute} must be nil or a Date" unless attributes[attribute].nil? || attributes[attribute].is_a?(Date)
      end

      attributes.each { |k,v| instance_variable_set("@#{k}", v) }
    end


    # Initialize a new Member from api data
    # @param [Hash] data the hash of data provided by the API
    def self.from_api(data)
      new({
        :id => Osm::to_i_or_nil(data['scoutid']),
        :section_id => Osm::to_i_or_nil(data['sectionidO']),
        :type => data['type'],
        :first_name => data['firstname'],
        :last_name => data['lastname'],
        :email1 => data['email1'],
        :email2 => data['email2'],
        :email3 => data['email3'],
        :email4 => data['email4'],
        :phone1 => data['phone1'],
        :phone2 => data['phone2'],
        :phone3 => data['phone3'],
        :phone4 => data['phone4'],
        :address => data['address'],
        :address2 => data['address2'],
        :date_of_birth => Osm::parse_date(data['dob'], :ignore_epoch => true),
        :started => Osm::parse_date(data['started']),
        :joining_in_years => data['joining_in_yrs'].to_i,
        :parents => data['parents'],
        :notes => data['notes'],
        :medical => data['medical'],
        :religion => data['religion'],
        :school => data['school'],
        :ethnicity => data['ethnicity'],
        :subs => data['subs'],
        :grouping_id => Osm::to_i_or_nil(data['patrolidO']),
        :grouping_leader => Osm::to_i_or_nil(data['patrolleaderO']),
        :joined => Osm::parse_date(data['joined']),
        :age => data['age'],
        :joined_years => data['yrs'].to_i,
      })
    end

    # Get the years element of this scout's age
    # @return [Fixnum] the number of years this scout has been alive
    def age_years
      return @age[0..1].to_i
    end

    # Get the months element of this scout's age
    # @return [Fixnum] the number of months since this scout's last birthday
    def age_months
      return @age[-2..-1].to_i
    end

    # Get the full name
    # @param [String] seperator what to split the scout's first name and last name with
    # @return [String] this scout's full name seperated by the optional seperator
    def name(seperator=' ')
      return "#{@first_name}#{seperator.to_s}#{@last_name}"
    end

  end # Class Member

end # Module
