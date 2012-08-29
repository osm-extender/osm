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


    # Initialize a new Activity
    # @param [Hash] attributes the hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)
    def initialize(attributes={})
      [:id, :group_id, :user_id].each do |attribute|
        it = attributes[attribute]
        raise ArgumentError, ":#{attribute} must be nil or a Fixnum > 0" unless it.nil? || (it.is_a?(Fixnum) && it > 0)
      end
      [:version, :running_time, :shared].each do |attribute|
        it = attributes[attribute]
        raise ArgumentError, ":#{attribute} must be nil or a Fixnum >= 0" unless it.nil? || (it.is_a?(Fixnum) && it >= 0)
      end

      [:title, :description, :resources, :instructions].each do |attribute|
        it = attributes[attribute]
        raise ArgumentError, ":#{attribute} must be nil or a String" unless it.nil? || it.is_a?(String)
      end

      raise ArgumentError, ':location must be either :indoors, :outdoors or :both' unless [:indoors, :outdoors, :both].include?(attributes[:location])

      raise ArgumentError, ':editable must be a Boolean' unless attributes[:editable].is_a?(TrueClass) || attributes[:editable].is_a?(FalseClass)
      raise ArgumentError, ':deletable must be a Boolean' unless attributes[:deletable].is_a?(TrueClass) || attributes[:deletable].is_a?(FalseClass)

      raise ArgumentError, ':rating must be a FixNum' unless attributes[:rating].is_a?(Fixnum)
      raise ArgumentError, ':used must be a FixNum' unless attributes[:used].is_a?(Fixnum)

      raise ArgumentError, ':sections must be an Array of Symbol' unless Osm::is_array_of?(attributes[:sections], Symbol)
      raise ArgumentError, ':tags must be an Array of String' unless Osm::is_array_of?(attributes[:tags], String)
      raise ArgumentError, ':versions must be an Array of Osm::Activity::Version' unless Osm::is_array_of?(attributes[:versions], Osm::Activity::Version)
      raise ArgumentError, ':files must be an Array of Osm::Activity::File' unless Osm::is_array_of?(attributes[:files], Osm::Activity::File)
      raise ArgumentError, ':badges must be an Array of Osm::Activity::Badge' unless Osm::is_array_of?(attributes[:badges], Osm::Activity::Badge)

      attributes.each { |k,v| instance_variable_set("@#{k}", v) }
    end

    # Initialize a new Activity from api data
    # @param [Hash] data the hash of data provided by the API
    def self.from_api(data)
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
      attributes[:sections] = data['sections'].is_a?(Array) ? Osm::make_array_of_symbols(data['sections']) : []
      attributes[:tags] = data['tags'].is_a?(Array) ? data['tags'] : []
      attributes[:versions] = []
      attributes[:files] = []
      attributes[:badges] = []

      # Populate Arrays
      (data['files'].is_a?(Array) ? data['files'] : []).each do |file_data|
        attributes[:files].push File.from_api(file_data)
      end
      (data['badges'].is_a?(Array) ? data['badges'] : []).each do |badge_data|
        attributes[:badges].push Badge.from_api(badge_data)
      end
      (data['versions'].is_a?(Array) ? data['versions'] : []).each do |version_data|
        attributes[:versions].push Version.from_api(version_data)
      end

      return new(attributes)
    end


    private
    class File
      attr_reader :id, :activity_id, :file_name, :name
      # @!attribute [r] id
      #   @return [Fixnum] the OSM ID for the file
      # @!attribute [r] activity_id
      #   @return [Fixnum] the OSM ID for the activity
      # @!attribute [r] file_name
      #   @return [String] the file name of the file
      # @!attribute [r] name
      #   @return [String] the name of the file (more human readable than file_name)

      # Initialize a new File
      # @param [Hash] attributes the hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)
      def initialize(attributes={})
        [:file_name, :name].each do |attribute|
          raise ArgumentError, ":#{attribute} must a String" unless attributes[attribute].is_a?(String)
        end
        [:id, :activity_id].each do |attribute|
          it = attributes[attribute]
          raise ArgumentError, ":#{attribute} must be nil or a Fixnum > 0" unless it.nil? || (it.is_a?(Fixnum) && it > 0)
        end

        attributes.each { |k,v| instance_variable_set("@#{k}", v) }
      end

      # Initialize a new File from api data
      # @param [Hash] data the hash of data provided by the API
      def self.from_api(data)
        return new({
          :id => Osm::to_i_or_nil(data['fileid']),
          :activity_id => Osm::to_i_or_nil(data['activityid']),
          :file_name => data['filename'],
          :name => data['name']
        })
      end

    end # Activity::File

    class Badge
      attr_reader :activity_id, :section_type, :type, :badge, :requirement, :label
      # @!attribute [r] activity_id
      #   @return [Fixnum] the activity being done
      # @!attribute [r] section_type
      #   @return [Symbol] the section the badge 'belongs' to
      # @!attribute [r] type
      #   @return [Symbol] the type of badge
      # @!attribute [r] badge
      #   @return [String] short name of the badge
      # @!attribute [r] requirement
      #   @return [String] OSM reference to this badge requirement
      # @!attribute [r] label
      #   @return [String] human readable label for the requirement

      # Initialize a new Badge
      # @param [Hash] attributes the hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)
      def initialize(attributes={})
        raise ArgumentError, ':activity_id must be nil or a Fixnum > 0' unless attributes[:activity_id].nil? || (attributes[:activity_id].is_a?(Fixnum) && attributes[:activity_id] > 0)
        [:type, :section_type].each do |attribute|
          raise ArgumentError, ":#{attribute} must be a Symbol" unless attributes[attribute].is_a?(Symbol)
        end
        [:label, :requirement, :badge].each do |attribute|
          raise ArgumentError, ":#{attribute} must a String" unless attributes[attribute].is_a?(String)
        end

        attributes.each { |k,v| instance_variable_set("@#{k}", v) }
      end

      # Initialize a new Badge from api data
      # @param [Hash] data the hash of data provided by the API
      def self.from_api(data)
        return new({
          :activity_id => Osm::to_i_or_nil(data['activityid']),
          :section_type => data['section'].to_sym,
          :type => data['badgetype'].to_sym,
          :badge => data['badge'],
          :requirement => data['columnname'],
          :label => data['label']
        })
      end

    end # Activity::Badge

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

      # Initialize a new Version
      # @param [Hash] attributes the hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)
      def initialize(attributes={})
        raise ArgumentError, ':version must be nil or a Fixnum > 0' unless attributes[:version].nil? || (attributes[:version].is_a?(Fixnum) && attributes[:version] >= 0)
        raise ArgumentError, ':created_by must be nil or a Fixnum >= 0' unless attributes[:created_by].nil? || (attributes[:created_by].is_a?(Fixnum) && attributes[:created_by] > 0)
        raise ArgumentError, ':created_by_name must be nil or a String' unless attributes[:created_by_name].nil?  || attributes[:created_by_name].is_a?(String)
        raise ArgumentError, ':label must be nil or a String' unless attributes[:label].nil?  || attributes[:label].is_a?(String)

        attributes.each { |k,v| instance_variable_set("@#{k}", v) }
      end

      # Initialize a new Version from api data
      # @param [Hash] data the hash of data provided by the API
      def self.from_api(data)
        return new({
          :version => Osm::to_i_or_nil(data['value']),
          :created_by => Osm::to_i_or_nil(data['userid']),
          :created_by_name => data['firstname'],
          :label => data['label']
        })
      end

    end # Activity::Version

  end # Activity

end # Module
