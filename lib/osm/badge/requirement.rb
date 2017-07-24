module OSM
  class Badge < OSM::Model
    class Requirement
      include ActiveAttr::Model

      # @!attribute [rw] badge
      #   @return [OSM::Badge] the badge the requirement belongs to
      # @!attribute [rw] name
      #   @return [String] the name of the badge requirement
      # @!attribute [rw] description
      #   @return [String] a description of the badge requirement
      # @!attribute [rw] id
      #   @return [Integer] the id for the requirement (passed to OSM)
      # @!attribute [rw] mod
      #   @return [OSM::Badge::RequirementModule] the module the requirement belongs to
      # @!attribute [rw] editable
      #   @return true, false

      attribute :badge, type: Object
      attribute :name, type: String
      attribute :description, type: String
      attribute :mod, type: Object
      attribute :id, type: Integer
      attribute :editable, type: Boolean

      validates_presence_of :name
      validates_presence_of :description
      validates_presence_of :mod
      validates_numericality_of :id, only_integer: true, greater_than: 0
      validates_presence_of :badge
      validates_inclusion_of :editable, in: [true, false]

      # @!method initialize
      #   Initialize a new Badge::Requirement
      #   @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)

      # Compare Badge::Requirement based on badge then requirement
      def <=>(other)
        result = badge <=> other.try(:badge)
        result = id <=> other.try(:id) if result.zero?
        result
      end

      def inspect
        OSM.inspect_instance(self, replace_with: { 'badge' => :identifier })
      end

    end
  end
end
