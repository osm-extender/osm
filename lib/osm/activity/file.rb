module Osm
  class Activity < Osm::Model
    class File
      include ActiveAttr::Model

      # @!attribute [rw] id
      #   @return [Integer] the OSM ID for the file
      # @!attribute [rw] activity_id
      #   @return [Integer] the OSM ID for the activity
      # @!attribute [rw] file_name
      #   @return [String] the file name of the file
      # @!attribute [rw] name
      #   @return [String] the name of the file (more human readable than file_name)

      attribute :id, type: Integer
      attribute :activity_id, type: Integer
      attribute :file_name, type: String
      attribute :name, type: String

      validates_numericality_of :id, only_integer: true, greater_than: 0
      validates_numericality_of :activity_id, only_integer: true, greater_than: 0
      validates_presence_of :file_name
      validates_presence_of :name

      # @!method initialize
      #   Initialize a new Term
      #   @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)

      protected def sort_by
        ['activity_id', 'name']
      end

    end
  end
end
