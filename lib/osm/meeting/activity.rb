module OSM
  class Meeting < OSM::Model
    class Activity
      include ActiveAttr::Model

      # @!attribute [rw] activity_id
      #   @return [Integer] the activity being done
      # @!attribute [rw] title
      #   @return [String] the activity's title
      # @!attribute [rw] notes
      #   @return [String] notes relevant to doing this activity on this meeting

      attribute :activity_id, type: Integer
      attribute :title, type: String
      attribute :notes, type: String, default: ''

      validates_numericality_of :activity_id, only_integer: true, greater_than: 0
      validates_presence_of :title

      # @!method initialize
      #   Initialize a new Meeting::Activity
      #   @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)


      # Compare Activity based on title then activity_id
      def <=>(other)
        result = title <=> other.try(:title)
        result = activity_id <=> other.try(:activity_id) if result.zero?
        result
      end

    end
  end
end
