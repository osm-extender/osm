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
    #   @return [Integer] the id for the member
    # @!attribute [rw] section_id
    #   @return [Integer] the section the member belongs to
    # @!attribute [rw] first_name
    #   @return [String] the member's first name
    # @!attribute [rw] last_name
    #   @return [String] the member's last name
    # @!attribute [rw] grouping_id
    #   @return [Integer] the ID of the grouping within the section that the member belongs to
    # @!attribute [rw] grouping_label
    #   @return [String] the name of the grouping within the section that the member belongs to
    # @!attribute [rw] grouping_leader
    #   @return [Integer] whether the member is the grouping leader (0=no, 1=seconder/APL, 2=sixer/PL, 3=senior PL)
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

    attribute :id, type: Integer
    attribute :section_id, type: Integer
    attribute :first_name, type: String
    attribute :last_name, type: String
    attribute :grouping_id, type: Integer
    attribute :grouping_label, type: String
    attribute :grouping_leader, type: Integer
    attribute :grouping_leader_label, type: String
    attribute :age, type: String
    attribute :date_of_birth, type: Date
    attribute :started_section, type: Date
    attribute :finished_section, type: Date
    attribute :joined_movement, type: Date
    attribute :gender, type: Object
    attribute :additional_information, type: Object, default: DirtyHashy.new
    attribute :additional_information_labels, type: Object, default: DirtyHashy.new
    attribute :contact, type: Object
    attribute :primary_contact, type: Object
    attribute :secondary_contact, type: Object
    attribute :emergency_contact, type: Object
    attribute :doctor, type: Object

    validates_numericality_of :id, only_integer:true, greater_than:0, unless: Proc.new { |r| r.id.nil? }
    validates_numericality_of :section_id, only_integer:true, greater_than:0
    validates_numericality_of :grouping_id, only_integer:true, greater_than_or_equal_to:-2
    validates_numericality_of :grouping_leader, only_integer:true, greater_than_or_equal_to:0, less_than_or_equal_to:14, allow_nil: true
    validates_presence_of :first_name
    validates_presence_of :last_name
    validates_presence_of :date_of_birth
    validates_presence_of :started_section
    validates_presence_of :joined_movement
    validates_format_of :age, with: /\A[0-9]{1,3} \/ (?:0?[0-9]|1[012])\Z/, message: 'age is not in the correct format (yy / mm)', allow_blank: true
    validates_inclusion_of :gender, in: [:male, :female, :other, :unspecified], allow_nil: true
    validates :contact, validity:{allow_nil: true}
    validates :primary_contact, validity:{allow_nil: true}
    validates :secondary_contact, validity:{allow_nil: true}
    validates :emergency_contact, validity:{allow_nil: true}
    validates :doctor, validity:{allow_nil: true}


    # Get members for a section
    # @param api [Osm::Api] The api to use to make the request
    # @param section [Osm::Section, Integer, #to_i] The section (or its ID) to get the members for
    # @param term [Osm::Term, Integer, #to_i, nil] The term (or its ID) to get the members for, passing nil causes the current term to be used
    # @!macro options_get
    # @return [Array<Osm::Member>]
    def self.get_for_section(api:, section:, term: nil, no_read_cache: false)
      require_ability_to(api: api, to: :read, on: :member, section: section, no_read_cache: no_read_cache)
      if term.nil?
        section = Osm::Section.get(api: api, id: section) if section.is_a?(Integer)
        term = section.waiting? ? -1 : Osm::Term.get_current_term_for_section(api: api, section: section)
      end
      cache_key = ['members', section.to_i, term.to_i]

      cache_fetch(api: api, key: cache_key, no_read_cache: no_read_cache) do
        api_response = api.post_query('ext/members/contact/grid/?action=getMembers', post_data: {
          'section_id' => section.to_i,
          'term_id' => term.to_i,
        })

        data = api_response['data'].is_a?(Hash) ? api_response['data'].values : []
        structure = (api_response['meta'] || {})['structure'] || []
        structure = structure.map{ |i| [i['group_id'].to_i, i ] }.to_h # Make a hash of identifier to group data hash

        custom_labels = {}
        key_key = 'column_id'   # the key in the data from OSM to use as the key in additional_information and labels hashes
        structure.each do |gid, group|
          columns = group['columns'] || []
          custom_labels[gid.to_i] = columns.map.select{ |a| gid.eql?(GID_CUSTOM) || !CORE_FIELD_IDS.include?(a['column_id'].to_i) }.map{ |c| [c[key_key], c['label']] }.to_h
        end

        data.map do |item|
          item_data = item['custom_data'].map{ |k,v| [k.to_i, v] }.to_h
          member_contact = item_data[GID_MEMBER_CONTACT].nil? ? nil : item_data[GID_MEMBER_CONTACT].map{ |k,v| [k.to_i, v] }.select{ |k,v| CORE_FIELD_IDS.include?(k) }.to_h
          member_custom = item_data[GID_MEMBER_CONTACT].nil? ? DirtyHashy.new : DirtyHashy[ item_data[GID_MEMBER_CONTACT].select{ |k,v| !CORE_FIELD_IDS.include?(k.to_i) }.map{ |k,v| [k.to_i, v] } ]
          primary_contact = item_data[GID_PRIMARY_CONTACT].nil? ? nil : item_data[GID_PRIMARY_CONTACT].map{ |k,v| [k.to_i, v] }.select{ |k,v| CORE_FIELD_IDS.include?(k) }.to_h
          primary_custom = item_data[GID_PRIMARY_CONTACT].nil? ? DirtyHashy.new : DirtyHashy[ item_data[GID_PRIMARY_CONTACT].select{ |k,v| !CORE_FIELD_IDS.include?(k.to_i) }.map{ |k,v| [k.to_i, v] } ]
          secondary_contact = item_data[GID_SECONDARY_CONTACT].nil? ? nil : item_data[GID_SECONDARY_CONTACT].map{ |k,v| [k.to_i, v] }.select{ |k,v| CORE_FIELD_IDS.include?(k) }.to_h
          secondary_custom = item_data[GID_SECONDARY_CONTACT].nil? ? DirtyHashy.new : DirtyHashy[ item_data[GID_SECONDARY_CONTACT].select{ |k,v| !CORE_FIELD_IDS.include?(k.to_i) }.map{ |k,v| [k.to_i, v] } ]
          emergency_contact = item_data[GID_EMERGENCY_CONTACT].nil? ? nil : item_data[GID_EMERGENCY_CONTACT].map{ |k,v| [k.to_i, v] }.select{ |k,v| CORE_FIELD_IDS.include?(k) }.to_h
          emergency_custom = item_data[GID_EMERGENCY_CONTACT].nil? ? DirtyHashy.new : DirtyHashy[ item_data[GID_EMERGENCY_CONTACT].select{ |k,v| !CORE_FIELD_IDS.include?(k.to_i) }.map{ |k,v| [k.to_i, v] } ]
          doctor_contact = item_data[GID_DOCTOR_CONTACT].nil? ? nil : item_data[GID_DOCTOR_CONTACT].map{ |k,v| [k.to_i, v] }.select{ |k,v| CORE_FIELD_IDS.include?(k) }.to_h
          doctor_custom = item_data[GID_DOCTOR_CONTACT].nil? ? DirtyHashy.new : DirtyHashy[ item_data[GID_DOCTOR_CONTACT].select{ |k,v| !CORE_FIELD_IDS.include?(k.to_i) }.map{ |k,v| [k.to_i, v] } ]
          floating_data = item_data[GID_FLOATING].nil? ? {} : item_data[GID_FLOATING].map{ |k,v| [k.to_i, v] }.select{ |k,v| CORE_FIELD_IDS.include?(k) }.to_h
          custom_data = item_data[GID_CUSTOM].nil? ? DirtyHashy.new : DirtyHashy[ item_data[GID_CUSTOM].map{ |k,v| [k.to_i, v] } ]

          new(
            id: Osm::to_i_or_nil(item['member_id']),
            section_id: Osm::to_i_or_nil(item['section_id']),
            first_name: item['first_name'],
            last_name: item['last_name'],
            grouping_id: Osm::to_i_or_nil(item['patrol_id']),
            grouping_label: item['patrol'],
            grouping_leader: item['patrol_role_level'],
            grouping_leader_label: item['patrol_role_level_label'],
            age: item['age'],
            date_of_birth: Osm::parse_date(item['date_of_birth'], ignore_epoch: true),
            started_section: Osm::parse_date(item['joined']),
            finished_section: Osm::parse_date(item['end_date']),
            joined_movement: Osm::parse_date(item['started']),
            gender: {'male'=>:male, 'female'=>:female, 'other'=>:other, 'unspecified'=>:unspecified}[(floating_data[CID_GENDER] || '').downcase],
            contact: member_contact.nil? ? nil : MemberContact.new(
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
              additional_information: member_custom,
              additional_information_labels: custom_labels[GID_MEMBER_CONTACT],
            ),
            primary_contact: primary_contact.nil? ? nil : PrimaryContact.new(
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
              additional_information: primary_custom,
              additional_information_labels: custom_labels[GID_PRIMARY_CONTACT],
            ),
            secondary_contact: secondary_contact.nil? ? nil : SecondaryContact.new(
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
              additional_information: secondary_custom,
              additional_information_labels: custom_labels[GID_SECONDARY_CONTACT],
            ),
            emergency_contact: emergency_contact.nil? ? nil : EmergencyContact.new(
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
            doctor: doctor_contact.nil? ? nil : DoctorContact.new(
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
        end # data.map
      end # cache fetch
    end


    # @!method initialize
    #   Initialize a new Member
    #   @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)


    # Create the user in OSM
    # @param api [Osm::Api] The api to use to make the request
    # @return [Boolan, nil] whether the member was successfully added or not (nil is returned if the user was created but not with all the data)
    # @raise [Osm::ObjectIsInvalid] If the Member is invalid
    # @raise [Osm::Error] If the member already exists in OSM
    def create(api)
      fail Osm::Error, 'the member already exists in OSM' unless id.nil?
      fail Osm::ObjectIsInvalid, 'member is invalid' unless valid?
      require_ability_to(api, :write, :member, section_id)

      data = api.post_query("users.php?action=newMember", post_data: {
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
        Osm::Term.get_for_section(api: api, section: section_id).each do |term|
          cache_delete(api: api, key: ['members', section_id, term.id])
        end
        # Now it's created we need to give OSM the rest of the data
        updated = update(api, true)
        return updated ? true : nil
      else
        return false
      end
    end

    # Update the member in OSM
    # @param api [Osm::Api] The api to use to make the request
    # @param force true, false Whether to force updates (ie tell OSM every attribute changed even if we don't think it did)
    # @return true, false whether the member was successfully updated or not
    # @raise [Osm::ObjectIsInvalid] If the Member is invalid
    def update(api, force: false)
      fail Osm::ObjectIsInvalid, 'member is invalid' unless valid?
      require_ability_to(api: api, to: :write, on: :member, section: section_id)

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
        data = api.post_query("ext/members/contact/?action=update", post_data: {
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
        data = api.post_query("ext/customdata/?action=updateColumn&section_id=#{section_id}", post_data: {
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
        data = api.post_query("ext/customdata/?action=updateColumn&section_id=#{section_id}", post_data: {
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
      updated = (contact.nil? || contact.update(api: api, member: self, force: force)) && updated
      updated = (primary_contact.nil? || primary_contact.update(api: api, member: self, force: force)) && updated
      updated = (secondary_contact.nil? || secondary_contact.update(api: api, member: self, force: force)) && updated
      updated = (emergency_contact.nil? ||emergency_contact.update(api: api, member: self, force: force)) && updated
      updated = (doctor.nil? || doctor.update(api: api, member: self, force: force)) && updated

      # Finish off
      if updated
        reset_changed_attributes
        additional_information.clean_up!
        # The cached columns for the members will be out of date - remove them
        Osm::Term.get_for_section(api: api, section: section_id).each do |term|
          cache_delete(api: api, key: ['members', section_id, term.id])
        end
      end
      return updated
    end

    # Get the years element of this scout's age
    # @return [Integer] the number of years this scout has been alive
    def age_years
      return age[0..1].to_i
    end

    # Get the months element of this scout's age
    # @return [Integer] the number of months since this scout's last birthday
    def age_months
      return age[-2..-1].to_i
    end

    # Get the full name
    # @param seperatpr [String] What to split the member's first name and last name with
    # @return [String] this scout's full name seperated by the optional seperator
    def name(seperator=' ')
      return [first_name, last_name].select{ |i| !i.blank? }.join(seperator)
    end

    # Check if the member is in the leaders grouping
    # @return true, false
    def leader?
      grouping_id.eql?(-2)
    end

    # Check if the member is in a non-leaders grouping
    # @return true, false
    def youth?
      grouping_id > 0
    end

    # Check if the member is male
    # @return true, false
    def male?
      gender.eql?(:male)
    end

    # Check if the member is male
    # @return true, false
    def female?
      gender.eql?(:female)
    end

    # Check if this is a current member of the section they were retrieved for
    # @param date [Date] The date to check membership status for
    # @return true, false
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
        [:contact, :primary_contact, :secondary_contact].each do |contact|
          contact = send(contact)
          items.push *contact.send(meth) unless contact.nil?
        end
        return items
      end
    end

    # Get the Key to use in My.SCOUT links for this member
    # @param api [Osm::Api] The api to use to make the request
    # @return [String] the key
    # @raise [Osm::ObjectIsInvalid] If the Member is invalid
    # @raise [Osm::Error] if the member does not already exist in OSM or the member's My.SCOUT key could not be retrieved from OSM
    def myscout_link_key(api)
      fail Osm::ObjectIsInvalid, 'member is invalid' unless valid?
      require_ability_to(api: api, to: :read, on: :member, section: section_id)
      fail Osm::Error, 'the member does not already exist in OSM' if id.nil?

      if @myscout_link_key.nil?
        data = api.post_query("api.php?action=getMyScoutKey&sectionid=#{section_id}&scoutid=#{self.id}")
        fail Osm::Error, 'Could not retrieve the key for the link from OSM' unless data['ok']
        @myscout_link_key = data['key']
      end

      return @myscout_link_key
    end

    # Get the member's photo
    # @param api [Osm::Api] The api to use to make the request
    # @param black_and_white true, false Whether you want the photo in blank and white (defaults to false unless the member is not active)
    # @!macro options_get
    # @raise [Osm:Error] if the member doesn't exist in OSM
    # @return the photo of the member
    def get_photo(api, black_and_white: !current?, no_read_cache: false)
      fail Osm::ObjectIsInvalid, 'member is invalid' unless valid?
      require_ability_to(api, :read, :member, section_id)
      fail Osm::Error, 'the member does not already exist in OSM' if id.nil?

      cache_key = ['member_photo', self.id, black_and_white]
      cache_fetch(api: api, key: cache_key, no_read_cache: no_read_cache) do
        api.post_query("ext/members/contact/images/member.php?sectionid=#{section_id}&scoutid=#{self.id}&bw=#{black_and_white}")
      end
    end

    # Get the My.SCOUT link for this member
    # @param api [Osm::Api] The api to use to make the request
    # @param link_to [Symbol] The page in My.SCOUT to link to (:payments, :events, :programme, :badges, :notice, :details, :census or :giftaid)
    # @param item_id [#to_i] Allows you to link to a specfic item (only for :events)
    # @return [String] the URL for this member's My.SCOUT
    # @raise [Osm::ObjectIsInvalid] If the Member is invalid
    # @raise [Osm::ArgumentIsInvalid] If link_to is not an allowed Symbol
    # @raise [Osm::Error] if the member does not already exist in OSM or the member's My.SCOUT key could not be retrieved from OSM
    def myscout_link(api, link_to: :badges, item_id: nil)
      fail Osm::ObjectIsInvalid, 'member is invalid' unless valid?
      require_ability_to(api: api, to: :read, on: :member, section: section_id)
      fail Osm::Error, 'the member does not already exist in OSM' if id.nil?
      fail Osm::ArgumentIsInvalid, 'link_to is invalid' unless [:payments, :events, :programme, :badges, :notice, :details, :census, :giftaid].include?(link_to)

      link = "#{Osm::Api::BASE_URLS[api.site]}/parents/#{link_to}.php?sc=#{self.id}&se=#{section_id}&c=#{myscout_link_key(api)}"
      link += "&e=#{item_id.to_i}" if item_id && link_to.eql?(:events)
      return link
    end

    private def sort_by
      ['section_id', 'grouping_id', '-grouping_leader', 'last_name', 'first_name']
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

      attribute :first_name, type: String
      attribute :last_name, type: String
      attribute :address_1, type: String
      attribute :address_2, type: String
      attribute :address_3, type: String
      attribute :address_4, type: String
      attribute :postcode, type: String
      attribute :phone_1, type: String
      attribute :phone_2, type: String
      attribute :additional_information, type: Object, default: DirtyHashy.new
      attribute :additional_information_labels, type: Object, default: DirtyHashy.new

      # @!method initialize
      #   Initialize a new Contact
      #   @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)

      # Get the full name
      # @param seperator [String] What to split the contact's first name and last name with
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
      # @param api [Osm::Api] The api to use to make the request
      # @param section [Osm::Member] The member to update the contact for
      # @param force true, false Whether to force updates (ie tell OSM every attribute changed even if we don't think it did)
      # @return true, false whether the member was successfully updated or not
      # @raise [Osm::ObjectIsInvalid] If the Contact is invalid
      def update(api:, member:, force: false)
        fail Osm::ObjectIsInvalid, 'member is invalid' unless valid?
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
          result = api.post_query("ext/customdata/?action=update&section_id=#{member.section_id}", post_data: {
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
      #   @return true, false whether the member should receive emails from leaders on their primary email address
      # @!attribute [rw] receive_email_2
      #   @return true, false whether the member should receive emails from leaders on their secondary email address
      # @!attribute [rw] receive_phone_1
      #   @return true, false whether the member should receive SMSs from leaders on their primary phone number
      # @!attribute [rw] receive_phone_2
      #   @return true, false whether the member should receive SMSs from leaders on their secondary phone number

      attribute :email_1, type: String
      attribute :receive_email_1, type: Boolean, default: false
      attribute :email_2, type: String
      attribute :receive_email_2, type: Boolean, default: false
      attribute :receive_phone_1, type: Boolean, default: false
      attribute :receive_phone_2, type: Boolean, default: false

      validates_inclusion_of :receive_email_1, in: [true, false]
      validates_inclusion_of :receive_email_2, in: [true, false]
      validates_inclusion_of :receive_phone_1, in: [true, false]
      validates_inclusion_of :receive_phone_2, in: [true, false]
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
      #   @return true, false whether the contact should receive emails from leaders on their primary email address
      # @!attribute [rw] receive_email_2
      #   @return true, false whether the contact should receive emails from leaders on their secondary email address
      # @!attribute [rw] receive_phone_1
      #   @return true, false whether the contact should receive SMSs from leaders on their primary phone number
      # @!attribute [rw] receive_phone_2
      #   @return true, false whether the contact should receive SMSs from leaders on their secondary phone number

      attribute :email_1, type: String
      attribute :receive_email_1, type: Boolean, default: false
      attribute :email_2, type: String
      attribute :receive_email_2, type: Boolean, default: false
      attribute :receive_phone_1, type: Boolean, default: false
      attribute :receive_phone_2, type: Boolean, default: false

      validates_inclusion_of :receive_email_1, in: [true, false]
      validates_inclusion_of :receive_email_2, in: [true, false]
      validates_inclusion_of :receive_phone_1, in: [true, false]
      validates_inclusion_of :receive_phone_2, in: [true, false]
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

      attribute :email_1, type: String
      attribute :email_2, type: String

    end # class EmergencyContact


    class DoctorContact < Osm::Member::Contact
      GROUP_ID = Osm::Member::GID_DOCTOR_CONTACT

      # @!attribute [rw] surgery
      #   @return [String] the surgery name

      attribute :surgery, type: String

    end # class DoctorContact

  end # Class Member

end # Module
