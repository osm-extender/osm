module Osm

  class Badges

    # Get badge stock levels for a section
    # @param [Osm::Api] api The api to use to make the request
    # @param [Osm::Section, Fixnum, #to_i] section The section (or its ID) to get the due badges for
    # @param [Osm::Term, Fixnum, #to_i, nil] term The term (or its ID) to get the stock levels for, passing nil causes the current term to be used
    # @!macro options_get
    # @return Hash
    def self.get_stock(api, section, term=nil, options={})
      Osm::Model.require_ability_to(api, :read, :badge, section, options)
      section = Osm::Section.get(api, section, options) unless section.is_a?(Osm::Section)
      term_id = term.nil? ? Osm::Term.get_current_term_for_section(api, section).id : term.to_i
      cache_key = ['badge_stock', section.id, term_id]

      if !options[:no_cache] && Osm::Model.cache_exist?(api, cache_key)
        return Osm::Model.cache_read(api, cache_key)
      end

      data = api.perform_query("challenges.php?action=getInitialBadges&type=core&sectionid=#{section.id}&section=#{section.type}&termid=#{term_id}")
      data = (data['stock'] || {}).select{ |k,v| !k.eql?('sectionid') }.
                                   inject({}){ |new_hash,(badge, level)| new_hash[badge] = level.to_i; new_hash }

      Osm::Model.cache_write(api, cache_key, data)
      return data
    end

    # Get due badges
    # @param [Osm::Api] api The api to use to make the request
    # @param [Osm::Section, Fixnum, #to_i] section The section (or its ID) to get the due badges for
    # @param [Osm::Term, Fixnum, #to_i, nil] term The term (or its ID) to get the due badges for, passing nil causes the current term to be used
    # @!macro options_get
    # @return [Osm::Badges::DueBadges]
    def self.get_due_badges(api, section, term=nil, options={})
      Osm::Model.require_ability_to(api, :read, :badge, section, options)
      section = Osm::Section.get(api, section, options) unless section.is_a?(Osm::Section)
      term_id = (term.nil? ? Osm::Term.get_current_term_for_section(api, section, options) : term).to_i
      cache_key = ['due_badges', section.id, term_id]

      if !options[:no_cache] && Osm::Model.cache_exist?(api, cache_key)
        return Osm::Model.cache_read(api, cache_key)
      end

      data = api.perform_query("challenges.php?action=outstandingBadges&section=#{section.type}&sectionid=#{section.id}&termid=#{term_id}")

      data = {} unless data.is_a?(Hash) # OSM/OGM returns an empty array to represent no badges
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

      due_badges = Osm::Badges::DueBadges.new(attributes)
      Osm::Model.cache_write(api, cache_key, due_badges)
      return due_badges
    end


    class DueBadges < Osm::Model
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
      #   @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)


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

    end # Class Badges::DueBadges

  end # Class Badges

end # Module
