module Osm

  class Member < Osm::Model
    # Constants for group id
    GID_PRIMARY_CONTACT = 1
    GID_SECONDARY_CONTACT = 2
    GID_EMERGENCY_CONTACT = 3
    GID_DOCTOR_CONTACT = 4
    GID_CUSTOM = 5
    GID_MEMBER_CONTACT = 6
    GID_FLOATING = 7

    # Constants for column id
    CUSTOM_FIELD_IDS_START_AT = 55
    CORE_FIELD_IDS_FINISH_AT = CUSTOM_FIELD_IDS_START_AT - 1
    CORE_FIELD_IDS = (1..54).to_a
    CID_FIRST_NAME = 2
    CID_LAST_NAME = 3
    CID_ADDRESS_1 = 7
    CID_ADDRESS_2 = 8
    CID_ADDRESS_3 = 9
    CID_ADDRESS_4 = 10
    CID_POSTCODE = 11
    CID_EMAIL_1 = 12
    CID_RECIEVE_EMAIL_1 = 13
    CID_EMAIL_2 = 14
    CID_RECIEVE_EMAIL_2 = 15
    CID_PHONE_1 = 18
    CID_RECIEVE_PHONE_1 = 19
    CID_PHONE_2 = 20
    CID_RECIEVE_PHONE_2 = 21
    CID_GENDER = 34
    CID_SURGERY = 54

    # @!attribute [rw] id
    #   @return [Fixnum] the id for the member
    # @!attribute [rw] section_id
    #   @return [Fixnum] the section the member belongs to
    # @!attribute [rw] first_name
    #   @return [String] the member's first name
    # @!attribute [rw] last_name
    #   @return [String] the member's last name
    # @!attribute [rw] grouping_id
    #   @return [Fixnum] the ID of the grouping within the section that the member belongs to
    # @!attribute [rw] grouping_label
    #   @return [String] the name of the grouping within the section that the member belongs to
    # @!attribute [rw] grouping_leader
    #   @return [Fixnum] whether the member is the grouping leader (0=no, 1=seconder/APL, 2=sixer/PL, 3=senior PL)
    # @!attribute [rw] grouping_leader_label
    #   @return [String] whether the member is the grouping leader
    # @!attribute [rw] age
    #   @return [String] the member's current age (yy/mm) 
    # @!attribute [rw] gender
    #   @return [Symbol] the member's gender (:male, :female, :other or :unspecified)
    # @!attribute [rw] date_of_birth
    #   @return [Date] the member's date of birth
    # @!attribute [rw] started_section
    #   @return [Date] when the member started the section they were retrieved for
    # @!attribute [rw] finished_section
    #   @return [Date] when the member finished the section they were retrieved for
    # @!attribute [rw] joined_movement
    #   @return [Date] when the member joined the movement
    # @!attribute [rw] custom
    #   @return [DirtyHashy] the custom data (key is OSM's variable name, value is the data)
    # @!attribute [rw] custom_labels
    #   @return [DirtyHashy] the labels for the custom data (key is OSM's variable name, value is the label)
    # @!attribute [rw] contact
    #   @return [Osm::Member::MemberContact] the member's contact details
    # @!attribute [rw] primary_contact
    #   @return [Osm::Member::PrimaryContact] the member's primary contact (primary contact 1 in OSM)
    # @!attribute [rw] secondary_contact
    #   @return [Osm::Member::PrimaryContact] the member's secondary contact (primary contact 2 in OSM)
    # @!attribute [rw] emergency_contact
    #   @return [Osm::Member::EmergencyContact] the member's emergency contact
    # @!attribute [rw] doctor
    #   @return [Osm::Member::DoctorContact] the member's doctor

    attribute :id, :type => Integer
    attribute :section_id, :type => Integer
    attribute :first_name, :type => String
    attribute :last_name, :type => String
    attribute :grouping_id, :type => Integer
    attribute :grouping_label, :type => String
    attribute :grouping_leader, :type => Integer
    attribute :grouping_leader_label, :type => String
    attribute :age, :type => String
    attribute :date_of_birth, :type => Date
    attribute :started_section, :type => Date
    attribute :finished_section, :type => Date
    attribute :joined_movement, :type => Date
    attribute :gender, :type => Object
    attribute :custom, :type => Object, :default => DirtyHashy.new
    attribute :custom_labels, :type => Object, :default => DirtyHashy.new
    attribute :contact, :type => Object
    attribute :primary_contact, :type => Object
    attribute :secondary_contact, :type => Object
    attribute :emergency_contact, :type => Object
    attribute :doctor, :type => Object

    if ActiveModel::VERSION::MAJOR < 4
      attr_accessible :id, :section_id, :first_name, :last_name, :grouping_id, :grouping_leader,
                      :date_of_birth, :started_section, :finished_section, :joined_movement, :age,
                      :grouping_label, :grouping_leader_label, :gender, :custom, :custom_labels,
                      :contact, :primary_contact, :secondary_contact, :emergency_contact, :doctor
    end

    validates_numericality_of :id, :only_integer=>true, :greater_than=>0, :unless => Proc.new { |r| r.id.nil? }
    validates_numericality_of :section_id, :only_integer=>true, :greater_than=>0
    validates_numericality_of :grouping_id, :only_integer=>true, :greater_than_or_equal_to=>-2
    validates_numericality_of :grouping_leader, :only_integer=>true, :greater_than_or_equal_to=>0, :less_than_or_equal_to=>14, :allow_nil => true
    validates_presence_of :first_name
    validates_presence_of :last_name
    validates_presence_of :grouping_label, :allow_blank => true
    validates_presence_of :grouping_leader_label, :allow_blank => true
    validates_presence_of :custom, :allow_blank => true
    validates_presence_of :custom_labels, :allow_blank => true
    validates_presence_of :date_of_birth
    validates_presence_of :started_section
    validates_presence_of :finished_section, :allow_nil=>true
    validates_presence_of :joined_movement
    validates_format_of :age, :with => /\A[0-9]{1,3} \/ (?:0?[0-9]|1[012])\Z/, :message => 'age is not in the correct format (yy / mm)', :allow_blank => true
    validates_inclusion_of :gender, :in => [:male, :female, :other, :unspecified], :allow_nil => true
    validates :contact, :validity=>true
    validates :primary_contact, :validity=>true
    validates :secondary_contact, :validity=>true
    validates :emergency_contact, :validity=>true
    validates :doctor, :validity=>true


    # Get members for a section
    # @param [Osm::Api] api The api to use to make the request
    # @param [Osm::Section, Fixnum, #to_i] section The section (or its ID) to get the members for
    # @param [Osm::Term, Fixnum, #to_i, nil] term The term (or its ID) to get the members for, passing nil causes the current term to be used
    # @!macro options_get
    # @return [Array<Osm::Member>]
    def self.get_for_section(api, section, term=nil, options={})
      require_ability_to(api, :read, :member, section, options)
      if term.nil?
        section = Osm::Section.get(api, section) if section.is_a?(Fixnum)
        term = section.waiting? ? -1 : Osm::Term.get_current_term_for_section(api, section)
      end
      cache_key = ['members', section.to_i, term.to_i]

      if !options[:no_cache] && cache_exist?(api, cache_key)
        return cache_read(api, cache_key)
      end

      result = Array.new

      api_response = api.perform_query('ext/members/contact/grid/?action=getMembers', {
        'section_id' => section.to_i,
        'term_id' => term.to_i,
      })

      data = api_response['data'].is_a?(Hash) ? api_response['data'].values : []
      structure = (api_response['meta'] || {})['structure'] || []
      structure = Hash[ structure.map{ |i| [i['group_id'].to_i, i ] } ] # Make a hash of identifier to group data hash

      custom_labels = {}
      structure.each do |gid, group|
        columns = group['columns'] || []
        columns.map!{ |c| [c['column_id'].to_i, c['label']] }
        columns.select!{ |a| (gid == GID_CUSTOM) || (a[0] > CORE_FIELD_IDS_FINISH_AT) }
        labels = DirtyHashy[ columns ]
        custom_labels[gid.to_i] = labels
      end

      data.each do |item|
        item_data = Hash[ item['custom_data'].map{ |k,v| [k.to_i, v] } ]
        member_contact = Hash[ item_data[GID_MEMBER_CONTACT].map{ |k,v| [k.to_i, v] }.select{ |i| i[0] < CUSTOM_FIELD_IDS_START_AT } ]
        primary_contact = Hash[ item_data[GID_PRIMARY_CONTACT].map{ |k,v| [k.to_i, v] }.select{ |i| i[0] < CUSTOM_FIELD_IDS_START_AT } ]
        secondary_contact = Hash[ item_data[GID_SECONDARY_CONTACT].map{ |k,v| [k.to_i, v] }.select{ |i| i[0] < CUSTOM_FIELD_IDS_START_AT } ]
        emergency_contact = Hash[ item_data[GID_EMERGENCY_CONTACT].map{ |k,v| [k.to_i, v] }.select{ |i| i[0] < CUSTOM_FIELD_IDS_START_AT } ]
        doctor_contact = Hash[ item_data[GID_DOCTOR_CONTACT].map{ |k,v| [k.to_i, v] }.select{ |i| i[0] < CUSTOM_FIELD_IDS_START_AT } ]
        floating_data = Hash[ item_data[GID_FLOATING].map{ |k,v| [k.to_i, v] }.select{ |i| i[0] < CUSTOM_FIELD_IDS_START_AT } ]

        result.push Osm::Member.new(
          :id => Osm::to_i_or_nil(item['member_id']),
          :section_id => Osm::to_i_or_nil(item['section_id']),
          :first_name => item['first_name'],
          :last_name => item['last_name'],
          :grouping_id => Osm::to_i_or_nil(item['patrol_id']),
          :grouping_label => item['patrol'],
          :grouping_leader => item['patrol_role_level'],
          :grouping_leader_label => item['patrol_role_level_label'],
          :age => item['age'],
          :date_of_birth => Osm::parse_date(item['date_of_birth'], :ignore_epoch => true),
          :started_section => Osm::parse_date(item['joined']),
          :finished_section => Osm::parse_date(item['end_date']),
          :joined_movement => Osm::parse_date(item['started']),
          :gender => {'male'=>:male, 'female'=>:female, 'other'=>:other, 'unspecified'=>:unspecified}[(floating_data[CID_GENDER] || '').downcase],
          :contact => MemberContact.new(
            first_name: item['first_name'],
            last_name: item['last_name'],
            address_1: member_contact[CID_ADDRESS_1],
            address_2: member_contact[CID_ADDRESS_2],
            address_3: member_contact[CID_ADDRESS_3],
            address_4: member_contact[CID_ADDRESS_4],
            postcode: member_contact[CID_POSTCODE],
            phone_1: member_contact[CID_PHONE_1],
            phone_2: member_contact[CID_PHONE_2],
            email_1: member_contact[CID_EMAIL_1],
            email_2: member_contact[CID_EMAIL_2],
            receive_phone_1: member_contact[CID_RECIEVE_PHONE_1],
            receive_phone_2: member_contact[CID_RECIEVE_PHONE_2],
            receive_email_1: member_contact[CID_RECIEVE_EMAIL_1],
            receive_email_2: member_contact[CID_RECIEVE_EMAIL_2],
            custom: DirtyHashy[ item_data[GID_MEMBER_CONTACT].map{ |k,v| [k.to_i, v] }.select{ |i| i[0] > CORE_FIELD_IDS_FINISH_AT } ],
            custom_labels: custom_labels[GID_MEMBER_CONTACT] || DirtyHashy.new,
          ),
          :primary_contact => PrimaryContact.new(
            first_name: primary_contact[CID_FIRST_NAME],
            last_name: primary_contact[CID_LAST_NAME],
            address_1: primary_contact[CID_ADDRESS_1],
            address_2: primary_contact[CID_ADDRESS_2],
            address_3: primary_contact[CID_ADDRESS_3],
            address_4: primary_contact[CID_ADDRESS_4],
            postcode: primary_contact[CID_POSTCODE],
            phone_1: primary_contact[CID_PHONE_1],
            phone_2: primary_contact[CID_PHONE_2],
            email_1: primary_contact[CID_EMAIL_1],
            email_2: primary_contact[CID_EMAIL_2],
            receive_phone_1: primary_contact[CID_RECIEVE_PHONE_1],
            receive_phone_2: primary_contact[CID_RECIEVE_PHONE_2],
            receive_email_1: primary_contact[CID_RECIEVE_EMAIL_1],
            receive_email_2: primary_contact[CID_RECIEVE_EMAIL_2],
            custom: DirtyHashy[ item_data[GID_PRIMARY_CONTACT].map{ |k,v| [k.to_i, v] }.select{ |i| i[0] > CORE_FIELD_IDS_FINISH_AT } ],
            custom_labels: custom_labels[GID_PRIMARY_CONTACT] || DirtyHashy.new,
          ),
          :secondary_contact => PrimaryContact.new(
            first_name: secondary_contact[CID_FIRST_NAME],
            last_name: secondary_contact[CID_LAST_NAME],
            address_1: secondary_contact[CID_ADDRESS_1],
            address_2: secondary_contact[CID_ADDRESS_2],
            address_3: secondary_contact[CID_ADDRESS_3],
            address_4: secondary_contact[CID_ADDRESS_4],
            postcode: secondary_contact[CID_POSTCODE],
            phone_1: secondary_contact[CID_PHONE_1],
            phone_2: secondary_contact[CID_PHONE_2],
            email_1: secondary_contact[CID_EMAIL_1],
            email_2: secondary_contact[CID_EMAIL_2],
            receive_phone_1: secondary_contact[CID_RECIEVE_PHONE_1],
            receive_phone_2: secondary_contact[CID_RECIEVE_PHONE_2],
            receive_email_1: secondary_contact[CID_RECIEVE_EMAIL_1],
            receive_email_2: secondary_contact[CID_RECIEVE_EMAIL_2],
            custom: DirtyHashy[ item_data[GID_SECONDARY_CONTACT].map{ |k,v| [k.to_i, v] }.select{ |i| i[0] > CORE_FIELD_IDS_FINISH_AT } ],
            custom_labels: custom_labels[GID_SECONDARY_CONTACT] || DirtyHashy.new,
          ),
          :emergency_contact => EmergencyContact.new(
            first_name: emergency_contact[CID_FIRST_NAME],
            last_name: emergency_contact[CID_LAST_NAME],
            address_1: emergency_contact[CID_ADDRESS_1],
            address_2: emergency_contact[CID_ADDRESS_2],
            address_3: emergency_contact[CID_ADDRESS_3],
            address_4: emergency_contact[CID_ADDRESS_4],
            postcode: emergency_contact[CID_POSTCODE],
            phone_1: emergency_contact[CID_PHONE_1],
            phone_2: emergency_contact[CID_PHONE_2],
            email_1: emergency_contact[CID_EMAIL_1],
            email_2: emergency_contact[CID_EMAIL_2],
            custom: DirtyHashy[ item_data[GID_EMERGENCY_CONTACT].map{ |k,v| [k.to_i, v] }.select{ |i| i[0] > CORE_FIELD_IDS_FINISH_AT } ],
            custom_labels: custom_labels[GID_EMERGENCY_CONTACT] || DirtyHashy.new,
          ),
          :doctor => DoctorContact.new(
            first_name: doctor_contact[CID_FIRST_NAME],
            last_name: doctor_contact[CID_LAST_NAME],
            surgery: doctor_contact[CID_SURGERY],
            address_1: doctor_contact[CID_ADDRESS_1],
            address_2: doctor_contact[CID_ADDRESS_2],
            address_3: doctor_contact[CID_ADDRESS_3],
            address_4: doctor_contact[CID_ADDRESS_4],
            postcode: doctor_contact[CID_POSTCODE],
            phone_1: doctor_contact[CID_PHONE_1],
            phone_2: doctor_contact[CID_PHONE_2],
            custom: DirtyHashy[ item_data[GID_DOCTOR_CONTACT].map{ |k,v| [k.to_i, v] }.select{ |i| i[0] > CORE_FIELD_IDS_FINISH_AT } ],
            custom_labels: custom_labels[GID_DOCTOR_CONTACT] || DirtyHashy.new,
          ),
          custom: DirtyHashy[ item_data[GID_CUSTOM].map{ |k,v| [k.to_i, v] } ],
          custom_labels: custom_labels[GID_CUSTOM] || DirtyHashy.new,
        )
      end

      cache_write(api, cache_key, result)
      return result
    end


    # @!method initialize
    #   Initialize a new Member
    #   @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)


    # Create the user in OSM
    # @param [Osm::Api] api The api to use to make the request
    # @return [Boolan] whether the member was successfully added or not
    # @raise [Osm::ObjectIsInvalid] If the Member is invalid
    # @raise [Osm::Error] If the member already exists in OSM
    def create(api)
      raise Osm::ObjectIsInvalid, 'member is invalid' unless valid?
      require_ability_to(api, :write, :member, section_id)
      raise Osm::Error, 'the member already exists in OSM' unless id.nil?

      data = api.perform_query("users.php?action=newMember", {
        'firstname' => first_name,
        'lastname' => last_name,
        'dob' => date_of_birth.strftime(Osm::OSM_DATE_FORMAT),
        'started' => started.strftime(Osm::OSM_DATE_FORMAT),
        'startedsection' => joined.strftime(Osm::OSM_DATE_FORMAT),
        'patrolid' => grouping_id,
        'patrolleader' => grouping_leader,
        'sectionid' => section_id,
        'email1' => email1,
        'email2' => email2,
        'email3' => email3,
        'email4' => email4,
        'phone1' => phone1,
        'phone2' => phone2,
        'phone3' => phone3,
        'phone4' => phone4,
        'address' => address,
        'address2' => address2,
        'parents' => parents,
        'notes' => notes,
        'medical' => medical,
        'religion' => religion,
        'school' => school,
        'ethnicity' => ethnicity,
        'subs' => subs,
        'custom1' => custom1,
        'custom2' => custom2,
        'custom3' => custom3,
        'custom4' => custom4,
        'custom5' => custom5,
        'custom6' => custom6,
        'custom7' => custom7,
        'custom8' => custom8,
        'custom9' => custom9,
      })

      if (data.is_a?(Hash) && (data['result'] == 'ok') && (data['scoutid'].to_i > 0))
        self.id = data['scoutid'].to_i
        # The cached members for the section will be out of date - remove them
        Osm::Term.get_for_section(api, section_id).each do |term|
          cache_delete(api, ['members', section_id, term.id])
        end
        return true
      else
        return false
      end
    end

    # Update the member in OSM
    # @param [Osm::Api] api The api to use to make the request
    # @return [Boolan] whether the member was successfully updated or not
    # @raise [Osm::ObjectIsInvalid] If the Member is invalid
    def update(api)
      raise Osm::ObjectIsInvalid, 'member is invalid' unless valid?
      require_ability_to(api, :write, :member, section_id)

      to_update = changed_attributes
      values = {}
      values['firstname']      = first_name if to_update.include?('first_name')
      values['lastname']       = last_name  if to_update.include?('last_name')
      values['dob']            = date_of_birth.strftime(Osm::OSM_DATE_FORMAT) if to_update.include?('date_of_birth')
      values['started']        = started.strftime(Osm::OSM_DATE_FORMAT) if to_update.include?('started')
      values['startedsection'] = joined.strftime(Osm::OSM_DATE_FORMAT) if to_update.include?('joined')
      values['email1']         = email1     if to_update.include?('email1')
      values['email2']         = email2     if to_update.include?('email2')
      values['email3']         = email3     if to_update.include?('email3')
      values['email4']         = email4     if to_update.include?('email4')
      values['phone1']         = phone1     if to_update.include?('phone1')
      values['phone2']         = phone2     if to_update.include?('phone2')
      values['phone3']         = phone3     if to_update.include?('phone3')
      values['phone4']         = phone4     if to_update.include?('phone3')
      values['address']        = address    if to_update.include?('address')
      values['address2']       = address2   if to_update.include?('address2')
      values['parents']        = parents    if to_update.include?('parents')
      values['notes']          = notes      if to_update.include?('notes')
      values['medical']        = medical    if to_update.include?('medical')
      values['religion']       = religion   if to_update.include?('religion')
      values['school']         = school     if to_update.include?('school')
      values['ethnicity']      = ethnicity  if to_update.include?('ethnicity')
      values['subs']           = subs       if to_update.include?('subs')
      values['custom1']        = custom1    if to_update.include?('custom1')
      values['custom2']        = custom2    if to_update.include?('custom2')
      values['custom3']        = custom3    if to_update.include?('custom3')
      values['custom4']        = custom4    if to_update.include?('custom4')
      values['custom5']        = custom5    if to_update.include?('custom5')
      values['custom6']        = custom6    if to_update.include?('custom6')
      values['custom7']        = custom7    if to_update.include?('custom7')
      values['custom8']        = custom8    if to_update.include?('custom8')
      values['custom9']        = custom9    if to_update.include?('custom9')

      result = true
      values.each do |column, value|
        data = api.perform_query("users.php?action=updateMember&dateFormat=generic", {
          'scoutid' => self.id,
          'column' => column,
          'value' => value,
          'sectionid' => section_id,
        })
        result &= (data[column] == value.to_s)
      end

      if to_update.include?('grouping_id') || to_update.include?('grouping_leader')
        data = api.perform_query("users.php?action=updateMemberPatrol", {
          'scoutid' => self.id,
          'patrolid' => grouping_id,
          'pl' => grouping_leader,
          'sectionid' => section_id,
        })
        result &= ((data['patrolid'].to_i == grouping_id) && (data['patrolleader'].to_i == grouping_leader))
      end

      if result
        reset_changed_attributes
        # The cached columns for the flexi record will be out of date - remove them
        Osm::Term.get_for_section(api, section_id).each do |term|
          Osm::Model.cache_delete(api, ['members', section_id, term.id])
        end
      end

      return result
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
    # @param [String] seperator What to split the scout's first name and last name with
    # @return [String] this scout's full name seperated by the optional seperator
    def name(seperator=' ')
      return "#{first_name}#{seperator.to_s}#{last_name}"
    end

    # Check if the member is in the leaders grouping
    # @return [Boolean]
    def leader?
      grouping_id.eql?(-2)
    end

    # Check if the member is in a non-leaders grouping
    # @return [Boolean]
    def youth?
      grouping_id > 0
    end

    # Check if the member is male
    # @return [Boolean]
    def male?
      gender == :male
    end

    # Check if the member is male
    # @return [Boolean]
    def female?
      gender == :female
    end

    # Check if this is a current member of the section they were retrieved for
    # @param [Date] date The date to check membership status for
    # @return [Boolean]
    def current?(date=Date.today)
      if finished_section.nil?
        return (started_section <= date)
      else
        return (started_section <= date) && (finished_section >= date)
      end
    end

    # @!method all_emails
    # Get an array of all email addresses from all contacts for the member (not emergency or doctor)
    # @return [Array<String>]
    # @!method all_emails_with_name
    # Get an array of all email addresses from all contacts for the member in a format which includes the contact's name (not emergency or doctor)
    # @return [Array<String>]
    # @!method enabled_emails
    # Get an array of all email addresses from all contacts for the member (not emergency or doctor)
    # @return [Array<String>]
    # @!method enabled_emails_with_name
    # Get an array of all email addresses from all contacts for the member in a format which includes the contact's name (not emergency or doctor)
    # @return [Array<String>]
    # @!method all_phones
    # Get an array of all phone numbers from all contacts for the member (not emergency or doctor)
    # @return [Array<String>]
    # @!method enabled_phones
    # Get an array of enabled phone numbers from all contacts for the member (not emergency or doctor)
    # @return [Array<String>]
    [:all_emails, :all_emails_with_name, :enabled_emails, :enabled_emails_with_name, :all_phones, :enabled_phones].each do |meth|
      define_method meth do
        items = []
        [:contact, :primary_contact, :secondary_contact].each do |cont|
          items.push *send(cont).send(meth)
        end
        return items
      end
    end

    # Get the Key to use in My.SCOUT links for this member
    # @param [Osm::Api] api The api to use to make the request
    # @return [String] the key
    # @raise [Osm::ObjectIsInvalid] If the Member is invalid
    # @raise [Osm::Error] if the member does not already exist in OSM or the member's My.SCOUT key could not be retrieved from OSM
    def myscout_link_key(api)
      raise Osm::ObjectIsInvalid, 'member is invalid' unless valid?
      require_ability_to(api, :read, :member, section_id)
      raise Osm::Error, 'the member does not already exist in OSM' if id.nil?

      if @myscout_link_key.nil?
        data = api.perform_query("api.php?action=getMyScoutKey&sectionid=#{section_id}&scoutid=#{self.id}")
        raise Osm::Error, 'Could not retrieve the key for the link from OSM' unless data['ok']
        @myscout_link_key = data['key']
      end

      return @myscout_link_key
    end

    # Get the member's photo
    # @param [Osm::Api] api The api to use to make the request
    # @param [Boolean] black_and_white Whether you want the photo in blank and white (defaults to false unless the member is not active)
    # @!macro options_get
    # @raise [Osm:Error] if the member doesn't exist in OSM
    # @return the photo of the member
    def get_photo(api, black_and_white=!current?, options={})
      raise Osm::ObjectIsInvalid, 'member is invalid' unless valid?
      require_ability_to(api, :read, :member, section_id)
      raise Osm::Error, 'the member does not already exist in OSM' if id.nil?

      cache_key = ['member_photo', self.id, black_and_white]

      if !options[:no_cache] && cache_exist?(api, cache_key)
        return cache_read(api, cache_key)
      end

      url = "ext/members/contact/images/member.php?sectionid=#{section_id}&scoutid=#{self.id}&bw=#{black_and_white}"
      image = api.perform_query(url)

      cache_write(api, cache_key, image) unless image.nil?
      return image
    end

    # Get the My.SCOUT link for this member
    # @param [Osm::Api] api The api to use to make the request
    # @param [Symbol] link_to The page in My.SCOUT to link to (:payments, :events, :programme, :badges, :notice, :details, :census or :giftaid)
    # @param [#to_i] item_id Allows you to link to a specfic item (only for :events)
    # @return [String] the URL for this member's My.SCOUT
    # @raise [Osm::ObjectIsInvalid] If the Member is invalid
    # @raise [Osm::ArgumentIsInvalid] If link_to is not an allowed Symbol
    # @raise [Osm::Error] if the member does not already exist in OSM or the member's My.SCOUT key could not be retrieved from OSM
    def myscout_link(api, link_to=:badges, item_id=nil)
      raise Osm::ObjectIsInvalid, 'member is invalid' unless valid?
      require_ability_to(api, :read, :member, section_id)
      raise Osm::Error, 'the member does not already exist in OSM' if id.nil?
      raise Osm::ArgumentIsInvalid, 'link_to is invalid' unless [:payments, :events, :programme, :badges, :notice, :details, :census, :giftaid].include?(link_to)

      link = "#{api.base_url}/parents/#{link_to}.php?sc=#{self.id}&se=#{section_id}&c=#{myscout_link_key(api)}"
      link += "&e=#{item_id.to_i}" if item_id && link_to.eql?(:events)
      return link
    end

    # Compare member based on section_id, grouping_id, grouping_leader (descending), last_name then first_name
    def <=>(another)
      result = self.section_id <=> another.try(:section_id)
      result = self.grouping_id <=> another.try(:grouping_id) if result == 0
      result = -(self.grouping_leader <=> another.try(:grouping_leader)) if result == 0
      result = self.last_name <=> another.try(:last_name) if result == 0
      result = self.first_name <=> another.try(:first_name) if result == 0
      return result
    end


    module EmailableContact
      # Get an array of all emails for the contact
      # @return [Array<String>]
      def all_emails
        [email_1, email_2].select{ |e| !e.blank? }
      end

      # Get an array of enabled emails for the contact
      # @return [Array<String>]
      def enabled_emails
        emails = []
        emails.push email_1 if receive_email_1
        emails.push email_2 if receive_email_2
        emails.select{ |e| !e.blank? }
      end

      # Get an array of all emails for the contact in a format which includes their name
      # @return [Array<String>]
      def all_emails_with_name
        [email_1, email_2].select{ |e| !e.blank? }.map{ |e| "\"#{name}\" <#{e}>" }
      end

      # Get an array of enabled emails for the contact in a format which includes their name
      # @return [Array<String>]
      def enabled_emails_with_name
        emails = []
        emails.push email_1 if receive_email_1
        emails.push email_2 if receive_email_2
        emails.select{ |e| !e.blank? }.map{ |e| "\"#{name}\" <#{e}>" }
      end
    end

    module PhoneableContact
      # Get an array of enabled phone numbers for the contact
      def enabled_phones
        phones = []
        phones.push phone_1.gsub(/[^\d\+]/, '') if receive_phone_1
        phones.push phone_2.gsub(/[^\d\+]/, '') if receive_phone_2
        phones.select{ |n| !n.blank? }.map{ |n| n }
      end
    end


    class Contact < Osm::Model
      # @!attribute [rw] first_name
      #   @return [String] the contact's first name
      # @!attribute [rw] last_name
      #   @return [String] the contact's last name
      # @!attribute [rw] address_1
      #   @return [String] the 1st line of the address
      # @!attribute [rw] address_2
      #   @return [String] the 2nd line of the address
      # @!attribute [rw] address_3
      #   @return [String] the 3rd line of the address
      # @!attribute [rw] address_4
      #   @return [String] the 4th line of the address
      # @!attribute [rw] postcode
      #   @return [String] the postcode of the address
      # @!attribute [rw] phone_1
      #   @return [String] the primary phone number
      # @!attribute [rw] phone_2
      #   @return [String] the secondary phone number
      # @!attribute [rw] custom
      #   @return [DirtyHashy] the custom data (key is OSM's variable name, value is the data)
      # @!attribute [rw] custom_labels
      #   @return [DirtyHashy] the labels for the custom data (key is OSM's variable name, value is the label)

      attribute :first_name, :type => String
      attribute :last_name, :type => String
      attribute :address_1, :type => String
      attribute :address_2, :type => String
      attribute :address_3, :type => String
      attribute :address_4, :type => String
      attribute :postcode, :type => String
      attribute :phone_1, :type => String
      attribute :phone_2, :type => String
      attribute :custom, :type => Object, :default => DirtyHashy.new
      attribute :custom_labels, :type => Object, :default => DirtyHashy.new

      if ActiveModel::VERSION::MAJOR < 4
        attr_accessible :first_name, :last_name, :address_1, :address_2, :address_3, :address_4,
                        :postcode, :phone_1, :phone_2, :custom, :custom_labels
      end

      # @!method initialize
      #   Initialize a new Contact
      #   @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)

      # Get the full name
      # @param [String] seperator What to split the scout's first name and last name with
      # @return [String] this scout's full name seperated by the optional seperator
      def name(seperator=' ')
        return "#{first_name}#{seperator.to_s}#{last_name}"
      end

      # Get an array of all phone numbers for the contact
      # @return [Array<String>]
      def all_phones
        [phone_1, phone_2].select{ |n| !n.blank? }.map{ |n| n.gsub(/[^\d\+]/, '') }
      end
    end


    class MemberContact < Osm::Member::Contact
      include EmailableContact
      include PhoneableContact
      # @!attribute [rw] email_1
      #   @return [String] the primary email address for the member
      # @!attribute [rw] email_2
      #   @return [String] the secondary email address for the member
      # @!attribute [rw] receive_email_1
      #   @return [Boolean] whether the member should receive emails from leaders on their primary email address
      # @!attribute [rw] receive_email_2
      #   @return [Boolean] whether the member should receive emails from leaders on their secondary email address
      # @!attribute [rw] receive_phone_1
      #   @return [Boolean] whether the member should receive SMSs from leaders on their primary phone number
      # @!attribute [rw] receive_phone_2
      #   @return [Boolean] whether the member should receive SMSs from leaders on their secondary phone number

      attribute :email_1, :type => String
      attribute :receive_email_1, :type => Boolean, :default => false
      attribute :email_2, :type => String
      attribute :receive_email_2, :type => Boolean, :default => false
      attribute :receive_phone_1, :type => Boolean, :default => false
      attribute :receive_phone_2, :type => Boolean, :default => false

      if ActiveModel::VERSION::MAJOR < 4
        attr_accessible :email_1, :email_2, :receive_email_1, :receive_email_2,
                        :receive_phone_1, :receive_phone_2
      end

      validates_inclusion_of :receive_email_1, :in => [true, false]
      validates_inclusion_of :receive_email_2, :in => [true, false]
      validates_inclusion_of :receive_phone_1, :in => [true, false]
      validates_inclusion_of :receive_phone_2, :in => [true, false]
    end


    class PrimaryContact < Osm::Member::Contact
      include EmailableContact
      include PhoneableContact
      # @!attribute [rw] email_1
      #   @return [String] the primary email address for the contact
      # @!attribute [rw] email_2
      #   @return [String] the secondary email address for the contact
      # @!attribute [rw] receive_email_1
      #   @return [Boolean] whether the contact should receive emails from leaders on their primary email address
      # @!attribute [rw] receive_email_2
      #   @return [Boolean] whether the contact should receive emails from leaders on their secondary email address
      # @!attribute [rw] receive_phone_1
      #   @return [Boolean] whether the contact should receive SMSs from leaders on their primary phone number
      # @!attribute [rw] receive_phone_2
      #   @return [Boolean] whether the contact should receive SMSs from leaders on their secondary phone number

      attribute :email_1, :type => String
      attribute :receive_email_1, :type => Boolean, :default => false
      attribute :email_2, :type => String
      attribute :receive_email_2, :type => Boolean, :default => false
      attribute :receive_phone_1, :type => Boolean, :default => false
      attribute :receive_phone_2, :type => Boolean, :default => false

      if ActiveModel::VERSION::MAJOR < 4
        attr_accessible :email_1, :email_2,
                        :receive_email_1, :receive_email_2, :receive_phone_1, :receive_phone_2
      end

      validates_inclusion_of :receive_email_1, :in => [true, false]
      validates_inclusion_of :receive_email_2, :in => [true, false]
      validates_inclusion_of :receive_phone_1, :in => [true, false]
      validates_inclusion_of :receive_phone_2, :in => [true, false]
    end # class PrimaryContact


    class EmergencyContact < Osm::Member::Contact
      # @!attribute [rw] email_1
      #   @return [String] the primary email address for the contact
      # @!attribute [rw] email_2
      #   @return [String] the secondary email address for the contact

      attribute :email_1, :type => String
      attribute :email_2, :type => String

      if ActiveModel::VERSION::MAJOR < 4
        attr_accessible :email_1, :email_2
      end

      # Get the full name
      # @param [String] seperator What to split the scout's first name and last name with
      # @return [String] this scout's full name seperated by the optional seperator
      def name(seperator=' ')
        return "#{first_name}#{seperator.to_s}#{last_name}"
      end
    end # class EmergencyContact


    class DoctorContact < Osm::Member::Contact
      # @!attribute [rw] first_name
      #   @return [String] the contact's first name
      # @!attribute [rw] last_name
      #   @return [String] the contact's last name
      # @!attribute [rw] surgery
      #   @return [String] the surgery name

      attribute :first_name, :type => String
      attribute :last_name, :type => String
      attribute :surgery, :type => String

      if ActiveModel::VERSION::MAJOR < 4
        attr_accessible :first_name, :last_name, :surgery
      end

      # Get the full name
      # @param [String] seperator What to split the scout's first name and last name with
      # @return [String] this scout's full name seperated by the optional seperator
      def name(seperator=' ')
        return "Dr. #{first_name}#{seperator.to_s}#{last_name}"
      end
    end # class DoctorContact

  end # Class Member

end # Module
