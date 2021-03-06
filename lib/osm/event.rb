module Osm

  class Event < Osm::Model
    class BadgeLink < Osm::Model; end # Ensure the constant exists for the validators
    class Column < Osm::Model; end # Ensure the constant exists for the validators

    LIST_ATTRIBUTES = [:id, :section_id, :name, :start, :finish, :cost, :location, :notes, :archived, :public_notepad, :confirm_by_date, :allow_changes, :reminders, :attendance_limit, :attendance_limit_includes_leaders, :attendance_reminder, :allow_booking]
    EXTRA_ATTRIBUTES = [:notepad, :columns, :badges]
    SORT_BY = [:start, :name, :id]

    # @!attribute [rw] id
    #   @return [Fixnum] the id for the event
    # @!attribute [rw] section_id
    #   @return [Fixnum] the id for the section
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
    #   @return [Boolean] if the event has been archived
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
    #   @return [Boolean] whether parent's can change their child's details
    # @!attribute [rw] reminders
    #   @return [Boolean] whether email reminders are sent for the event
    # @!attribute [rw] attendance_limit
    #   @return [Fixnum] the maximum number of people who can attend the event (0 = no limit)
    # @!attendance [rw] attendance_limit_includes_leaders
    #   @return [Boolean] whether the attendance limit includes leaders
    # @!attribute [rw] attendance_reminder
    #   @return [Fixnum] how many days before the event to send a reminder to those attending (0 (off), 1, 3, 7, 14, 21, 28)
    # @!attribute [rw] allow_booking
    #   @return [Boolean] whether booking is allowed through My.SCOUT

    attribute :id, :type => Integer
    attribute :section_id, :type => Integer
    attribute :name, :type => String
    attribute :start, :type => DateTime
    attribute :finish, :type => DateTime
    attribute :cost, :type => String, :default => 'TBC'
    attribute :location, :type => String, :default => ''
    attribute :notes, :type => String, :default => ''
    attribute :archived, :type => Boolean, :default => false
    attribute :badges, :default => []
    attribute :files, :default => []
    attribute :columns, :default => []
    attribute :notepad, :type => String, :default => ''
    attribute :public_notepad, :type => String, :default => ''
    attribute :confirm_by_date, :type => Date
    attribute :allow_changes, :type => Boolean, :default => false
    attribute :reminders, :type => Boolean, :default => true
    attribute :attendance_limit, :type => Integer, :default => 0
    attribute :attendance_limit_includes_leaders, :type => Boolean, :default => false
    attribute :attendance_reminder, :type => Integer, :default => 0
    attribute :allow_booking, :type => Boolean, :default => true

    if ActiveModel::VERSION::MAJOR < 4
      attr_accessible :id, :section_id, :name, :start, :finish, :cost, :location, :notes, :archived,
                      :fields, :badges, :files, :columns, :notepad, :public_notepad, :confirm_by_date,
                      :allow_changes, :reminders, :attendance_limit, :attendance_limit_includes_leaders,
                      :attendance_reminder, :allow_booking
    end

    validates_numericality_of :id, :only_integer=>true, :greater_than=>0, :allow_nil => true
    validates_numericality_of :section_id, :only_integer=>true, :greater_than=>0
    validates_numericality_of :attendance_limit, :only_integer=>true, :greater_than_or_equal_to=>0
    validates_presence_of :name
    validates :badges, :array_of => {:item_type => Osm::Event::BadgeLink, :item_valid => true}
    validates :columns, :array_of => {:item_type => Osm::Event::Column, :item_valid => true}
    validates :files, :array_of => {:item_type => String}
    validates_inclusion_of :allow_changes, :in => [true, false]
    validates_inclusion_of :reminders, :in => [true, false]
    validates_inclusion_of :attendance_limit_includes_leaders, :in => [true, false]
    validates_inclusion_of :allow_booking, :in => [true, false]
    validates_inclusion_of :attendance_reminder, :in => [0, 1, 3, 7, 14, 21, 28]
    validates_format_of :cost, :with => /\A(?:\d+\.\d{2}|TBC)\Z/


    # @!method initialize
    #   Initialize a new Event
    #   @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)


    # Get events for a section
    # @param [Osm::Api] api The api to use to make the request
    # @param [Osm::Section, Fixnum, #to_i] section The section (or its ID) to get the events for
    # @!macro options_get
    # @option options [Boolean] :include_archived (optional) if true then archived events will also be returned
    # @return [Array<Osm::Event>]
    def self.get_for_section(api, section, options={})
      require_ability_to(api, :read, :events, section, options)
      section_id = section.to_i
      cache_key = ['events', section_id]
      events = nil

      if !options[:no_cache] && cache_exist?(api, cache_key)
        ids = cache_read(api, cache_key)
        events = get_from_ids(api, ids, 'event', section, options, :get_for_section)
      end

      if events.nil?
        data = api.perform_query("events.php?action=getEvents&sectionid=#{section_id}&showArchived=true")
        events = Array.new
        ids = Array.new
        unless data['items'].nil?
          data['items'].map { |i| i['eventid'].to_i }.each do |event_id|
            event_data = api.perform_query("events.php?action=getEvent&sectionid=#{section_id}&eventid=#{event_id}")
            files_data = api.perform_query("ext/uploads/events/?action=listAttachments&sectionid=#{section_id}&eventid=#{event_id}")
            files = files_data.is_a?(Hash) ? files_data['files'] : files_data
            files = [] unless files.is_a?(Array)

            event = self.new_event_from_data(event_data)
            event.files = files
            events.push event
            ids.push event.id
            cache_write(api, ['event', event.id], event)
          end
        end
        cache_write(api, cache_key, ids)
      end

      return events if options[:include_archived]
      return events.reject do |event|
        event.archived?
      end
    end

    # Get event list for a section (not all details for each event)
    # @param [Osm::Api] api The api to use to make the request
    # @param [Osm::Section, Fixnum, #to_i] section The section (or its ID) to get the events for
    # @!macro options_get
    # @return [Array<Hash>]
    def self.get_list(api, section, options={})
      require_ability_to(api, :read, :events, section, options)
      section_id = section.to_i
      cache_key = ['events_list', section_id]
      events_cache_key = ['events', section_id]
      events = nil

      unless options[:no_cache]

        # Try getting from cache
        if cache_exist?(api, cache_key)
          return cache_read(api, cache_key)
        end
  
        # Try generating from cached events
        if cache_exist?(api, events_cache_key)
          ids = cache_read(api, events_cache_key)
          events = get_from_ids(api, ids, 'event', section, options, :get_for_section).map do |e|
            e.attributes.symbolize_keys.select do |k,v|
              LIST_ATTRIBUTES.include?(k)
            end
          end
        end

      end

      # Fetch from OSM
      if events.nil?
        data = api.perform_query("events.php?action=getEvents&sectionid=#{section_id}&showArchived=true")
        events = Array.new
        unless data['items'].nil?
          data['items'].map do |event_data|
            events.push(attributes_from_data(event_data))
          end
        end
      end

      cache_write(api, cache_key, events)
      return events
    end

    # Get an event
    # @param [Osm::Api] api The api to use to make the request
    # @param [Osm::Section, Fixnum, #to_i] section The section (or its ID) to get the events for
    # @param [Fixnum, #to_i] event_id The id of the event to get
    # @!macro options_get
    # @return [Osm::Event, nil] the event (or nil if it couldn't be found
    def self.get(api, section, event_id, options={})
      require_ability_to(api, :read, :events, section, options)
      section_id = section.to_i
      event_id = event_id.to_i
      cache_key = ['event', event_id]

      if !options[:no_cache] && cache_exist?(api, cache_key)
        return cache_read(api, cache_key)
      end

      event_data = api.perform_query("events.php?action=getEvent&sectionid=#{section_id}&eventid=#{event_id}")
      return self.new_event_from_data(event_data)
    end


    # Create an event in OSM
    # If something goes wrong adding badges to OSM then the event returned will have been read from OSM
    # @param [Osm::Api] api The api to use to make the request
    # @return [Osm::Event, nil] the created event, nil if failed
    # @raise [Osm::ObjectIsInvalid] If the Event is invalid
    def self.create(api, parameters)
      require_ability_to(api, :write, :events, parameters[:section_id])
      event = new(parameters)
      raise Osm::ObjectIsInvalid, 'event is invalid' unless event.valid?

      data = api.perform_query("events.php?action=addEvent&sectionid=#{event.section_id}", {
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
        'allowbooking' => event.allow_booking ? 'true' : 'false',
      })

      if (data.is_a?(Hash) && data.has_key?('id'))
        event.id = data['id'].to_i

        # The cached events for the section will be out of date - remove them
        cache_delete(api, ['events', event.section_id])

        # Add badge links to OSM
        badges_created = true
        event.badges.each do |badge|
          badges_created &= event.add_badge_link(api, badge)
        end

        if badges_created
          cache_write(api, ['event', event.id], event)
          return event
        else
          # Someting went wrong adding badges so return what OSM has
          return get(api, event.section_id, event.id)
        end
      else
        return nil
      end
    end

    # Update event in OSM
    # @param [Osm::Api] api The api to use to make the request
    # @return [Boolean] whether the update succedded (will return true if no updates needed to be made)
    def update(api)
      require_ability_to(api, :write, :events, section_id)
       updated = true

      # Update main attributes
      update_main_attributes = false
      %w{ id name location start finish cost cost_tbc notes confirm_by_date allow_changes reminders attendance_limit attendance_limit_includes_leaders allow_booking }.each do |a|
        if changed_attributes.include?(a)
          update_main_attributes = true
          break # no use checking the others
        end
      end
      if update_main_attributes
        data = api.perform_query("events.php?action=addEvent&sectionid=#{section_id}", {
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
          'allowbooking' => allow_booking ? 'true' : 'false',
        })
        updated &= data.is_a?(Hash) && (data['id'].to_i == id)
      end

      # Private notepad
      if changed_attributes.include?('notepad')
        data = api.perform_query("events.php?action=saveNotepad&sectionid=#{section_id}", {
          'eventid' => id,
          'notepad' => notepad,
        })
        updated &= data.is_a?(Hash)
      end

      # MySCOUT notepad
      if changed_attributes.include?('public_notepad')
        data = api.perform_query("events.php?action=saveNotepad&sectionid=#{section_id}", {
          'eventid' => id,
          'pnnotepad' => public_notepad,
        })
        updated &= data.is_a?(Hash)
      end

      # Badges
      if changed_attributes.include?('badges')
        original_badges = @original_attributes['badges'] || []

        # Deleted badges
        badges_to_delete = []
        original_badges.each do |badge|
          unless badges.include?(badge)
            badges_to_delete.push badge
          end
        end
        badges_to_delete.each do |badge|
          data = api.perform_query("ext/badges/records/index.php?action=deleteBadgeLink&sectionid=#{section_id}", {
            'section' => badge.badge_section,
            'sectionid' => section_id,
            'type' => 'event',
            'id' => id,
            'badge_id' => badge.badge_id,
            'badge_version' => badge.badge_version,
            'column_id' => badge.requirement_id,
          })
          updated &= data.is_a?(Hash) && data['status']
        end

        # Added badges
        badges.each do |badge|
          unless original_badges.include?(badge)
            updated &= add_badge_link(api, badge)
          end
        end
      end # includes badges

      if updated
        reset_changed_attributes
        # The cached event will be out of date - remove it
        cache_delete(api, ['event', id])
        return true
      else
        return false
      end
    end

    # Delete event from OSM
    # @param [Osm::Api] api The api to use to make the request
    # @return [Boolean] whether the delete succedded
    def delete(api)
      require_ability_to(api, :write, :events, section_id)

      data = api.perform_query("events.php?action=deleteEvent&sectionid=#{section_id}&eventid=#{id}")

      if data.is_a?(Hash) && data['ok']
        cache_delete(api, ['event', id])
        return true
      end
      return false
    end


    # Get event attendance
    # @param [Osm::Api] api The api to use to make the request
    # @param [Osm::Term, Fixnum, #to_i, nil] term The term (or its ID) to get the members for, passing nil causes the current term to be used
    # @!macro options_get
    # @option options [Boolean] :include_archived (optional) if true then archived activities will also be returned
    # @return [Array<Osm::Event::Attendance>]
    def get_attendance(api, term=nil, options={})
      require_ability_to(api, :read, :events, section_id, options)
      term_id = term.nil? ? Osm::Term.get_current_term_for_section(api, section_id).id : term.to_i
      cache_key = ['event_attendance', id, term_id]

      if !options[:no_cache] && cache_exist?(api, cache_key)
        return cache_read(api, cache_key)
      end

      data = api.perform_query("events.php?action=getEventAttendance&eventid=#{id}&sectionid=#{section_id}&termid=#{term_id}")
      data = data['items'] || []

      payment_values = {
        'Manual' => :manual,
        'Automatic' => :automatic,
      }
      attending_values = {
        'Yes' => :yes,
        'No' => :no,
        'Invited' => :invited,
        'Show in My.SCOUT' => :shown,
        'Reserved' => :reserved,
      }

      attendance = []
      data.each_with_index do |item, index|
        attendance.push Osm::Event::Attendance.new(
          :event => self,
          :member_id => Osm::to_i_or_nil(item['scoutid']),
          :grouping_id => Osm::to_i_or_nil(item['patrolid'].eql?('') ? nil : item['patrolid']),
          :first_name => item['firstname'],
          :last_name => item['lastname'],
          :date_of_birth => item['dob'].nil? ? nil : Osm::parse_date(item['dob'], :ignore_epoch => true),
          :attending => attending_values[item['attending']],
          :payment_control => payment_values[item['payment']],
          :fields => item.select { |key, value| key.to_s.match(/\Af_\d+\Z/) }
                         .inject({}){ |h,(k,v)| h[k[2..-1].to_i] = v; h },
          :payments => item.select { |key, value| key.to_s.match(/\Ap\d+\Z/) }
                           .inject({}){ |h,(k,v)| h[k[1..-1].to_i] = v; h },
          :row => index,
        )
      end

      cache_write(api, cache_key, attendance)
      return attendance
    end

    # Add a badge link to the event in OSM
    # @param [Osm::Api] api The api to use to make the request
    # @param [Osm::Event::BadgeLink] link The badge link to add, if column_id is nil then a new column is created with requirement_label as the name
    # @return [Boolean] whether the update succedded
    def add_badge_link(api, link)
      raise Osm::ObjectIsInvalid, 'link is invalid' unless link.valid?

      data = api.perform_query("ext/badges/records/index.php?action=linkBadgeToItem&sectionid=#{section_id}", {
        'section' => link.badge_section,
        'sectionid' => section_id,
        'type' => 'event',
        'id' => id,
        'badge_id' => link.badge_id,
        'badge_version' => link.badge_version,
        'column_id' => link.requirement_id.to_i.eql?(0) ? -2 : link.requirement_id,
        'column_data' => link.data,
        'new_column_name' => link.requirement_id.to_i.eql?(0) ? link.requirement_label : '',
      })
      return (data.is_a?(Hash) && data['status'])
    end

    # Add a column to the event in OSM
    # @param [Osm::Api] api The api to use to make the request
    # @param [String] label The label for the field in OSM
    # @param [String] name The label for the field in My.SCOUT (if this is blank then parents can't edit it)
    # @param [Boolean] required Whether the parent is required to enter something
    # @return [Boolean] whether the update succedded
    # @raise [Osm::ArgumentIsInvalid] If the name is blank
    def add_column(api, name, label='', required=false)
      require_ability_to(api, :write, :events, section_id)
      raise Osm::ArgumentIsInvalid, 'name is invalid' if name.blank?

      data = api.perform_query("events.php?action=addColumn&sectionid=#{section_id}&eventid=#{id}", {
        'columnName' => name,
        'parentLabel' => label,
        'parentRequire' => (required ? 1 : 0),
      })

      # The cached events for the section will be out of date - remove them
      cache_delete(api, ['events', section_id])
      cache_delete(api, ['event', id])
      cache_delete(api, ['event_attendance', id])

      self.columns = self.class.new_event_from_data(data).columns

      return data.is_a?(Hash) && (data['eventid'].to_i == id)
    end

    # Whether thete is a limit on attendance for this event
    # @return [Boolean] whether thete is a limit on attendance for this event
    def limited_attendance?
      (attendance_limit != 0)
    end

    # Whether there are spaces left for the event
    # @param [Osm::Api] api The api to use to make the request
    # @return [Boolean] whether there are spaces left for the event
    def spaces?(api)
      return true unless limited_attendance?
      return attendance_limit > attendees(api)
    end

    # Get the number of spaces left for the event
    # @param [Osm::Api] api The api to use to make the request
    # @return [Fixnum, nil] the number of spaces left (nil if there is no attendance limit)
    def spaces(api)
      return nil unless limited_attendance?
      return attendance_limit - attendees(api)
    end

    # Whether the cost is to be confirmed
    # @return [Boolean] whether the cost is TBC
    def cost_tbc?
      cost.eql?('TBC')
    end

    # Whether the cost is zero
    # @return [Boolean] whether the cost is zero
    def cost_free?
      cost.eql?('0.00')
    end


    private
    def attendees(api)
      attendees = 0
      get_attendance(api).each do |a|
        attendees += 1 unless attendance_limit_includes_leaders && (a.grouping_id == -2)
      end
      return attendees
    end

    def self.attributes_from_data(event_data)
      {
        :id => Osm::to_i_or_nil(event_data['eventid']),
        :section_id => Osm::to_i_or_nil(event_data['sectionid']),
        :name => event_data['name'],
        :start => Osm::make_datetime(event_data['startdate'], event_data['starttime']),
        :finish => Osm::make_datetime(event_data['enddate'], event_data['endtime']),
        :cost => event_data['cost'].eql?('-1') ? 'TBC' : event_data['cost'],
        :location => event_data['location'],
        :notes => event_data['notes'],
        :archived => event_data['archived'].eql?('1'),
        :public_notepad => event_data['publicnotes'],
        :confirm_by_date => Osm::parse_date(event_data['confdate']),
        :allow_changes => event_data['allowchanges'].eql?('1'),
        :reminders => !event_data['disablereminders'].eql?('1'),
        :attendance_limit => event_data['attendancelimit'].to_i,
        :attendance_limit_includes_leaders => event_data['limitincludesleaders'].eql?('1'),
        :attendance_reminder => event_data['attendancereminder'].to_i,
        :allow_booking => event_data['allowbooking'].eql?('1'),
      }
    end

    def self.new_event_from_data(event_data)
      event = Osm::Event.new(attributes_from_data(event_data))
      event.notepad = event_data['notepad']

      columns = []
      config_raw = event_data['config']
      config_raw = '[]' if config_raw.blank?
      column_data = ActiveSupport::JSON.decode(config_raw)
      column_data = [] unless column_data.is_a?(Array)
      column_data.each do |field|
        columns.push Column.new(:id => field['id'], :name => field['name'], :label => field['pL'], :parent_required => field['pR'].to_s.eql?('1'), :event => event)
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
          badge_version: field['badge_version'],
        )
      end
      event.badges = badges

      return event
    end


    class BadgeLink
      include ActiveModel::MassAssignmentSecurity if ActiveModel::VERSION::MAJOR < 4
      include ActiveAttr::Model

      SORT_BY = [:badge_section, :badge_type, :badge_name, :requirement_label]

      # @!attribute [rw] badge_type
      #   @return [Symbol] the type of badge
      # @!attribute [rw] badge_section
      #   @return [Symbol] the section type that the badge belongs to
      # @!attribute [rw] requirement_label
      #   @return [String] human firendly requirement label
      # @!attribute [rw] data
      #   @return [String] what to put in the column when the badge records are updated
      # @!attribute [rw] badge_name
      #   @return [String] the badge's name
      # @!attribute [rw] badge_id
      #   @return [Fixnum] the badge's ID in OSM
      # @!attribute [rw] badge_version
      #   @return [Fixnum] the version of the badge
      # @!attribute [rw] requirement_id
      #   @return [Fixnum] the requirement's ID in OSM

      attribute :badge_type, :type => Object
      attribute :badge_section, :type => Object
      attribute :requirement_label, :type => String
      attribute :data, :type => String
      attribute :badge_name, :type => String
      attribute :badge_id, :type => Integer
      attribute :badge_version, :type => Integer
      attribute :requirement_id, :type => Integer

      if ActiveModel::VERSION::MAJOR < 4
        attr_accessible :badge_type, :badge_section, :requirement_label, :data, :badge_name, :badge_id, :badge_version, :requirement_id
      end

      validates_presence_of :badge_name
      validates_inclusion_of :badge_section, :in => [:beavers, :cubs, :scouts, :explorers, :staged]
      validates_inclusion_of :badge_type, :in => [:core, :staged, :activity, :challenge]
      validates_numericality_of :badge_id, :only_integer=>true, :greater_than=>0
      validates_numericality_of :badge_version, :only_integer=>true, :greater_than_or_equal_to=>0
      validates_numericality_of :requirement_id, :only_integer=>true, :greater_than=>0, :allow_nil=>true

      # @!method initialize
      #   Initialize a new Meeting::Activity
      #   @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)

    end # Class Event::BadgeLink


    class Column < Osm::Model
      SORT_BY = [:event, :id]

      # @!attribute [rw] id
      #   @return [String] OSM id for the column
      # @!attribute [rw] name
      #   @return [String] name for the column (displayed in OSM)
      # @!attribute [rw] label
      #   @return [String] label to display in My.SCOUT ("" prevents display in My.SCOUT)
      # @!attribute [rw] parent_required
      #   @return [Boolean] whether the parent is required to enter something
      # @!attriute [rw] event
      #   @return [Osm::Event] the event that this column belongs to

      attribute :id, :type => String
      attribute :name, :type => String
      attribute :label, :type => String, :default => ''
      attribute :parent_required, :type => Boolean, :default => false
      attribute :event

      if ActiveModel::VERSION::MAJOR < 4
        attr_accessible :id, :name, :label, :parent_required, :event
      end

      validates_presence_of :id
      validates_presence_of :name


      # @!method initialize
      #   Initialize a new Column
      #   @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)


      # Update event column in OSM
      # @param [Osm::Api] api The api to use to make the request
      # @return [Boolean] if the operation suceeded or not
      def update(api)
        require_ability_to(api, :write, :events, event.section_id)

        data = api.perform_query("events.php?action=renameColumn&sectionid=#{event.section_id}&eventid=#{event.id}", {
          'columnId' => id,
          'columnName' => name,
          'pL' => label,
          'pR' => (parent_required ? 1 : 0),
        })

        (ActiveSupport::JSON.decode(data['config']) || []).each do |i|
          if i['id'] == id
            if i['name'].eql?(name) && (i['pL'].nil? || i['pL'].eql?(label)) && (i['pR'].eql?('1') == parent_required)
              reset_changed_attributes
                # The cached event will be out of date - remove it
                cache_delete(api, ['event', event.id])
                # The cached event attedance will be out of date
                cache_delete(api, ['event_attendance', event.id])
              return true
            end
          end
        end
        return false
      end

      # Delete event column from OSM
      # @param [Osm::Api] api The api to use to make the request
      # @return [Boolean] whether the delete succedded
      def delete(api)
        require_ability_to(api, :write, :events, event.section_id)

        data = api.perform_query("events.php?action=deleteColumn&sectionid=#{event.section_id}&eventid=#{event.id}", {
          'columnId' => id
        })

        (ActiveSupport::JSON.decode(data['config']) || []).each do |i|
          return false if i['id'] == id
        end

        new_columns = []
        event.columns.each do |column|
          new_columns.push(column) unless column == self
        end
        event.columns = new_columns

        cache_write(api, ['event', event.id], event)
        return true
      end

      def inspect
        Osm.inspect_instance(self, options={:replace_with => {'event' => :id}})
      end

    end # class Column


    class Attendance < Osm::Model
      SORT_BY = [:event, :row]

      # @!attribute [rw] member_id
      #   @return [Fixnum] OSM id for the member
      # @!attribute [rw] grouping__id
      #   @return [Fixnum] OSM id for the grouping the member is in
      # @!attribute [rw] fields
      #   @return [Hash] Keys are the field's id, values are the field values
      # @!attribute [rw] row
      #   @return [Fixnum] part of the OSM API
      # @!attriute [rw] event
      #   @return [Osm::Event] the event that this attendance applies to
      # @!attribute [rw] first_name
      #   @return [String] the member's first name
      # @!attribute [rw] last_name
      #   @return [String] the member's last name
      # @!attribute [rw] date_of_birth
      #   @return [Date] the member's date of birth
      # @!attribute [rw] attending
      #   @return [Symbol] whether the member is attending (either :yes, :no, :invited, :shown, :reserved or nil)
      # @!attribute [rw] payments
      #   @return [Hash] keys are the payment's id, values are the payment state
      # @!attribute [rw] payment_control
      #   @return [Symbol] whether payments are done manually or automatically (either :manual, :automatic or nil)
  
      attribute :row, :type => Integer
      attribute :member_id, :type => Integer
      attribute :grouping_id, :type => Integer
      attribute :fields, :default => {}
      attribute :event
      attribute :first_name, :type => String
      attribute :last_name, :type => String
      attribute :date_of_birth, :type => Date
      attribute :attending
      attribute :payments, :default => {}
      attribute :payment_control

      if ActiveModel::VERSION::MAJOR < 4
        attr_accessible :member_id, :grouping_id, :fields, :row, :event, :first_name, :last_name, :date_of_birth, :attending, :payments, :payment_control
      end

      validates_numericality_of :row, :only_integer=>true, :greater_than_or_equal_to=>0
      validates_numericality_of :member_id, :only_integer=>true, :greater_than=>0
      validates_numericality_of :grouping_id, :only_integer=>true, :greater_than_or_equal_to=>-2
      validates :fields, :hash => { :key_type => Fixnum, :value_type => String }
      validates :payments, :hash => { :key_type => Fixnum, :value_type => String }
      validates_each :event do |record, attr, value|
        record.event.valid?
      end
      validates_presence_of :first_name
      validates_presence_of :last_name
      validates_presence_of :date_of_birth
      validates_inclusion_of :payment_control, :in => [:manual, :automatic, nil]
      validates_inclusion_of :attending, :in => [:yes, :no, :invited, :shown, :reserved, nil]


      # @!method initialize
      #   Initialize a new Attendance
      #   @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)
      old_initialize = instance_method(:initialize)
      define_method :initialize do |*args|
        ret_val = old_initialize.bind(self).call(*args)
        self.fields = DirtyHashy.new(self.fields)
        self.fields.clean_up!
        return ret_val
      end


      # Update event attendance
      # @param [Osm::Api] api The api to use to make the request
      # @return [Boolean] if the operation suceeded or not
      def update(api)
        require_ability_to(api, :write, :events, event.section_id)

        payment_values = {
          :manual => 'Manual',
          :automatic => 'Automatic',
        }
        attending_values = {
          :yes => 'Yes',
          :no => 'No',
          :invited => 'Invited',
          :shown => 'Show in My.SCOUT',
          :reserved => 'Reserved',
        }

        updated = true
        fields.changes.each do |field, (was,now)|
          data = api.perform_query("events.php?action=updateScout", {
            'scoutid' => member_id,
            'column' => "f_#{field}",
            'value' => now,
            'sectionid' => event.section_id,
            'row' => row,
            'eventid' => event.id,
          })
          updated = false unless data.is_a?(Hash)
        end

        if changed_attributes.include?('payment_control')
          data = api.perform_query("events.php?action=updateScout", {
            'scoutid' => member_id,
            'column' => 'payment',
            'value' => payment_values[payment_control],
            'sectionid' => event.section_id,
            'row' => row,
            'eventid' => event.id,
          })
          updated = false unless data.is_a?(Hash)
        end
        if changed_attributes.include?('attending')
          data = api.perform_query("events.php?action=updateScout", {
            'scoutid' => member_id,
            'column' => 'attending',
            'value' => attending_values[attending],
            'sectionid' => event.section_id,
            'row' => row,
            'eventid' => event.id,
          })
          updated = false unless data.is_a?(Hash)
        end

        if updated
          reset_changed_attributes
          fields.clean_up!
          # The cached event attedance will be out of date
          cache_delete(api, ['event_attendance', event.id])
        end
        return updated
      end

      # Get audit trail
      # @param [Osm::Api] api The api to use to make the request
      # @!macro options_get
      # @return [Array<Hash>]
      def get_audit_trail(api, options={})
        require_ability_to(api, :read, :events, event.section_id, options)
        cache_key = ['event\_attendance\_audit', event.id, member_id]

        if !options[:no_cache] && cache_exist?(api, cache_key)
          return cache_read(api, cache_key)
        end

        data = api.perform_query("events.php?action=getEventAudit&sectionid=#{event.section_id}&scoutid=#{member_id}&eventid=#{event.id}")
        data ||= []

        attending_values = {
          'Yes' => :yes,
          'No' => :no,
          'Invited' => :invited,
          'Show in My.SCOUT' => :shown,
          'Reserved' => :reserved,
        }

        trail = []
        data.each do |item|
          this_item = {
            :at => DateTime.strptime(item['date'], '%d/%m/%Y %H:%M'),
            :by => item['updatedby'].strip,
            :type => item['type'].to_sym,
            :description => item['desc'],
            :event_id => event.id,
            :member_id => member_id,
            :event_attendance => self,
          }
          if this_item[:type].eql?(:detail)
            results = this_item[:description].match(/\ASet '(?<label>.+)' to '(?<value>.+)'\Z/)
            this_item[:label] = results[:label]
            this_item[:value] = results[:value]
          end
          if this_item[:type].eql?(:attendance)
            results = this_item[:description].match(/\AAttendance: (?<attending>.+)\Z/)
            this_item[:attendance] = attending_values[results[:attending]]
          end
          trail.push this_item
        end

        cache_write(api, cache_key, trail)
        return trail
      end

      # @! method automatic_payments?
      #  Check wether payments are made automatically for this member
      #  @return [Boolean]
      # @! method manual_payments?
      #  Check wether payments are made manually for this member
      #  @return [Boolean]
      [:automatic, :manual].each do |payment_control_type|
        define_method "#{payment_control_type}_payments?" do
          payments == payment_control_type
        end
      end

      # @! method is_attending?
      #  Check wether the member has said they are attending the event
      #  @return [Boolean]
      # @! method is_not_attending?
      #  Check wether the member has said they are not attending the event
      #  @return [Boolean]
      # @! method is_invited?
      #  Check wether the member has been invited to the event
      #  @return [Boolean]
      # @! method is_shown?
      #  Check wether the member can see the event in My.SCOUT
      # @! method is_reserved?
      #  Check wether the member has reserved a space when one becomes availible
      #  @return [Boolean]
      [:attending, :not_attending, :invited, :shown, :reserved].each do |attending_type|
        define_method "is_#{attending_type}?" do
          attending == attending_type
        end
      end

      def inspect
        Osm.inspect_instance(self, options={:replace_with => {'event' => :id}})
      end

    end # Class Attendance

  end # Class Event

end # Module
