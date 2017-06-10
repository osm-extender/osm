module Osm

  class Meeting < Osm::Model
    # @!attribute [rw] id
    #   @return [Integer] the id of the meeting
    # @!attribute [rw] section_id
    #   @return [Integer] the section the meeting belongs to
    # @!attribute [rw] title
    #   @return [String] the title of the meeting
    # @!attribute [rw] notes_for_parents
    #   @return [String] notes to be shared with parents
    # @!attribute [rw] games
    #   @return [String] games to be played during the meeting
    # @!attribute [rw] pre_notes
    #   @return [String] notes for the start of the meeting
    # @!attribute [rw] post_notes
    #   @return [String] notes for the end of the meeting
    # @!attribute [rw] leaders
    #   @return [String] the leaders present at the meeting
    # @!attribute [rw] date
    #   @return [Date] the date of the meeting
    # @!attribute [rw] activities
    #   @return [Array<Activity>] list of activities being done during the meeting
    # @!attribute [rw] badge_links
    #   @return [Array<BadgeLink>] list of badge links added to the meeting
    # @!attribute [rw] start_time
    #   @return [String] the start time (hh:mm)
    # @!attribute [rw] finish_time
    #   @return [String] the end time (hh:mm)

    attribute :id, type: Integer
    attribute :section_id, type: Integer
    attribute :title, type: String, default: 'Unnamed meeting'
    attribute :notes_for_parents, type: String, default: ''
    attribute :games, type: String, default: ''
    attribute :pre_notes, type: String, default: ''
    attribute :post_notes, type: String, default: ''
    attribute :leaders, type: String, default: ''
    attribute :date, type: Date
    attribute :start_time, type: String
    attribute :finish_time, type: String
    attribute :activities, default: []
    attribute :badge_links, default: []

    validates_numericality_of :id, only_integer: true, greater_than: 0
    validates_numericality_of :section_id, only_integer: true, greater_than: 0
    validates_presence_of :title
    validates_presence_of :date
    validates_format_of :start_time, with: Osm::OSM_TIME_REGEX, message: 'is not in the correct format (HH:MM)', allow_blank: true
    validates_format_of :finish_time, with: Osm::OSM_TIME_REGEX, message: 'is not in the correct format (HH:MM)', allow_blank: true
    validates :activities, array_of: { item_type: Osm::Meeting::Activity, item_valid: true }
    validates :badge_links, array_of: { item_type: Osm::Meeting::BadgeLink, item_valid: true }

    # @!method initialize
    #   Initialize a new Meeting
    #   @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)


    # Get the programme for a given term
    # @param api [Osm::Api] The api to use to make the request
    # @param section [Osm::Section, Integer, #to_i] The section (or its ID) to get the programme for
    # @param term [Osm::term, Integer, nil] The term (or its ID) to get the programme for, passing nil causes the current term to be used
    # @!macro options_get
    # @return [Array<Osm::Meeting>]
    def self.get_for_section(api:, section:, term: nil, no_read_cache: false)
      require_ability_to(api: api, to: :read, on: :programme, section: section, no_read_cache: no_read_cache)
      section_id = section.to_i
      term_id = term.nil? ? Osm::Term.get_current_term_for_section(api: api, section: section).id : term.to_i
      cache_key = ['programme', section_id, term_id]

      cache_fetch(api: api, key: cache_key, no_read_cache: no_read_cache) do
        data = api.post_query("programme.php?action=getProgramme&sectionid=#{section_id}&termid=#{term_id}")
        data = { 'items'=>[],'activities'=>{} } if data.is_a? Array
        items = data['items'] || []
        activities = data['activities'] || {}
        badge_links = data['badgelinks'] || {}

        items.map do |item|
          attributes = {}
          attributes[:id] = Osm.to_i_or_nil(item['eveningid'])
          attributes[:section_id] = Osm.to_i_or_nil(item['sectionid'])
          attributes[:title] = item['title'] || 'Unnamed meeting'
          attributes[:notes_for_parents] = item['notesforparents'] || ''
          attributes[:games] = item['games'] || ''
          attributes[:pre_notes] = item['prenotes'] || ''
          attributes[:post_notes] = item['postnotes'] || ''
          attributes[:leaders] = item['leaders'] || ''
          attributes[:start_time] = item['starttime'].nil? ? nil : item['starttime'][0..4]
          attributes[:finish_time] = item['endtime'].nil? ? nil : item['endtime'][0..4]
          attributes[:date] = Osm.parse_date(item['meetingdate'])

          our_activities = activities[item['eveningid']]
          attributes[:activities] = Array.new
          unless our_activities.nil?
            our_activities.each do |activity_data|
              if activity_data.is_a?(Array)
                activity_data = activity_data.find{ |a| a.is_a?(Hash) && a.has_key?('activityid') }
              end
              attributes[:activities].push Osm::Meeting::Activity.new(
                activity_id: Osm.to_i_or_nil(activity_data['activityid']),
                title: activity_data['title'],
                notes: activity_data['notes']
              )
            end
          end # unless our_activities.nil?

          our_badge_links = badge_links[item['eveningid']]
          attributes[:badge_links] = Array.new
          unless our_badge_links.nil?
            our_badge_links.each do |badge_data|
              attributes[:badge_links].push Osm::Meeting::BadgeLink.new(
                badge_type: badge_data['badgetype'].to_sym,
                badge_section: badge_data['section'].to_sym,
                badge_name: badge_data['badgeLongName'],
                badge_id: Osm.to_i_or_nil(badge_data['badge_id']),
                badge_version: Osm.to_i_or_nil(badge_data['badge_version']),
                requirement_id: Osm.to_i_or_nil(badge_data['column_id']),
                requirement_label: badge_data['columnnameLongName'],
                data: badge_data['data']
              )
            end
          end # unless our_badge_links.nil?
          new(attributes)
        end # items.map
      end # cache fetch
    end


    # Create a meeting in OSM
    # @param api [Osm::Api] The api to use to make the request
    # @param **attributes [] The attributes for the meeting to create
    # @return [Osm::Meeting, nil] the created meeting, nil if failed
    def self.create(api, **attributes)
      require_ability_to(api: api, to: :write, on: :programme, section: attributes[:section_id])
      meeting = new(**attributes)

      data = api.post_query('programme.php?action=addActivityToProgramme', post_data: {
        'meetingdate' => meeting.date.strftime(Osm::OSM_DATE_FORMAT),
        'sectionid' => meeting.section_id,
        'activityid' => -1,
        'start' => meeting.date.strftime(Osm::OSM_DATE_FORMAT),
        'starttime' => meeting.start_time,
        'endtime' => meeting.finish_time,
        'title' => meeting.title
      })

      # The cached programmes for the section will be out of date - remove them
      Osm::Term.get_for_section(api, meeting.section_id).each do |term|
        cache_delete(api: api, cache_key: ['programme', meeting.section_id, term.id])
      end

      data.is_a?(Hash) ? meeting : nil
    end


    # Update a meeting in OSM
    # @param api [Osm::Api] The api to use to make the request
    # @return true, false if the operation suceeded or not
    # @raise [Osm::ObjectIsInvalid] If the Meeting is invalid
    def update(api)
      fail Osm::ObjectIsInvalid, 'meeting is invalid' unless valid?
      require_ability_to(api: api, to: :write, on: :programme, section: section_id)

      activities_data = Array.new
      activities.each do |activity|
        this_activity = {
          'activityid' => activity.activity_id,
          'notes' => activity.notes
        }
        activities_data.push this_activity
      end

      api_data = {
        'eveningid' => id,
        'sectionid' => section_id,
        'meetingdate' => date.strftime(Osm::OSM_DATE_FORMAT),
        'starttime' => start_time,
        'endtime' => finish_time,
        'title' => title,
        'notesforparents' => notes_for_parents,
        'prenotes' => pre_notes,
        'postnotes' => post_notes,
        'games' => games,
        'leaders' => leaders,
        'activity' => activities_data.to_json,
        'badgelinks' => badge_links.map{ |b|
          {
            'badge_id' => b.badge_id.to_s,
            'badge_version' => b.badge_version.to_s,
            'column_id' => b.requirement_id.to_s,
            'badge' => nil,
            'badgeLongName' => b.badge_name,
            'columnname' => nil,
            'columnnameLongName' => b.requirement_label,
            'data' => b.data,
            'section' => b.badge_section,
            'sectionLongName' => nil,
            'badgetype' => b.badge_type.to_s,
            'badgetypeLongName' => nil
          }
        }.to_json
      }
      response = api.post_query('programme.php?action=editEvening', post_data: api_data)

      if response.is_a?(Hash) && response['result'].zero?
        reset_changed_attributes
        # The cached programmes for the section will be out of date - remove them
        Osm::Term.get_for_section(api, section_id).each do |term|
          cache_delete(api: api, key: ['programme', section_id, term.id]) if term.contains_date?(date)
        end
        return true
      else
        return false
      end
    end

    # Add an activity to this meeting in OSM
    # @param api [Osm::Api] The api to use to make the request
    # @param activity [Osm::Activity] The Activity to add to the Meeting
    # @param notes [String] The notes which should appear for this Activity on this Meeting
    # @return true, false Whether the activity ws successfully added
    def add_activity(api:, activity:, notes: '')
      if activity.add_to_programme(api: api, section: section_id, date: date, notes: notes)
        activities.push Osm::Meeting::Activity.new(activity_id: activity.id, notes: notes, title: activity.title)

        # The cached programmes for the section will be out of date - remove them
        Osm::Term.get_for_section(api, section_id).each do |term|
          cache_delete(api: api, key: ['programme', section_id, term.id]) if term.contains_date?(date)
        end

        return true
      end

      false
    end

    # Delete meeting from OSM
    # @param api [Osm::Api] The api to use to make the request
    # @return true, false true
    def delete(api)
      require_ability_to(api: api, to: :write, on: :programme, section: section_id)
      data = api.post_query("programme.php?action=deleteEvening&eveningid=#{id}&sectionid=#{section_id}")

      # The cached programmes for the section will be out of date - remove them
      Osm::Term.get_for_section(api, section_id).each do |term|
        cache_delete(api: api, key: ['programme', section_id, term.id]) if term.contains_date?(date)
      end

      true
    end


    # Get the badge requirements met on a specific meeting
    # Requires either write permission to badges (prefered as it's one OSM query)
    # or read permission to programme.
    # @param api [Osm::Api] The api to use to make the request
    # @!macro options_get
    # @return [Array<Hash>] hashes ready to pass into the update_register method
    # @return [nil] if something went wrong
    def get_badge_requirements(api, no_read_cache: false)
      section = Osm::Section.get(api: api, id: section_id)
      cache_key = ['badge_requirements', section.id, id]

      cache_fetch(api: api, key: cache_key, no_read_cache: no_read_cache) do
        badges = nil

        if has_permission?(api: api, to: :write, on: :badge, section: section_id, no_read_cache: no_read_cache)
          # We can shortcut and do it in one query
          badges = api.post_query("users.php?action=getActivityRequirements&date=#{date.strftime(Osm::OSM_DATE_FORMAT)}&sectionid=#{section.id}&section=#{section.type}")
        else
          # We'll have to iterate through the activities
          require_ability_to(api: api, to: :read, on: :programme, section: section_id, no_read_cache: no_read_cache)
          links = badge_links
          activities.each do |activity|
            activity = Osm::Activity.get(api: api, id: activity.activity_id, no_read_cache: no_read_cache)
            links += activity.badges
          end

          badges = []
          links.each do |badge|
            badges.push(              'badge' => nil,#"activity_animalcarer",
              'badge_id' => badge.badge_id,
              'badge_version' => badge.badge_version,
              'column_id' => badge.requirement_id,
              'badgeName' => badge.badge_name,
              'badgetype' => badge.badge_type,
              'columngroup' => nil,#"A",
              'columnname' => nil,#"a",
              'data' => badge.data,
              'eveningid' => id,
              'meetingdate' => date,
              'name' => badge.requirement_label,
              'section' => badge.badge_section,
              'sectionid' => section_id)
          end
        end # if to pick which method to use to get the data from OSM

        badges
      end # cache fetch
    end


    private def sort_by
      ['section_id', 'date', 'start_time', 'id']
    end

  end
end
