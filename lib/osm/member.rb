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
    CORE_FIELD_IDS = (1..21).to_a + [34, 54]


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
    # @!attribute [rw] additional_information
    #   @return [DirtyHashy] the Additional Information (key is OSM's variable name, value is the data)
    # @!attribute [rw] additional_information_labels
    #   @return [DirtyHashy] the labels for the additional information (key is OSM's variable name, value is the label)
    # @!attribute [rw] contact
    #   @return [Osm::Member::MemberContact, nil] the member's contact details (nil if hidden in OSM)
    # @!attribute [rw] primary_contact
    #   @return [Osm::Member::PrimaryContact, nil] the member's primary contact (primary contact 1 in OSM) (nil if hidden in OSM)
    # @!attribute [rw] secondary_contact
    #   @return [Osm::Member::SecondaryContact, nil] the member's secondary contact (primary contact 2 in OSM) (nil if hidden in OSM)
    # @!attribute [rw] emergency_contact
    #   @return [Osm::Member::EmergencyContact, nil] the member's emergency contact (nil if hidden in OSM)
    # @!attribute [rw] doctor
    #   @return [Osm::Member::DoctorContact, nil] the member's doctor (nil if hidden in OSM)

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
    attribute :additional_information, :type => Object, :default => DirtyHashy.new
    attribute :additional_information_labels, :type => Object, :default => DirtyHashy.new
    attribute :contact, :type => Object
    attribute :primary_contact, :type => Object
    attribute :secondary_contact, :type => Object
    attribute :emergency_contact, :type => Object
    attribute :doctor, :type => Object

    if ActiveModel::VERSION::MAJOR < 4
      attr_accessible :id, :section_id, :first_name, :last_name,
                      :grouping_id, :grouping_leader,
                      :date_of_birth, :started_section, :finished_section, :joined_movement, :age,
                      :grouping_label, :grouping_leader_label, :gender,
                      :additional_information, :additional_information_labels,
                      :contact, :primary_contact, :secondary_contact, :emergency_contact, :doctor
    end

    unless ActiveModel::VERSION::MAJOR < 4
      validates_presence_of :grouping_label, :allow_blank => true
      validates_presence_of :grouping_leader_label, :allow_blank => true
      validates_presence_of :additional_information, :allow_blank => true
      validates_presence_of :additional_information_labels, :allow_blank => true
      validates_presence_of :finished_section, :allow_nil=>true
    end
    validates_numericality_of :id, :only_integer=>true, :greater_than=>0, :unless => Proc.new { |r| r.id.nil? }
    validates_numericality_of :section_id, :only_integer=>true, :greater_than=>0
    validates_numericality_of :grouping_id, :only_integer=>true, :greater_than_or_equal_to=>-2
    validates_numericality_of :grouping_leader, :only_integer=>true, :greater_than_or_equal_to=>0, :less_than_or_equal_to=>14, :allow_nil => true
    validates_presence_of :first_name
    validates_presence_of :last_name
    validates_presence_of :date_of_birth
    validates_presence_of :started_section
    validates_presence_of :joined_movement
    validates_format_of :age, :with => /\A[0-9]{1,3} \/ (?:0?[0-9]|1[012])\Z/, :message => 'age is not in the correct format (yy / mm)', :allow_blank => true
    validates_inclusion_of :gender, :in => [:male, :female, :other, :unspecified], :allow_nil => true
    validates :contact, :validity=>{allow_nil: true}
    validates :primary_contact, :validity=>{allow_nil: true}
    validates :secondary_contact, :validity=>{allow_nil: true}
    validates :emergency_contact, :validity=>{allow_nil: true}
    validates :doctor, :validity=>{allow_nil: true}


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
      key_key = 'column_id'   # the key in the data from OSM to use as the key in additional_information and labels hashes
      structure.each do |gid, group|
        columns = group['columns'] || []
        custom_labels[gid.to_i] = Hash[ columns.map.select{ |a| gid.eql?(GID_CUSTOM) || !CORE_FIELD_IDS.include?(a['column_id'].to_i) }.map{ |c| [c[key_key], c['label']] } ]
      end

      data.each do |item|
        item_data = Hash[ item['custom_data'].map{ |k,v| [k.to_i, v] } ]
        member_contact = item_data[GID_MEMBER_CONTACT].nil? ? nil : Hash[ item_data[GID_MEMBER_CONTACT].map{ |k,v| [k.to_i, v] }.select{ |k,v| CORE_FIELD_IDS.include?(k) } ]
        member_custom = item_data[GID_MEMBER_CONTACT].nil? ? DirtyHashy.new : DirtyHashy[ item_data[GID_MEMBER_CONTACT].select{ |k,v| !CORE_FIELD_IDS.include?(k.to_i) }.map{ |k,v| [k.to_i, v] } ]
        primary_contact = item_data[GID_PRIMARY_CONTACT].nil? ? nil : Hash[ item_data[GID_PRIMARY_CONTACT].map{ |k,v| [k.to_i, v] }.select{ |k,v| CORE_FIELD_IDS.include?(k) } ]
        primary_custom = item_data[GID_PRIMARY_CONTACT].nil? ? DirtyHashy.new : DirtyHashy[ item_data[GID_PRIMARY_CONTACT].select{ |k,v| !CORE_FIELD_IDS.include?(k.to_i) }.map{ |k,v| [k.to_i, v] } ]
        secondary_contact = item_data[GID_SECONDARY_CONTACT].nil? ? nil : Hash[ item_data[GID_SECONDARY_CONTACT].map{ |k,v| [k.to_i, v] }.select{ |k,v| CORE_FIELD_IDS.include?(k) } ]
        secondary_custom = item_data[GID_SECONDARY_CONTACT].nil? ? DirtyHashy.new : DirtyHashy[ item_data[GID_SECONDARY_CONTACT].select{ |k,v| !CORE_FIELD_IDS.include?(k.to_i) }.map{ |k,v| [k.to_i, v] } ]
        emergency_contact = item_data[GID_EMERGENCY_CONTACT].nil? ? nil : Hash[ item_data[GID_EMERGENCY_CONTACT].map{ |k,v| [k.to_i, v] }.select{ |k,v| CORE_FIELD_IDS.include?(k) } ]
        emergency_custom = item_data[GID_EMERGENCY_CONTACT].nil? ? DirtyHashy.new : DirtyHashy[ item_data[GID_EMERGENCY_CONTACT].select{ |k,v| !CORE_FIELD_IDS.include?(k.to_i) }.map{ |k,v| [k.to_i, v] } ]
        doctor_contact = item_data[GID_DOCTOR_CONTACT].nil? ? nil : Hash[ item_data[GID_DOCTOR_CONTACT].map{ |k,v| [k.to_i, v] }.select{ |k,v| CORE_FIELD_IDS.include?(k) } ]
        doctor_custom = item_data[GID_DOCTOR_CONTACT].nil? ? DirtyHashy.new : DirtyHashy[ item_data[GID_DOCTOR_CONTACT].select{ |k,v| !CORE_FIELD_IDS.include?(k.to_i) }.map{ |k,v| [k.to_i, v] } ]
        floating_data = item_data[GID_FLOATING].nil? ? {} : Hash[ item_data[GID_FLOATING].map{ |k,v| [k.to_i, v] }.select{ |k,v| CORE_FIELD_IDS.include?(k) } ]
        custom_data = item_data[GID_CUSTOM].nil? ? DirtyHashy.new : DirtyHashy[ item_data[GID_CUSTOM].map{ |k,v| [k.to_i, v] } ]

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
          :contact => member_contact.nil? ? nil : MemberContact.new(
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
            receive_phone_1: member_contact[CID_RECIEVE_PHONE_1].eql?('yes'),
            receive_phone_2: member_contact[CID_RECIEVE_PHONE_2].eql?('yes'),
            receive_email_1: member_contact[CID_RECIEVE_EMAIL_1].eql?('yes'),
            receive_email_2: member_contact[CID_RECIEVE_EMAIL_2].eql?('yes'),
            additional_information: member_custom,
            additional_information_labels: custom_labels[GID_MEMBER_CONTACT],
          ),
          :primary_contact => primary_contact.nil? ? nil : PrimaryContact.new(
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
            receive_phone_1: primary_contact[CID_RECIEVE_PHONE_1].eql?('yes'),
            receive_phone_2: primary_contact[CID_RECIEVE_PHONE_2].eql?('yes'),
            receive_email_1: primary_contact[CID_RECIEVE_EMAIL_1].eql?('yes'),
            receive_email_2: primary_contact[CID_RECIEVE_EMAIL_2].eql?('yes'),
            additional_information: primary_custom,
            additional_information_labels: custom_labels[GID_PRIMARY_CONTACT],
          ),
          :secondary_contact => secondary_contact.nil? ? nil : SecondaryContact.new(
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
            receive_phone_1: secondary_contact[CID_RECIEVE_PHONE_1].eql?('yes'),
            receive_phone_2: secondary_contact[CID_RECIEVE_PHONE_2].eql?('yes'),
            receive_email_1: secondary_contact[CID_RECIEVE_EMAIL_1].eql?('yes'),
            receive_email_2: secondary_contact[CID_RECIEVE_EMAIL_2].eql?('yes'),
            additional_information: secondary_custom,
            additional_information_labels: custom_labels[GID_SECONDARY_CONTACT],
          ),
          :emergency_contact => emergency_contact.nil? ? nil : EmergencyContact.new(
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
            additional_information: emergency_custom,
            additional_information_labels: custom_labels[GID_EMERGENCY_CONTACT],
          ),
          :doctor => doctor_contact.nil? ? nil : DoctorContact.new(
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
            additional_information: doctor_custom,
            additional_information_labels: custom_labels[GID_DOCTOR_CONTACT],
          ),
          additional_information: custom_data,
          additional_information_labels: custom_labels[GID_CUSTOM],
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
    # @return [Boolan, nil] whether the member was successfully added or not (nil is returned if the user was created but not with all the data)
    # @raise [Osm::ObjectIsInvalid] If the Member is invalid
    # @raise [Osm::Error] If the member already exists in OSM
    def create(api)
      raise Osm::Error, 'the member already exists in OSM' unless id.nil?
      raise Osm::ObjectIsInvalid, 'member is invalid' unless valid?
      require_ability_to(api, :write, :member, section_id)

      data = api.perform_query("users.php?action=newMember", {
        'firstname' => first_name,
        'lastname' => last_name,
        'dob' => date_of_birth.strftime(Osm::OSM_DATE_FORMAT),
        'started' => joined_movement.strftime(Osm::OSM_DATE_FORMAT),
        'startedsection' => started_section.strftime(Osm::OSM_DATE_FORMAT),
        'sectionid' => section_id,
      })

      if (data.is_a?(Hash) && (data['result'] == 'ok') && (data['scoutid'].to_i > 0))
        self.id = data['scoutid'].to_i
        # The cached members for the section will be out of date - remove them
        Osm::Term.get_for_section(api, section_id).each do |term|
          cache_delete(api, ['members', section_id, term.id])
        end
        # Now it's created we need to give OSM the rest of the data
        updated = update(api, true)
        return updated ? true : nil
      else
        return false
      end
    end

    # Update the member in OSM
    # @param [Osm::Api] api The api to use to make the request
    # @param [Boolean] force Whether to force updates (ie tell OSM every attribute changed even if we don't think it did)
    # @return [Boolean] whether the member was successfully updated or not
    # @raise [Osm::ObjectIsInvalid] If the Member is invalid
    def update(api, force=false)
      raise Osm::ObjectIsInvalid, 'member is invalid' unless valid?
      require_ability_to(api, :write, :member, section_id)

      updated = true

      # Do core attributes
      attribute_map = [
        ['first_name', 'firstname', first_name],
        ['last_name', 'lastname', last_name],
        ['grouping_id', 'patrolid', grouping_id],
        ['grouping_leader', 'patrolleader', grouping_leader],
        ['date_of_birth', 'dob', date_of_birth.strftime(Osm::OSM_DATE_FORMAT)],
        ['started_section', 'startedsection', started_section.strftime(Osm::OSM_DATE_FORMAT)],
        ['joined_movement', 'started', joined_movement.strftime(Osm::OSM_DATE_FORMAT)],
      ] # our name => OSM name
      attribute_map.select{ |attr,col,val| force || changed_attributes.include?(attr) }.each do |attr,col,val|
        data = api.perform_query("ext/members/contact/?action=update", {
          'scoutid' => self.id,
          'column' => col,
          'value' => val,
          'sectionid' => section_id,
        })
        updated = updated && data.is_a?(Hash) && data['ok'].eql?(true)
      end # each attr to update

      # Do 'floating' attributes
      if force || changed_attributes.include?('gender')
        new_value = {male: 'Male', female: 'Female', other: 'Other'}[gender] || 'Unspecified'
        data = api.perform_query("ext/customdata/?action=updateColumn&section_id=#{section_id}", {
          'associated_id' => self.id,
          'associated_type' => 'member',
          'value' => new_value,
          'column_id' => CID_GENDER,
          'group_id' => GID_FLOATING,
          'context' => 'members',
        })
        updated = updated && data.is_a?(Hash) && data['data'].is_a?(Hash) && data['data']['value'].eql?(new_value)
      end

      # Do custom attributes
      additional_information.keys.select{ |a| force || additional_information.changes.keys.include?(a) }.each do |attr|
        new_value = additional_information[attr]
        data = api.perform_query("ext/customdata/?action=updateColumn&section_id=#{section_id}", {
          'associated_id' => self.id,
          'associated_type' => 'member',
          'value' => new_value,
          'column_id' => attr,
          'group_id' => GID_CUSTOM,
          'context' => 'members',
        })
        updated = updated && data.is_a?(Hash) && data['data'].is_a?(Hash) && data['data']['value'].to_s.eql?(new_value.to_s)
      end # each attr to update

      # Do contacts
      updated = (contact.nil? || contact.update(api, self, force)) && updated
      updated = (primary_contact.nil? || primary_contact.update(api, self, force)) && updated
      updated = (secondary_contact.nil? || secondary_contact.update(api, self, force)) && updated
      updated = (emergency_contact.nil? ||emergency_contact.update(api, self, force)) && updated
      updated = (doctor.nil? || doctor.update(api, self, force)) && updated

      # Finish off
      if updated
        reset_changed_attributes
        additional_information.clean_up!
        # The cached columns for the members will be out of date - remove them
        Osm::Term.get_for_section(api, section_id).each do |term|
          Osm::Model.cache_delete(api, ['members', section_id, term.id])
        end
      end
      return updated
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
    # @param [String] seperator What to split the member's first name and last name with
    # @return [String] this scout's full name seperated by the optional seperator
    def name(seperator=' ')
      return [first_name, last_name].select{ |i| !i.blank? }.join(seperator)
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
    # @param date [Date] The date to check membership status for
    # @return true, false
    def current?(date=Date.today)
      return nil if started_section.nil? and finished_section.nil?
      if finished_section.nil?
        started_section <= date
      elsif started_section.nil?
        finished_section >= date
      else
        (started_section <= date) && (finished_section >= date)
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

      # Get an array of all emails for the contact in a format which includes their name
      # @return [Array<String>]
      def all_emails_with_name
        [email_1, email_2].select{ |e| !e.blank? }.map{ |e| "\"#{name}\" <#{e}>" }
      end

    end

    module EnableableEmailableContact
      include EmailableContact

      # Get an array of enabled emails for the contact
      # @return [Array<String>]
      def enabled_emails
        emails = []
        emails.push email_1 if receive_email_1
        emails.push email_2 if receive_email_2
        emails.select{ |e| !e.blank? }
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

    module EnableablePhoneableContact
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
      # @!attribute [rw] additional_information
      #   @return [DirtyHashy] the additional information (key is OSM's variable name, value is the data)
      # @!attribute [rw] additional_information_labels
      #   @return [DirtyHashy] the labels for the additional information (key is OSM's variable name, value is the label)

      attribute :first_name, :type => String
      attribute :last_name, :type => String
      attribute :address_1, :type => String
      attribute :address_2, :type => String
      attribute :address_3, :type => String
      attribute :address_4, :type => String
      attribute :postcode, :type => String
      attribute :phone_1, :type => String
      attribute :phone_2, :type => String
      attribute :additional_information, :type => Object, :default => DirtyHashy.new
      attribute :additional_information_labels, :type => Object, :default => DirtyHashy.new

      if ActiveModel::VERSION::MAJOR < 4
        attr_accessible :first_name, :last_name,
                        :address_1, :address_2, :address_3, :address_4,
                        :postcode, :phone_1, :phone_2,
                        :additional_information, :additional_information_labels
      end

      # @!method initialize
      #   Initialize a new Contact
      #   @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)

      # Get the full name
      # @param [String] seperator What to split the contact's first name and last name with
      # @return [String] this scout's full name seperated by the optional seperator
      def name(seperator=' ')
        return [first_name, last_name].select{ |i| !i.blank? }.join(seperator)
      end

      # Get an array of all phone numbers for the contact
      # @return [Array<String>]
      def all_phones
        [phone_1, phone_2].select{ |n| !n.blank? }.map{ |n| n.gsub(/[^\d\+]/, '') }
      end

      # Update the contact in OSM
      # @param [Osm::Api] api The api to use to make the request
      # @param [Osm::Member] section The member to update the contact for
      # @param [Boolean] force Whether to force updates (ie tell OSM every attribute changed even if we don't think it did)
      # @return [Boolean] whether the member was successfully updated or not
      # @raise [Osm::ObjectIsInvalid] If the Contact is invalid
      def update(api, member, force=false)
        raise Osm::ObjectIsInvalid, 'member is invalid' unless valid?
        require_ability_to(api, :write, :member, member.section_id)

        attribute_map = {
          'first_name' => 'data[firstname]',
          'last_name' => 'data[lastname]',
          'surgery' => 'data[surgery]',
          'address_1' => 'data[address1]',
          'address_2' => 'data[address2]',
          'address_3' => 'data[address3]',
          'address_4' => 'data[address4]',
          'postcode' => 'data[postcode]',
          'phone_1' => 'data[phone1]',
          'receive_phone_1' => 'data[phone1_sms]',
          'phone_2' => 'data[phone2]',
          'receive_phone_2' => 'data[phone2_sms]',
          'email_1' => 'data[email1]',
          'receive_email_1' => 'data[email1_leaders]',
          'email_2' => 'data[email2]',
          'receive_email_2' => 'data[email2_leaders]',
        } # our name => OSM name

        data = {}
        attributes.keys.select{ |a| !['additional_information', 'additional_information_labels'].include?(a) }.select{ |a| force || changed_attributes.include?(a) }.each do |attr|
          value = send(attr)
          value = 'yes' if value.eql?(true)
          data[attribute_map[attr]] = value
        end
        additional_information.keys.select{ |a| force || additional_information.changes.keys.include?(a) }.each do |attr|
          data["data[#{attr}]"] = additional_information[attr]
        end

        updated = true
        unless data.empty?
          result = api.perform_query("ext/customdata/?action=update&section_id=#{member.section_id}", {
            'associated_id' => member.id,
            'associated_type' => 'member',
            'context' => 'members',
            'group_id' => self.class::GROUP_ID,
          }.merge(data))
          updated = result.is_a?(Hash) && result['status'].eql?(true)
        end

        # Finish off
        if updated
          reset_changed_attributes
          additional_information.clean_up!
        end
        return updated
      end

    end


    class MemberContact < Osm::Member::Contact
      include EnableableEmailableContact
      include EnableablePhoneableContact

      GROUP_ID = Osm::Member::GID_MEMBER_CONTACT

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
      include EnableableEmailableContact
      include EnableablePhoneableContact

      GROUP_ID = Osm::Member::GID_PRIMARY_CONTACT

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

    class SecondaryContact < Osm::Member::PrimaryContact
      GROUP_ID = Osm::Member::GID_SECONDARY_CONTACT
    end # class SecondaryContact

    class EmergencyContact < Osm::Member::Contact
      include EmailableContact

      GROUP_ID = Osm::Member::GID_EMERGENCY_CONTACT

      # @!attribute [rw] email_1
      #   @return [String] the primary email address for the contact
      # @!attribute [rw] email_2
      #   @return [String] the secondary email address for the contact

      attribute :email_1, :type => String
      attribute :email_2, :type => String

      if ActiveModel::VERSION::MAJOR < 4
        attr_accessible :email_1, :email_2
      end

    end # class EmergencyContact


    class DoctorContact < Osm::Member::Contact
      GROUP_ID = Osm::Member::GID_DOCTOR_CONTACT

      # @!attribute [rw] surgery
      #   @return [String] the surgery name

      attribute :surgery, :type => String

      if ActiveModel::VERSION::MAJOR < 4
        attr_accessible :surgery
      end

    end # class DoctorContact

  end # Class Member

end # Module
