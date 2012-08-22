module Osm

  class Activity

    attr_reader :id, :version, :group_id, :user_id, :title, :description, :resources, :instructions, :running_time, :location, :shared, :rating, :editable, :deletable, :used, :versions, :sections, :tags, :files, :badges
    # @!attribute [r] id
    #   @return [Fixnum] the id for the activity
    # @!attribute [r] version
    #   @return [Fixnum] the version of the activity
    # @!attribute [r] group_id
    #   @return [Fixnum] the group_id
    # @!attribute [r] user_id
    #   @return [Fixnum] the user_id of the creator of the activity
    # @!attribute [r] title
    #   @return [String] the activity's title
    # @!attribute [r] description
    #   @return [String] the description of the activity
    # @!attribute [r] resources
    #   @return [String] resources required to do the activity
    # @!attribute [r] instructions
    #   @return [String] instructions for doing the activity
    # @!attribute [r] running_time
    #   @return [Fixnum] duration of the activity in minutes
    # @!attribute [r] location
    #   @return [Symbol] :indoors, :outdoors or :both
    # @!attribute [r] shared
    #   @return [Fixnum] 2 - Public, 0 - Private
    # @!attribute [r] rating
    #   @return [Fixnum] ?
    # @!attribute [r] editable
    #   @return [Boolean] Wether the current API user can edit this activity
    # @!attribute [r] deletable
    #   @return [Boolean] Wether the current API user can delete this activity
    # @!attribute [r] used
    #   @return [Fixnum] How many times this activity has been used (total accross all of OSM)
    # @!attribute [r] versions
    #   @return [Array<Osm::Activity::Version>]
    # @!attribute [r] sections
    #   @return [Array<Symbol>] the sections the activity is appropriate for
    # @!attribute [r] tags
    #   @return [Array<String>] the tags attached to the activity
    # @!attribute [r] files
    #   @return [Array<Osm::Activity::File>
    # @!attribute [r] badges
    #   @return [Array<Osm::Activity::Badge>


    # Initialize a new Activity using the hash returned by the API call
    # @param data the hash of data for the object returned by the API
    def initialize(data)
      @id = Osm::to_i_or_nil(data['details']['activityid'])
      @version = data['details']['version'].to_i
      @group_id = Osm::to_i_or_nil(data['details']['groupid'])
      @user_id = Osm::to_i_or_nil(data['details']['userid'])
      @title = data['details']['title']
      @description = data['details']['description']
      @resources = data['details']['resources']
      @instructions = data['details']['instructions']
      @running_time = Osm::to_i_or_nil(data['details']['runningtime'])
      @location = data['details']['location'].to_sym
      @shared = Osm::to_i_or_nil(data['details']['shared'])
      @rating = data['details']['rating'].to_i
      @editable = data['editable']
      @deletable = data['deletable'] ? true : false
      @used = data['used'].to_i
      @versions = []
      @sections = data['sections'].is_a?(Array) ? Osm::make_array_of_symbols(data['sections']) : []
      @tags = data['tags'].is_a?(Array) ? data['tags'] : []
      @files = []
      @badges = []

      # Populate Arrays
      (data['files'].is_a?(Array) ? data['files'] : []).each do |file_data|
        @files.push File.new(file_data)
      end
      (data['badges'].is_a?(Array) ? data['badges'] : []).each do |badge_data|
        @badges.push Badge.new(badge_data)
      end
      (data['versions'].is_a?(Array) ? data['versions'] : []).each do |version_data|
        @versions.push Version.new(version_data)
      end
      @files.freeze
      @badges.freeze
      @versions.freeze
    end


    private
    class File
      attr_reader :file_id, :activity_id, :file_name, :name
      # @!attribute [r] file_id
      #   @return [Fixnum] the OSM ID for the file
      # @!attribute [r] activity_id
      #   @return [Fixnum] the OSM ID for the activity
      # @!attribute [r] file_name
      #   @return [String] the file name of the file
      # @!attribute [r] name
      #   @return [String] the name of the file (more human readable than file_name)

      # Initialize a new File using the hash returned by the API call
      # @param data the hash of data for the object returned by the API
      def initialize(data)
        @file_id = Osm::to_i_or_nil(data['fileid'])
        @activity_id = Osm::to_i_or_nil(data['activityid'])
        @file_name = data['filename']
        @name = data['name']
      end
    end

    class Badge
      attr_reader :activity_id, :section, :type, :badge, :requirement, :label
      # @!attribute [r] activity_id
      #   @return [Fixnum] the activity being done
      # @!attribute [r] section
      #   @return [Symbol] the section the badge 'belongs' to
      # @!attribute [r] type
      #   @return [Symbol] the type of badge
      # @!attribute [r] badge
      #   @return [String] short name of the badge
      # @!attribute [r] requirement
      #   @return [String] OSM reference to this badge requirement
      # @!attribute [r] label
      #   @return [String] human readable label for the requirement

      # Initialize a new Badge using the hash returned by the API call
      # @param data the hash of data for the object returned by the API
      def initialize(data)
        @activity_id = Osm::to_i_or_nil(data['activityid'])
        @section = data['section'].to_sym
        @type = data['badgetype'].to_sym
        @badge = data['badge']
        @requirement = data['columnname']
        @label = data['label']
      end
    end

    class Version
      attr_reader :version, :created_by, :created_by_name, :label
      # @!attribute [r] version
      #   @return [Fixnum] the version of the activity
      # @!attribute [r] created_by
      #   @return [Fixnum] the OSM user ID of the person who created this version
      # @!attribute [r] created_by_name
      #   @return [String] the aname of the OSM user who created this version
      # @!attribute [r] label
      #   @return [String] the human readable label to use for this version

      # Initialize a new Version using the hash returned by the API call
      # @param data the hash of data for the object returned by the API
      def initialize(data)
        @version = Osm::to_i_or_nil(data['value'])
        @created_by = Osm::to_i_or_nil(data['userid'])
        @created_by_name = data['firstname']
        @label = data['label']
      end
    end

  end
end
