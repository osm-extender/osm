module Osm
  class Meeting < Osm::Model
    class BadgeLink
      include ActiveAttr::Model

      # @!attribute [rw] badge_type
      #   @return [Symbol] the type of badge
      # @!attribute [rw] badge_section
      #   @return [Symbol] the section type that the badge belongs to
      # @!attribute [rw] requirement_label
      #   @return [String] human firendly requirement label
      # @!attribute [rw] data
      #   @return [String] what to put in the column when the badge records are updated
      # @!attribute [rw] badge_name
      #   @return [String] the badge's name
      # @!attribute [rw] badge_id
      #   @return [Integer] the badge's ID in OSM
      # @!attribute [rw] badge_version
      #   @return [Integer] the version of the badge
      # @!attribute [rw] requirement_id
      #   @return [Integer] the requirement's ID in OSM

      attribute :badge_type, type: Object
      attribute :badge_section, type: Object
      attribute :requirement_label, type: String
      attribute :data, type: String
      attribute :badge_name, type: String
      attribute :badge_id, type: Integer
      attribute :badge_version, type: Integer
      attribute :requirement_id, type: Integer

      validates_presence_of :badge_name
      validates_inclusion_of :badge_section, in: [:beavers, :cubs, :scouts, :explorers, :staged]
      validates_inclusion_of :badge_type, in: [:core, :staged, :activity, :challenge]
      validates_numericality_of :badge_id, only_integer:true, greater_than:0
      validates_numericality_of :badge_version, only_integer:true, greater_than_or_equal_to:0
      validates_numericality_of :requirement_id, only_integer:true, greater_than:0, allow_nil:true

      # @!method initialize
      #   Initialize a new Meeting::Activity
      #   @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)

    end
  end
end
