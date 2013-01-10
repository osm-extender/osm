module Osm

  class Evening < Osm::Model
    class Activity; end # Ensure the constant exists for the validators

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


    # Get the programme for a given term
    # @param [Osm::Api] api The api to use to make the request
    # @param [Osm::Section, Fixnum] section the section (or its ID) to get the programme for
    # @param [Osm::term, Fixnum, nil] term the term (or its ID) to get the programme for, passing nil causes the current term to be used
    # @!macro options_get
    # @return [Array<Osm::Evening>]
    def self.get_programme(api, section, term, options={})
      section_id = section.to_i
      term_id = term.nil? ? Osm::Term.get_current_term_for_section(api, section).id : term.to_i
      cache_key = ['programme', section_id, term_id]

      if !options[:no_cache] && cache_exist?(api, cache_key) && get_user_permission(api, section_id, :programme).include?(:read)
        return cache_read(api, cache_key)
      end

      data = api.perform_query("programme.php?action=getProgramme&sectionid=#{section_id}&termid=#{term_id}")

      result = Array.new
      data = {'items'=>[],'activities'=>{}} if data.is_a? Array
      items = data['items'] || []
      activities = data['activities'] || {}

      items.each do |item|
        attributes = {}
        attributes[:id] = Osm::to_i_or_nil(item['eveningid'])
        attributes[:section_id] = Osm::to_i_or_nil(item['sectionid'])
        attributes[:title] = item['title'] || 'Unnamed meeting'
        attributes[:notes_for_parents] = item['notesforparents'] || ''
        attributes[:games] = item['games'] || ''
        attributes[:pre_notes] = item['prenotes'] || ''
        attributes[:post_notes] = item['postnotes'] || ''
        attributes[:leaders] = item['leaders'] || ''
        attributes[:start_time] = item['starttime'].nil? ? nil : item['starttime'][0..4]
        attributes[:finish_time] = item['endtime'].nil? ? nil : item['endtime'][0..4]
        attributes[:meeting_date] = Osm::parse_date(item['meetingdate'])
  
        our_activities = activities[item['eveningid']]
        attributes[:activities] = Array.new
        unless our_activities.nil?
          our_activities.each do |activity_data|
            attributes[:activities].push Osm::Evening::Activity.new(
              :activity_id => Osm::to_i_or_nil(activity_data['activityid']),
              :title => activity_data['title'],
              :notes => activity_data['notes'],
            )
          end
        end
  
        result.push new(attributes)
      end

      cache_write(api, cache_key, result)
      return result
    end


    # Create an evening in OSM
    # @param [Osm::Api] api The api to use to make the request
    # @param [Osm::Section, Fixnum] section or section_id to add the evening to
    # @param [Date] meeting_date the date of the meeting
    # @return [Boolean] if the operation suceeded or not
    def self.create(api, section, meeting_date)
      section_id = section.to_i
      api_data = {
        'meetingdate' => meeting_date.strftime(Osm::OSM_DATE_FORMAT),
        'sectionid' => section_id,
        'activityid' => -1
      }

      data = api.perform_query("programme.php?action=addActivityToProgramme", api_data)

      # The cached programmes for the section will be out of date - remove them
      Osm::Term.get_for_section(api, section).each do |term|
        cache_delete(api, ['programme', section_id, term.id])
      end

      return data.is_a?(Hash) && (data['result'] == 0)
    end


    # Update an evening in OSM
    # @param [Osm::Api] api The api to use to make the request
    # @return [Boolean] if the operation suceeded or not
    def update(api)
      raise ObjectIsInvalid, 'evening is invalid' unless valid?

      activities_data = Array.new
      activities.each do |activity|
        this_activity = {
          'activityid' => activity.activity_id,
          'notes' => activity.notes,
        }
        activities_data.push this_activity
      end
      activities_data = ActiveSupport::JSON.encode(activities_data)

      api_data = {
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
        'activity' => activities_data,
      }
      response = api.perform_query("programme.php?action=editEvening", api_data)

      # The cached programmes for the section will be out of date - remove them
      Osm::Term.get_for_section(api, section_id).each do |term|
        cache_delete(api, ['programme', section_id, term.id]) if term.contains_date?(meeting_date)
      end

      return response.is_a?(Hash) && (response['result'] == 0)
    end

    # Delete evening from OSM
    # @param [Osm::Api] api The api to use to make the request
    # @return [Boolean] true
    def delete(api)
      data = api.perform_query("programme.php?action=deleteEvening&eveningid=#{id}&sectionid=#{section_id}")

      # The cached programmes for the section will be out of date - remove them
      Osm::Term.get_for_section(api, section_id).each do |term|
        cache_delete(api, ['programme', section_id, term.id]) if term.contains_date?(meeting_date)
      end

      return true
    end


    # Get the badge requirements met on a specific evening
    # @param [Osm::Api] api The api to use to make the request
    # @!macro options_get
    # @return [Array<Hash>] hashes ready to pass into the update_register method
    def get_badge_requirements(api, options={})
      section = Osm::Section.get(api, section_id)
      cache_key = ['badge_requirements', section.id, id]

      if !options[:no_cache] && cache_exist?(api, cache_key) && get_user_permission(api, section_id, :programme).include?(:read)
        return cache_read(api, cache_key)
      end

      data = api.perform_query("users.php?action=getActivityRequirements&date=#{meeting_date.strftime(Osm::OSM_DATE_FORMAT)}&sectionid=#{section.id}&section=#{section.type}")

      cache_write(api, cache_key, data)
      return data
    end


    private
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

    end # Class Evening::Activity

  end # Class Evening

end # Module
