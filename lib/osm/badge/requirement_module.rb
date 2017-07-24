module OSM
  class Badge < OSM::Model
    class RequirementModule
      include ActiveAttr::Model

      # @!attribute [rw] badge
      #   @return [OSM::Badge] the badge the requirement module belongs to
      # @!attribute [rw] letter
      #   @return [String] the letter of the module
      # @!attribute [rw] id
      #   @return [Integer] the id for the module
      # @!attribute [rw] min_required
      #   @return [Integer] the minimum number of requirements which must be met to achieve this module
      # @!attribute [rw] custom_columns
      #   @return [Integer, nil] ?
      # @!attribute [rw] completed_into_column
      #   @return [Integer, nil] ?
      # @!attribute [rw] numeric_into_column
      #   @return [Integer, nil] ?
      # @!attribute [rw] add_column_id_to_numeric
      #   @return [Integer, nil] ?

      attribute :badge, type: Object
      attribute :letter, type: String
      attribute :id, type: Integer
      attribute :min_required, type: Integer
      attribute :custom_columns, type: Integer
      attribute :completed_into_column, type: Integer
      attribute :numeric_into_column, type: Integer
      attribute :add_column_id_to_numeric, type: Integer

      validates_presence_of :badge
      validates_presence_of :letter
      validates_numericality_of :id, only_integer: true, greater_than: 0
      validates_numericality_of :min_required, only_integer: true, greater_than_or_equal_to: 0
      validates_numericality_of :custom_columns, only_integer: true, greater_than_or_equal_to: 0, allow_nil: true
      validates_numericality_of :completed_into_column, only_integer: true, greater_than: 0, allow_nil: true
      validates_numericality_of :numeric_into_column, only_integer: true, greater_than: 0, allow_nil: true
      validates_numericality_of :add_column_id_to_numeric, only_integer: true, greater_than: 0, allow_nil: true

      # @!method initialize
      #   Initialize a new Badge::RequirementModule
      #   @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)

      # Compare Badge::RequirementModule based on badge then letter
      def <=>(other)
        result = badge <=> other.try(:badge)
        result = letter <=> other.try(:letter) if result.zero?
        result = id <=> other.try(:id) if result.zero?
        result
      end

      def inspect
        OSM.inspect_instance(self, replace_with: { 'badge' => :identifier })
      end

    end
  end
end
