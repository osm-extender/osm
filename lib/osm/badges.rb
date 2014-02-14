module Osm

  class Badges

    # Get badge stock levels for a section
    # @param [Osm::Api] api The api to use to make the request
    # @param [Osm::Section, Fixnum, #to_i] section The section (or its ID) to get the badge stock for
    # @!macro options_get
    # @return Hash
    def self.get_stock(api, section, options={})
      Osm::Model.require_ability_to(api, :read, :badge, section, options)
      section = Osm::Section.get(api, section, options) unless section.is_a?(Osm::Section)
      term_id = Osm::Term.get_current_term_for_section(api, section).id
      cache_key = ['badge_stock', section.id]

      if !options[:no_cache] && Osm::Model.cache_exist?(api, cache_key)
        return Osm::Model.cache_read(api, cache_key)
      end

      data = api.perform_query("challenges.php?action=getInitialBadges&type=core&sectionid=#{section.id}&section=#{section.type}&termid=#{term_id}")
      data = (data['stock'] || {}).select{ |k,v| !k.eql?('sectionid') }.
                                   inject({}){ |new_hash,(badge, level)| new_hash[badge] = level.to_i; new_hash }

      Osm::Model.cache_write(api, cache_key, data)
      return data
    end

    # Update badge stock levels
    # @param [Osm::Api] api The api to use to make the request
    # @param [Osm::Section, Fixnum, #to_i] section The section (or its ID) to update ther badge stock for
    # @param [Sring, #to_s] badge_key The badge to set the stock level for
    # @param [Fixnum, #to_i] stock_level How many of the provided badge there are
    # @return [Boolan] whether the update was successfull or not
    def self.update_stock(api, section, badge_key, stock_level)
      Osm::Model.require_ability_to(api, :write, :badge, section)
      section = Osm::Section.get(api, section) unless section.is_a?(Osm::Section)

      Osm::Model.cache_delete(api, ['badge_stock', section.id])

      data = api.perform_query("challenges.php?action=updateStock", {
        'stock' => stock_level,
        'table' => badge_key,
        'sectionid' => section.id,
        'section' => section.type,
      })
      return data.is_a?(Hash) && (data['sectionid'].to_i == section.id) && (data[badge_key.to_s].to_i == stock_level)
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

      by_member = {}
      member_names = {}
      badge_names = {}
      pending_raw.each do |key, members|
        members.each do |member|
          id = Osm.to_i_or_nil(member['scoutid'])
          description = descriptions_raw[key]['name'] + (descriptions_raw[key]['section'].eql?('staged') ? " (Level #{member['level']})" : '')
          description_key = key + (descriptions_raw[key]['section'].eql?('staged') ? "_#{member['level']}" : '_1')
          badge_names[description_key] = description
          by_member[id] ||= []
          by_member[id].push(description_key)
          member_names[id] = "#{member['firstname']} #{member['lastname']}"
        end
      end

      due_badges = Osm::Badges::DueBadges.new(
        :by_member => by_member,
        :member_names => member_names,
        :badge_names => badge_names,
      )
      Osm::Model.cache_write(api, cache_key, due_badges)
      return due_badges
    end


    class DueBadges < Osm::Model
      # @!attribute [rw] badge_names
      #   @return [Hash] name to display for each of the badges
      # @!attribute [rw] by_member
      #   @return [Hash] the due badges grouped by member
      # @!attribute [rw] member_names
      #   @return [Hash] the name to display for each member

      attribute :badge_names, :default => {}
      attribute :by_member, :default => {}
      attribute :member_names, :default => {}

      if ActiveModel::VERSION::MAJOR < 4
        attr_accessible :badge_names, :by_member, :member_names
      end

      validates :badge_names, :hash => {:key_type => String, :value_type => String}
      validates :member_names, :hash => {:key_type => Fixnum, :value_type => String}

      validates_each :by_member do |record, attr, value|
        badge_names_keys = record.badge_names.keys
        member_names_keys = record.member_names.keys
        record.errors.add(attr, 'must be a Hash') unless value.is_a?(Hash)
        value.each do |k, v|
          record.errors.add(attr, 'keys must be Fixnum') unless k.is_a?(Fixnum)
          record.errors.add(attr, 'keys must exist as a key in :member_names') unless member_names_keys.include?(k)
          record.errors.add(attr, 'values must be Arrays') unless v.is_a?(Array)
          v.each do |vv|
            record.errors.add(attr, 'internal values must be Strings') unless vv.is_a?(String)
            record.errors.add(attr, 'internal values must exist as a key in :badge_names') unless badge_names_keys.include?(vv)
          end
        end
      end


      # @!method initialize
      #   Initialize a new DueBadges
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
        by_member.each do |member_name, badges|
          badges.each do |badge|
            totals[badge] ||= 0
            totals[badge] += 1
          end
        end
        return totals
      end

    end # Class Badges::DueBadges

  end # Class Badges

end # Module
