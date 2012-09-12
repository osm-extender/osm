module Osm

  class Member
    include ::ActiveAttr::MassAssignmentSecurity
    include ::ActiveAttr::Model

    # @!attribute [rw] id
    #   @return [Fixnum] the id for the member
    # @!attribute [rw] section_id
    #   @return [Fixnum] the section the member belongs to
    # @!attribute [rw] type
    #   @return [String] ?
    # @!attribute [rw] first_name
    #   @return [String] the member's first name
    # @!attribute [rw] last_name
    #   @return [String] the member's last name
    # @!attribute [rw] email1
    #   @return [String] the 1st email address for the member
    # @!attribute [rw] email2
    #   @return [String] the 2nd email address for the member
    # @!attribute [rw] email3
    #   @return [String] the 3rd email address for the member
    # @!attribute [rw] email4
    #   @return [String] the 4th email address for the member
    # @!attribute [rw] phone1
    #   @return [String] the 1st phone number for the member
    # @!attribute [rw] phone2
    #   @return [String] the 2nd phone number for the member
    # @!attribute [rw] phone3
    #   @return [String] the 3rd phone number for the member
    # @!attribute [rw] phone4
    #   @return [String] the 4th phone number for the member
    # @!attribute [rw] address
    #   @return [String] the member's address
    # @!attribute [rw] address2
    #   @return [String] the member's 2nd address
    # @!attribute [rw] date_of_birth
    #   @return [Date] the member's date of birth
    # @!attribute [rw] started
    #   @return [Date] when the member started Scouting
    # @!attribute [rw] joining_in_years
    #   @return [Fixnum] ?
    # @!attribute [rw] parents
    #   @return [String] the member's parent's names
    # @!attribute [rw] notes
    #   @return [String] notes relating to the member
    # @!attribute [rw] medical
    #   @return [String] the member's key medical details
    # @!attribute [rw] religion
    #   @return [String] the member's religion
    # @!attribute [rw] school
    #   @return [String] the school the member attends
    # @!attribute [rw] ethnicity
    #   @return [String] the member's ethnicity
    # @!attribute [rw] subs
    #   @return [String] details about the member's subs
    # @!attribute [rw] grouping_id
    #   @return [Fixnum] the grouping within the section that the member belongs to
    # @!attribute [rw] grouping_leader
    #   @return [Fixnum] wether the member is the grouping leader (0=no, 1=seconder/APL, 2=sixer/PL)
    # @!attribute [rw] joined
    #   @return [Date] when the member joined the section
    # @!attribute [rw] age
    #   @return [String] the member's current age (yy/mm)
    # @!attribute [rw] joined_years
    #   @return [Fixnum] how many years the member has been in Scouting

    attribute :id, :type => Integer
    attribute :section_id, :type => Integer
    attribute :type, :type => String
    attribute :first_name, :type => String
    attribute :last_name, :type => String
    attribute :email1, :type => String, :default => ''
    attribute :email2, :type => String, :default => ''
    attribute :email3, :type => String, :default => ''
    attribute :email4, :type => String, :default => ''
    attribute :phone1, :type => String, :default => ''
    attribute :phone2, :type => String, :default => ''
    attribute :phone3, :type => String, :default => ''
    attribute :phone4, :type => String, :default => ''
    attribute :address, :type => String, :default => ''
    attribute :address2, :type => String, :default => ''
    attribute :date_of_birth, :type => Date
    attribute :started, :type => Date
    attribute :joining_in_years, :type => Integer
    attribute :parents, :type => String, :default => ''
    attribute :notes, :type => String, :default => ''
    attribute :medical, :type => String, :default => ''
    attribute :religion, :type => String, :default => ''
    attribute :school, :type => String, :default => ''
    attribute :ethnicity, :type => String, :default => ''
    attribute :subs, :type => String, :default => ''
    attribute :grouping_id, :type => Integer
    attribute :grouping_leader, :type => Integer
    attribute :joined, :type => Date
    attribute :age, :type => String
    attribute :joined_years, :type => Integer

    attr_accessible :id, :section_id, :type, :first_name, :last_name, :email1, :email2, :email3, :email4, :phone1, :phone2, :phone3, :phone4, :address, :address2, :date_of_birth, :started, :joining_in_years, :parents, :notes, :medical, :religion, :school, :ethnicity, :subs, :grouping_id, :grouping_leader, :joined, :age, :joined_years

    validates_numericality_of :id, :only_integer=>true, :greater_than=>0
    validates_numericality_of :section_id, :only_integer=>true, :greater_than=>0
    validates_numericality_of :grouping_id, :only_integer=>true, :greater_than_or_equal_to=>-2
    validates_numericality_of :grouping_leader, :only_integer=>true, :greater_than_or_equal_to=>0, :less_than_or_equal_to=>2
    validates_numericality_of :joined_years, :only_integer=>true, :greater_than_or_equal_to=>-1
    validates_numericality_of :joining_in_years, :only_integer=>true, :greater_than_or_equal_to=>0
    validates_presence_of :first_name
    validates_presence_of :last_name
    validates_presence_of :date_of_birth
    validates_presence_of :started
    validates_presence_of :joined
    validates_format_of :age, :with => /\A[0-9]{2}\/(0[0-9]|1[012])\Z/, :message => 'age is not in the correct format (yy/mm)', :allow_blank => true


    # @!method initialize
    #   Initialize a new Term
    #   @param [Hash] attributes the hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)


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
      return age[0..1].to_i
    end

    # Get the months element of this scout's age
    # @return [Fixnum] the number of months since this scout's last birthday
    def age_months
      return age[-2..-1].to_i
    end

    # Get the full name
    # @param [String] seperator what to split the scout's first name and last name with
    # @return [String] this scout's full name seperated by the optional seperator
    def name(seperator=' ')
      return "#{first_name}#{seperator.to_s}#{last_name}"
    end

  end # Class Member

end # Module
