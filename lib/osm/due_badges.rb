module Osm

  class DueBadges
    include ::ActiveAttr::MassAssignmentSecurity
    include ::ActiveAttr::Model

    # @!attribute [rw] descriptions
    #   @return [Hash] descriptions for each of the badges
    # @!attribute [rw] by_member
    #   @return [Hash] the due badges grouped by member

    attribute :descriptions, :default => {}
    attribute :by_member, :default => {}

    attr_accessible :descriptions, :by_member

    validates_each :descriptions do |record, attr, value|
      record.errors.add(attr, 'must be a Hash') unless value.is_a?(Hash)
      value.each do |k, v|
        record.errors.add(attr, 'keys must be Symbols') unless k.is_a?(Symbol)
        record.errors.add(attr, 'values must be Hashes') unless v.is_a?(Hash)
        [:name, :section, :type, :badge].each do |key|
          record.errors.add(attr, "values must include the key #{key}") unless v.keys.include?(key)
        end
      end
    end

    validates_each :by_member do |record, attr, value|
      record.errors.add(attr, 'must be a Hash') unless value.is_a?(Hash)
      value.each do |k, v|
        record.errors.add(attr, 'keys must be String') unless k.is_a?(String)
        record.errors.add(attr, 'values must be Arrays') unless v.is_a?(Array)
        v.each do |vv|
          record.errors.add(attr, 'internal values must be Hashes') unless vv.is_a?(Hash)
          record.errors.add(attr, 'internal values must include the key :badge') unless vv.keys.include?(:badge)
          record.errors.add(attr, 'internal values :badge value must be a Symbol') unless vv[:badge].is_a?(Symbol)
          record.errors.add(attr, 'internal values must include the key :extra_information') unless vv.keys.include?(:extra_information)
          record.errors.add(attr, 'internal values :extra_information value must be a String') unless vv[:extra_information].is_a?(String)
        end
      end
    end


    # @!method initialize
    #   Initialize a new Term
    #   @param [Hash] attributes the hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)


    # Initialize a new DueBadges from api data
    # @param [Hash] data the hash of data provided by the API
    def self.from_api(data)
      data = {} unless data.is_a?(Hash)
      attributes = {}

      attributes[:pending] = data['pending'].is_a?(Hash) ? Osm::symbolize_hash(data['pending']) : {}
      attributes[:descriptions] = data['description'].is_a?(Hash) ? Osm::symbolize_hash(data['description']) : {}

      attributes[:pending].each_key do |key|
        attributes[:pending][key].each_with_index do |item, index|
          attributes[:pending][key][index] = item = Osm::symbolize_hash(item)
          item[:sid] = item[:sid].to_i
          item[:completed] = item[:completed].to_i
        end
      end
      attributes[:descriptions].each_key do |key|
        attributes[:descriptions][key] = Osm::symbolize_hash(attributes[:descriptions][key])
        attributes[:descriptions][key][:section] = attributes[:descriptions][key][:section].to_sym
        attributes[:descriptions][key][:type] = attributes[:descriptions][key][:type].to_sym
      end


      attributes[:by_member] = {}
      attributes[:pending].each_key do |key|
        attributes[:pending][key].each do |item|
          name = "#{item[:firstname]} #{item[:lastname]}"
          attributes[:by_member][name] ||= []
          badge = {
            :badge => key,
            :extra_information => item[:extra]
          }
          attributes[:by_member][name].push badge
        end
      end
      
      new(attributes)
    end

    # Check if there are no badges due
    # @return [Boolean]
    def empty?
      return by_member.empty?
    end

    # Calculate the total number of badges needed
    # @return [Hash] the total number of each badge which is due
    def totals(attributes={})
      totals = {}
      by_member.keys.each do |member_name|
        by_member[member_name].each do |badge_record|
          badge_symbol = badge_record[:badge]
          badge_extra = badge_record[:extra_information]
          totals[badge_record[:badge]] ||= {}
          totals[badge_symbol][badge_extra] ||= 0
          totals[badge_symbol][badge_extra] += 1
        end
      end
      return totals
    end

  end # Class DueBadges

end # Module
