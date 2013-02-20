module Osm

  class Event < Osm::Model
    class Column; end # Ensure the constant exists for the validators

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
    #   @return [String] the cost of the event
    # @!attribute [rw] location
    #   @return [String] where the event is
    # @!attribute [rw] notes
    #   @return [String] notes about the event
    # @!attribute [rw] archived
    #   @return [Boolean] if the event has been archived
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

    attribute :id, :type => Integer
    attribute :section_id, :type => Integer
    attribute :name, :type => String
    attribute :start, :type => DateTime
    attribute :finish, :type => DateTime
    attribute :cost, :type => String, :default => ''
    attribute :location, :type => String, :default => ''
    attribute :notes, :type => String, :default => ''
    attribute :archived, :type => Boolean, :default => false
    attribute :columns, :default => []
    attribute :notepad, :type => String, :default => ''
    attribute :public_notepad, :type => String, :default => ''
    attribute :confirm_by_date, :type => Date
    attribute :allow_changes, :type => Boolean, :default => false
    attribute :reminders, :type => Boolean, :default => true
    attribute :attendance_limit, :type => Integer, :default => 0
    attribute :attendance_limit_includes_leaders, :type => Boolean, :default => false

    attr_accessible :id, :section_id, :name, :start, :finish, :cost, :location, :notes, :archived,
                    :fields, :columns, :notepad, :public_notepad, :confirm_by_date, :allow_changes,
                    :reminders, :attendance_limit, :attendance_limit_includes_leaders

    validates_numericality_of :id, :only_integer=>true, :greater_than=>0, :allow_nil => true
    validates_numericality_of :section_id, :only_integer=>true, :greater_than=>0
    validates_numericality_of :attendance_limit, :only_integer=>true, :greater_than_or_equal_to=>0
    validates_presence_of :name
    validates :columns, :array_of => {:item_type => Osm::Event::Column, :item_valid => true}
    validates_inclusion_of :allow_changes, :in => [true, false]
    validates_inclusion_of :reminders, :in => [true, false]
    validates_inclusion_of :attendance_limit_includes_leaders, :in => [true, false]


    # @!method initialize
    #   Initialize a new Event
    #   @param [Hash] attributes the hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)


    # Get events for a section
    # @param [Osm::Api] api The api to use to make the request
    # @param [Osm::Section, Fixnum] section the section (or its ID) to get the events for
    # @!macro options_get
    # @option options [Boolean] :include_archived (optional) if true then archived activities will also be returned
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
            event = self.new_event_from_data(event_data)
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

    # Get an event
    # @param [Osm::Api] api The api to use to make the request
    # @param [Osm::Section, Fixnum] section the section (or its ID) to get the events for
    # @param [Fixnum] event_id the id of the event to get
    # @!macro options_get
    # @option options [Boolean] :include_archived (optional) if true then archived activities will also be returned
    # @return [Osm::Event, nil] the event (or nil if it couldn't be found
    def self.get(api, section, event_id, options={})
      require_ability_to(api, :read, :events, section, options)
      section_id = section.to_i
      cache_key = ['event', event_id]

      if !options[:no_cache] && cache_exist?(api, cache_key)
        return cache_read(api, cache_key)
      end

      event_data = api.perform_query("events.php?action=getEvent&sectionid=#{section_id}&eventid=#{event_id}")
      return self.new_event_from_data(event_data)
    end


    # Create an event in OSM
    # @param [Osm::Api] api The api to use to make the request
    # @return [Osm::Event, nil] the created event, nil if failed
    def self.create(api, parameters)
      require_ability_to(api, :write, :events, parameters[:section_id])
      event = new(parameters)
      raise ObjectIsInvalid, 'event is invalid' unless event.valid?

      data = api.perform_query("events.php?action=addEvent&sectionid=#{event.section_id}", {
        'name' => event.name,
        'location' => event.location,
        'startdate' => event.start? ? event.start.strftime(Osm::OSM_DATE_FORMAT) : '',
        'enddate' => event.finish? ? event.finish.strftime(Osm::OSM_DATE_FORMAT) : '',
        'cost' => event.cost,
        'notes' => event.notes,
        'starttime' => event.start? ? event.start.strftime(Osm::OSM_TIME_FORMAT) : '',
        'endtime' => event.finish? ? event.finish.strftime(Osm::OSM_TIME_FORMAT) : '',
        'confdate' => event.confirm_by_date? ? event.confirm_by_date.strftime(Osm::OSM_DATE_FORMAT) : '',
        'allowChanges' => event.allow_changes ? 'true' : 'false',
        'disablereminders' => !event.reminders ? 'true' : 'false',
        'attendancelimit' => event.attendance_limit,
        'limitincludesleaders' => event.attendance_limit_includes_leaders,
      })

      # The cached events for the section will be out of date - remove them
      cache_delete(api, ['events', event.section_id])
      cache_write(api, ['event', event.id], event)

      if (data.is_a?(Hash) && data.has_key?('id'))
        event.id = data['id'].to_i
        return event
      else
        return nil
      end
    end

    # Update event in OSM
    # @param [Osm::Api] api The api to use to make the request
    # @return [Boolean] whether the update succedded
    def update(api)
      require_ability_to(api, :write, :events, section_id)

      to_update = changed_attributes

      data = api.perform_query("events.php?action=addEvent&sectionid=#{section_id}", {
        'eventid' => id,
        'name' => name,
        'location' => location,
        'startdate' => start? ? start.strftime(Osm::OSM_DATE_FORMAT) : '',
        'enddate' => finish? ? finish.strftime(Osm::OSM_DATE_FORMAT) : '',
        'cost' => cost,
        'notes' => notes,
        'starttime' => start? ? start.strftime(Osm::OSM_TIME_FORMAT) : '',
        'endtime' => finish? ? finish.strftime(Osm::OSM_TIME_FORMAT) : '',
        'confdate' => confirm_by_date? ? confirm_by_date.strftime(Osm::OSM_DATE_FORMAT) : '',
        'allowChanges' => allow_changes ? 'true' : 'false',
        'disablereminders' => !reminders ? 'true' : 'false',
        'attendancelimit' => attendance_limit,
        'limitincludesleaders' => attendance_limit_includes_leaders,
      })

      api.perform_query("events.php?action=saveNotepad&sectionid=#{section_id}", {
        'eventid' => id,
        'notepad' => notepad,
      }) if to_update.include?('notepad')

      api.perform_query("events.php?action=saveNotepad&sectionid=#{section_id}", {
        'eventid' => id,
        'pnnotepad' => public_notepad,
      }) if to_update.include?('public_notepad')

      # The cached event will be out of date - remove it
      cache_delete(api, ['event', id])

      return data.is_a?(Hash) && (data['id'].to_i == id)
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
    # @param [Osm::Term, Fixnum, nil] term the term (or its ID) to get the members for, passing nil causes the current term to be used
    # @!macro options_get
    # @option options [Boolean] :include_archived (optional) if true then archived activities will also be returned
    # @return [Array<Osm::Event::Attendance>]
    def get_attendance(api, term=nil, options={})
      require_ability_to(api, :read, :events, section_id, options)
      term_id = term.nil? ? Osm::Term.get_current_term_for_section(api, section_id).id : term.to_i
      cache_key = ['event_attendance', id]

      if !options[:no_cache] && cache_exist?(api, cache_key)
        return cache_read(api, cache_key)
      end

      data = api.perform_query("events.php?action=getEventAttendance&eventid=#{id}&sectionid=#{section_id}&termid=#{term_id}")
      data = data['items']

      attendance = []
      data.each_with_index do |item, index|
        item.merge!({
          'dob' => item['dob'].nil? ? nil : Osm::parse_date(item['dob'], :ignore_epoch => true),
          'attending' => item['attending'].eql?('Yes'),
        })

        attendance.push Osm::Event::Attendance.new(
          :event => self,
          :member_id => Osm::to_i_or_nil(item['scoutid']),
          :grouping_id => Osm::to_i_or_nil(item['patrolid'].eql?('') ? nil : item['patrolid']),
          :fields => item.select { |key, value|
            ['firstname', 'lastname', 'dob', 'attending'].include?(key) || key.to_s.match(/\Af_\d+\Z/)
          },
          :row => index,
        )
      end

      cache_write(api, cache_key, attendance)
      return attendance
    end


    # Add a column to the event in OSM
    # @param [Osm::Api] api The api to use to make the request
    # @param [String] label the label for the field in OSM
    # @param [String] name the label for the field in My.SCOUT (if this is blank then parents can't edit it)
    # @return [Boolean] whether the update succedded
    def add_column(api, name, label='')
      require_ability_to(api, :write, :events, section_id)
      raise ArgumentIsInvalid, 'name is invalid' if name.blank?

      data = api.perform_query("events.php?action=addColumn&sectionid=#{section_id}&eventid=#{id}", {
        'columnName' => name,
        'parentLabel' => label
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


    private
    def attendees(api)
      attendees = 0
      get_attendance(api).each do |a|
        attendees += 1 unless attendance_limit_includes_leaders && (a.grouping_id == -2)
      end
      return attendees
    end

    def self.new_event_from_data(event_data)
      event = Osm::Event.new(
        :id => Osm::to_i_or_nil(event_data['eventid']),
        :section_id => Osm::to_i_or_nil(event_data['sectionid']),
        :name => event_data['name'],
        :start => Osm::make_datetime(event_data['startdate'], event_data['starttime']),
        :finish => Osm::make_datetime(event_data['enddate'], event_data['endtime']),
        :cost => event_data['cost'],
        :location => event_data['location'],
        :notes => event_data['notes'],
        :archived => event_data['archived'].eql?('1'),
        :notepad => event_data['notepad'],
        :public_notepad => event_data['publicnotes'],
        :confirm_by_date => Osm::parse_date(event_data['confdate']),
        :allow_changes => event_data['allowchanges'].eql?('1'),
        :reminders => !event_data['disablereminders'].eql?('1'),
        :attendance_limit => event_data['attendancelimit'].to_i,
        :attendance_limit_includes_leaders => event_data['limitincludesleaders'].eql?('1'),
      )

      columns = []
      ActiveSupport::JSON.decode(event_data['config']).each do |field|
        columns.push Column.new(:id => field['id'], :name => field['name'], :label => field['pL'], :event => event)
      end
      event.columns = columns
      return event
    end


    class Column
      include ::ActiveAttr::MassAssignmentSecurity
      include ::ActiveAttr::Model
  
      # @!attribute [rw] id
      #   @return [String] OSM id for the column
      # @!attribute [rw] name
      #   @return [String] name for the column (displayed in OSM)
      # @!attribute [rw] label
      #   @return [String] label to display in My.SCOUT ("" prevents display in My.SCOUT)
      # @!attriute [rw] event
      #   @return [Osm::Event] the event that this column belongs to

      attribute :id, :type => String
      attribute :name, :type => String
      attribute :label, :type => String, :default => ''
      attribute :event

      attr_accessible :id, :name, :label, :event

      validates_presence_of :id
      validates_presence_of :name


      # @!method initialize
      #   Initialize a new Column
      #   @param [Hash] attributes the hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)


      # Update event column in OSM
      # @param [Osm::Api] api The api to use to make the request
      # @return [Boolean] if the operation suceeded or not
      def update(api)
        Osm::Model.require_ability_to(api, :write, :events, event.section_id)

        data = api.perform_query("events.php?action=renameColumn&sectionid=#{event.section_id}&eventid=#{event.id}", {
          'columnId' => id,
          'columnName' => name,
          'pL' => label
        })

        # The cached event will be out of date - remove it
        Osm::Model.cache_delete(api, ['event', event.id])
        # The cached event attedance will be out of date
        Osm::Model.cache_delete(api, ['event_attendance', event.id])

        (ActiveSupport::JSON.decode(data['config']) || []).each do |i|
          if i['id'] == id
            return i['name'].eql?(name) && (i['pL'].nil? || i['pL'].eql?(label))
          end
        end
        return false
      end

      # Delete event column from OSM
      # @param [Osm::Api] api The api to use to make the request
      # @return [Boolean] whether the delete succedded
      def delete(api)
        Osm::Model.require_ability_to(api, :write, :events, event.section_id)

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

        Osm::Model.cache_write(api, ['event', event.id], event)
        return true
      end

    end # class Column


    class Attendance < Osm::Model  
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
  
      attribute :row, :type => Integer
      attribute :member_id, :type => Integer
      attribute :grouping_id, :type => Integer
      attribute :fields, :default => {}
      attribute :event
  
      attr_accessible :member_id, :grouping_id, :fields, :row, :event
  
      validates_numericality_of :row, :only_integer=>true, :greater_than_or_equal_to=>0
      validates_numericality_of :member_id, :only_integer=>true, :greater_than=>0
      validates_numericality_of :grouping_id, :only_integer=>true, :greater_than_or_equal_to=>-2
      validates :fields, :hash => {:key_type => String}
      validates_each :event do |record, attr, value|
        record.event.valid?
      end

  
      # @!method initialize
      #   Initialize a new Attendance
      #   @param [Hash] attributes the hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)


      # Update event attendance
      # @param [Osm::Api] api The api to use to make the request
      # @param [String] field_id the id of the field to update (must be 'attending' or /\Af_\d+\Z/)
      # @return [Boolean] if the operation suceeded or not
      def update(api, field_id)
        require_ability_to(api, :write, :events, event.section_id)
        raise ArgumentIsInvalid, 'field_id is invalid' unless field_id.match(/\Af_\d+\Z/) || field_id.eql?('attending')

        data = api.perform_query("events.php?action=updateScout", {
          'scoutid' => member_id,
          'column' => field_id,
          'value' => !field_id.eql?('attending') ? fields[field_id] : (fields['attending'] ? 'Yes' : 'No'),
          'sectionid' => event.section_id,
          'row' => row,
          'eventid' => event.id,
        })
  
        # The cached event attedance will be out of date
        Osm::Model.cache_delete(api, ['event_attendance', event.id])
  
        return data.is_a?(Hash)
      end

    end # Class Attendance

  end # Class Event

end # Module
