module Osm

  class Activity < Osm::Model
    class Badge; end # Ensure the constant exists for the validators
    class File; end # Ensure the constant exists for the validators
    class Version; end # Ensure the constant exists for the validators

    SORT_BY = [:id, :version]

    # @!attribute [rw] id
    #   @return [Fixnum] the id for the activity
    # @!attribute [rw] version
    #   @return [Fixnum] the version of the activity
    # @!attribute [rw] group_id
    #   @return [Fixnum] the group_id
    # @!attribute [rw] user_id
    #   @return [Fixnum] the user_id of the creator of the activity
    # @!attribute [rw] title
    #   @return [String] the activity's title
    # @!attribute [rw] description
    #   @return [String] the description of the activity
    # @!attribute [rw] resources
    #   @return [String] resources required to do the activity
    # @!attribute [rw] instructions
    #   @return [String] instructions for doing the activity
    # @!attribute [rw] running_time
    #   @return [Fixnum] duration of the activity in minutes
    # @!attribute [rw] location
    #   @return [Symbol] :indoors, :outdoors or :both
    # @!attribute [rw] shared
    #   @return [Fixnum] 2 - Public, 0 - Private
    # @!attribute [rw] rating
    #   @return [Fixnum] ?
    # @!attribute [rw] editable
    #   @return [Boolean] Wether the current API user can edit this activity
    # @!attribute [rw] deletable
    #   @return [Boolean] Wether the current API user can delete this activity
    # @!attribute [rw] used
    #   @return [Fixnum] How many times this activity has been used (total accross all of OSM)
    # @!attribute [rw] versions
    #   @return [Array<Osm::Activity::Version>]
    # @!attribute [rw] sections
    #   @return [Array<Symbol>] the sections the activity is appropriate for
    # @!attribute [rw] tags
    #   @return [Array<String>] the tags attached to the activity
    # @!attribute [rw] files
    #   @return [Array<Osm::Activity::File>
    # @!attribute [rw] badges
    #   @return [Array<Osm::Activity::Badge>

    attribute :id, :type => Integer
    attribute :version, :type => Integer
    attribute :group_id, :type => Integer
    attribute :user_id, :type => Integer
    attribute :title, :type => String
    attribute :description, :type => String
    attribute :resources, :type => String
    attribute :instructions, :type => String
    attribute :running_time, :type => Integer
    attribute :location
    attribute :shared, :type => Integer
    attribute :rating, :type => Integer
    attribute :editable, :type => Boolean, :default => true
    attribute :deletable, :type => Boolean, :default => true
    attribute :used, :type => Integer
    attribute :versions, :default => []
    attribute :sections, :default => []
    attribute :tags, :default => []
    attribute :files, :default => []
    attribute :badges, :default => []

    validates_numericality_of :id, :only_integer=>true, :greater_than=>0
    validates_numericality_of :version, :only_integer=>true, :greater_than_or_equal_to=>0, :allow_nil=>true
    validates_numericality_of :group_id, :only_integer=>true, :greater_than=>0, :allow_nil=>true
    validates_numericality_of :user_id, :only_integer=>true, :greater_than=>0, :allow_nil=>true
    validates_numericality_of :running_time, :only_integer=>true, :greater_than_or_equal_to=>0
    validates_numericality_of :shared, :only_integer=>true, :greater_than_or_equal_to=>0, :allow_nil=>true
    validates_numericality_of :rating, :only_integer=>true, :allow_nil=>true
    validates_numericality_of :used, :only_integer=>true, :allow_nil=>true
    validates_presence_of :title
    validates_presence_of :description
    validates_presence_of :resources
    validates_presence_of :instructions
    validates_inclusion_of :editable, :in => [true, false]
    validates_inclusion_of :deletable, :in => [true, false]
    validates_inclusion_of :location, :in => [:indoors, :outdoors, :both], :message => 'is not a valid location'

    validates :sections, :array_of => {:item_type => Symbol}
    validates :tags, :array_of => {:item_type => String}
    validates :badges, :array_of => {:item_type => Osm::Activity::Badge, :item_valid => true}
    validates :files, :array_of => {:item_type => Osm::Activity::File, :item_valid => true}
    validates :versions, :array_of => {:item_type => Osm::Activity::Version, :item_valid => true}


    # Get activity details
    # @param [Osm::Api] api The api to use to make the request
    # @param [Fixnum] activity_id The activity ID
    # @param [Fixnum] version The version of the activity to retreive, if nil the latest version will be assumed
    # @!macro options_get
    # @return [Osm::Activity]
    def self.get(api, activity_id, version=nil, options={})
      cache_key = ['activity', activity_id]

      if !options[:no_cache] && cache_exist?(api, [*cache_key, version])
        activity = cache_read(api, [*cache_key, version])
        if (activity.shared == 2) || (activity.user_id == api.user_id) ||  # Shared or owned by this user
        Osm::Section.get_all(api).map{ |s| s.group_id }.uniq.include?(activity.group_id)  # user belomngs to the group owning the activity
          return activity
        else
          return nil
        end
      end

      data = nil
      if version.nil?
        data = api.perform_query("programme.php?action=getActivity&id=#{activity_id}")
      else
        data = api.perform_query("programme.php?action=getActivity&id=#{activity_id}&version=#{version}")
      end

      attributes = {}
      attributes[:id] = Osm::to_i_or_nil(data['details']['activityid'])
      attributes[:version] = data['details']['version'].to_i
      attributes[:group_id] = Osm::to_i_or_nil(data['details']['groupid'])
      attributes[:user_id] = Osm::to_i_or_nil(data['details']['userid'])
      attributes[:title] = data['details']['title']
      attributes[:description] = data['details']['description']
      attributes[:resources] = data['details']['resources']
      attributes[:instructions] = data['details']['instructions']
      attributes[:running_time] = Osm::to_i_or_nil(data['details']['runningtime'])
      attributes[:location] = data['details']['location'].to_sym
      attributes[:shared] = Osm::to_i_or_nil(data['details']['shared'])
      attributes[:rating] = data['details']['rating'].to_i
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
          :id => Osm::to_i_or_nil(file_data['fileid']),
          :activity_id => Osm::to_i_or_nil(file_data['activityid']),
          :file_name => file_data['filename'],
          :name => file_data['name']
        )
      end
      (data['badges'].is_a?(Array) ? data['badges'] : []).each do |badge_data|
        attributes[:badges].push Badge.new(
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
      (data['versions'].is_a?(Array) ? data['versions'] : []).each do |version_data|
        attributes[:versions].push Version.new(
          :version => Osm::to_i_or_nil(version_data['value']),
          :created_by => Osm::to_i_or_nil(version_data['userid']),
          :created_by_name => version_data['firstname'],
          :label => version_data['label']
        )
      end

      activity = Osm::Activity.new(attributes)

      cache_write(api, [*cache_key, nil], activity) if version.nil?
      cache_write(api, [*cache_key, version], activity)
      return activity
    end


    # @!method initialize
    #   Initialize a new Term
    #   @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)


    # Get the link to display this activity in OSM
    # @return [String] the link for this member's My.SCOUT
    # @raise [Osm::ObjectIsInvalid] If the Activity is invalid
    def osm_link
      fail Osm::ObjectIsInvalid, 'activity is invalid' unless valid?
      return "https://www.onlinescoutmanager.co.uk/?l=p#{self.id}"
    end

    # Add this activity to the programme in OSM
    # @param [Osm::Api] api The api to use to make the request
    # @param [Osm::Section, Fixnum, #to_i] section The Section (or it's ID) to add the Activity to
    # @param [Date, DateTime] date The date of the Evening to add the Activity to (OSM will create the Evening if it doesn't already exist)
    # @param [String] notes The notes which should appear for this Activity on this Evening
    # @return [Boolean] Whether the activity was successfully added
    def add_to_programme(api, section, date, notes="")
      require_ability_to(api, :write, :programme, section)

      data = api.perform_query("programme.php?action=addActivityToProgramme", {
        'meetingdate' => date.strftime(Osm::OSM_DATE_FORMAT),
        'activityid' => id,
        'sectionid' => section.to_i,
        'notes' => notes,
      })

      if (data == {'result'=>0})
        # The cached activity will be out of date - remove it
        cache_delete(api, ['activity', self.id])
        return true
      else
        return false
      end
    end

    # Update this activity in OSM
    # @param [Osm::Api] api The api to use to make the request
    # @param [Osm::Section, Fixnum, #to_i] section The Section (or it's ID)
    # @param [Boolean] secret_update Whether this is a secret update
    # @return [Boolean] Whether the activity was successfully added
    # @raise [Osm::ObjectIsInvalid] If the Activity is invalid
    # @raise [Osm::Forbidden] If the Activity is not editable
    def update(api, section, secret_update=false)
      fail Osm::ObjectIsInvalid, 'activity is invalid' unless valid?
      fail Osm::Forbidden, "You are not allowed to update this activity" unless self.editable

      data = api.perform_query("programme.php?action=update", {
        'title' => title,
        'description' => description,
        'resources' => resources,
        'instructions' => instructions,
        'id' => id,
        'files' => files.map{|f| f.id }.join(','),
        'time' => running_time.to_s,
        'location' => location,
        'sections' => sections.to_json,
        'tags' => tags.to_json,
        'links' => badges.map{ |b|
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
            'sections' => sections.map{ |s| s.to_s },
            'badgetype' => b.badge_type.to_s,
            'badgetypeLongName' => nil,
          }
        }.to_json,
        'shared' => shared,
        'sectionid' => section.to_i,
        'secretEdit' => secret_update,
      })

      if (data == {'result'=>true})
        # The cached activity will be out of date - remove it
        cache_delete(api, ['activity', self.id])
        return true
      else
        return false
      end
    end


    private
    class File
      include ActiveAttr::Model

      # @!attribute [rw] id
      #   @return [Fixnum] the OSM ID for the file
      # @!attribute [rw] activity_id
      #   @return [Fixnum] the OSM ID for the activity
      # @!attribute [rw] file_name
      #   @return [String] the file name of the file
      # @!attribute [rw] name
      #   @return [String] the name of the file (more human readable than file_name)

      attribute :id, :type => Integer
      attribute :activity_id, :type => Integer
      attribute :file_name, :type => String
      attribute :name, :type => String

      validates_numericality_of :id, :only_integer=>true, :greater_than=>0
      validates_numericality_of :activity_id, :only_integer=>true, :greater_than=>0
      validates_presence_of :file_name
      validates_presence_of :name

      # @!method initialize
      #   Initialize a new Term
      #   @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)

      # Compare File based on activity_id then name
      def <=>(another)
        result = self.activity_id <=> another.try(:activity_id)
        result = self.name <=> another.try(:name) if result == 0
        return result
      end

    end # Class Activity::File

    class Badge
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

    end # Class Activity::Badge

    class Version
      include ActiveAttr::Model

      # @!attribute [rw] version
      #   @return [Fixnum] the version of the activity
      # @!attribute [rw] created_by
      #   @return [Fixnum] the OSM user ID of the person who created this version
      # @!attribute [rw] created_by_name
      #   @return [String] the aname of the OSM user who created this version
      # @!attribute [rw] label
      #   @return [String] the human readable label to use for this version

      attribute :version, :type => Integer
      attribute :created_by, :type => Integer
      attribute :created_by_name, :type => String
      attribute :label, :type => String

      validates_numericality_of :version, :only_integer=>true, :greater_than_or_equal_to=>0
      validates_numericality_of :created_by, :only_integer=>true, :greater_than=>0
      validates_presence_of :created_by_name
      validates_presence_of :label

      # @!method initialize
      #   Initialize a new Version
      #   @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)

      # Compare Version based on activity_id then version
      def <=>(another)
        result = self.activity_id <=> another.try(:activity_id)
        result = self.version <=> another.try(:version) if result == 0
        return result
      end

    end # Class Activity::Version

  end # Class Activity

end # Module
