module Osm

  class Evening

    attr_accessor :evening_id, :section_id, :title, :notes_for_parents, :games, :pre_notes, :post_notes, :leaders, :meeting_date, :activities
    attr_reader :start_time, :end_time
    # @!attribute [rw] evening_id
    #   @return [Fixnum] the id of the evening
    # @!attribute [rw] section_id
    #   @return [Fixnum] the section the evening belongs to
    # @!attribute [rw] title
    #   @return [String] the title of the evening
    # @!attribute [rw] notes_for_parents
    #   @return [String] notes to be shared with parents
    # @!attribute [rw] games
    #   @return [String] games to be played during the evening
    # @!attribute [rw] pre_notes
    #   @return [String] notes for the start of the evening
    # @!attribute [rw] post_notes
    #   @return [String] notes for the end of the evening
    # @!attribute [rw] leaders
    #   @return [String] the leaders present at the evening
    # @!attribute [rw] meeting_date
    #   @return [Date] the date of the evening
    # @!attribute [rw] activities
    #   @return [Array<Activity>] list of activities being done during the evening
    # @!attribute [rw] start_time
    #   @return [String] the start time (hh:mm)
    # @!attribute [rw] end_time
    #   @return [String] the end time (hh:mm)

    # Initialize a new Evening
    # @param [Hash] attributes the hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)
    def initialize(attributes={})
      [:evening_id, :section_id].each do |attribute|
        raise ArgumentError, ":#{attribute} must be nil or a Fixnum > 0" unless attributes[attribute].nil? || (attributes[attribute].is_a?(Fixnum) && attributes[attribute] > 0)
      end
      [:title, :notes_for_parents, :games, :pre_notes, :post_notes, :leaders].each do |attribute|
        raise ArgumentError, ":#{attribute} must be nil or a String" unless (attributes[attribute].nil? || attributes[attribute].is_a?(String))
      end
      raise ArgumentError, ':meeting_date must be a Date' unless attributes[:meeting_date].is_a?(Date)
      raise ArgumentError, ':activities must be nil or an Array of Osm::Evening::Activity' unless (attributes[:activities].nil? || Osm::is_array_of?(attributes[:activities], Osm::Evening::Activity))

      attributes.each { |k,v| send("#{k}=", v) }

      @activities ||= []
      @title ||= 'Unnamed meeting'
      [:notes_for_parents, :games, :pre_notes, :post_notes, :leaders].each do |attribute|
        instance_variable_set("@#{attribute}", '') if instance_variable_get("@#{attribute}").nil?
      end
    end


    # Initialize a new Evening from api data
    # @param [Hash] data the hash of data provided by the API
    # @param activities an array of hashes to generate the list of ProgrammeActivity objects
    def self.from_api(data, activities)
      attributes = {}
      attributes[:evening_id] = Osm::to_i_or_nil(data['eveningid'])
      attributes[:section_id] = Osm::to_i_or_nil(data['sectionid'])
      attributes[:title] = data['title'] || 'Unnamed meeting'
      attributes[:notes_for_parents] = data['notesforparents'] || ''
      attributes[:games] = data['games'] || ''
      attributes[:pre_notes] = data['prenotes'] || ''
      attributes[:post_notes] = data['postnotes'] || ''
      attributes[:leaders] = data['leaders'] || ''
      attributes[:start_time] = data['starttime'].nil? ? nil : data['starttime'][0..4]
      attributes[:end_time] = data['endtime'].nil? ? nil : data['endtime'][0..4]
      attributes[:meeting_date] = Osm::parse_date(data['meetingdate'])

      attributes[:activities] = Array.new
      unless activities.nil?
        activities.each do |item|
          attributes[:activities].push Evening::Activity.from_api(item)
        end
      end

      new(attributes)
    end

    # Custom setters for times
    [:start, :end].each do |attribute|
      define_method "#{attribute}_time=" do |value|
        unless value.nil?
          value = value.strftime('%H:%M') unless value.is_a?(String)
          raise ArgumentError, 'invalid time' unless /\A(?:[0-1][0-9]|2[0-3]):[0-5][0-9]\Z/.match(value)
        end
        instance_variable_set("@#{attribute}_time", value)
      end
    end

    # Get the evening's data for use with the API
    # @return [Hash]
    def to_api
      {
        'eveningid' => evening_id,
        'sectionid' => section_id,
        'meetingdate' => meeting_date.strftime(Osm::OSM_DATE_FORMAT),
        'starttime' => start_time,
        'endtime' => end_time,
        'title' => title,
        'notesforparents' => notes_for_parents,
        'prenotes' => pre_notes,
        'postnotes' => post_notes,
        'games' => games,
        'leaders' => leaders,
        'activity' => activities_for_to_api,
      }
    end


    private
    # Get the JSON for the activities to pass to the OSM API
    # @return [String]
    def activities_for_to_api
      to_save = Array.new
      @activities.each do |activity|
        this_activity = {
          'activityid' => activity.activity_id,
          'notes' => activity.notes,
        }
        to_save.push this_activity
      end
      return ActiveSupport::JSON.encode(to_save)
    end


    class Activity

      attr_reader :activity_id, :title, :notes
      # @!attribute [r] activity_id
      #   @return [Fixnum] the activity being done
      # @!attribute [r] title
      #   @return [String] the activity's title
      # @!attribute [r] notes
      #   @return [String] notes relevant to doing this activity on this evening
  
      # Initialize a new Evening::Activity
      # @param [Hash] attributes the hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)
      def initialize(attributes={})
        raise ArgumentError, ':activity_id must be a Fixnum > 0' unless (attributes[:activity_id].is_a?(Fixnum) && attributes[:activity_id] > 0)
        raise ArgumentError, ':title must be nil or a String' unless (attributes[:title].nil? || attributes[:title].is_a?(String))
        raise ArgumentError, ':notes must be nil or a String' unless (attributes[:notes].nil? || attributes[:notes].is_a?(String))
  
        attributes.each { |k,v| instance_variable_set("@#{k}", v) }
      end


      # Initialize a new Evening::Activity from api data
      # @param [Hash] data the hash of data provided by the API
      def self.from_api(data)
        new({
          :activity_id => Osm::to_i_or_nil(data['activityid']),
          :title => data['title'],
          :notes => data['notes'],
        })
      end

    end


  end

end
