module Osm

  class Member < Osm::Model

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
    # @!attribute [rw] custom1
    #   @return [String] the custom1 data for the member
    # @!attribute [rw] custom2
    #   @return [String] the custom2 data for the member
    # @!attribute [rw] custom3
    #   @return [String] the custom3 data for the member
    # @!attribute [rw] custom4
    #   @return [String] the custom4 data for the member
    # @!attribute [rw] custom5
    #   @return [String] the custom5 data for the member
    # @!attribute [rw] custom6
    #   @return [String] the custom6 data for the member
    # @!attribute [rw] custom7
    #   @return [String] the custom7 data for the member
    # @!attribute [rw] custom8
    #   @return [String] the custom8 data for the member
    # @!attribute [rw] custom9
    #   @return [String] the custom9 data for the member
    # @!attribute [rw] grouping_id
    #   @return [Fixnum] the grouping within the section that the member belongs to
    # @!attribute [rw] grouping_leader
    #   @return [Fixnum] whether the member is the grouping leader (0=no, 1=seconder/APL, 2=sixer/PL)
    # @!attribute [rw] joined
    #   @return [Date] when the member joined the section
    # @!attribute [rw] age
    #   @return [String] the member's current age (yy/mm)
    # @!attribute [rw] joined_years
    #   @return [Fixnum] how many years the member has been in Scouting
    # @!attribute [rw] has_photo
    #   @return [Boolean] whether the scout has a photo in OSM

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
    attribute :custom1, :type => String, :default => ''
    attribute :custom2, :type => String, :default => ''
    attribute :custom3, :type => String, :default => ''
    attribute :custom4, :type => String, :default => ''
    attribute :custom5, :type => String, :default => ''
    attribute :custom6, :type => String, :default => ''
    attribute :custom7, :type => String, :default => ''
    attribute :custom8, :type => String, :default => ''
    attribute :custom9, :type => String, :default => ''
    attribute :grouping_id, :type => Integer
    attribute :grouping_leader, :type => Integer
    attribute :joined, :type => Date
    attribute :age, :type => String
    attribute :joined_years, :type => Integer
    attribute :has_photo, :type => Boolean, :default => false

    attr_accessible :id, :section_id, :type, :first_name, :last_name, :email1, :email2, :email3, :email4,
                    :phone1, :phone2, :phone3, :phone4, :address, :address2, :date_of_birth, :started,
                    :joining_in_years, :parents, :notes, :medical, :religion, :school, :ethnicity, :subs,
                    :custom1, :custom2, :custom3, :custom4, :custom5, :custom6, :custom7, :custom8, :custom9,
                    :grouping_id, :grouping_leader, :joined, :age, :joined_years,
                    :has_photo

    validates_numericality_of :id, :only_integer=>true, :greater_than=>0, :unless => Proc.new { |r| r.id.nil? }
    validates_numericality_of :section_id, :only_integer=>true, :greater_than=>0
    validates_numericality_of :grouping_id, :only_integer=>true, :greater_than_or_equal_to=>-2
    validates_numericality_of :grouping_leader, :only_integer=>true, :greater_than_or_equal_to=>0, :less_than_or_equal_to=>2
    validates_numericality_of :joined_years, :only_integer=>true, :greater_than_or_equal_to=>-1, :allow_nil=>true
    validates_numericality_of :joining_in_years, :only_integer=>true, :greater_than_or_equal_to=>-1, :allow_nil=>true
    validates_presence_of :first_name
    validates_presence_of :last_name
    validates_presence_of :date_of_birth
    validates_presence_of :started
    validates_presence_of :joined
    validates_format_of :age, :with => /\A[0-9]{2}\/(0[0-9]|1[012])\Z/, :message => 'age is not in the correct format (yy/mm)', :allow_blank => true
    validates_inclusion_of :has_photo, :in => [true, false]


    # Get members for a section
    # @param [Osm::Api] api The api to use to make the request
    # @param [Osm::Section, Fixnum, #to_i] section The section (or its ID) to get the members for
    # @param [Osm::Term, Fixnum, #to_i, nil] term The term (or its ID) to get the members for, passing nil causes the current term to be used
    # @!macro options_get
    # @return [Array<Osm::Member>]
    def self.get_for_section(api, section, term=nil, options={})
      require_ability_to(api, :read, :member, section, options)
      section = Osm::Section.get(api, section) if section.is_a?(Fixnum)
      term = -1 if section.waiting?
      term_id = term.nil? ? Osm::Term.get_current_term_for_section(api, section).id : term.to_i
      cache_key = ['members', section.id, term_id]

      if !options[:no_cache] && cache_exist?(api, cache_key)
        return cache_read(api, cache_key)
      end

      data = api.perform_query("users.php?action=getUserDetails&sectionid=#{section.id}&termid=#{term_id}")
      summary_data = api.perform_query("ext/members/contact/?action=getListOfMembers&sort=patrolid&sectionid=#{section.id}&termid=#{term_id}&section=#{section.type}") || {}

      summary_data = summary_data['items'] || []
      summary_data = Hash[summary_data.map { |i| [i['scoutid'].to_i, i] }]

      result = Array.new
      data['items'].each do |item|
        id = Osm::to_i_or_nil(item['scoutid'])
        result.push Osm::Member.new(
          :section_id => section.id,
          :id => id,
          :type => item['type'],
          :first_name => item['firstname'],
          :last_name => item['lastname'],
          :email1 => item['email1'],
          :email2 => item['email2'],
          :email3 => item['email3'],
          :email4 => item['email4'],
          :phone1 => item['phone1'],
          :phone2 => item['phone2'],
          :phone3 => item['phone3'],
          :phone4 => item['phone4'],
          :address => item['address'],
          :address2 => item['address2'],
          :date_of_birth => Osm::parse_date(item['dob'], :ignore_epoch => true),
          :started => Osm::parse_date(item['started']),
          :joining_in_years => item['joining_in_yrs'].to_i,
          :parents => item['parents'],
          :notes => item['notes'],
          :medical => item['medical'],
          :religion => item['religion'],
          :school => item['school'],
          :ethnicity => item['ethnicity'],
          :subs => item['subs'],
          :custom1 => item['custom1'],
          :custom2 => item['custom2'],
          :custom3 => item['custom3'],
          :custom4 => item['custom4'],
          :custom5 => item['custom5'],
          :custom6 => item['custom6'],
          :custom7 => item['custom7'],
          :custom8 => item['custom8'],
          :custom9 => item['custom9'],
          :grouping_id => Osm::to_i_or_nil(item['patrolid']),
          :grouping_leader => Osm::to_i_or_nil(item['patrolleader']),
          :joined => Osm::parse_date(item['joined']),
          :age => item['age'].gsub(' ', ''),
          :joined_years => item['yrs'].to_i,
          :has_photo => summary_data[id]['pic']
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
    # @param [Boolean] black_and_white Whether you want the photo in blank and white
    # @!macro options_get
    # @raise [Osm:Error] if the member has no photo or doesn't exist in OSM
    # @return the photo of the member
    def get_photo(api, black_and_white=false, options={})
      raise Osm::ObjectIsInvalid, 'member is invalid' unless valid?
      require_ability_to(api, :read, :member, section_id)
      raise Osm::Error, 'the member does not already exist in OSM' if id.nil?
      raise Osm::Error, "the member doesn't have a photo in OSM" unless has_photo

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
    # @param [Symbol] link_to The page in My.SCOUT to link to (:payments, :events, :programme, :badges, :notice or :details)
    # @param [#to_i] item_id Allows you to link to a specfic item (only for :events)
    # @return [String] the URL for this member's My.SCOUT
    # @raise [Osm::ObjectIsInvalid] If the Member is invalid
    # @raise [Osm::ArgumentIsInvalid] If link_to is not an allowed Symbol
    # @raise [Osm::Error] if the member does not already exist in OSM or the member's My.SCOUT key could not be retrieved from OSM
    def myscout_link(api, link_to=:badges, item_id=nil)
      raise Osm::ObjectIsInvalid, 'member is invalid' unless valid?
      require_ability_to(api, :read, :member, section_id)
      raise Osm::Error, 'the member does not already exist in OSM' if id.nil?
      raise Osm::ArgumentIsInvalid, 'link_to is invalid' unless [:payments, :events, :programme, :badges, :notice, :details].include?(link_to)

      link = "#{api.base_url}/parents/#{link_to}.php?sc=#{self.id}&se=#{section_id}&c=#{myscout_link_key(api)}"
      link += "&e=#{item_id.to_i}" if item_id && link_to.eql?(:events)
      return link
    end

    # Compare Activity based on section_id, grouping_id, grouping_leader (descending), last_name then first_name
    def <=>(another)
      result = self.section_id <=> another.try(:section_id)
      result = self.grouping_id <=> another.try(:grouping_id) if result == 0
      result = -(self.grouping_leader <=> another.try(:grouping_leader)) if result == 0
      result = self.last_name <=> another.try(:last_name) if result == 0
      result = self.first_name <=> another.try(:first_name) if result == 0
      return result
    end

  end # Class Member

end # Module
