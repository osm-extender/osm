module OSM
  class Activity < OSM::Model
    class Version
      include ActiveAttr::Model

      # @!attribute [rw] version
      #   @return [Integer] the version of the activity
      # @!attribute [rw] created_by
      #   @return [Integer] the OSM user ID of the person who created this version
      # @!attribute [rw] created_by_name
      #   @return [String] the aname of the OSM user who created this version
      # @!attribute [rw] label
      #   @return [String] the human readable label to use for this version

      attribute :version, type: Integer
      attribute :created_by, type: Integer
      attribute :created_by_name, type: String
      attribute :label, type: String

      validates_numericality_of :version, only_integer: true, greater_than_or_equal_to: 0
      validates_numericality_of :created_by, only_integer: true, greater_than: 0
      validates_presence_of :created_by_name
      validates_presence_of :label

      # @!method initialize
      #   Initialize a new Version
      #   @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)

      protected def sort_by
        ['activity_id', 'version']
      end

    end
  end
end
