module Osm

  class Activity

    attr_reader :id, :version, :group_id, :user_id, :title, :description, :resources, :instructions, :running_time, :location, :shared, :rating, :editable, :deletable, :used, :versions, :sections, :tags, :files, :badges
    # @!attribute [r] id
    #   @return [FixNum] the id for the activity
    # @!attribute [r] version
    #   @return [FixNum] the version of the activity
    # @!attribute [r] group_id
    #   @return [FixNum] the group_id
    # @!attribute [r] user_id
    #   @return [FixNum] the user_id of the creator of the activity
    # @!attribute [r] title
    #   @return [String] the activity's title
    # @!attribute [r] description
    #   @return [String] the description of the activity
    # @!attribute [r] resources
    #   @return [String] resources required to do the activity
    # @!attribute [r] instructions
    #   @return [String] instructions for doing the activity
    # @!attribute [r] running_time
    #   @return [FixNum] duration of the activity in minutes
    # @!attribute [r] location
    #   @return [Symbol] :indoors or :outdoors
    # @!attribute [r] shared
    #   @return [FixNum] ?
    # @!attribute [r] rating
    #   @return [FixNum] ?
    # @!attribute [r] editable
    #   @return [Boolean] ?
    # @!attribute [r] deletable
    #   @return [Boolean] ?
    # @!attribute [r] used
    #   @return [FixNum] ?
    # @!attribute [r] versions
    #   @return [Hash] ?
    # @!attribute [r] sections
    #   @return [Array<Symbol>] the sections the activity is appropriate for
    # @!attribute [r] tags
    #   @return [Array<String>] the tags attached to the activity
    # @!attribute [r] files
    #   @return [Array] ?
    # @!attribute [r] badges
    #   @return [Array] ?


    # Initialize a new Activity using the hash returned by the API call
    # @param data the hash of data for the object returned by the API
    def initialize(data)
      @id = data['details']['activityid'].to_i
      @version = data['details']['version'].to_i
      @group_id = data['details']['groupid'].to_i
      @user_id = data['details']['userid'].to_i
      @title = data['details']['title']
      @description = data['details']['description']
      @resources = data['details']['resources']
      @instructions = data['details']['instructions']
      @running_time = data['details']['runningtime'].to_i
      @location = data['details']['location'].to_sym
      @shared = data['details']['shared'].to_i
      @rating = data['details']['rating'].to_i
      @editable = data['editable']
      @deletable = data['deletable']
      @used = data['used'].to_i
      @versions = data['versions']
      @sections = Osm::make_array_of_symbols(data['sections'] || [])
      @tags = data['tags'] || []
      @files = data['files'] || []
      @badges = data['badges'] || []

      # Clean versions hashes
      @versions.each do |version|
        version.keys.each do |key|
          version[(key.to_sym rescue key) || key] = version.delete(key)
        end
        version[:value] = version[:value].to_i
        version[:user_id] = version[:userid].to_i
        version.delete(:userid)
        version[:selected] = (version[:selected] == 'selected')
      end
    end

  end

end
