module Osm

  class Evening
    class Activity; end # Ensure the constant exists for the validators

    include ::ActiveAttr::MassAssignmentSecurity
    include ::ActiveAttr::Model

    # @!attribute [rw] id
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
    # @!attribute [rw] finish_time
    #   @return [String] the end time (hh:mm)

    attribute :id, :type => Integer
    attribute :section_id, :type => Integer
    attribute :title, :type => String, :default => 'Unnamed meeting'
    attribute :notes_for_parents, :type => String, :default => ''
    attribute :games, :type => String, :default => ''
    attribute :pre_notes, :type => String, :default => ''
    attribute :post_notes, :type => String, :default => ''
    attribute :leaders, :type => String, :default => ''
    attribute :meeting_date, :type => Date
    attribute :start_time, :type => String
    attribute :finish_time, :type => String
    attribute :activities, :default => []

    attr_accessible :id, :section_id, :title, :notes_for_parents, :games, :pre_notes, :post_notes, :leaders, :meeting_date, :activities, :start_time, :finish_time

    validates_numericality_of :id, :only_integer=>true, :greater_than=>0
    validates_numericality_of :section_id, :only_integer=>true, :greater_than=>0
    validates_presence_of :title
    validates_presence_of :meeting_date
    validates_format_of :start_time, :with => Osm::OSM_TIME_REGEX, :message => 'is not in the correct format (HH:MM)', :allow_blank => true
    validates_format_of :finish_time, :with => Osm::OSM_TIME_REGEX, :message => 'is not in the correct format (HH:MM)', :allow_blank => true

    validates :activities, :array_of => {:item_type => Osm::Evening::Activity, :item_valid => true}

    # @!method initialize
    #   Initialize a new Evening
    #   @param [Hash] attributes the hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)


    # Initialize a new Evening from api data
    # @param [Hash] data the hash of data provided by the API
    # @param activities an array of hashes to generate the list of ProgrammeActivity objects
    def self.from_api(data, activities)
      attributes = {}
      attributes[:id] = Osm::to_i_or_nil(data['eveningid'])
      attributes[:section_id] = Osm::to_i_or_nil(data['sectionid'])
      attributes[:title] = data['title'] || 'Unnamed meeting'
      attributes[:notes_for_parents] = data['notesforparents'] || ''
      attributes[:games] = data['games'] || ''
      attributes[:pre_notes] = data['prenotes'] || ''
      attributes[:post_notes] = data['postnotes'] || ''
      attributes[:leaders] = data['leaders'] || ''
      attributes[:start_time] = data['starttime'].nil? ? nil : data['starttime'][0..4]
      attributes[:finish_time] = data['endtime'].nil? ? nil : data['endtime'][0..4]
      attributes[:meeting_date] = Osm::parse_date(data['meetingdate'])

      attributes[:activities] = Array.new
      unless activities.nil?
        activities.each do |item|
          attributes[:activities].push Evening::Activity.from_api(item)
        end
      end

      new(attributes)
    end

    # Get the evening's data for use with the API
    # @return [Hash]
    def to_api
      {
        'eveningid' => id,
        'sectionid' => section_id,
        'meetingdate' => meeting_date.strftime(Osm::OSM_DATE_FORMAT),
        'starttime' => start_time,
        'endtime' => finish_time,
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
      activities.each do |activity|
        this_activity = {
          'activityid' => activity.activity_id,
          'notes' => activity.notes,
        }
        to_save.push this_activity
      end
      return ActiveSupport::JSON.encode(to_save)
    end


    class Activity
      include ::ActiveAttr::MassAssignmentSecurity
      include ::ActiveAttr::Model

      # @!attribute [rw] activity_id
      #   @return [Fixnum] the activity being done
      # @!attribute [rw] title
      #   @return [String] the activity's title
      # @!attribute [rw] notes
      #   @return [String] notes relevant to doing this activity on this evening

      attribute :activity_id, :type => Integer
      attribute :title, :type => String
      attribute :notes, :type => String, :default => ''

      attr_accessible :activity_id, :title, :notes

      validates_numericality_of :activity_id, :only_integer=>true, :greater_than=>0
      validates_presence_of :title


      # @!method initialize
      #   Initialize a new Evening::Activity
      #   @param [Hash] attributes the hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)

  
      # Initialize a new Evening::Activity from api data
      # @param [Hash] data the hash of data provided by the API
      def self.from_api(data)
        new({
          :activity_id => Osm::to_i_or_nil(data['activityid']),
          :title => data['title'],
          :notes => data['notes'],
        })
      end

    end # Class Evening::Activity

  end # Class Evening

end # Module
