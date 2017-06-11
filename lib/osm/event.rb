module Osm
  class Event < Osm::Model
    LIST_ATTRIBUTES = [:id, :section_id, :name, :start, :finish, :cost, :location, :notes, :archived, :public_notepad, :confirm_by_date, :allow_changes, :reminders, :attendance_limit, :attendance_limit_includes_leaders, :attendance_reminder, :allow_booking].freeze
    EXTRA_ATTRIBUTES = [:notepad, :columns, :badges].freeze
    private_constant :LIST_ATTRIBUTES, :EXTRA_ATTRIBUTES

    # @!attribute [rw] id
    #   @return [Integer] the id for the event
    # @!attribute [rw] section_id
    #   @return [Integer] the id for the section
    # @!attribute [rw] name
    #   @return [String] the name of the event
    # @!attribute [rw] start
    #   @return [DateTime] when the event starts
    # @!attribute [rw] finish
    #   @return [DateTime] when the event ends
    # @!attribute [rw] cost
    #   @return [String] the cost of the event (formatted to \d+\.\d{2}) or "TBC"
    # @!attribute [rw] location
    #   @return [String] where the event is
    # @!attribute [rw] notes
    #   @return [String] notes about the event
    # @!attribute [rw] archived
    #   @return true, false if the event has been archived
    # @!attribute [rw] badges
    #   @return [Array<Osm::Event::BadgeLink>] the badge links for the event
    # @!attribute [rw] files
    #   @return [Array<String>] the files attached to this event
    # @!attribute [rw] columns
    #   @return [Array<Osm::Event::Column>] the custom columns for the event
    # @!attribute [rw] notepad
    #   @return [String] notepad for the event
    # @!attribute [rw] public_notepad
    #   @return [String] public notepad (shown in My.SCOUT) for the event
    # @!attribute [rw] confirm_by_date
    #   @return [Date] the date parents can no longer add/change their child's details
    # @!attribute [rw] allow_changes
    #   @return true, false whether parent's can change their child's details
    # @!attribute [rw] reminders
    #   @return true, false whether email reminders are sent for the event
    # @!attribute [rw] attendance_limit
    #   @return [Integer] the maximum number of people who can attend the event (0 = no limit)
    # @!attendance [rw] attendance_limit_includes_leaders
    #   @return true, false whether the attendance limit includes leaders
    # @!attribute [rw] attendance_reminder
    #   @return [Integer] how many days before the event to send a reminder to those attending (0 (off), 1, 3, 7, 14, 21, 28)
    # @!attribute [rw] allow_booking
    #   @return true, false whether booking is allowed through My.SCOUT

    attribute :id, type: Integer
    attribute :section_id, type: Integer
    attribute :name, type: String
    attribute :start, type: DateTime
    attribute :finish, type: DateTime
    attribute :cost, type: String, default: 'TBC'
    attribute :location, type: String, default: ''
    attribute :notes, type: String, default: ''
    attribute :archived, type: Boolean, default: false
    attribute :badges, default: []
    attribute :files, default: []
    attribute :columns, default: []
    attribute :notepad, type: String, default: ''
    attribute :public_notepad, type: String, default: ''
    attribute :confirm_by_date, type: Date
    attribute :allow_changes, type: Boolean, default: false
    attribute :reminders, type: Boolean, default: true
    attribute :attendance_limit, type: Integer, default: 0
    attribute :attendance_limit_includes_leaders, type: Boolean, default: false
    attribute :attendance_reminder, type: Integer, default: 0
    attribute :allow_booking, type: Boolean, default: true

    validates_numericality_of :id, only_integer: true, greater_than: 0, allow_nil: true
    validates_numericality_of :section_id, only_integer: true, greater_than: 0
    validates_numericality_of :attendance_limit, only_integer: true, greater_than_or_equal_to: 0
    validates_presence_of :name
    validates :badges, array_of: { item_type: Osm::Event::BadgeLink, item_valid: true }
    validates :columns, array_of: { item_type: Osm::Event::Column, item_valid: true }
    validates :files, array_of: { item_type: String }
    validates_inclusion_of :allow_changes, in: [true, false]
    validates_inclusion_of :reminders, in: [true, false]
    validates_inclusion_of :attendance_limit_includes_leaders, in: [true, false]
    validates_inclusion_of :allow_booking, in: [true, false]
    validates_inclusion_of :attendance_reminder, in: [0, 1, 3, 7, 14, 21, 28]
    validates_format_of :cost, with: /\A(?:\d+\.\d{2}|TBC)\Z/


    # @!method initialize
    #   Initialize a new Event
    #   @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)


    # Get events for a section
    # @param api [Osm::Api] The api to use to make the request
    # @param section [Osm::Section, Integer, #to_i] The section (or its ID) to get the events for
    # @param include_archived true, false whether to include archived events
    # @!macro options_get
    # @return [Array<Osm::Event>]
    def self.get_for_section(api:, section:, include_archived: false, no_read_cache: false)
      require_ability_to(api: api, to: :read, on: :events, section: section, no_read_cache: no_read_cache)
      section_id = section.to_i
      cache_key = ['events', section_id]
      events = nil

      if cache_exist?(api: api, key: cache_key, no_read_cache: no_read_cache)
        ids = cache_read(api: api, key: cache_key)
        events = get_from_ids(api: api, ids: ids, key_base: 'event', method: :get_for_section)
      end

      if events.nil?
        data = api.post_query("events.php?action=getEvents&sectionid=#{section_id}&showArchived=true")
        events = []
        ids = []
        unless data['items'].nil?
          data['items'].map { |i| i['eventid'].to_i }.each do |event_id|
            event_data = api.post_query("events.php?action=getEvent&sectionid=#{section_id}&eventid=#{event_id}")
            files_data = api.post_query("ext/uploads/events/?action=listAttachments&sectionid=#{section_id}&eventid=#{event_id}")
            files = files_data.is_a?(Hash) ? files_data['files'] : files_data
            files = [] unless files.is_a?(Array)

            event = new_event_from_data(event_data)
            event.files = files
            events.push event
            ids.push event.id
            cache_write(api: api, key: ['event', event.id], data: event)
          end
        end
        cache_write(api: api, key: cache_key, data: ids)
      end

      return events if include_archived
      events.reject(&:archived?)
    end

    # Get event list for a section (not all details for each event)
    # @param api [Osm::Api] The api to use to make the request
    # @param section [Osm::Section, Integer, #to_i] The section (or its ID) to get the events for
    # @!macro options_get
    # @return [Array<Hash>]
    def self.get_list(api:, section:, no_read_cache: false)
      require_ability_to(api: api, to: :read, on: :events, section: section, no_read_cache: no_read_cache)
      section_id = section.to_i
      cache_key = ['events_list', section_id]
      events_cache_key = ['events', section_id]
      events = nil

      unless no_read_cache
        # Try getting from cache
        if cache_exist?(api: api, key: cache_key)
          return cache_read(api: api, key: cache_key)
        end

        # Try generating from cached events
        if cache_exist?(api: api, key: events_cache_key)
          ids = cache_read(api: api, key: events_cache_key)
          events = get_from_ids(api: api, ids: ids, key_base: 'event', method: :get_for_section).map do |e|
            e.attributes.symbolize_keys.select do |k, _v|
              LIST_ATTRIBUTES.include?(k)
            end
          end
          return events
        end
      end # unless no_read_cache

      # Fetch from OSM
      if events.nil?
        data = api.post_query("events.php?action=getEvents&sectionid=#{section_id}&showArchived=true")
        events = []
        unless data['items'].nil?
          data['items'].map do |event_data|
            events.push(attributes_from_data(event_data))
          end
        end
      end

      cache_write(api: api, key: cache_key, data: events)
      events
    end

    # Get an event
    # @param api [Osm::Api] api The to use to make the request
    # @param section [Osm::Section, Integer, #to_i] The section (or its ID) to get the events for
    # @param id [Integer, #to_i] The id of the event to get
    # @!macro options_get
    # @return [Osm::Event, nil] the event (or nil if it couldn't be found
    def self.get(api:, section:, id:, no_read_cache: false)
      require_ability_to(api: api, to: :read, on: :events, section: section, no_read_cache: no_read_cache)
      section_id = section.to_i
      event_id = id.to_i
      cache_key = ['event', event_id]

      cache_fetch(api: api, key: cache_key, no_read_cache: no_read_cache) do
        new_event_from_data(api.post_query("events.php?action=getEvent&sectionid=#{section_id}&eventid=#{event_id}"))
      end
    end


    # Create an event in OSM
    # If something goes wrong adding badges to OSM then the event returned will have been read from OSM
    # @param api [Osm::Api] The api to use to make the request
    # @return [Osm::Event, nil] the created event, nil if failed
    # @raise [Osm::ObjectIsInvalid] If the Event is invalid
    def self.create(api:, **parameters)
      require_ability_to(api: api, to: :write, on: :events, section: parameters[:section_id])
      event = new(parameters)
      fail Osm::ObjectIsInvalid, 'event is invalid' unless event.valid?

      data = api.post_query("events.php?action=addEvent&sectionid=#{event.section_id}", post_data: {
        'name' => event.name,
        'location' => event.location,
        'startdate' => event.start? ? event.start.strftime(Osm::OSM_DATE_FORMAT) : '',
        'enddate' => event.finish? ? event.finish.strftime(Osm::OSM_DATE_FORMAT) : '',
        'cost' => event.cost_tbc? ? '-1' : event.cost,
        'notes' => event.notes,
        'starttime' => event.start? ? event.start.strftime(Osm::OSM_TIME_FORMAT) : '',
        'endtime' => event.finish? ? event.finish.strftime(Osm::OSM_TIME_FORMAT) : '',
        'confdate' => event.confirm_by_date? ? event.confirm_by_date.strftime(Osm::OSM_DATE_FORMAT) : '',
        'allowChanges' => event.allow_changes ? 'true' : 'false',
        'disablereminders' => !event.reminders ? 'true' : 'false',
        'attendancelimit' => event.attendance_limit,
        'attendancereminder' => event.attendance_reminder,
        'limitincludesleaders' => event.attendance_limit_includes_leaders ? 'true' : 'false',
        'allowbooking' => event.allow_booking ? 'true' : 'false'
      })

      return nil unless data.is_a?(Hash) && data.key?('id')
      event.id = data['id'].to_i

      # The cached events for the section will be out of date - remove them
      cache_delete(api: api, key: ['events', event.section_id])

      # Add badge links to OSM
      badges_created = true
      event.badges.each do |badge|
        badges_created &= event.add_badge_link(api: api, link: badge)
      end

      if badges_created
        cache_write(api: api, key: ['event', event.id], data: event)
        return event
      else
        # Someting went wrong adding badges so return what OSM has
        return get(api: api, section: event.section_id, id: event.id, no_read_cache: true)
      end
    end

    # Update event in OSM
    # @param api [Osm::Api] The api to use to make the request
    # @return true, false whether the update succedded (will return true if no updates needed to be made)
    def update(api)
      require_ability_to(api: api, to: :write, on: :events, section: section_id)
      updated = true

      # Update main attributes
      update_main_attributes = false
      %w{id name location start finish cost cost_tbc notes confirm_by_date allow_changes reminders attendance_limit attendance_limit_includes_leaders allow_booking}.each do |a|
        if changed_attributes.include?(a)
          update_main_attributes = true
          break # no use checking the others
        end
      end
      if update_main_attributes
        data = api.post_query("events.php?action=addEvent&sectionid=#{section_id}", post_data: {
          'eventid' => id,
          'name' => name,
          'location' => location,
          'startdate' => start? ? start.strftime(Osm::OSM_DATE_FORMAT) : '',
          'enddate' => finish? ? finish.strftime(Osm::OSM_DATE_FORMAT) : '',
          'cost' => cost_tbc? ? '-1' : cost,
          'notes' => notes,
          'starttime' => start? ? start.strftime(Osm::OSM_TIME_FORMAT) : '',
          'endtime' => finish? ? finish.strftime(Osm::OSM_TIME_FORMAT) : '',
          'confdate' => confirm_by_date? ? confirm_by_date.strftime(Osm::OSM_DATE_FORMAT) : '',
          'allowChanges' => allow_changes ? 'true' : 'false',
          'disablereminders' => !reminders ? 'true' : 'false',
          'attendancelimit' => attendance_limit,
          'attendancereminder' => attendance_reminder,
          'limitincludesleaders' => attendance_limit_includes_leaders ? 'true' : 'false',
          'allowbooking' => allow_booking ? 'true' : 'false'
        })
        updated &= data.is_a?(Hash) && (data['id'].to_i == id)
      end

      # Private notepad
      if changed_attributes.include?('notepad')
        data = api.post_query("events.php?action=saveNotepad&sectionid=#{section_id}", post_data: {
          'eventid' => id,
          'notepad' => notepad
        })
        updated &= data.is_a?(Hash)
      end

      # MySCOUT notepad
      if changed_attributes.include?('public_notepad')
        data = api.post_query("events.php?action=saveNotepad&sectionid=#{section_id}", post_data: {
          'eventid' => id,
          'pnnotepad' => public_notepad
        })
        updated &= data.is_a?(Hash)
      end

      # Badges
      if changed_attributes.include?('badges')
        original_badges = @original_attributes['badges'] || []

        # Deleted badges
        badges_to_delete = []
        original_badges.each do |badge|
          badges_to_delete.push badge unless badges.include?(badge)
        end
        badges_to_delete.each do |badge|
          data = api.post_query("ext/badges/records/index.php?action=deleteBadgeLink&sectionid=#{section_id}", post_data: {
            'section' => badge.badge_section,
            'sectionid' => section_id,
            'type' => 'event',
            'id' => id,
            'badge_id' => badge.badge_id,
            'badge_version' => badge.badge_version,
            'column_id' => badge.requirement_id
          })
          updated &= data.is_a?(Hash) && data['status']
        end

        # Added badges
        badges.each do |badge|
          unless original_badges.include?(badge)
            updated &= add_badge_link(api: api, link: badge)
          end
        end
      end # includes badges

      if updated
        reset_changed_attributes
        # The cached event will be out of date - remove it
        cache_delete(api: api, key: ['event', id])
      end
      updated
    end

    # Delete event from OSM
    # @param api [Osm::Api] The api to use to make the request
    # @return true, false whether the delete succedded
    def delete(api)
      require_ability_to(api: api, to: :write, on: :events, section: section_id)

      data = api.post_query("events.php?action=deleteEvent&sectionid=#{section_id}&eventid=#{id}")

      if data.is_a?(Hash) && data['ok']
        cache_delete(api: api, key: ['event', id])
        return true
      end
      false
    end


    # Get event attendance
    # @param api [Osm::Api] The api to use to make the request
    # @param term [Osm::Term, Integer, #to_i, nil] The term (or its ID) to get the members for, passing nil causes the current term to be used
    # @!macro options_get
    # @option options true, false :include_archived (optional) if true then archived activities will also be returned
    # @return [Array<Osm::Event::Attendance>]
    def get_attendance(api:, term: nil, no_read_cache: false)
      require_ability_to(api: api, to: :read, on: :events, section: section_id, no_read_cache: no_read_cache)
      term_id = term.nil? ? Osm::Term.get_current_term_for_section(api: api, section: section_id, no_read_cache: no_read_cache).id : term.to_i
      cache_key = ['event_attendance', id, term_id]

      cache_fetch(api: api, key: cache_key, no_read_cache: no_read_cache) do
        data = api.post_query("events.php?action=getEventAttendance&eventid=#{id}&sectionid=#{section_id}&termid=#{term_id}")
        data = data['items'] || []

        payment_values = {
          'Manual' => :manual,
          'Automatic' => :automatic
        }
        attending_values = {
          'Yes' => :yes,
          'No' => :no,
          'Invited' => :invited,
          'Show in My.SCOUT' => :shown,
          'Reserved' => :reserved
        }

        data.each_with_index.map do |item, index|
          Osm::Event::Attendance.new(
            event: self,
            member_id: Osm.to_i_or_nil(item['scoutid']),
            grouping_id: Osm.to_i_or_nil(item['patrolid'].eql?('') ? nil : item['patrolid']),
            first_name: item['firstname'],
            last_name: item['lastname'],
            date_of_birth: item['dob'].nil? ? nil : Osm.parse_date(item['dob'], ignore_epoch: true),
            attending: attending_values[item['attending']],
            payment_control: payment_values[item['payment']],
            fields:   item.select { |key, _value| key.to_s.match(/\Af_\d+\Z/) }
                          .each_with_object({}) { |(key, val), hash| hash[key[2..-1].to_i] = val },
            payments: item.select { |key, _value| key.to_s.match(/\Ap\d+\Z/) }
                          .each_with_object({}) { |(key, val), hash| hash[key[1..-1].to_i] = val },
            row: index
          )
        end # each data
      end # cache fetch
    end

    # Add a badge link to the event in OSM
    # @param api [Osm::Api] The api to use to make the request
    # @param link [Osm::Event::BadgeLink] The badge link to add, if column_id is nil then a new column is created with requirement_label as the name
    # @return true, false whether the update succedded
    def add_badge_link(api:, link:)
      fail Osm::ObjectIsInvalid, 'link is invalid' unless link.valid?
      require_ability_to(api: api, to: :write, on: :events, section: section_id)

      data = api.post_query("ext/badges/records/index.php?action=linkBadgeToItem&sectionid=#{section_id}", post_data: {
        'section' => link.badge_section,
        'sectionid' => section_id,
        'type' => 'event',
        'id' => id,
        'badge_id' => link.badge_id,
        'badge_version' => link.badge_version,
        'column_id' => link.requirement_id.to_i.eql?(0) ? -2 : link.requirement_id,
        'column_data' => link.data,
        'new_column_name' => link.requirement_id.to_i.eql?(0) ? link.requirement_label : ''
      })
      (data.is_a?(Hash) && data['status'])
    end

    # Add a column to the event in OSM
    # @param api [Osm::Api] The api to use to make the request
    # @param label [String] The label for the field in OSM
    # @param name [String] The label for the field in My.SCOUT (if this is blank then parents can't edit it)
    # @param required true, false Whether the parent is required to enter something
    # @return true, false whether the update succedded
    # @raise [Osm::ArgumentIsInvalid] If the name is blank
    def add_column(api:, name:, label: '', required: false)
      require_ability_to(api: api, to: :write, on: :events, section: section_id)
      fail Osm::ArgumentIsInvalid, 'name is invalid' if name.blank?

      data = api.post_query("events.php?action=addColumn&sectionid=#{section_id}&eventid=#{id}", post_data: {
        'columnName' => name,
        'parentLabel' => label,
        'parentRequire' => (required ? 1 : 0)
      })

      # The cached events for the section will be out of date - remove them
      cache_delete(api: api, key: ['events', section_id])
      cache_delete(api: api, key: ['event', id])
      cache_delete(api: api, key: ['event_attendance', id])

      self.columns = self.class.new_event_from_data(data).columns

      data.is_a?(Hash) && (data['eventid'].to_i == id)
    end

    # Whether thete is a limit on attendance for this event
    # @return true, false whether thete is a limit on attendance for this event
    def limited_attendance?
      (attendance_limit != 0)
    end

    # Whether there are spaces left for the event
    # @param api [Osm::Api] The api to use to make the request
    # @return true, false whether there are spaces left for the event
    def spaces?(api)
      return true unless limited_attendance?
      attendance_limit > attendees(api)
    end

    # Get the number of spaces left for the event
    # @param api [Osm::Api] The api to use to make the request
    # @return [Integer, nil] the number of spaces left (nil if there is no attendance limit)
    def spaces(api)
      return nil unless limited_attendance?
      attendance_limit - attendees(api)
    end

    # Whether the cost is to be confirmed
    # @return true, false whether the cost is TBC
    def cost_tbc?
      cost.eql?('TBC')
    end

    # Whether the cost is zero
    # @return true, false whether the cost is zero
    def cost_free?
      cost.eql?('0.00')
    end


    protected

    def self.attributes_from_data(event_data)
      {
        id: Osm.to_i_or_nil(event_data['eventid']),
        section_id: Osm.to_i_or_nil(event_data['sectionid']),
        name: event_data['name'],
        start: Osm.make_datetime(date: event_data['startdate'], time: event_data['starttime']),
        finish: Osm.make_datetime(date: event_data['enddate'], time: event_data['endtime']),
        cost: event_data['cost'].eql?('-1') ? 'TBC' : event_data['cost'],
        location: event_data['location'],
        notes: event_data['notes'],
        archived: event_data['archived'].eql?('1'),
        public_notepad: event_data['publicnotes'],
        confirm_by_date: Osm.parse_date(event_data['confdate']),
        allow_changes: event_data['allowchanges'].eql?('1'),
        reminders: !event_data['disablereminders'].eql?('1'),
        attendance_limit: event_data['attendancelimit'].to_i,
        attendance_limit_includes_leaders: event_data['limitincludesleaders'].eql?('1'),
        attendance_reminder: event_data['attendancereminder'].to_i,
        allow_booking: event_data['allowbooking'].eql?('1')
      }
    end

    def self.new_event_from_data(event_data)
      event = Osm::Event.new(attributes_from_data(event_data))
      event.notepad = event_data['notepad']

      columns = []
      config_raw = event_data['config']
      config_raw = '[]' if config_raw.blank?
      column_data = JSON.parse(config_raw)
      column_data = [] unless column_data.is_a?(Array)
      column_data.each do |field|
        columns.push Column.new(id: field['id'], name: field['name'], label: field['pL'], parent_required: field['pR'].to_s.eql?('1'), event: event)
      end
      event.columns = columns

      badges = []
      badges_data = event_data['badgelinks']
      badges_data = [] unless badges_data.is_a?(Array)
      badges_data.each do |field|
        badges.push BadgeLink.new(
          badge_type: field['badgetype'].to_sym,
          badge_section: field['section'].to_sym,
          requirement_id: field['column_id'],
          badge_name: field['badgeLongName'],
          requirement_label: field['columnnameLongName'],
          data: field['data'],
          badge_id: field['badge_id'],
          badge_version: field['badge_version']
        )
      end
      event.badges = badges

      event
    end

    private

    def attendees(api)
      attendees = 0
      get_attendance(api: api).each do |a|
        attendees += 1 unless attendance_limit_includes_leaders && (a.grouping_id == -2)
      end
      attendees
    end

    def sort_by
      ['start', 'name', 'id']
    end

  end
end
