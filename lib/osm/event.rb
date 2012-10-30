module Osm

  class Event < Osm::Model

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
    # @!attribute [rw] fields
    #   @return [Hash] Keys are the field's id, values are the field names

    attribute :id, :type => Integer
    attribute :section_id, :type => Integer
    attribute :name, :type => String
    attribute :start, :type => DateTime
    attribute :finish, :type => DateTime
    attribute :cost, :type => String, :default => ''
    attribute :location, :type => String, :default => ''
    attribute :notes, :type => String, :default => ''
    attribute :archived, :type => Boolean, :default => false
    attribute :fields, :default => {}

    attr_accessible :id, :section_id, :name, :start, :finish, :cost, :location, :notes, :archived, :fields

    validates_numericality_of :id, :only_integer=>true, :greater_than=>0, :allow_nil => true
    validates_numericality_of :section_id, :only_integer=>true, :greater_than=>0
    validates_presence_of :name
    validates :fields, :hash => {:key_type => String, :value_type => String}


    # @!method initialize
    #   Initialize a new Term
    #   @param [Hash] attributes the hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)


    # Get events for a section
    # @param [Osm::Api] api The api to use to make the request
    # @param [Osm::Section, Fixnum] section the section (or its ID) to get the events for
    # @!macro options_get
    # @option options [Boolean] :include_archived (optional) if true then archived activities will also be returned
    # @return [Array<Osm::Event>]
    def self.get_for_section(api, section, options={})
      section_id = section.to_i
      cache_key = ['events', section_id]
      events = nil

      if !options[:no_cache] && cache_exist?(api, cache_key) && get_user_permission(api, section_id, :events).include?(:read)
        return cache_read(api, cache_key)
      end

      data = api.perform_query("events.php?action=getEvents&sectionid=#{section_id}&showArchived=true")

      events = Array.new
      unless data['items'].nil?
        data['items'].each do |item|
          event_id = Osm::to_i_or_nil(item['eventid'])
          fields_data = api.perform_query("events.php?action=getEvent&sectionid=#{section_id}&eventid=#{event_id}")
          fields = {}
          ActiveSupport::JSON.decode(fields_data['config']).each do |field|
            fields[field['id']] = field['name']
          end

          event = Osm::Event.new(
            :id => event_id,
            :section_id => Osm::to_i_or_nil(item['sectionid']),
            :name => item['name'],
            :start => Osm::make_datetime(item['startdate'], item['starttime']),
            :finish => Osm::make_datetime(item['enddate'], item['endtime']),
            :cost => item['cost'],
            :location => item['location'],
            :notes => item['notes'],
            :archived => item['archived'].eql?('1'),
            :fields => fields,
          )
          events.push event
          cache_write(api, ['event', event.id], event)
        end
      end
      cache_write(api, cache_key, events)

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
      section_id = section.to_i
      cache_key = ['event', event_id]

      if !options[:no_cache] && cache_exist?(api, cache_key) && get_user_permission(api, section_id, :events).include?(:read)
        return cache_read(api, cache_key)
      end

      events = get_for_section(api, section, options)
      return nil unless events.is_a? Array

      events.each do |event|
        return event if event.id == event_id
      end

      return nil
    end


    # Create an event in OSM
    # @param [Osm::Api] api The api to use to make the request
    # @return [Osm::Event, nil] the created event, nil if failed
    def self.create(api, parameters)
      event = new(parameters)
      raise ObjectIsInvalid, 'event is invalid' unless event.valid?
      raise Forbidden, 'you do not have permission to write to events for this section' unless get_user_permission(api, event.section_id, :events).include?(:write)

      data = api.perform_query("events.php?action=addEvent&sectionid=#{event.section_id}", {
        'name' => event.name,
        'location' => event.location,
        'startdate' => event.start.strftime(Osm::OSM_DATE_FORMAT),
        'enddate' => event.finish.strftime(Osm::OSM_DATE_FORMAT),
        'cost' => event.cost,
        'notes' => event.notes,
        'starttime' => event.start.strftime(Osm::OSM_TIME_FORMAT),
        'endtime' => event.finish.strftime(Osm::OSM_TIME_FORMAT),
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
    # @return [Boolean] wether the update succedded
    def update(api)
      raise Forbidden, 'you do not have permission to write to events for this section' unless get_user_permission(api, section_id, :events).include?(:write)

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
      })

      # The cached events for the section will be out of date - remove them
      cache_delete(api, ['event', id])
      cache_delete(api, ['events', section_id])

      return data.is_a?(Hash) && (data['id'].to_i == id)
    end

    # Delete event from OSM
    # @param [Osm::Api] api The api to use to make the request
    # @return [Boolean] wether the delete succedded
    def delete(api)
      raise Forbidden, 'you do not have permission to write to events for this section' unless get_user_permission(api, section_id, :events).include?(:write)

      data = api.perform_query("events.php?action=deleteEvent&sectionid=#{section_id}&eventid=#{id}")

      # The cached events for the section will be out of date - remove them
      cache_delete(api, ['events', section_id])
      cache_delete(api, ['event', id])

      return data.is_a?(Hash) ? data['ok'] : false
    end


    # Get event attendance
    # @param [Osm::Api] api The api to use to make the request
    # @param [Osm::Term, Fixnum, nil] term the term (or its ID) to get the members for, passing nil causes the current term to be used
    # @!macro options_get
    # @option options [Boolean] :include_archived (optional) if true then archived activities will also be returned
    # @return [Array<Osm::Event::Attendance>]
    def get_attendance(api, term=nil, options={})
      term_id = term.nil? ? Osm::Term.get_current_term_for_section(api, section).id : term.to_i
      cache_key = ['event_attendance', id]

      if !options[:no_cache] && cache_exist?(api, cache_key) && get_user_permission(api, section_id, :events).include?(:read)
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


    # Add a field in OSM
    # @param [Osm::Api] api The api to use to make the request
    # @param [String] field_label the label for the field to add
    # @return [Boolean] wether the update succedded
    def add_field(api, label)
      raise ArgumentIsInvalid, 'label is invalid' if label.blank?
      raise Forbidden, 'you do not have permission to write to events for this section' unless get_user_permission(api, section_id, :events).include?(:write)

      data = api.perform_query("events.php?action=addColumn&sectionid=#{section_id}&eventid=#{id}", {
        'columnName' => label
      })

      # The cached events for the section will be out of date - remove them
      cache_delete(api, ['events', section_id])
      cache_delete(api, ['event', id])
      cache_delete(api, ['event_attendance', id])

      return data.is_a?(Hash) && (data['eventid'].to_i == id)
    end



    class Attendance
      include ::ActiveAttr::MassAssignmentSecurity
      include ::ActiveAttr::Model
  
      # @!attribute [rw] member_id
      #   @return [Fixnum] OSM id for the member
      # @!attribute [rw] grouping__id
      #   @return [Fixnum] OSM id for the grouping the member is in
      # @!attribute [rw] fields
      #   @return [Hash] Keys are the field's id, values are the field values
      # @!attribute [rw] row
      #   @return [Fixnum] part of the OSM API
  
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
      #   Initialize a new FlexiRecordData
      #   @param [Hash] attributes the hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)


      # Update event attendance
      # @param [Osm::Api] api The api to use to make the request
      # @param [String] field_id the id of the field to update (must be 'attending' or /\Af_\d+\Z/)
      # @return [Boolean] if the operation suceeded or not
      def update(api, field_id)
        raise ArgumentIsInvalid, 'field_id is invalid' unless field_id.match(/\Af_\d+\Z/) || field_id.eql?('attending')
        raise Forbidden, 'you do not have permission to write to events for this section' unless Osm::Model.get_user_permission(api, event.section_id, :events).include?(:write)

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
