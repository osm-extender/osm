module Osm

  class Section < Osm::Model
    class FlexiRecord; end # Ensure the constant exists for the validators

    # @!attribute [rw] id
    #   @return [Fixnum] the id for the section
    # @!attribute [rw] name
    #   @return [String] the section name
    # @!attribute [rw] group_id
    #   @return [Fixnum] the id for the group
    # @!attribute [rw] group_name
    #   @return [String] the group name
    # @!attribute [rw] subscription_level
    #   @return [Fixnum] what subscription the section has to OSM (1-bronze, 2-silver, 3-gold)
    # @!attribute [rw] subscription_expires
    #   @return [Date] when the section's subscription to OSM expires
    # @!attribute [rw] type
    #   @return [Symbol] the section type (:beavers, :cubs, :scouts, :exporers, :adults, :waiting, :unknown)
    # @!attribute [rw] column_names
    #   @return [Hash] custom names to use for the data columns
    # @!attribute [rw] fields
    #   @return [Hash] which columns are shown in OSM
    # @!attribute [rw] intouch_fields
    #   @return [Hash] which columns are shown in OSM's in touch reports
    # @!attribute [rw] mobile_fields
    #   @return [Hash] which columns are shown in the OSM mobile app
    # @!attribute [rw] flexi_records
    #   @return [Array<FlexiRecord>] list of the extra records the section has
    # @!attribute [rw] gocardless
    #   @return [Boolean] does the section use gocardless
    # @!attribute [rw] myscout_events_expires
    #   @return [Date] when the subscription to Events in My.SCOUT expires
    # @!attribute [rw] myscout_badges_expires
    #   @return [Date] when the subscription to Badges in My.SCOUT expires
    # @!attribute [rw] myscout_programme_expires
    #   @return [Date] when the subscription to Badges in My.SCOUT expires
    # @!attribute [rw] myscout_events
    #   @return [Boolean] whether the section uses the Events part of My.SCOUT
    # @!attribute [rw] myscout_badges
    #   @return [Boolean] whether the section uses the Badges part of My.SCOUT
    # @!attribute [rw] myscout_programme
    #   @return [Boolean] whether the section uses the Programme part of My.SCOUT
    # @!attribute [rw] myscout_payments
    #   @return [Boolean] whether the section uses the Payments part of My.SCOUT
    # @!attribute [rw] myscout_emails
    #   @return [Hash of Symbol to Boolean] which email addresses are linked to MyScout for each Member
    # @!attribute [rw] myscout_email_address_from
    #   @return [String] which email address to send My.SCOUT emails as coming from
    # @!attribute [rw] myscout_email_address_copy
    #   @return [String] which email address to send copys of My.SCOUT emails to
    # @!attribute [rw] myscout_badges_partial
    #   @return [Boolean] Wether parents can see partially completed badges
    # @!attribute [rw] myscout_programme_summary
    #   @return [Boolean] Wether parents can see summary of programme items
    # @!attribute [rw] myscout_event_reminder_count
    #   @return [Fixnum] How many event reminders to send to parents who haven't responded
    # @!attribute [rw] myscout_event_reminder_frequency
    #   @return [Fixnum] How many days to leave between event reminder emails
    # @!attribute [rw] myscout_payment_reminder_count
    #   @return [Fixnum] How many payment reminders to send to parents who haven't paid yet
    # @!attribute [rw] myscout_payment_reminder_frequency
    #   @return [Fixnum] How many days to leave between payment reminder emails

    attribute :id, :type => Integer
    attribute :name, :type => String
    attribute :group_id, :type => Integer
    attribute :group_name, :type => String
    attribute :subscription_level, :default => 1
    attribute :subscription_expires, :type => Date
    attribute :type, :default => :unknown
    attribute :column_names, :default => {}
    attribute :fields, :default => {}
    attribute :intouch_fields, :default => {}
    attribute :mobile_fields, :default => {}
    attribute :flexi_records, :default => []
    attribute :gocardless, :type => Boolean
    attribute :myscout_events_expires, :type => Date
    attribute :myscout_badges_expires, :type => Date
    attribute :myscout_programme_expires, :type => Date
    attribute :myscout_events, :type => Boolean
    attribute :myscout_badges, :type => Boolean
    attribute :myscout_programme, :type => Boolean
    attribute :myscout_payments, :type => Boolean
    attribute :myscout_emails, :default => {}
    attribute :myscout_email_address_from, :type => String, :default => ''
    attribute :myscout_email_address_copy, :type => String, :default => ''
    attribute :myscout_badges_partial, :type => Boolean
    attribute :myscout_programme_summary, :type => Boolean
    attribute :myscout_event_reminder_count, :type => Integer
    attribute :myscout_event_reminder_frequency, :type => Integer
    attribute :myscout_payment_reminder_count, :type => Integer
    attribute :myscout_payment_reminder_frequency, :type => Integer

    attr_accessible :id, :name, :group_id, :group_name, :subscription_level, :subscription_expires,
                    :type, :column_names, :fields, :intouch_fields, :mobile_fields, :flexi_records,
                    :gocardless, :myscout_events_expires, :myscout_badges_expires,
                    :myscout_programme_expires, :myscout_events, :myscout_badges,
                    :myscout_programme, :myscout_payments, :myscout_emails,
                    :myscout_email_address_from, :myscout_email_address_copy,
                    :myscout_badges_partial, :myscout_programme_summary,
                    :myscout_event_reminder_count, :myscout_event_reminder_frequency,
                    :myscout_payment_reminder_count, :myscout_payment_reminder_frequency

    validates_numericality_of :id, :only_integer=>true, :greater_than=>0, :allow_nil => true
    validates_numericality_of :group_id, :only_integer=>true, :greater_than=>0, :allow_nil => true
    validates_numericality_of :myscout_event_reminder_count, :only_integer=>true, :greater_than_or_equal_to=>-1
    validates_numericality_of :myscout_event_reminder_frequency, :only_integer=>true, :greater_than_or_equal_to=>-1
    validates_numericality_of :myscout_payment_reminder_count, :only_integer=>true, :greater_than_or_equal_to=>-1
    validates_numericality_of :myscout_payment_reminder_frequency, :only_integer=>true, :greater_than_or_equal_to=>-1

    validates_presence_of :name
    validates_presence_of :group_name
    validates_presence_of :subscription_level
    validates_presence_of :subscription_expires
    validates_presence_of :type
    validates_presence_of :column_names, :unless => Proc.new { |a| a.column_names == {} }
    validates_presence_of :fields, :unless => Proc.new { |a| a.fields == {} }
    validates_presence_of :intouch_fields, :unless => Proc.new { |a| a.intouch_fields == {} }
    validates_presence_of :mobile_fields, :unless => Proc.new { |a| a.mobile_fields == {} }
    validates_presence_of :flexi_records, :unless => Proc.new { |a| a.flexi_records == [] }

    validates_inclusion_of :subscription_level, :in => (1..3), :message => 'is not a valid subscription level'
    validates_inclusion_of :gocardless, :in => [true, false]
    validates_inclusion_of :myscout_events, :in => [true, false]
    validates_inclusion_of :myscout_badges, :in => [true, false]
    validates_inclusion_of :myscout_programme, :in => [true, false]
    validates_inclusion_of :myscout_payments, :in => [true, false]
    validates_inclusion_of :myscout_badges_partial, :in => [true, false]
    validates_inclusion_of :myscout_programme_summary, :in => [true, false]

    validates :column_names, :hash => {:key_type => Symbol, :value_type => String}
    validates :fields, :hash => {:key_type => Symbol, :value_in => [true, false]}
    validates :intouch_fields, :hash => {:key_type => Symbol, :value_in => [true, false]}
    validates :mobile_fields, :hash => {:key_type => Symbol, :value_in => [true, false]}
    validates :myscout_emails, :hash => {:key_in => [:email1, :email2, :email3, :email4], :value_in => [true, false]}


    # @!method initialize
    #   Initialize a new Section
    #   @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)


    # Get the user's sections
    # @param [Osm::Api] api The api to use to make the request
    # @!macro options_get
    # @return [Array<Osm::Section>]
    def self.get_all(api, options={})
      cache_key = ['sections', api.user_id]

      if !options[:no_cache] && cache_exist?(api, cache_key)
        ids = cache_read(api, cache_key)
        return get_from_ids(api, ids, 'section', options, :get_all)
      end

      data = api.perform_query('api.php?action=getUserRoles')

      result = Array.new
      ids = Array.new
      permissions = Hash.new
      data.each do |role_data|
        unless role_data['section'].eql?('discount')  # It's not an actual section
          section_data = role_data['sectionConfig'].is_a?(String) ? ActiveSupport::JSON.decode(role_data['sectionConfig']) : role_data['sectionConfig']
          myscout_data = section_data['portal'] || {}
          section_data['portalExpires'] ||= {}
          section_id = Osm::to_i_or_nil(role_data['sectionid'])

          # Make sense of flexi records
          fr_data = []
          flexi_records = []
          fr_data = section_data['extraRecords'] if section_data['extraRecords'].is_a?(Array)
          fr_data = section_data['extraRecords'].values if section_data['extraRecords'].is_a?(Hash)
          fr_data.each do |record_data|
            # Expect item to be: {:name=>String, :extraid=>Fixnum}
            # Sometimes get item as: [String, {"name"=>String, "extraid"=>Fixnum}]
            record_data = record_data[1] if record_data.is_a?(Array)
            flexi_records.push Osm::FlexiRecord.new(
              :id => Osm::to_i_or_nil(record_data['extraid']),
              :name => record_data['name'],
              :section_id => section_id,
            )
          end

          section = new(
            :id => section_id,
            :name => role_data['sectionname'],
            :subscription_level => Osm::to_i_or_nil(section_data['subscription_level']),
            :subscription_expires => Osm::parse_date(section_data['subscription_expires']),
            :type => !section_data['sectionType'].nil? ? section_data['sectionType'].to_sym : (!section_data['section'].nil? ? section_data['section'].to_sym : :unknown),
            :num_scouts => section_data['numscouts'],
            :column_names => section_data['columnNames'].is_a?(Hash) ? Osm::symbolize_hash(section_data['columnNames']) : {},
            :fields => section_data['fields'].is_a?(Hash) ? Osm::symbolize_hash(section_data['fields']) : {},
            :intouch_fields => section_data['intouch'].is_a?(Hash) ? Osm::symbolize_hash(section_data['intouch']) : {},
            :mobile_fields => section_data['mobFields'].is_a?(Hash) ? Osm::symbolize_hash(section_data['mobFields']) : {},
            :flexi_records => flexi_records.sort,
            :group_id => role_data['groupid'],
            :group_name => role_data['groupname'],
            :gocardless => (section_data['gocardless'] || 'false').downcase.eql?('true'),
            :myscout_events_expires => Osm::parse_date(section_data['portalExpires']['events']),
            :myscout_badges_expires => Osm::parse_date(section_data['portalExpires']['badges']),
            :myscout_programme_expires => Osm::parse_date(section_data['portalExpires']['programme']),
            :myscout_events => myscout_data['events'] == 1,
            :myscout_badges => myscout_data['badges'] == 1,
            :myscout_programme => myscout_data['programme'] == 1,
            :myscout_payments => myscout_data['payments'] == 1,
            :myscout_emails => (myscout_data['emails'] || {}).inject({}) { |n,(k,v)| n[k.to_sym] = v.eql?('true'); n},
            :myscout_email_address_from => myscout_data['emailAddress'] ? myscout_data['emailAddress'] : '',
            :myscout_email_address_copy => myscout_data['emailAddressCopy'] ? myscout_data['emailAddressCopy'] : '',
            :myscout_badges_partial => myscout_data['badgesPartial'] == 1,
            :myscout_programme_summary => myscout_data['programmeSummary'] == 1,
            :myscout_event_reminder_count => myscout_data['eventRemindCount'].to_i,
            :myscout_event_reminder_frequency => myscout_data['eventRemindFrequency'].to_i,
            :myscout_payment_reminder_count => myscout_data['paymentRemindCount'].to_i,
            :myscout_payment_reminder_frequency => myscout_data['paymentRemindFrequency'].to_i,
          )

          result.push section
          ids.push section.id
          cache_write(api, ['section', section.id], section)
          permissions.merge!(section.id => Osm.make_permissions_hash(role_data['permissions']))
        end
      end

      permissions.each do |s_id, perms|
        api.set_user_permissions(s_id, perms)
      end
      cache_write(api, cache_key, ids)
      return result
    end


    # Get a section
    # @param [Osm::Api] api The api to use to make the request
    # @param [Fixnum] section_id The section id of the required section
    # @!macro options_get
    # @return nil if an error occured or the user does not have access to that section
    # @return [Osm::Section]
    def self.get(api, section_id, options={})
      cache_key = ['section', section_id]

      if !options[:no_cache] && cache_exist?(api, cache_key) && can_access_section?(api, section_id)
        return cache_read(api, cache_key)
      end

      sections = get_all(api, options)
      return nil unless sections.is_a? Array

      sections.each do |section|
        return section if section.id == section_id
      end
      return nil
    end


    # Get the section's notepad from OSM
    # @param [Osm::Api] api The api to use to make the request
    # @!macro options_get
    # @return [String] the section's notepad
    def get_notepad(api, options={})
      require_access_to_section(api, self, options)
      cache_key = ['notepad', id]

      if !options[:no_cache] && cache_exist?(api, cache_key) && can_access_section?(api, section_id)
        return cache_read(api, cache_key)
      end

      notepads = api.perform_query('api.php?action=getNotepads')
      return '' unless notepads.is_a?(Hash)

      notepad = ''
      notepads.each do |key, value|
        cache_write(api, ['notepad', key.to_i], value)
        notepad = value if key.to_i == id
      end

      return notepad
    end

    # Set the section's notepad in OSM
    # @param [Osm::Api] api The api to use to make the request
    # @param [String] content The content of the notepad
    # @return [Boolean] whether the notepad was sucessfully updated
    def set_notepad(api, content)
      require_access_to_section(api, self)
      data = api.perform_query("users.php?action=updateNotepad&sectionid=#{id}", {'value' => content})

      if data.is_a?(Hash) && data['ok'] # Success
        cache_write(api, ['notepad', id], content)
        return true
      end
      return false
    end


    # Get badge stock levels
    # @param [Osm::Api] api The api to use to make the request
    # @param [Osm::Term, Fixnum, #to_i, nil] term The term (or its ID) to get the stock levels for, passing nil causes the current term to be used
    # @!macro options_get
    # @return Hash
    def get_badge_stock(api, term=nil, options={})
      require_ability_to(api, :read, :badge, self, options)
      term_id = term.nil? ? Osm::Term.get_current_term_for_section(api, self).id : term.to_i
      cache_key = ['badge_stock', id, term_id]

      if !options[:no_cache] && cache_exist?(api, cache_key)
        return cache_read(api, cache_key)
      end

      data = api.perform_query("challenges.php?action=getInitialBadges&type=core&sectionid=#{id}&section=#{type}&termid=#{term_id}")
      data = (data['stock'] || {}).select{ |k,v| !k.eql?('sectionid') }.
                                   inject({}){ |new_hash,(badge, level)| new_hash[badge] = level.to_i; new_hash }

      cache_write(api, cache_key, data)
      return data
    end


    # Check if this section is one of the youth sections
    # @return [Boolean]
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
    # @!method adults?
    #   Check if this is an Adults section
    #   @return (Boolean)
    # @!method waiting?
    #   Check if this is a waiting list
    #   @return (Boolean)
    [:beavers, :cubs, :scouts, :explorers, :adults, :waiting].each do |attribute|
      define_method "#{attribute}?" do
        type == attribute
      end
    end

    # Get the name for the section's subscription level
    # @return [String, nil] the name of the subscription level (nil if no name exists)
    def subscription_level_name
      return {
        1 => 'Bronze',
        2 => 'Silver',
        3 => 'Gold',
      }[subscription_level]
    end

    def <=>(another)
      begin
        compare_group_name = group_name <=> another.group_name
        return compare_group_name unless compare_group_name == 0
  
        return 0 if type == another.type
        [:beavers, :cubs, :scouts, :explorers, :waiting, :adults].each do |type|
          return -1 if type == type
          return 1 if another.type == type
        end
      rescue NoMethodError
        return 1
      end
    end

    def ==(another)
      begin
        return self.id == another.id
      rescue NoMethodError
        return false
      end
    end

  end # Class Section

end # Module
