module Osm
  class Register
    class Attendance < Osm::Model
      # @!attribute [rw] member_id
      #   @return [Integer] The OSM ID for the member
      # @!attribute [rw] grouping_id
      #   @return [Integer] The OSM ID for the member's grouping
      # @!attribute [rw] section_id
      #   @return [Integer] The OSM ID for the member's section
      # @!attribute [rw] first_name
      #   @return [String] The member's first name
      # @!attribute [rw] last_name
      #   @return [String] The member's last name
      # @!attribute [rw] total
      #   @return [FixNum] Total
      # @!attribute [rw] attendance
      #   @return [Hash] The data for each field - keys are the date, values one of :yes, :unadvised_absent or :advised_absent

      attribute :member_id, type: Integer
      attribute :grouping_id, type: Integer
      attribute :section_id, type: Integer
      attribute :first_name, type: String
      attribute :last_name, type: String
      attribute :total, type: Integer
      attribute :attendance, default: {}

      validates_numericality_of :member_id, only_integer:true, greater_than:0
      validates_numericality_of :grouping_id, only_integer:true, greater_than_or_equal_to:-2
      validates_numericality_of :section_id, only_integer:true, greater_than:0
      validates_numericality_of :total, only_integer:true, greater_than_or_equal_to:0
      validates_presence_of :first_name
      validates_presence_of :last_name

      validates :attendance, hash: {key_type: Date, value_in: [:yes, :unadvised_absent, :advised_absent]}


      # @!method initialize
      #   Initialize a new registerData
      #   @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)


      # Find out if the member was present on a date
      # @param [Date] date The date to check attendance for
      # @return true, false whether the member was presnt on the given date
      def present_on?(date)
        attendance[date] == :yes
      end

      # Find out if the member was absent on a date
      # @param [Date] date The date to check attendance for
      # @return true, false whether the member was absent on the given date
      def absent_on?(date)
        attendance[date] != :yes
      end

      private
      def sort_by
        [:section_id, :grouping_id, :last_name, :first_name]
      end

    end
  end
end
