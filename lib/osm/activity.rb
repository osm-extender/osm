module OSM
  class Activity < OSM::Model
    # @!attribute [rw] id
    #   @return [Integer] the id for the activity
    # @!attribute [rw] version
    #   @return [Integer] the version of the activity
    # @!attribute [rw] group_id
    #   @return [Integer] the group_id
    # @!attribute [rw] user_id
    #   @return [Integer] the user_id of the creator of the activity
    # @!attribute [rw] title
    #   @return [String] the activity's title
    # @!attribute [rw] description
    #   @return [String] the description of the activity
    # @!attribute [rw] resources
    #   @return [String] resources required to do the activity
    # @!attribute [rw] instructions
    #   @return [String] instructions for doing the activity
    # @!attribute [rw] running_time
    #   @return [Integer] duration of the activity in minutes
    # @!attribute [rw] location
    #   @return [Symbol] :indoors, :outdoors or :both
    # @!attribute [rw] shared
    #   @return [Integer] 2 - Public, 0 - Private
    # @!attribute [rw] rating
    #   @return [Integer] ?
    # @!attribute [rw] editable
    #   @return true, false Wether the current API user can edit this activity
    # @!attribute [rw] deletable
    #   @return true, false Wether the current API user can delete this activity
    # @!attribute [rw] used
    #   @return [Integer] How many times this activity has been used (total accross all of OSM)
    # @!attribute [rw] versions
    #   @return [Array<OSM::Activity::Version>]
    # @!attribute [rw] sections
    #   @return [Array<Symbol>] the sections the activity is appropriate for
    # @!attribute [rw] tags
    #   @return [Array<String>] the tags attached to the activity
    # @!attribute [rw] files
    #   @return [Array<OSM::Activity::File>
    # @!attribute [rw] badges
    #   @return [Array<OSM::Activity::Badge>

    attribute :id, type: Integer
    attribute :version, type: Integer
    attribute :group_id, type: Integer
    attribute :user_id, type: Integer
    attribute :title, type: String
    attribute :description, type: String
    attribute :resources, type: String
    attribute :instructions, type: String
    attribute :running_time, type: Integer
    attribute :location
    attribute :shared, type: Integer
    attribute :rating, type: Integer
    attribute :editable, type: Boolean, default: true
    attribute :deletable, type: Boolean, default: true
    attribute :used, type: Integer
    attribute :versions, default: []
    attribute :sections, default: []
    attribute :tags, default: []
    attribute :files, default: []
    attribute :badges, default: []

    validates_numericality_of :id, only_integer: true, greater_than: 0
    validates_numericality_of :version, only_integer: true, greater_than_or_equal_to: 0, allow_nil: true
    validates_numericality_of :group_id, only_integer: true, greater_than: 0, allow_nil: true
    validates_numericality_of :user_id, only_integer: true, greater_than: 0, allow_nil: true
    validates_numericality_of :running_time, only_integer: true, greater_than_or_equal_to: 0
    validates_numericality_of :shared, only_integer: true, greater_than_or_equal_to: 0, allow_nil: true
    validates_numericality_of :rating, only_integer: true, allow_nil: true
    validates_numericality_of :used, only_integer: true, allow_nil: true
    validates_presence_of :title
    validates_presence_of :description
    validates_presence_of :resources
    validates_presence_of :instructions
    validates_inclusion_of :editable, in: [true, false]
    validates_inclusion_of :deletable, in: [true, false]
    validates_inclusion_of :location, in: [:indoors, :outdoors, :both], message: 'is not a valid location'

    validates :sections, array_of: { item_type: Symbol }
    validates :tags, array_of: { item_type: String }
    validates :badges, array_of: { item_type: OSM::Activity::Badge, item_valid: true }
    validates :files, array_of: { item_type: OSM::Activity::File, item_valid: true }
    validates :versions, array_of: { item_type: OSM::Activity::Version, item_valid: true }


    # Get activity details
    # @param api [OSM::Api] The api to use to make the request
    # @param id [Integer] The activity ID
    # @param version [Integer] The version of the activity to retreive, if nil the latest version will be assumed
    # @!macro options_get
    # @return [OSM::Activity]
    def self.get(api:, id:, version: nil, no_read_cache: false)
      cache_key = ['activity', id]

      if cache_exist?(api: api, key: [*cache_key, version], no_read_cache: no_read_cache)
        activity = cache_read(api, [*cache_key, version])
        if (activity.shared == 2) || (activity.user_id == api.user_id) ||  # Shared or owned by this user
        OSM::Section.get_all(api: api).map(&:group_id).uniq.include?(activity.group_id)  # user belomngs to the group owning the activity
          return activity
        else
          return nil
        end
      end

      data = nil
      if version.nil?
        data = api.post_query("programme.php?action=getActivity&id=#{id}")
      else
        data = api.post_query("programme.php?action=getActivity&id=#{id}&version=#{version}")
      end
      details = data.fetch('details')

      attributes = {}
      attributes[:id] = details.fetch('activityid').to_i
      attributes[:version] = details.fetch('version').to_i
      attributes[:group_id] = details.fetch('groupid').to_i
      attributes[:user_id] = details.fetch('userid').to_i
      attributes[:title] = details.fetch('title')
      attributes[:description] = details.fetch('description')
      attributes[:resources] = details.fetch('resources')
      attributes[:instructions] = details.fetch('instructions')
      attributes[:running_time] = details.fetch('runningtime').to_i
      attributes[:location] = details.fetch('location').to_sym
      attributes[:shared] = details.fetch('shared').to_i
      attributes[:rating] = details.fetch('rating').to_i
      attributes[:editable] = data['editable']
      attributes[:deletable] = data['deletable'] ? true : false
      attributes[:used] = data['used'].to_i
      attributes[:sections] = data['sections'].is_a?(Array) ? data['sections'].map(&:to_sym) : []
      attributes[:tags] = data['tags'].is_a?(Array) ? data['tags'] : []
      attributes[:versions] = []
      attributes[:files] = []
      attributes[:badges] = []

      # Populate Arrays
      (data['files'].is_a?(Array) ? data['files'] : []).each do |file_data|
        attributes[:files].push File.new(
          id: OSM.to_i_or_nil(file_data['fileid']),
          activity_id: OSM.to_i_or_nil(file_data['activityid']),
          file_name: file_data['filename'],
          name: file_data['name']
        )
      end
      (data['badges'].is_a?(Array) ? data['badges'] : []).each do |badge_data|
        attributes[:badges].push Badge.new(
          badge_type: badge_data['badgetype'].to_sym,
          badge_section: badge_data['section'].to_sym,
          badge_name: badge_data['badgeLongName'],
          badge_id: OSM.to_i_or_nil(badge_data['badge_id']),
          badge_version: OSM.to_i_or_nil(badge_data['badge_version']),
          requirement_id: OSM.to_i_or_nil(badge_data['column_id']),
          requirement_label: badge_data['columnnameLongName'],
          data: badge_data['data']
        )
      end
      (data['versions'].is_a?(Array) ? data['versions'] : []).each do |version_data|
        attributes[:versions].push Version.new(
          version: OSM.to_i_or_nil(version_data['value']),
          created_by: OSM.to_i_or_nil(version_data['userid']),
          created_by_name: version_data['firstname'],
          label: version_data['label']
        )
      end

      activity = OSM::Activity.new(attributes)

      cache_write(api: api, key: [*cache_key, nil], data: activity) if version.nil?
      cache_write(api: api, key: [*cache_key, version], data: activity)
      activity
    end


    # @!method initialize
    #   Initialize a new Term
    #   @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)


    # Get the link to display this activity in OSM
    # @return [String] the link for this member's My.SCOUT
    # @raise [OSM::ObjectIsInvalid] If the Activity is invalid
    def osm_link
      fail OSM::ObjectIsInvalid, 'activity is invalid' unless valid?
      "https://www.onlinescoutmanager.co.uk/?l=p#{id}"
    end

    # Add this activity to the programme in OSM
    # @param api [OSM::Api] The api to use to make the request
    # @param section [OSM::Section, Integer, #to_i] The Section (or it's ID) to add the Activity to
    # @param date [Date, DateTime] The date of the Evening to add the Activity to (OSM will create the Evening if it doesn't already exist)
    # @param notes [String] The notes which should appear for this Activity on this Evening
    # @return true, false Whether the activity was successfully added
    def add_to_programme(api:, section:, date:, notes: '')
      require_ability_to(api: api, to: :write, on: :programme, section: section)

      data = api.post_query('programme.php?action=addActivityToProgramme', post_data: {
        'meetingdate' => date.strftime(OSM::OSM_DATE_FORMAT),
        'activityid' => id,
        'sectionid' => section.to_i,
        'notes' => notes
      })

      return false unless data == { 'result' => 0 }
      # The cached activity will be out of date - remove it
      cache_delete(api: api, key: ['activity', id])
      true
    end

    # Update this activity in OSM
    # @param api [OSM::Api] The api to use to make the request
    # @param section [OSM::Section, Integer, #to_i] The Section (or it's ID)
    # @param secret_update true, false Whether this is a secret update
    # @return true, false Whether the activity was successfully added
    # @raise [OSM::ObjectIsInvalid] If the Activity is invalid
    # @raise [OSM::Forbidden] If the Activity is not editable
    def update(api:, section:, secret_update: false)
      fail OSM::ObjectIsInvalid, 'activity is invalid' unless valid?
      fail OSM::Forbidden, 'You are not allowed to update this activity' unless editable

      data = api.post_query('programme.php?action=update', post_data: {
        'title' => title,
        'description' => description,
        'resources' => resources,
        'instructions' => instructions,
        'id' => id,
        'files' => files.map(&:id).join(','),
        'time' => running_time.to_s,
        'location' => location,
        'sections' => sections.to_json,
        'tags' => tags.to_json,
        'links' => badges.map do |b|
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
            'sections' => sections.map(&:to_s),
            'badgetype' => b.badge_type.to_s,
            'badgetypeLongName' => nil
          }
        end.to_json,
        'shared' => shared,
        'sectionid' => section.to_i,
        'secretEdit' => secret_update
      })

      return false unless data == { 'result' => true }
      # The cached activity will be out of date - remove it
      cache_delete(api: api, key: ['activity', id])
      true
    end


    protected

    def sort_by
      ['id', 'version']
    end

  end
end
