module Osm

  class ProgrammeActivity

    attr_reader :evening_id, :activity_id, :title, :notes
    # @!attribute [r] eveing_id
    #   @return [FixNum] the evening the activity is being done
    # @!attribute [r] activity_id
    #   @return [FixNum] the activity being done
    # @!attribute [r] title
    #   @return [String] the activity's title
    # @!attribute [r] notes
    #   @return [String] tnotes relevant to doing this activity on this evening

    # Initialize a new EveningActivity using the hash returned by the API call
    # @param data the hash of data for the object returned by the API
    def initialize(data)
      @evening_id = Osm::to_i_or_nil(data['eveningid'])
      @activity_id = Osm::to_i_or_nil(data['activityid'])
      @title = data['title']
      @notes = data['notes']
    end

  end

end
