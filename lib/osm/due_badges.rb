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

    validates :descriptions, :hash => {:key_type => String, :value_type => String}

    validates_each :by_member do |record, attr, value|
      desc_keys = record.descriptions.keys
      record.errors.add(attr, 'must be a Hash') unless value.is_a?(Hash)
      value.each do |k, v|
        record.errors.add(attr, 'keys must be String') unless k.is_a?(String)
        record.errors.add(attr, 'values must be Arrays') unless v.is_a?(Array)
        v.each do |vv|
          record.errors.add(attr, 'internal values must be Strings') unless vv.is_a?(String)
          record.errors.add(attr, 'internal values must exist as a key in :descriptions') unless desc_keys.include?(vv)
        end
      end
    end


    # @!method initialize
    #   Initialize a new Term
    #   @param [Hash] attributes the hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)


    # Initialize a new DueBadges from api data
    # @param [Hash] data the hash of data provided by the API
    def self.from_api(data)
      data = {} unless data.is_a?(Hash) # OSM returns an empty array to represent no badges
      pending_raw = data['pending'] || {}
      descriptions_raw = data['description'] || {}

      attributes = {
        :by_member => {},
        :descriptions => {}
      }

      pending_raw.each do |key, members|
        members.each do |member|
          name = "#{member['firstname']} #{member['lastname']}"
          description = descriptions_raw[key]['name'] + (descriptions_raw[key]['section'].eql?('staged') ? " (Level #{member['level']})" : '')
          description_key = key + (descriptions_raw[key]['section'].eql?('staged') ? "_#{member['level']}" : '_1')

          attributes[:descriptions][description_key] = description
          attributes[:by_member][name] ||= []
          attributes[:by_member][name].push(description_key)
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
    def totals()
      totals = {}
      by_member.keys.each do |member_name|
        by_member[member_name].each do |badge|
          totals[badge] ||= 0
          totals[badge] += 1
        end
      end
      return totals
    end

  end # Class DueBadges

end # Module
