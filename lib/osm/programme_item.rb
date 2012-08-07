module Osm

  class ProgrammeItem

    attr_accessor :evening_id, :section_id, :title, :notes_for_parents, :games, :pre_notes, :post_notes, :leaders, :meeting_date, :activities
    attr_reader :start_time, :end_time
    # @!attribute [rw] evening_id
    #   @return [FixNum] the id of the evening
    # @!attribute [rw] sectionid
    #   @return [FixNum] the section the evening belongs to
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
    #   @return [Array<ProgrammeActivity>] tlist of activities being done during the evening
    # @!attribute [rw] start_time
    #   @return [String] the start time (hh:mm)
    # @!attribute [rw] end_time
    #   @return [String] the end time (hh:mm)

    # Initialize a new ProgrammeItem using the hash returned by the API call
    # @param data the hash of data for the object returned by the API
    # @param activities an array of hashes to generate the list of ProgrammeActivity objects
    def initialize(data, activities)
      @evening_id = Osm::to_i_or_nil(data['eveningid'])
      @section_id = Osm::to_i_or_nil(data['sectionid'])
      @title = data['title'] || 'Unnamed meeting'
      @notes_for_parents = data['notesforparents'] || ''
      @games = data['games'] || ''
      @pre_notes = data['prenotes'] || ''
      @post_notes = data['postnotes'] || ''
      @leaders = data['leaders'] || ''
      @start_time = data['starttime'].nil? ? nil : data['starttime'][0..4]
      @end_time = data['endtime'].nil? ? nil : data['endtime'][0..4]
      @meeting_date = Osm::parse_date(data['meetingdate'])

      @activities = Array.new
      unless activities.nil?
        activities.each do |item|
          @activities.push Osm::ProgrammeActivity.new(item)
        end
      end
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


    # Get the JSON for the activitied to pass to the OSM API
    # @return [String]
    def activities_for_saving
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

  end

end
