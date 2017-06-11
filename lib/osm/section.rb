module Osm

  class Section < Osm::Model
    # @!attribute [rw] id
    #   @return [Integer] the id for the section
    # @!attribute [rw] name
    #   @return [String] the section name
    # @!attribute [rw] group_id
    #   @return [Integer] the id for the group
    # @!attribute [rw] group_name
    #   @return [String] the group name
    # @!attribute [rw] subscription_level
    #   @return [Integer] what subscription the section has to OSM (1-bronze, 2-silver, 3-gold, 4-gold+)
    # @!attribute [rw] subscription_expires
    #   @return [Date] when the section's subscription to OSM expires
    # @!attribute [rw] type
    #   @return [Symbol] the section type (:beavers, :cubs, :scouts, :exporers, :network, :adults, :waiting, :unknown)
    # @!attribute [rw] flexi_records
    #   @return [Array<FlexiRecord>] list of the extra records the section has
    # @!attribute [rw] gocardless
    #   @return true, false does the section use gocardless
    # @!attribute [rw] myscout_events_expires
    #   @return [Date] when the subscription to Events in My.SCOUT expires
    # @!attribute [rw] myscout_badges_expires
    #   @return [Date] when the subscription to Badges in My.SCOUT expires
    # @!attribute [rw] myscout_programme_expires
    #   @return [Date] when the subscription to Badges in My.SCOUT expires
    # @!attribute [rw] myscout_events_expires
    #   @return [Date] when the subscription to Events in My.SCOUT expires
    # @!attribute [rw] myscout_details_expires
    #   @return true, false whether the section uses the Personal Details part of My.SCOUT
    # @!attribute [rw] myscout_badges
    #   @return true, false whether the section uses the Badges part of My.SCOUT
    # @!attribute [rw] myscout_programme
    #   @return true, false whether the section uses the Programme part of My.SCOUT
    # @!attribute [rw] myscout_payments
    #   @return true, false whether the section uses the Payments part of My.SCOUT
    # @!attribute [rw] myscout_details
    #   @return true, false whether the section uses the Personal Details part of My.SCOUT
    # @!attribute [rw] myscout_emails
    #   @return [Hash of Symbol to Boolean] which email addresses are linked to MyScout for each Member
    # @!attribute [rw] myscout_email_address_from
    #   @return [String] which email address to send My.SCOUT emails as coming from
    # @!attribute [rw] myscout_email_address_copy
    #   @return [String] which email address to send copys of My.SCOUT emails to
    # @!attribute [rw] myscout_badges_partial
    #   @return true, false Wether parents can see partially completed badges
    # @!attribute [rw] myscout_programme_summary
    #   @return true, false Wether parents can see summary of programme items
    # @!attribute [rw] myscout_programme_times
    #   @return true, false Whether parents can see times of programme items
    # @!attribute [rw] myscout_programme_show
    #   @return [Integer] How many programme itemms parents can see (the next 5, 10, 15, 20 meetings, -1 (whole term), 0 (remaining this term) or -2 (all future))
    # @!attribute [rw] myscout_event_reminder_count
    #   @return [Integer] How many event reminders to send to parents who haven't responded
    # @!attribute [rw] myscout_event_reminder_frequency
    #   @return [Integer] How many days to leave between event reminder emails
    # @!attribute [rw] myscout_payment_reminder_count
    #   @return [Integer] How many payment reminders to send to parents who haven't paid yet
    # @!attribute [rw] myscout_payment_reminder_frequency
    #   @return [Integer] How many days to leave between payment reminder emails
    # @!attribute [rw] myscout_details_email_changes_to
    #   @return [String] email address to send changes to personal details made through My.SCOUT to


    attribute :id, type: Integer
    attribute :name, type: String
    attribute :group_id, type: Integer
    attribute :group_name, type: String
    attribute :subscription_level, default: 1
    attribute :subscription_expires, type: Date
    attribute :type, default: :unknown
    attribute :flexi_records, default: []
    attribute :gocardless, type: Boolean
    attribute :myscout_events_expires, type: Date
    attribute :myscout_badges_expires, type: Date
    attribute :myscout_programme_expires, type: Date
    attribute :myscout_details_expires, type: Date
    attribute :myscout_events, type: Boolean
    attribute :myscout_badges, type: Boolean
    attribute :myscout_programme, type: Boolean
    attribute :myscout_payments, type: Boolean
    attribute :myscout_details, type: Boolean
    attribute :myscout_emails, default: {}
    attribute :myscout_email_address_from, type: String, default: ''
    attribute :myscout_email_address_copy, type: String, default: ''
    attribute :myscout_badges_partial, type: Boolean
    attribute :myscout_programme_summary, type: Boolean
    attribute :myscout_programme_times, type: Boolean
    attribute :myscout_programme_show, type: Integer, default: 0
    attribute :myscout_event_reminder_count, type: Integer
    attribute :myscout_event_reminder_frequency, type: Integer
    attribute :myscout_payment_reminder_count, type: Integer
    attribute :myscout_payment_reminder_frequency, type: Integer
    attribute :myscout_details_email_changes_to, type: String, default: ''

    validates_numericality_of :id, only_integer: true, greater_than: 0, allow_nil: true
    validates_numericality_of :group_id, only_integer: true, greater_than: 0, allow_nil: true
    validates_numericality_of :myscout_event_reminder_count, only_integer: true, greater_than_or_equal_to: -1
    validates_numericality_of :myscout_event_reminder_frequency, only_integer: true, greater_than_or_equal_to: -1
    validates_numericality_of :myscout_payment_reminder_count, only_integer: true, greater_than_or_equal_to: -1
    validates_numericality_of :myscout_payment_reminder_frequency, only_integer: true, greater_than_or_equal_to: -1
    validates_presence_of :name
    validates_presence_of :group_name
    validates_presence_of :subscription_level
    validates_presence_of :subscription_expires
    validates_presence_of :type
#    validates_presence_of :flexi_records, unless: Proc.new { |a| a.flexi_records == [] }

    validates_inclusion_of :subscription_level, in: (1..3), message: 'is not a valid subscription level'
    validates_inclusion_of :gocardless, in: [true, false]
    validates_inclusion_of :myscout_events, in: [true, false]
    validates_inclusion_of :myscout_badges, in: [true, false]
    validates_inclusion_of :myscout_programme, in: [true, false]
    validates_inclusion_of :myscout_payments, in: [true, false]
    validates_inclusion_of :myscout_details, in: [true, false]
    validates_inclusion_of :myscout_badges_partial, in: [true, false]
    validates_inclusion_of :myscout_programme_summary, in: [true, false]
    validates_inclusion_of :myscout_programme_times, in: [true, false]
    validates_inclusion_of :myscout_programme_show, in: [-2, -1, 0, 5, 10, 15, 20]

    validates :myscout_emails, hash: { key_in: [:email1, :email2, :email3, :email4], value_in: [true, false] }
    validates :flexi_records, array_of: { item_type: Osm::FlexiRecord, item_valid: true }


    # @!method initialize
    #   Initialize a new Section
    #   @param attributes [Hash] The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)


    # Get the user's sections
    # @param api [Osm::Api] The api to use to make the request
    # @!macro options_get
    # @return [Array<Osm::Section>]
    def self.get_all(api:, no_read_cache: false)
      cache_key = ['sections', api.user_id]

      if cache_exist?(api: api, key: cache_key, no_read_cache: no_read_cache)
        ids = cache_read(api: api, key: cache_key)
        return get_from_ids(api: api, ids: ids, key_base: 'section', no_read_cache: no_read_cache, method: :get_all)
      end

      result = []
      ids = []
      permissions = {}
      api.get_user_roles(no_read_cache: no_read_cache).each do |role_data|
        next if role_data['section'].eql?('discount')  # It's not an actual section
        next if role_data['sectionConfig'].nil? # No config for the section = user hasn't got access

        section_data = role_data['sectionConfig'].is_a?(String) ? JSON.parse(role_data['sectionConfig']) : role_data['sectionConfig']
        myscout_data = section_data['portal'] || {}
        portal_expires = section_data['portalExpires'] ||= {}
        section_id = Osm.to_i_or_nil(role_data['sectionid'])

        # Make sense of flexi records
        fr_data = []
        flexi_records = []
        fr_data = section_data['extraRecords'] if section_data['extraRecords'].is_a?(Array)
        fr_data = section_data['extraRecords'].values if section_data['extraRecords'].is_a?(Hash)
        fr_data.each do |record_data|
          # Expect item to be: {name:String, extraid:Integer}
          # Sometimes get item as: [String, {"name"=>String, "extraid"=>Integer}]
          record_data = record_data[1] if record_data.is_a?(Array)
          flexi_records.push Osm::FlexiRecord.new(
            id: Osm.to_i_or_nil(record_data['extraid']),
            name: record_data['name'],
            section_id: section_id
          )
        end

        section = new(
          id: section_id,
          name: role_data['sectionname'],
          subscription_level: Osm.to_i_or_nil(section_data['subscription_level']),
          subscription_expires: Osm.parse_date(section_data['subscription_expires']),
          type: !section_data['sectionType'].nil? ? section_data['sectionType'].to_sym : (!section_data['section'].nil? ? section_data['section'].to_sym : :unknown),
          num_scouts: section_data['numscouts'],
          flexi_records: flexi_records.sort,
          group_id: role_data['groupid'],
          group_name: role_data['groupname'],
          gocardless: (section_data['gocardless'] || 'false').casecmp('true').eql?(0),
          myscout_events_expires: Osm.parse_date(portal_expires['events']),
          myscout_badges_expires: Osm.parse_date(portal_expires['badges']),
          myscout_programme_expires: Osm.parse_date(portal_expires['programme']),
          myscout_details_expires: Osm.parse_date(portal_expires['details']),
          myscout_events: myscout_data['events'] == 1,
          myscout_badges: myscout_data['badges'] == 1,
          myscout_programme: myscout_data['programme'] == 1,
          myscout_payments: myscout_data['payments'] == 1,
          myscout_details: myscout_data['details'] == 1,
          myscout_emails: (myscout_data['emails'] || {}).each_with_object({}) { |(key, val), hash| hash[key.to_sym] = val.eql?('true') },
          myscout_email_address_from: myscout_data['emailAddress'] ? myscout_data['emailAddress'] : '',
          myscout_email_address_copy: myscout_data['emailAddressCopy'] ? myscout_data['emailAddressCopy'] : '',
          myscout_badges_partial: myscout_data['badgesPartial'] == 1,
          myscout_programme_summary: myscout_data['programmeSummary'] == 1,
          myscout_programme_times: myscout_data['programmeTimes'] == 1,
          myscout_programme_show: myscout_data['programmeShow'].to_i,
          myscout_event_reminder_count: myscout_data['eventRemindCount'].to_i,
          myscout_event_reminder_frequency: myscout_data['eventRemindFrequency'].to_i,
          myscout_payment_reminder_count: myscout_data['paymentRemindCount'].to_i,
          myscout_payment_reminder_frequency: myscout_data['paymentRemindFrequency'].to_i,
          myscout_details_email_changes_to: myscout_data['contactNotificationEmail']
        )

        result.push section
        ids.push section.id
        cache_write(api: api, key: ['section', section.id], data: section)
        permissions.merge!(section.id => Osm.make_permissions_hash(role_data['permissions']))
      end

      permissions.each do |s_id, perms|
        api.set_user_permissions(section: s_id, permissions: perms)
      end
      cache_write(api: api, key: cache_key, data: ids)
      result
    end


    # Get a section
    # @param api [Osm::Api] The api to use to make the request
    # @param id [Integer] The section id of the required section
    # @!macro options_get
    # @return nil if an error occured or the user does not have access to that section
    # @return [Osm::Section]
    def self.get(api:, id:, **options)
      cache_key = ['section', id]

      if cache_exist?(api: api, key: cache_key, no_read_cache: options[:no_read_cache]) && has_access_to_section?(api: api, section: id)
        return cache_read(api: api, key: cache_key)
      end

      sections = get_all(api: api, **options)
      return nil unless sections.is_a? Array

      sections.each do |section|
        return section if section.id == id
      end
      nil
    end


    # Get the section's notepad from OSM
    # @param api [Osm::Api] The api to use to make the request
    # @!macro options_get
    # @return [String] the section's notepad
    def get_notepad(api, **options)
      require_access_to_section(api, self, options)
      cache_key = ['notepad', id]

      if cache_exist?(api: api, key: cache_key, no_read_cache: options[:no_read_cache]) && has_access_to_section?(api: api, section: id)
        return cache_read(api: api, key: cache_key)
      end

      notepads = api.post_query('api.php?action=getNotepads')
      return '' unless notepads.is_a?(Hash)

      notepad = ''
      notepads.each do |key, value|
        cache_write(api: api, key: ['notepad', key.to_i], data: value)
        notepad = value if key.to_i == id
      end

      notepad
    end

    # Set the section's notepad in OSM
    # @param api [Osm::Api] The api to use to make the request
    # @param content [String] The content of the notepad
    # @return true, false whether the notepad was sucessfully updated
    def set_notepad(api:, content:)
      require_access_to_section(api, self)
      data = api.post_query("users.php?action=updateNotepad&sectionid=#{id}", post_data: { 'value' => content })

      if data.is_a?(Hash) && data['ok'] # Success
        cache_write(api: api, key: ['notepad', id], data: content)
        return true
      end
      false
    end


    # Check if this section is one of the youth sections
    # @return true, false
    def youth_section?
      [:beavers, :cubs, :scouts, :explorers].include?(type)
    end

    # Custom section type checkers
    # @!method beavers?
    #   Check if this is a Beavers section
    #   @return (Boolean)
    # @!method cubs?
    #   Check if this is a Cubs section
    #   @return (Boolean)
    # @!method scouts?
    #   Check if this is a Scouts section
    #   @return (Boolean)
    # @!method explorers?
    #   Check if this is an Explorers section
    #   @return (Boolean)
    # @!method network?
    #   Check if this is a Network section
    #   @return (Boolean)
    # @!method adults?
    #   Check if this is an Adults section
    #   @return (Boolean)
    # @!method waiting?
    #   Check if this is a waiting list
    #   @return (Boolean)
    [:beavers, :cubs, :scouts, :explorers, :network, :adults, :waiting].each do |attribute|
      define_method "#{attribute}?" do
        type == attribute
      end
    end

    # Check if the section has a subscription of a given level (or higher)
    # @param level [Integer, Symbol] the subscription level required
    # @return true, false Whether the section has a subscription of level (or higher)
    def subscription_at_least?(level)
      if level.is_a?(Symbol) # Convert to Integer
        case level
        when :bronze
          level = 1
        when :silver
          level = 2
        when :gold
          level = 3
        when :gold_plus
          level = 4
        else
          level = 0
        end
      end

      subscription_level >= level
    end

    # @!method bronze?
    #   Check if this has a Bronze level subscription
    #   @return (Boolean)
    # @!method silver?
    #   Check if this has a Silver level subscription
    #   @return (Boolean)
    # @!method gold?
    #   Check if this has a Gold level subscription
    #   @return (Boolean)
    # @!method gold_plus?
    #   Check if this has a Gold+ level subscription
    #   @return (Boolean)
    Osm::SUBSCRIPTION_LEVELS[1..-1].each_with_index do |attribute, index|
      define_method "#{attribute}?" do
        subscription_level == (index + 1)
      end
    end


    # Compare Section based on group_name type (age order), then name
    def <=>(other)
      type_order = [:beavers, :cubs, :scouts, :explorers, :network, :adults, :waiting]
      result = group_name <=> other.try(:group_name)
      if result.zero?
        result = type_order.find_index(type) <=> type_order.find_index(other.try(:type))
      end
      result = name <=> other.try(:name) if result.zero?
      result
    end

  end # Class Section

end # Module
