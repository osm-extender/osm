module Osm
  class Badge < Osm::Model
    # @!attribute [rw] name
    #   @return [String] the name of the badge
    # @!attribute [rw] requirement_notes
    #   @return [String] a description of the badge
    # @!attribute [rw] requirements
    #   @return [Array<Osm::Badge::Requirement>] the requirements of the badge
    # @!attribute [rw] modules
    #   @return [Array<Hash>] Details of the modules which make up the badge
    # @!attribute [rw] id
    #   @return [Integer] the badge's id in OSM
    # @!attribute [rw] version
    #   @return [Integer] the version of the badge
    # @!attribute [rw] identifier
    #   @return [String] the identifier used by OSM for this badge & version
    # @!attribute [rw] group_name
    #   @return [String] what group (if any) this badge belongs to (eg Core, Partnership), used only for display sorting
    # @!attribute [rw] latest
    #   @return true, false whether this is the latest version of the badge
    # @!attribute [rw] sharing
    #   @return [Symbol] the sharing status of this badge (:draft, :private, :optin, :default_locked, :optin_locked)
    # @!attribute [rw] user_id
    #   @return [Integer] the OSM user who created this (version of the) badge
    # @!attribute [rw] levels
    #   @return [Array<Integer>, nil] the levels available, nil if it's a single level badge
    # @!attribute [rw] min_modules_required
    #   @return [Integer] the minimum number of modules which must be completed to earn the badge
    # @!attribute [rw] min_requirements_required
    #   @return [Integer] the minimum number of requirements which must be completed to earn the badge
    # @!attribute [rw] add_columns_to_module
    #   @return [Integer, nil] the module to add columns to for nights away type badges
    # @!attribute [rw] level_requirement
    #   @return [Integer, nil] the column which stores the currently earnt level of nights away type badges
    # @!attribute [rw] requires_modules
    #   @return [Array<Array<String>>, nil] the module letters required to gain the badge, at least one from each inner Array
    # @!attribute [rw] other_requirements_required
    #   @return [Array<Hash>] the requirements (from other badges) required to complete this badge, {id: field ID, min: the minimum numerical value of the field's data}
    # @!attribute [rw] badges_required
    #   @return [Array<Hash>] the other badges required to complete this badge, {id: The ID of the badge, version: The version of the badge}
    # @!attribute [rw] show_level_letters
    #   @return true, false Whether to show letters not numbers for the levels of a staged badge

    attribute :name, type: String
    attribute :requirement_notes, type: String
    attribute :requirements, type: Object
    attribute :id, type: Integer
    attribute :version, type: Integer
    attribute :identifier, type: String
    attribute :group_name, type: String
    attribute :latest, type: Boolean
    attribute :sharing, type: Object
    attribute :user_id, type: Integer
    attribute :levels, type: Object
    attribute :modules, type: Object
    attribute :min_modules_required, type: Integer
    attribute :min_requirements_required, type: Integer
    attribute :add_columns_to_module, type: Integer
    attribute :level_requirement, type: Integer
    attribute :requires_modules, type: Object
    attribute :other_requirements_required, type: Object
    attribute :badges_required, type: Object
    attribute :show_level_letters, type: Boolean

    validates_presence_of :name
    validates_presence_of :requirement_notes
    validates_numericality_of :id, only_integer: true, greater_than_or_equal_to: 1
    validates_numericality_of :version, only_integer: true, greater_than_or_equal_to: 0
    validates_presence_of :identifier
    validates_inclusion_of :sharing, in: [:draft, :private, :optin, :optin_locked, :default_locked]
    validates_presence_of :user_id
    validates :requirements, array_of: { item_type: Osm::Badge::Requirement, item_valid: true }
    validates :modules, array_of: { item_type: Osm::Badge::RequirementModule, item_valid: true }
    validates_inclusion_of :latest, in: [true, false]
    validates :levels, array_of: { item_type: Integer }, allow_nil: true
    validates_numericality_of :min_modules_required, only_integer: true, greater_than_or_equal_to: 0
    validates_numericality_of :min_requirements_required, only_integer: true, greater_than_or_equal_to: 0
    validates_numericality_of :add_columns_to_module, only_integer: true, greater_than: 0, allow_nil: true
    validates_numericality_of :level_requirement, only_integer: true, greater_than: 0, allow_nil: true
    validates_inclusion_of :show_level_letters, in: [true, false]


    # @!method initialize
    #   Initialize a new Badge
    #   @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)


    # Get badge stock levels for a section
    # @param api [Osm::Api] The api to use to make the request
    # @param section [Osm::Section, Integer, #to_i] The section (or its ID) to get the badge stock for
    # @!macro options_get
    # @return Hash
    def self.get_stock(api:, section:, no_read_cache: false)
      Osm::Model.require_ability_to(api: api, to: :read, on: :badge, section: section, no_read_cache: no_read_cache)
      section = Osm::Section.get(api: api, section: section, no_read_cache: no_read_cache) unless section.is_a?(Osm::Section)
      term_id = Osm::Term.get_current_term_for_section(api: api, section: section).id
      cache_key = ['badge_stock', section.id]

      Osm::Model.cache_fetch(api: api, key: cache_key, no_read_cache: no_read_cache) do
        data = api.post_query("ext/badges/stock/?action=getBadgeStock&section=#{section.type}&section_id=#{section.id}&term_id=#{term_id}")
        data = (data['items'] || [])
        data.map!{ |i| [i['badge_id_level'], i['stock']] }
        data.to_h
      end # cache fetch
    end

    # Update badge stock levels
    # @param api [Osm::Api] The api to use to make the request
    # @param section [Osm::Section, Integer, #to_i] The section (or its ID) to update ther badge stock for
    # @param badge_id [Integer, #to_i] The badge to set the stock level for
    # @param badge_level [Integer, #to_i] The level of a staged badge to set the stock for (default 1)
    # @param stock_level [Integer, #to_i] How many of the provided badge there are
    # @return [Boolan] whether the update was successfull or not
    def self.update_stock(api:, section:, badge_id:, badge_level: 1, stock:)
      Osm::Model.require_ability_to(api: api, to: :write, on: :badge, section: section)
      section = Osm::Section.get(api: api, section: section) unless section.is_a?(Osm::Section)

      Osm::Model.cache_delete(api: api, key: ['badge_stock', section.id])

      data = api.post_query('ext/badges.php?action=updateStock', post_data: {
        'stock' => stock,
        'sectionid' => section.id,
        'section' => section.type,
        'type' => 'current',
        'level' => badge_level.to_i,
        'badge_id' => badge_id.to_i,
      })
      data.is_a?(Hash) && data['ok']
    end


    # Get due badges
    # @param api [Osm::Api] The api to use to make the request
    # @param section [Osm::Section, Integer, #to_i] The section (or its ID) to get the due badges for
    # @param term [Osm::Term, Integer, #to_i, nil] The term (or its ID) to get the due badges for, passing nil causes the current term to be used
    # @!macro options_get
    # @return [Osm::Badges::DueBadges]
    def self.get_due_badges(api:, section:, term: nil, no_read_cache: false)
      Osm::Model.require_ability_to(api: api, to: :read, on: :badge, section: section, no_read_cache: no_read_cache)
      section = Osm::Section.get(api: api, section: section, no_read_cache: no_read_cache) unless section.is_a?(Osm::Section)
      term_id = (term.nil? ? Osm::Term.get_current_term_for_section(api: api, section: section, no_read_cache: no_read_cache) : term).to_i
      cache_key = ['due_badges', section.id, term_id]

      Osm::Model.cache_fetch(api: api, key: cache_key, no_read_cache: no_read_cache) do
        data = api.post_query("ext/badges/due/?action=get&section=#{section.type}&sectionid=#{section.id}&termid=#{term_id}")

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

        Osm::Badge::Due.new(
          by_member: by_member,
          member_names: member_names,
          badge_names: badge_names,
          badge_stock: badge_stock
        )
      end # cache fetch
    end

    # Get badges
    # @param api [Osm::Api] The api to use to make the request
    # @param section [Osm::Section, Integer, #to_i] The section (or its ID) to get the due badges for
    # @param section_type [Symbol] The type of section to get badges for (if nil uses the type of the section param)
    # @!macro options_get
    # @return [Array<Osm::Badge>]
    def self.get_badges_for_section(api:, section:, section_type: nil, no_read_cache: false)
      fail Error, 'This method must be called on one of the subclasses (CoreBadge, ChallengeBadge, StagedBadge or ActivityBadge)' if type.nil?
      require_ability_to(api: api, to: :read, on: :badge, section: section, no_read_cache: no_read_cache)
      section = Osm::Section.get(api: api, section: section, no_read_cache: no_read_cache) unless section.is_a?(Osm::Section)
      section_type ||= section.type
      cache_key = ['badges', section_type, type]

      Osm::Model.cache_fetch(api: api, key: cache_key, no_read_cache: no_read_cache) do
        term_id = Osm::Term.get_current_term_for_section(api: api, section: section, no_read_cache: no_read_cache).to_i
        badges = []
        badge_sharing_map = {
          'draft' => :draft,
          'private' => :private,
          'optin' => :optin,
          'optin-locked' => :optin_locked,
          'default-locked' => :default_locked
        }

        data = api.post_query("ext/badges/records/?action=getBadgeStructureByType&section=#{section_type}&type_id=#{type_id}&term_id=#{term_id}&section_id=#{section.id}")
        badge_order = data['badgeOrder'].to_s.split(',')
        structures = data['structure'] || {}
        details = data['details'] || {}

        badge_order.each do |b|
          structure = structures[b]
          detail = details[b]
          config = JSON.parse(detail['config'] || '{}')

          badge = new(
            id: detail['badge_id'],
            version: detail['badge_version'],
            identifier: detail['badge_identifier'],
            name: detail['name'],
            requirement_notes: detail['description'],
            group_name: detail['group_name'],
            latest: detail['latest'].to_i.eql?(1),
            sharing: badge_sharing_map[detail['sharing']],
            user_id: Osm.to_i_or_nil(detail['userid']),
            levels: config['levelslist'],
            min_modules_required: config['numModulesRequired'].to_i,
            min_requirements_required: config['minRequirementsCompleted'].to_i,
            add_columns_to_module: Osm.to_i_or_nil(config['addcolumns']),
            level_requirement: Osm.to_i_or_nil(config['levels_column_id']),
            requires_modules: config['requires'],
            other_requirements_required: (config['columnsRequired'] || []).map{ |i| { id: Osm.to_i_or_nil(i['id']), min: i['min'].to_i } },
            badges_required: (config['badgesRequired'] || []).map{ |i| { id: Osm.to_i_or_nil(i['id']), version: i['version'].to_i } },
            show_level_letters: !!config['shownumbers']
          )

          modules = module_completion_data(api: api, badge: badge, no_read_cache: no_read_cache)
          badge.modules = modules
          modules = Hash[*modules.map{|m| [m.letter, m]}.flatten]

          requirements = []
          ((structure[1] || {})['rows'] || []).each do |r|
            requirements.push Osm::Badge::Requirement.new(
              badge: badge,
              name: r['name'],
              description: r['tooltip'],
              mod: modules[r['module']],
              id: Osm.to_i_or_nil(r['field']),
              editable: r['editable'].to_s.eql?('true')
            )
          end
          badge.requirements = requirements

          badges.push badge
        end # each badge_order

        badges
      end # cache fetch
    end

    # Get a summary of badges earnt by members
    # @param api [Osm::Api] The api to use to make the request
    # @param section [Osm::Section, Integer, #to_i] The section (or its ID) to get the due badges for
    # @param term [Osm::Term, Integer, #to_i, nil] The term (or its ID) to get the due badges for, passing nil causes the current term to be used
    # @!macro options_get
    # @return [Array<Hash>]
    def self.get_summary_for_section(api:, section:, term: nil, no_read_cache: false)
      fail Error, 'This method must NOT be called on one of the subclasses(CoreBadge, ChallengeBadge, StagedBadge or ActivityBadge)' unless type.nil?
      require_ability_to(api: api, to: :read, on: :badge, section: section, no_read_cache: no_read_cache)
      section = Osm::Section.get(api: api, section: section, no_read_cache: no_read_cache) unless section.is_a?(Osm::Section)
      term_id = (term.nil? ? Osm::Term.get_current_term_for_section(api: api, section: section, no_read_cache: no_read_cache) : term).to_i
      cache_key = ['badge-summary', section.id, term_id]

      Osm::Model.cache_fetch(api: api, key: cache_key, no_read_cache: no_read_cache) do
        summary = []
        data = api.post_query("ext/badges/records/summary/?action=get&mode=verbose&section=#{section.type}&sectionid=#{section.id}&termid=#{term_id}")
        data['items'].each do |item|
          new_item = {
            first_name: item['firstname'],
            last_name: item['lastname'],
            name: "#{item['firstname']} #{item['lastname']}",
            member_id: Osm.to_i_or_nil(item['scout_id']),
          }

          badge_data = Hash[item.to_a.select{ |k,v| !!k.match(/\d+_\d+/) }]
          badge_data.each do |badge_identifier, status|
            if status.is_a?(String)
              # Possible statuses: 
              # 'Started',
              # 'Due', 'Due Lvl 2'
              # 'Awarded', 'Awarded Lvl 2', '01/02/2003', '02/03/2004 (Lvl 2)'
              if status.eql?('Started')
                new_item[badge_identifier] = :started
              elsif status.eql?('Due')
                new_item[badge_identifier] = :due
              elsif match_data = status.match(/\ADue Lvl (\d+)\Z/)
                new_item[badge_identifier] = :due
                new_item["#{badge_identifier}_level"] = match_data[1].to_i
              elsif status.eql?('Awarded')
                new_item[badge_identifier] = :awarded
              elsif match_data = status.match(/\AAwarded Lvl (\d+)\Z/)
                new_item[badge_identifier] = :awarded
                new_item["#{badge_identifier}_level"] = match_data[1].to_i
              elsif match_data = status.match(Osm::OSM_DATE_REGEX)
                new_item[badge_identifier] = :awarded
                new_item["#{badge_identifier}_date"] = Osm.parse_date(match_data[0])
              elsif match_data = status.match(/\A(#{Osm::OSM_DATE_REGEX_UNANCHORED.to_s}) \(Lvl (\d+)\)\Z/)
                new_item[badge_identifier] = :awarded
                new_item["#{badge_identifier}_date"] = Osm.parse_date(match_data[1])
                new_item["#{badge_identifier}_level"] = match_data[2].to_i
              end # ifs on status
            end # if status is a string
          end # each badge data

          summary.push new_item
        end # each item in data
        summary
      end  # cache fetch
    end

    # Get a list of badge requirements met by members
    # @param api [Osm::Api] The api to use to make the request
    # @param section [Osm::Section, Integer, #to_i] The section (or its ID) to get the due badges for
    # @param term [Osm::Term, Integer, #to_i, nil] The term (or its ID) to get the due badges for, passing nil causes the current term to be used
    # @!macro options_get
    # @return [Array<Osm::Badge::Data>]
    def get_data_for_section(api:, section:, term: nil, no_read_cache: false)
      fail Error, 'This method must be called on one of the subclasses (CoreBadge, ChallengeBadge, StagedBadge or ActivityBadge)' if type.nil?
      Osm::Model.require_ability_to(api: api, to: :read, on: :badge, section: section, no_read_cache: no_read_cache)
      section = Osm::Section.get(api: api, section: section, no_read_cache: no_read_cache) unless section.is_a?(Osm::Section)
      term_id = (term.nil? ? Osm::Term.get_current_term_for_section(api: api, section: section, no_read_cache: no_read_cache) : term).to_i
      cache_key = ['badge_data', section.id, term_id, id, version]

      cache_fetch(api: api, key: cache_key, no_read_cache: no_read_cache) do
        data = api.post_query("ext/badges/records/?action=getBadgeRecords&term_id=#{term_id}&section=#{section.type}&badge_id=#{id}&section_id=#{section.id}&badge_version=#{version}")

        data['items'].map do |d|
          Osm::Badge::Data.new(
            member_id: d['scoutid'],
            first_name: d['firstname'],
            last_name: d['lastname'],
            due: d['completed'].to_i,
            awarded: d['awarded'].to_i,
            awarded_date: Osm.parse_date(d['awardeddate']),
            requirements: d.map{ |k,v| [k.to_i, v] }.to_h.except(0),
            section_id: section.id,
            badge: self
          )
        end
      end #cache fetch
    end


    def has_levels?
      !levels.nil?
    end

    def add_columns?
      !add_columns_to_module.nil?
    end

    def module_map
      @module_map ||= Hash[
        *modules.map{ |m| 
          [m.id, m.letter, m.letter, m.id]
        }.flatten
      ].except('z')
    end

    def needed_per_module
      @needed_per_module ||= Hash[*modules.map{ |m|
        [m.id, m.min_required, m.letter, m.min_required]
      }.flatten].except('z')
    end

    def module_letters
      @module_letters ||= modules.map{ |m| m.letter }.sort
    end

    def module_ids
      @module_ids ||= modules.map{ |m| m.id }.sort
    end


    protected

    def sort_by
      ['name', 'id', '-version']
    end


    private

    # return an array of hashes representing the modules of the badge
    def self.module_completion_data(api:, badge:, no_read_cache: false)
      fetched_this_time = @module_completion_data.nil? # Flag to ensure we only get the data once (at most) per invocation
      @module_completion_data = get_module_completion_data(api: api, no_read_cache: no_read_cache) if fetched_this_time

      if @module_completion_data[badge.id].nil? && !fetched_this_time
        @module_completion_data = get_module_completion_data(api: api, no_read_cache: no_read_cache)
        fetched_this_time = true
      end

      data = @module_completion_data[badge.id]
      fail ArgumentError, "That badge does't exist (bad ID)." if data.nil?

      if data[badge.version].nil? && !fetched_this_time
        @module_completion_data = get_module_completion_data(api, no_read_cache: no_read_cache)
        data = @module_completion_data[badge.id]
        fetched_this_time = true
      end
      data = data[badge.version]
      fail ArgumentError, "That badge does't exist (bad version)." if data.nil?

      data.each{ |i| i.badge = badge }
      data
    end

    # Return a 2 dimensional hash/array (badge ID, badge version) of hashes representing the modules
    def self.get_module_completion_data(api:, no_read_cache: false)
      cache_key = ['badge_module_completion_data']
      cache_fetch(api: api, key: cache_key, no_read_cache: no_read_cache, ttl: 86400) do
        osm_data = api.post_query('ext/badges/records/?action=_getModuleDetails')
        osm_data = (osm_data || {})['items'] || []
        osm_data.map! do |i|
          [
            Osm.to_i_or_nil(i['badge_id']),
            Osm.to_i_or_nil(i['badge_version']),
            Osm::Badge::RequirementModule.new(              id: Osm.to_i_or_nil(i['module_id']),
              letter: i['module_letter'],
              min_required: i['num_required'].to_i,
              custom_columns: i['custom_columns'].to_i,
              completed_into_column: i['completed_into_column_id'].to_i.eql?(0) ? nil : i['completed_into_column_id'].to_i,
              numeric_into_column: i['numeric_into_column_id'].to_i.eql?(0) ? nil : i['numeric_into_column_id'].to_i,
              add_column_id_to_numeric: i['add_column_id_to_numeric'].to_i.eql?(0) ? nil : i['add_column_id_to_numeric'].to_i)
          ]
        end # osm_data.map!

        data = {}
        osm_data.each do |id, version, m|
          data[id] ||= []
          data[id][version] ||= []
          data[id][version].push m
        end
        data
      end # cache fetch
    end

    public

    def self.type
      nil
    end
    def type
      self.class.type
    end

    private

    def self.subscription_required
      :bronze
    end
    def subscription_required
      self.class.subscription_required
    end

  end
end
