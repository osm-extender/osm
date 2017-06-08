module Osm
  class Meeting < Osm::Model
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

      validates_numericality_of :activity_id, only_integer:true, greater_than:0
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

    end
  end
end
