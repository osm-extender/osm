module OSM
  class Register
    class Field < OSM::Model
      # @!attribute [rw] id
      #   @return [String] OSM identifier for the field
      # @!attribute [rw] name
      #   @return [String] Human readable name for the field
      # @!attribute [rw] tooltip
      #   @return [String] Tooltip for the field

      attribute :id, type: String
      attribute :name, type: String
      attribute :tooltip, type: String, default: ''

      validates_presence_of :id
      validates_presence_of :name
      validates_presence_of :tooltip, allow_blank: true


      # @!method initialize
      #   Initialize a new RegisterField
      #   @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)

    end
  end
end
