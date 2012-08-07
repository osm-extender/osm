module Osm

  class Member

    attr_reader :id, :section_id, :type, :first_name, :last_name, :email1, :email2, :email3, :email4, :phone1, :phone2, :phone3, :phone4, :address, :address2, :date_of_birth, :started, :joined_in_years, :parents, :notes, :medical, :religion, :school, :ethnicity, :subs, :grouping_id, :grouping_leader, :joined, :age, :joined_years
    # @!attribute [r] id
    #   @return [FixNum] the id for the member
    # @!attribute [r] section_id
    #   @return [FixNum] the section the member belongs to
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
    # @!attribute [r] joined_in_years
    #   @return [FixNum] ?
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
    #   @return [FixNum] the grouping within the section that the member belongs to
    # @!attribute [r] grouping_leader
    #   @return [FixNum] wether the member is the grouping leader (0=no, 1=seconder/APL, 2=sixer/PL)
    # @!attribute [r] joined
    #   @return [Date] when the member joined the section
    # @!attribute [r] age
    #   @return [String] the member's current age (yy/mm)
    # @!attribute [r] joined_years
    #   @return [FixNum] how many years the member has been in Scouting


    # Initialize a new Member using the hash returned by the API call
    # @param data the hash of data for the object returned by the API
    def initialize(data)
      @id = Osm::to_i_or_nil(data['scoutid'])
      @section_id = Osm::to_i_or_nil(data['sectionidO'])
      @type = data['type']
      @first_name = data['firstname']
      @last_name = data['lastname']
      @email1 = data['email1']
      @email2 = data['email2']
      @email3 = data['email3']
      @email4 = data['email4']
      @phone1 = data['phone1']
      @phone2 = data['phone2']
      @phone3 = data['phone3']
      @phone4 = data['phone4']
      @address = data['address']
      @address2 = data['address2']
      @date_of_birth = Osm::parse_date(data['dob'])
      @started = Osm::parse_date(data['started'])
      @joined_in_years = data['joining_in_yrs'].to_i
      @parents = data['parents']
      @notes = data['notes']
      @medical = data['medical']
      @religion = data['religion']
      @school = data['school']
      @ethnicity = data['ethnicity']
      @subs = data['subs']
      @grouping_id = Osm::to_i_or_nil(data['patrolidO'])
      @grouping_leader = data['patrolleaderO'] # 0 - No, 1 = seconder, 2 = sixer
      @joined = Osm::parse_date(data['joined'])
      @age = data['age'] # 'yy / mm'
      @joined_years = data['yrs'].to_i
    end

    # Get the years element of this scout's age
    # @return [FixNum] the number of years this scout has been alive
    def age_years
      return @age[0..1].to_i
    end

    # Get the months element of this scout's age
    # @return [FixNum] the number of months since this scout's last birthday
    def age_months
      return @age[-2..-1].to_i
    end

    # Get the full name
    # @param [String] seperator what to split the scout's first name and last name with
    # @return [String] this scout's full name seperated by the optional seperator
    def name(seperator=' ')
      return "#{@first_name}#{seperator.to_s}#{@last_name}"
    end

  end

end
