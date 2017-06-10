module Osm
  class Badge < Osm::Model
    class Due < Osm::Model
      # @!attribute [rw] badge_names
      #   @return [Hash] name to display for each of the badges
      # @!attribute [rw] by_member
      #   @return [Hash] the due badges grouped by member
      # @!attribute [rw] member_names
      #   @return [Hash] the name to display for each member

      attribute :badge_names, default: {}
      attribute :by_member, default: {}
      attribute :member_names, default: {}
      attribute :badge_stock, default: {}

      validates :badge_names, hash: {key_type: String, value_type: String}
      validates :member_names, hash: {key_type: Integer, value_type: String}
      validates :badge_stock, hash: {key_type: String, value_type: Integer}

      validates_each :by_member do |record, attr, value|
        badge_names_keys = record.badge_names.keys
        member_names_keys = record.member_names.keys
        record.errors.add(attr, 'must be a Hash') unless value.is_a?(Hash)
        value.each do |k, v|
          record.errors.add(attr, 'keys must be Integer') unless k.is_a?(Integer)
          record.errors.add(attr, 'keys must exist as a key in :member_names') unless member_names_keys.include?(k)
          record.errors.add(attr, 'values must be Arrays') unless v.is_a?(Array)
          v.each do |vv|
            record.errors.add(attr, 'internal values must be Strings') unless vv.is_a?(String)
            record.errors.add(attr, 'internal values must exist as a key in :badge_names') unless badge_names_keys.include?(vv)
          end
        end
      end


      # @!method initialize
      #   Initialize a new Due
      #   @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)


      # Check if there are no badges due
      # @return true, false
      def empty?
        by_member.empty?
      end

      # Calculate the total number of badges needed
      # @return [Hash] the total number of each badge which is due
      def totals()
        totals = {}
        by_member.each do |member_name, badges|
          badges.each do |badge|
            totals[badge] ||= 0
            totals[badge] += 1
          end
        end
        totals
      end

    end
  end
end
