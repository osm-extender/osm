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

      data = api.perform_query("ext/badges/stock/?action=getBadgeStock&section=#{section.type}&section_id=#{section.id}&term_id=#{term_id}")
      data = (data['items'] || [])
      data.map!{ |i| [i['badge_id_level'], i['stock']] }
      data = data.to_h

      Osm::Model.cache_write(api, cache_key, data)
      return data
    end

    # Update badge stock levels
    # @param [Osm::Api] api The api to use to make the request
    # @param [Osm::Section, Fixnum, #to_i] section The section (or its ID) to update ther badge stock for
    # @param [Fixnum, #to_i] badge_id The badge to set the stock level for
    # @param [Fixnum, #to_i] badge_level The level of a staged badge to set the stock for (default 1)
    # @param [Fixnum, #to_i] stock_level How many of the provided badge there are
    # @return [Boolan] whether the update was successfull or not
    def self.update_stock(api, section, badge_id, badge_level=1, stock_level)
      Osm::Model.require_ability_to(api, :write, :badge, section)
      section = Osm::Section.get(api, section) unless section.is_a?(Osm::Section)

      Osm::Model.cache_delete(api, ['badge_stock', section.id])

      data = api.perform_query("ext/badges.php?action=updateStock", {
        'stock' => stock_level,
        'sectionid' => section.id,
        'section' => section.type,
        'type' => 'current',
        'level' => badge_level.to_i,
        'badge_id' => badge_id.to_i,
      })
      return data.is_a?(Hash) && data['ok']
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

      data = api.perform_query("ext/badges/due/?action=get&section=#{section.type}&sectionid=#{section.id}&termid=#{term_id}")

      data = {} unless data.is_a?(Hash) # OSM/OGM returns an empty array to represent no badges
      pending = data['pending'] || {}

      by_member = {}
      member_names = {}
      badge_names = {}
      badge_stock = {}

      pending.each do |badge_identifier, members|
        members.each do |member|
          badge_level_identifier = badge_identifier + "_#{member['completed']}"
          member_id = Osm.to_i_or_nil(member['scout_id'])
          badge_names[badge_level_identifier] = "#{member['label']} - #{member['name']}" + (!member['extra'].nil? ? " (#{member['extra']})" : '')
          badge_stock[badge_level_identifier] = member['current_stock'].to_i
          by_member[member_id] ||= []
          by_member[member_id].push(badge_level_identifier)
          member_names[member_id] = "#{member['firstname']} #{member['lastname']}"
        end
      end

      due_badges = Osm::Badges::DueBadges.new(
        :by_member => by_member,
        :member_names => member_names,
        :badge_names => badge_names,
        :badge_stock => badge_stock,
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
      attribute :badge_stock, :default => {}

      validates :badge_names, :hash => {:key_type => String, :value_type => String}
      validates :member_names, :hash => {:key_type => Fixnum, :value_type => String}
      validates :badge_stock, :hash => {:key_type => String, :value_type => Fixnum}

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
