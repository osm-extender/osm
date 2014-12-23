module Osm

  class Meeting < Osm::Model
    class Activity; end # Ensure the constant exists for the validators
    class BadgeLink; end # Ensure the constant exists for the validators

    # @!attribute [rw] id
    #   @return [Fixnum] the id of the meeting
    # @!attribute [rw] section_id
    #   @return [Fixnum] the section the meeting belongs to
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

    attribute :id, :type => Integer
    attribute :section_id, :type => Integer
    attribute :title, :type => String, :default => 'Unnamed meeting'
    attribute :notes_for_parents, :type => String, :default => ''
    attribute :games, :type => String, :default => ''
    attribute :pre_notes, :type => String, :default => ''
    attribute :post_notes, :type => String, :default => ''
    attribute :leaders, :type => String, :default => ''
    attribute :date, :type => Date
    attribute :start_time, :type => String
    attribute :finish_time, :type => String
    attribute :activities, :default => []
    attribute :badge_links, :default => []

    if ActiveModel::VERSION::MAJOR < 4
      attr_accessible :id, :section_id, :title, :notes_for_parents, :games, :pre_notes, :post_notes, :leaders, :date, :activities, :start_time, :finish_time, :badge_links
    end

    validates_numericality_of :id, :only_integer=>true, :greater_than=>0
    validates_numericality_of :section_id, :only_integer=>true, :greater_than=>0
    validates_presence_of :title
    validates_presence_of :date
    validates_format_of :start_time, :with => Osm::OSM_TIME_REGEX, :message => 'is not in the correct format (HH:MM)', :allow_blank => true
    validates_format_of :finish_time, :with => Osm::OSM_TIME_REGEX, :message => 'is not in the correct format (HH:MM)', :allow_blank => true
    validates :activities, :array_of => {:item_type => Osm::Meeting::Activity, :item_valid => true}
    validates :badge_links, :array_of => {:item_type => Osm::Meeting::BadgeLink, :item_valid => true}

    # @!method initialize
    #   Initialize a new Meeting
    #   @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)


    # Get the programme for a given term
    # @param [Osm::Api] api The api to use to make the request
    # @param [Osm::Section, Fixnum, #to_i] section The section (or its ID) to get the programme for
    # @param [Osm::term, Fixnum, nil] term The term (or its ID) to get the programme for, passing nil causes the current term to be used
    # @!macro options_get
    # @return [Array<Osm::Meeting>]
    def self.get_for_section(api, section, term=nil, options={})
      require_ability_to(api, :read, :programme, section, options)
      section_id = section.to_i
      term_id = term.nil? ? Osm::Term.get_current_term_for_section(api, section).id : term.to_i
      cache_key = ['programme', section_id, term_id]

      if !options[:no_cache] && cache_exist?(api, cache_key)
        return cache_read(api, cache_key)
      end

      data = api.perform_query("programme.php?action=getProgramme&sectionid=#{section_id}&termid=#{term_id}")

      result = Array.new
      data = {'items'=>[],'activities'=>{}} if data.is_a? Array
      items = data['items'] || []
      activities = data['activities'] || {}
      badge_links = data['badgelinks'] || {}

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
        attributes[:date] = Osm::parse_date(item['meetingdate'])

        our_activities = activities[item['eveningid']]
        attributes[:activities] = Array.new
        unless our_activities.nil?
          our_activities.each do |activity_data|
            if activity_data.is_a?(Array)
              activity_data = activity_data.find{ |a| a.is_a?(Hash) && a.has_key?('activityid') }
            end
            attributes[:activities].push Osm::Meeting::Activity.new(
              :activity_id => Osm::to_i_or_nil(activity_data['activityid']),
              :title => activity_data['title'],
              :notes => activity_data['notes'],
            )
          end
        end

        our_badge_links = badge_links[item['eveningid']]
        attributes[:badge_links] = Array.new
        unless our_badge_links.nil?
          our_badge_links.each do |badge_data|
            attributes[:badge_links].push Osm::Meeting::BadgeLink.new(
              :badge_type => badge_data['badgetype'].to_sym,
              :badge_section => badge_data['section'].to_sym,
              :badge_name => badge_data['badgeLongName'],
              :badge_id => Osm::to_i_or_nil(badge_data['badge_id']),
              :badge_version => Osm::to_i_or_nil(badge_data['badge_version']),
              :requirement_id => Osm::to_i_or_nil(badge_data['column_id']),
              :requirement_label => badge_data['columnnameLongName'],
              :data => badge_data['data'],
            )
          end
        end

        result.push new(attributes)
      end

      cache_write(api, cache_key, result)
      return result
    end


    # Create a meeting in OSM
    # @param [Osm::Api] api The api to use to make the request
    # @return [Osm::Meeting, nil] the created meeting, nil if failed
    def self.create(api, parameters)
      require_ability_to(api, :write, :programme, parameters[:section_id])
      meeting = new(parameters)

      data = api.perform_query("programme.php?action=addActivityToProgramme", {
        'meetingdate' => meeting.date.strftime(Osm::OSM_DATE_FORMAT),
        'sectionid' => meeting.section_id,
        'activityid' => -1,
        'start' => meeting.date.strftime(Osm::OSM_DATE_FORMAT),
        'starttime' => meeting.start_time,
        'endtime' => meeting.finish_time,
        'title' => meeting.title,
      })

      # The cached programmes for the section will be out of date - remove them
      Osm::Term.get_for_section(api, meeting.section_id).each do |term|
        cache_delete(api, ['programme', meeting.section_id, term.id])
      end

      return data.is_a?(Hash) ? meeting : nil
    end


    # Update an meeting in OSM
    # @param [Osm::Api] api The api to use to make the request
    # @return [Boolean] if the operation suceeded or not
    # @raise [Osm::ObjectIsInvalid] If the Meeting is invalid
    def update(api)
      raise Osm::ObjectIsInvalid, 'meeting is invalid' unless valid?
      require_ability_to(api, :write, :programme, section_id)

      activities_data = Array.new
      activities.each do |activity|
        this_activity = {
          'activityid' => activity.activity_id,
          'notes' => activity.notes,
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
        'activity' => ActiveSupport::JSON.encode(activities_data),
        'badgelinks' => ActiveSupport::JSON.encode(badge_links.map{ |b|
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
            'badgetypeLongName' => nil,
          }
        })
      }
      response = api.perform_query("programme.php?action=editEvening", api_data)

      if response.is_a?(Hash) && (response['result'] == 0)
        reset_changed_attributes
        # The cached programmes for the section will be out of date - remove them
        Osm::Term.get_for_section(api, section_id).each do |term|
          cache_delete(api, ['programme', section_id, term.id]) if term.contains_date?(date)
        end
        return true
      else
        return false
      end
    end

    # Add an activity to this meeting in OSM
    # @param [Osm::Api] api The api to use to make the request
    # @param [Osm::Activity] activity The Activity to add to the Meeting
    # @param [String] notes The notes which should appear for this Activity on this Meeting
    # @return [Boolean] Whether the activity ws successfully added
    def add_activity(api, activity, notes='')
      if activity.add_to_programme(api, section_id, date, notes)
        activities.push Osm::Meeting::Activity.new(:activity_id => activity.id, :notes => notes, :title => activity.title)

        # The cached programmes for the section will be out of date - remove them
        Osm::Term.get_for_section(api, section_id).each do |term|
          cache_delete(api, ['programme', section_id, term.id]) if term.contains_date?(date)
        end

        return true
      end

      return false
    end

    # Delete meeting from OSM
    # @param [Osm::Api] api The api to use to make the request
    # @return [Boolean] true
    def delete(api)
      require_ability_to(api, :write, :programme, section_id)
      data = api.perform_query("programme.php?action=deleteEvening&eveningid=#{id}&sectionid=#{section_id}")

      # The cached programmes for the section will be out of date - remove them
      Osm::Term.get_for_section(api, section_id).each do |term|
        cache_delete(api, ['programme', section_id, term.id]) if term.contains_date?(date)
      end

      return true
    end


    # Get the badge requirements met on a specific meeting
    # Requires either write permission to badges (prefered as it's one OSM query)
    # or read permission to programme.
    # @param [Osm::Api] api The api to use to make the request
    # @!macro options_get
    # @return [Array<Hash>] hashes ready to pass into the update_register method
    # @return [nil] if something went wrong
    def get_badge_requirements(api, options={})
      section = Osm::Section.get(api, section_id)
      cache_key = ['badge_requirements', section.id, id]
      if !options[:no_cache] && cache_exist?(api, cache_key)
        return cache_read(api, cache_key)
      end
      badges = nil

      if has_permission?(api, :write, :badge, section_id, options)
        # We can shortcut and do it in one query
        badges = api.perform_query("users.php?action=getActivityRequirements&date=#{date.strftime(Osm::OSM_DATE_FORMAT)}&sectionid=#{section.id}&section=#{section.type}")

      else
        # We'll have to iterate through the activities
        require_ability_to(api, :read, :programme, section_id, options)

        links = badge_links
        activities.each do |activity|
          activity = Osm::Activity.get(api, activity.activity_id, nil, options)
          links += activity.badges
        end

        badges = []
        links.each do |badge|
          badges.push({
            "badge" => nil,#"activity_animalcarer",
            "badge_id" => badge.badge_id,
            "badge_version" => badge.badge_version,
            "column_id" => badge.requirement_id,
            "badgeName" => badge.badge_name,
            "badgetype" => badge.badge_type,
            "columngroup" => nil,#"A",
            "columnname" => nil,#"a",
            "data" => badge.data,
            "eveningid" => id,
            "meetingdate" => date,
            "name" => badge.requirement_label,
            "section" => badge.badge_section,
            "sectionid" => section_id
          })
        end
      end

      cache_write(api, cache_key, badges) unless badges.nil?
      return badges
    end

    # Compare Meeting based on section_id, date, start_time then id
    def <=>(another)
      result = self.section_id <=> another.try(:section_id)
      result = self.date <=> another.try(:date) if result == 0
      if result == 0
        my_start_time = self.start_time.split(':').map{ |i| i.to_i }
        another_start_time = another.start_time.split(':').map{ |i| i.to_i }
        result = my_start_time[0] <=> another_start_time[0] if result == 0
        result = compare = my_start_time[1] <=> another_start_time[1] if result == 0
      end  
      result = self.id <=> another.try(:id) if result == 0
      return result
    end


    private
    class Activity
      include ActiveModel::MassAssignmentSecurity if ActiveModel::VERSION::MAJOR < 4
      include ActiveAttr::Model

      # @!attribute [rw] activity_id
      #   @return [Fixnum] the activity being done
      # @!attribute [rw] title
      #   @return [String] the activity's title
      # @!attribute [rw] notes
      #   @return [String] notes relevant to doing this activity on this meeting

      attribute :activity_id, :type => Integer
      attribute :title, :type => String
      attribute :notes, :type => String, :default => ''

      if ActiveModel::VERSION::MAJOR < 4
        attr_accessible :activity_id, :title, :notes
      end

      validates_numericality_of :activity_id, :only_integer=>true, :greater_than=>0
      validates_presence_of :title

      # @!method initialize
      #   Initialize a new Meeting::Activity
      #   @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)

      # Compare Activity based on title then activity_id
      def <=>(another)
        result = self.title <=> another.try(:title)
        result = self.activity_id <=> another.try(:activity_id) if result == 0
        return result
      end

    end # Class Meeting::Activity


    class BadgeLink
      include ActiveModel::MassAssignmentSecurity if ActiveModel::VERSION::MAJOR < 4
      include ActiveAttr::Model

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

      # Compare BadgeLink based on section, type, badge_name, requirement_label, data
      def <=>(another)
        [:badge_section, :badge_type, :badge_name, :requirement_label].each do |attribute|
          result = self.try(:data) <=> another.try(:data)
          return result unless result == 0
        end
        return self.try(:data) <=> another.try(:data)
      end

    end # Class Meeting::BadgeLink

  end # Class Meeting

end # Module
