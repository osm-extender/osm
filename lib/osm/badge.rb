module Osm

  class Badge < Osm::Model
    class Requirement; end # Ensure the constant exists for the validators
    class RequirementModule; end # Ensure the constant exists for the validators

    # @!attribute [rw] name
    #   @return [String] the name of the badge
    # @!attribute [rw] requirement_notes
    #   @return [String] a description of the badge
    # @!attribute [rw] requirements
    #   @return [Array<Osm::Badge::Requirement>] the requirements of the badge
    # @!attribute [rw] modules
    #   @return [Array<Hash>] Details of the modules which make up the badge
    # @!attribute [rw] id
    #   @return [Fixnum] the badge's id in OSM
    # @!attribute [rw] version
    #   @return [Fixnum] the version of the badge
    # @!attribute [rw] identifier
    #   @return [String] the identifier used by OSM for this badge & version
    # @!attribute [rw] group_name
    #   @return [String] what group (if any) this badge belongs to (eg Core, Partnership), used only for display sorting
    # @!attribute [rw] latest
    #   @return [Boolean] whether this is the latest version of the badge
    # @!attribute [rw] sharing
    #   @return [Symbol] the sharing status of this badge (:draft, :private, :optin, :default_locked, :optin_locked)
    # @!attribute [rw] user_id
    #   @return [Fixnum] the OSM user who created this (version of the) badge
    # @!attribute [rw] levels
    #   @return [Array<Fixnum>, nil] the levels available, nil if it's a single level badge
    # @!attribute [rw] min_modules_required
    #   @return [Fixnum] the minimum number of modules which must be completed to earn the badge
    # @!attribute [rw] min_requirements_required
    #   @return [Fixnum] the minimum number of requirements which must be completed to earn the badge
    # @!attribute [rw] add_columns_to_module
    #   @return [Fixnum, nil] the module to add columns to for nights away type badges
    # @!attribute [rw] level_requirement
    #   @return [Fixnum, nil] the column which stores the currently earnt level of nights away type badges
    # @!attribute [rw] requires_modules
    #   @return [Array<Array<String>>, nil] the module letters required to gain the badge, at least one from each inner Array
    # @!attribute [rw] other_requirements_required
    #   @return [Array<Hash>] the requirements (from other badges) required to complete this badge, {id: field ID, min: the minimum numerical value of the field's data}
    # @!attribute [rw] badges_required
    #   @return [Array<Hash>] the other badges required to complete this badge, {id: The ID of the badge, version: The version of the badge}
    # @!attribute [rw] show_level_letters
    #   @return [Boolean] Whether to show letters not numbers for the levels of a staged badge

    attribute :name, :type => String
    attribute :requirement_notes, :type => String
    attribute :requirements, :type => Object
    attribute :id, :type => Integer
    attribute :version, :type => Integer
    attribute :identifier, :type => String
    attribute :group_name, :type => String
    attribute :latest, :type => Boolean
    attribute :sharing, :type => Object
    attribute :user_id, :type => Integer
    attribute :levels, :type => Object
    attribute :modules, :type => Object
    attribute :min_modules_required, :type => Integer
    attribute :min_requirements_required, :type => Integer
    attribute :add_columns_to_module, :type => Integer
    attribute :level_requirement, :type => Integer
    attribute :requires_modules, :type => Object
    attribute :other_requirements_required, :type => Object
    attribute :badges_required, :type => Object
    attribute :show_level_letters, :type => Boolean

    validates_presence_of :name
    validates_presence_of :requirement_notes
    validates_numericality_of :id, :only_integer=>true, :greater_than_or_equal_to=>1
    validates_numericality_of :version, :only_integer=>true, :greater_than_or_equal_to=>0
    validates_presence_of :identifier
    validates_inclusion_of :sharing, :in => [:draft, :private, :optin, :optin_locked, :default_locked]
    validates_presence_of :user_id
    validates :requirements, :array_of => {:item_type => Osm::Badge::Requirement, :item_valid => true}
    validates :modules, :array_of => {:item_type => Osm::Badge::RequirementModule, :item_valid => true}
    validates_inclusion_of :latest, :in => [true, false]
    validates :levels, :array_of => {:item_type => Fixnum}, :allow_nil => true
    validates_numericality_of :min_modules_required, :only_integer=>true, :greater_than_or_equal_to=>0
    validates_numericality_of :min_requirements_required, :only_integer=>true, :greater_than_or_equal_to=>0
    validates_numericality_of :add_columns_to_module, :only_integer=>true, :greater_than=>0, :allow_nil=>true
    validates_numericality_of :level_requirement, :only_integer=>true, :greater_than=>0, :allow_nil=>true
    validates_inclusion_of :show_level_letters, :in => [true, false]


    # @!method initialize
    #   Initialize a new Badge
    #   @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)

    # Get badges
    # @param [Osm::Api] api The api to use to make the request
    # @param [Osm::Section, Fixnum, #to_i] section The section (or its ID) to get the due badges for
    # @param [Symbol] section_type The type of section to get badges for (if nil uses the type of the section param)
    # @!macro options_get
    # @return [Array<Osm::Badge>]
    def self.get_badges_for_section(api, section, section_type=nil, options={})
      fail Error, 'This method must be called on one of the subclasses (CoreBadge, ChallengeBadge, StagedBadge or ActivityBadge)' if type.nil?
      require_ability_to(api, :read, :badge, section, options)
      section = Osm::Section.get(api, section, options) unless section.is_a?(Osm::Section)
      section_type ||= section.type
      cache_key = ['badges', section_type, type]

      if !options[:no_cache] && Osm::Model.cache_exist?(api, cache_key)
        return cache_read(api, cache_key)
      end

      term_id = Osm::Term.get_current_term_for_section(api, section, options).to_i
      badges = []
      badge_sharing_map = {
        'draft' => :draft,
        'private' => :private,
        'optin' => :optin,
        'optin-locked' => :optin_locked,
        'default-locked' => :default_locked
      }

      data = api.perform_query("ext/badges/records/?action=getBadgeStructureByType&section=#{section_type}&type_id=#{type_id}&term_id=#{term_id}&section_id=#{section.id}")
      badge_order = data["badgeOrder"].to_s.split(',')
      structures = data["structure"] || {}
      details = data["details"] || {}

      badge_order.each do |b|
        structure = structures[b]
        detail = details[b]
        config = ActiveSupport::JSON.decode(detail['config'] || '{}')

        badge = new(
          :id => detail['badge_id'],
          :version => detail['badge_version'],
          :identifier => detail['badge_identifier'],
          :name => detail['name'],
          :requirement_notes => detail['description'],
          :group_name => detail['group_name'],
          :latest => detail['latest'].to_i.eql?(1),
          :sharing => badge_sharing_map[detail['sharing']],
          :user_id => Osm.to_i_or_nil(detail['userid']),
          :levels => config['levelslist'],
          :min_modules_required => config['numModulesRequired'].to_i,
          :min_requirements_required => config['minRequirementsCompleted'].to_i,
          :add_columns_to_module => Osm.to_i_or_nil(config['addcolumns']),
          :level_requirement => Osm.to_i_or_nil(config['levels_column_id']),
          :requires_modules => config['requires'],
          :other_requirements_required => (config['columnsRequired'] || []).map{ |i| {id: Osm.to_i_or_nil(i['id']), min: i['min'].to_i} },
          :badges_required => (config['badgesRequired'] || []).map{ |i| {id: Osm.to_i_or_nil(i['id']), version: i['version'].to_i} },
          :show_level_letters => !!config['shownumbers'],
        )

        modules = module_completion_data(api, badge, options)
        badge.modules = modules
        modules = Hash[*modules.map{|m| [m.letter, m]}.flatten]

        requirements = []
        ((structure[1] || {})['rows'] || []).each do |r|
          requirements.push Osm::Badge::Requirement.new(
            :badge => badge,
            :name => r['name'],
            :description => r['tooltip'],
            :mod => modules[r['module']],
            :id => Osm::to_i_or_nil(r['field']),
            :editable => r['editable'].to_s.eql?('true'),
          )
        end
        badge.requirements = requirements

        badges.push badge
      end

      cache_write(api, cache_key, badges)
      return badges
    end

    # Get a summary of badges earnt by members
    # @param [Osm::Api] api The api to use to make the request
    # @param [Osm::Section, Fixnum, #to_i] section The section (or its ID) to get the due badges for
    # @param [Osm::Term, Fixnum, #to_i, nil] term The term (or its ID) to get the due badges for, passing nil causes the current term to be used
    # @!macro options_get
    # @return [Array<Hash>]
    def self.get_summary_for_section(api, section, term=nil, options={})
      fail Error, 'This method must NOT be called on one of the subclasses(CoreBadge, ChallengeBadge, StagedBadge or ActivityBadge)' unless type.nil?
      require_ability_to(api, :read, :badge, section, options)
      section = Osm::Section.get(api, section, options) unless section.is_a?(Osm::Section)
      term_id = (term.nil? ? Osm::Term.get_current_term_for_section(api, section, options) : term).to_i
      cache_key = ['badge-summary', section.id, term_id]

      if !options[:no_cache] && Osm::Model.cache_exist?(api, cache_key)
        return cache_read(api, cache_key)
      end

      summary = []
      data = api.perform_query("ext/badges/records/summary/?action=get&mode=verbose&section=#{section.type}&sectionid=#{section.id}&termid=#{term_id}")
      data['items'].each do |item|
        new_item = {
          :first_name => item['firstname'],
          :last_name => item['lastname'],
          :name => "#{item['firstname']} #{item['lastname']}",
          :member_id => Osm.to_i_or_nil(item['scout_id']),
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
            end
          end
        end

        summary.push new_item
      end

      cache_write(api, cache_key, summary)
      return summary
    end

    # Get a list of badge requirements met by members
    # @param [Osm::Api] api The api to use to make the request
    # @param [Osm::Section, Fixnum, #to_i] section The section (or its ID) to get the due badges for
    # @param [Osm::Term, Fixnum, #to_i, nil] term The term (or its ID) to get the due badges for, passing nil causes the current term to be used
    # @!macro options_get
    # @return [Array<Osm::Badge::Data>]
    def get_data_for_section(api, section, term=nil, options={})
      fail Error, 'This method must be called on one of the subclasses (CoreBadge, ChallengeBadge, StagedBadge or ActivityBadge)' if type.nil?
      Osm::Model.require_ability_to(api, :read, :badge, section, options)
      section = Osm::Section.get(api, section, options) unless section.is_a?(Osm::Section)
      term_id = (term.nil? ? Osm::Term.get_current_term_for_section(api, section, options) : term).to_i
      cache_key = ['badge_data', section.id, term_id, id, version]

      if !options[:no_cache] && cache_exist?(api, cache_key)
        return cache_read(api, cache_key)
      end

      datas = []
      data = api.perform_query("ext/badges/records/?action=getBadgeRecords&term_id=#{term_id}&section=#{section.type}&badge_id=#{id}&section_id=#{section.id}&badge_version=#{version}")

      data['items'].each do |d|
        datas.push Osm::Badge::Data.new(
          :member_id => d['scoutid'],
          :first_name => d['firstname'],
          :last_name => d['lastname'],
          :due => d['completed'].to_i,
          :awarded => d['awarded'].to_i,
          :awarded_date => Osm.parse_date(d['awardeddate']),
          :requirements => d.map{ |k,v| [k.to_i, v] }.to_h.except(0),
          :section_id => section.id,
          :badge => self,
        )
      end

      cache_write(api, cache_key, datas)
      return datas
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


    # Compare Badge based on name then id then version (desc)
    def <=>(another)
      result = self.name <=> another.try(:name)
      result = self.id <=> another.try(:id) if result == 0
      result = another.try(:version) <=> self.version if result == 0
      return result
    end


    private
    # return an array of hashes representing the modules of the badge
    def self.module_completion_data(api, badge, options={})
      fetched_this_time = @module_completion_data.nil? # Flag to ensure we only get the data once (at most) per invocation
      @module_completion_data = get_module_completion_data(api, options) if fetched_this_time

      if @module_completion_data[badge.id].nil? && !fetched_this_time
        @module_completion_data = get_module_completion_data(api, options)
        fetched_this_time = true
      end
      data = @module_completion_data[badge.id]
      fail ArgumentError, "That badge does't exist (bad ID)." if data.nil?

      if data[badge.version].nil? && !fetched_this_time
        @module_completion_data = get_module_completion_data(api, options)
        data = @module_completion_data[badge.id]
        fetched_this_time = true
      end
      data = data[badge.version]
      fail ArgumentError, "That badge does't exist (bad version)." if data.nil?

      data.each{ |i| i.badge = badge }
      return data
    end

    # Return a 2 dimensional hash/array (badge ID, badge version) of hashes representing the modules
    def self.get_module_completion_data(api, options={})
      cache_key = ['badge_module_completion_data']
      if !options[:no_cache] && cache_exist?(api, cache_key)
        return cache_read(api, cache_key)
      end

      osm_data = api.perform_query('ext/badges/records/?action=_getModuleDetails')
      osm_data = (osm_data || {})['items'] || []
      osm_data.map! do |i|
        [
          Osm.to_i_or_nil(i['badge_id']),
          Osm.to_i_or_nil(i['badge_version']),
          Osm::Badge::RequirementModule.new({
            id: Osm.to_i_or_nil(i['module_id']),
            letter: i['module_letter'],
            min_required: i['num_required'].to_i,
            custom_columns: i['custom_columns'].to_i,
            completed_into_column: i['completed_into_column_id'].to_i.eql?(0) ? nil : i['completed_into_column_id'].to_i,
            numeric_into_column: i['numeric_into_column_id'].to_i.eql?(0) ? nil : i['numeric_into_column_id'].to_i,
            add_column_id_to_numeric: i['add_column_id_to_numeric'].to_i.eql?(0) ? nil : i['add_column_id_to_numeric'].to_i,
          })
        ]
      end

      data = {}
      osm_data.each do |id, version, m|
        data[id] ||= []
        data[id][version] ||= []
        data[id][version].push m
      end

      cache_write(api, cache_key, data, {expires_in: 864000}) # Expire in 24 hours as this data changes really slowly
      return data
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


    class Requirement
      include ActiveAttr::Model

      # @!attribute [rw] badge
      #   @return [Osm::Badge] the badge the requirement belongs to
      # @!attribute [rw] name
      #   @return [String] the name of the badge requirement
      # @!attribute [rw] description
      #   @return [String] a description of the badge requirement
      # @!attribute [rw] id
      #   @return [Fixnum] the id for the requirement (passed to OSM)
      # @!attribute [rw] mod
      #   @return [Osm::Badge::RequirementModule] the module the requirement belongs to
      # @!attribute [rw] editable
      #   @return [Boolean]

      attribute :badge, :type => Object
      attribute :name, :type => String
      attribute :description, :type => String
      attribute :mod, :type => Object
      attribute :id, :type => Integer
      attribute :editable, :type => Boolean

      validates_presence_of :name
      validates_presence_of :description
      validates_presence_of :mod
      validates_numericality_of :id, :only_integer=>true, :greater_than=>0
      validates_presence_of :badge
      validates_inclusion_of :editable, :in => [true, false]

      # @!method initialize
      #   Initialize a new Badge::Requirement
      #   @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)

      # Compare Badge::Requirement based on badge then requirement
      def <=>(another)
        result = self.badge <=> another.try(:badge)
        result = self.id <=> another.try(:id) if result == 0
        return result
      end

      def inspect
        Osm.inspect_instance(self, {:replace_with => {'badge' => :identifier}})
      end

    end # Class Requirement


    class RequirementModule
      include ActiveAttr::Model

      # @!attribute [rw] badge
      #   @return [Osm::Badge] the badge the requirement module belongs to
      # @!attribute [rw] letter
      #   @return [String] the letter of the module
      # @!attribute [rw] id
      #   @return [Fixnum] the id for the module
      # @!attribute [rw] min_required
      #   @return [Fixnum] the minimum number of requirements which must be met to achieve this module
      # @!attribute [rw] custom_columns
      #   @return [Fixnum, nil] ?
      # @!attribute [rw] completed_into_column
      #   @return [Fixnum, nil] ?
      # @!attribute [rw] numeric_into_column
      #   @return [Fixnum, nil] ?
      # @!attribute [rw] add_column_id_to_numeric
      #   @return [Fixnum, nil] ?

      attribute :badge, :type => Object
      attribute :letter, :type => String
      attribute :id, :type => Integer
      attribute :min_required, :type => Integer
      attribute :custom_columns, :type => Integer
      attribute :completed_into_column, :type => Integer
      attribute :numeric_into_column, :type => Integer
      attribute :add_column_id_to_numeric, :type => Integer

      validates_presence_of :badge
      validates_presence_of :letter
      validates_numericality_of :id, :only_integer=>true, :greater_than=>0
      validates_numericality_of :min_required, :only_integer=>true, :greater_than_or_equal_to=>0
      validates_numericality_of :custom_columns, :only_integer=>true, :greater_than_or_equal_to=>0, :allow_nil=>true
      validates_numericality_of :completed_into_column, :only_integer=>true, :greater_than=>0, :allow_nil=>true
      validates_numericality_of :numeric_into_column, :only_integer=>true, :greater_than=>0, :allow_nil=>true
      validates_numericality_of :add_column_id_to_numeric, :only_integer=>true, :greater_than=>0, :allow_nil=>true

      # @!method initialize
      #   Initialize a new Badge::RequirementModule
      #   @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)

      # Compare Badge::RequirementModule based on badge then letter
      def <=>(another)
        result = self.badge <=> another.try(:badge)
        result = self.letter <=> another.try(:letter) if result == 0
        result = self.id <=> another.try(:id) if result == 0
        return result
      end

      def inspect
        Osm.inspect_instance(self, {:replace_with => {'badge' => :identifier}})
      end

    end # Class RequirementModule


    class Data < Osm::Model
      SORT_BY = [:badge, :section_id, :member_id]

      # @!attribute [rw] member_id
      #   @return [Fixnum] ID of the member this data relates to
      # @!attribute [rw] first_name
      #   @return [Fixnum] the member's first name
      # @!attribute [rw] last_name
      #   @return [Fixnum] the member's last name
      # @!attribute [rw] due
      #   @return [Fixnum] whether this badge is due according to OSM, number indicates stage if appropriate
      # @!attribute [rw] awarded
      #   @return [Date] the last stage awarded
      # @!attribute [rw] awarded_date
      #   @return [Date] when the badge was awarded
      # @!attribute [rw] requirements
      #   @return [DirtyHashy] the data for each badge requirement
      # @!attribute [rw] section_id
      #   @return [Fixnum] the ID of the section the member belongs to
      # @!attribute [rw] badge
      #   @return [Osm::Badge] the badge that the data belongs to

      attribute :member_id, :type => Integer
      attribute :first_name, :type => String
      attribute :last_name, :type => String
      attribute :due, :type => Integer, :default => 0
      attribute :awarded, :type => Integer, :default => 0
      attribute :awarded_date, :type => Date, :default => nil
      attribute :requirements, :type => Object, :default => DirtyHashy.new
      attribute :section_id, :type => Integer
      attribute :badge, :type => Object

      validates_presence_of :badge
      validates_presence_of :first_name
      validates_presence_of :last_name
      validates_numericality_of :due, :only_integer=>true, :greater_than_or_equal_to=>0
      validates_numericality_of :awarded, :only_integer=>true, :greater_than_or_equal_to=>0
      validates_numericality_of :member_id, :only_integer=>true, :greater_than=>0
      validates_numericality_of :section_id, :only_integer=>true, :greater_than=>0
      validates :requirements, :hash => {:key_type => Fixnum, :value_type => String}


      # @!method initialize
      #   Initialize a new Badge::Data
      #   @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)
      # Override initialize to set @orig_attributes
      old_initialize = instance_method(:initialize)
      define_method :initialize do |*args|
        ret_val = old_initialize.bind(self).call(*args)
        self.requirements = DirtyHashy.new(self.requirements)
        self.requirements.clean_up!
        return ret_val
      end


      # Get the total number of gained requirements
      # @return [Fixnum] the total number of requirements considered gained
      def total_gained
        count = 0
        badge.requirements.each do |requirement|
          next unless requirement_met?(requirement.id)
          count += 1
        end
        return count
      end

      # Get the letters of modules gained
      # @return [Array<Stirng>]
      def modules_gained
        g_i_m = gained_in_modules
        gained = []
        badge.modules.each do |mod|
          next if g_i_m[mod.id] < mod.min_required
          gained.push mod.letter
        end
        gained
      end

      # Get the number of requirements gained in each module
      # @return [Hash]
      def gained_in_modules
        count = {}
        badge.modules.each do |mod|
          count[mod.id] ||= 0
          count[mod.letter] ||= 0
        end
        badge.requirements.each do |requirement|
          next unless requirement_met?(requirement.id)
          count[requirement.mod.id] += 1
          count[requirement.mod.letter] += 1
        end
        count
      end


      # Check if this badge has been earnt
      # @return [Boolean] whether the badge has been earnt (ignores other badge's and their requirements which might be needed)
      def earnt?
        if badge.has_levels?
          return earnt > awarded
        else
          return false if (due.eql?(1) && awarded.eql?(1))
          return true if (due.eql?(1) && awarded.eql?(0))

          if badge.min_modules_required > 0
            return false unless modules_gained.size >= badge.min_modules_required
          end
          if badge.min_requirements_required > 0
            return false unless total_gained >= badge.min_requirements_required
          end
          if badge.requires_modules
            # [['a'], ['b', 'c']] = a and (b or c)
            requires = badge.requires_modules.clone
            modules = modules_gained
            requires.map!{ |a| a.map{ |b| modules.include?(b) } } # Replace letters with true/false
            requires.map!{ |a| a.include?(true) } # Replace each combination with true/false
            return false if requires.include?(false) # Only earnt if all combinations are met
          end
          badge.other_requirements_required.each do |c|
            # {:id => ###, :min => #}
            if requirements.has_key?(c[:id]) # Only check it if the data is in the requirements Hash
              return false unless requirement_met?(c[:id])
              return false if requirements[c[:id]].to_i < c[:min]
            end
          end
          badge.badges_required.each do |b|
            # {:id => ###, :version => #}
            #TODO
          end
          return true
        end
      end


      # Get what stage which has most recently been earnt
      # (using #earnt? will tell you if it's still due (not yet awarded))
      # @return [Fixnum] the stage which has most recently been due
      def earnt
        unless badge.has_levels?
          return earnt? ? 1 : 0
        end

        levels_column = badge.level_requirement
        unless badge.show_level_letters # It's a hikes, nights type badge
          badge.levels.reverse_each do |level|
            return level if requirements[levels_column].to_i >= level
          end
        else # It's an activity type badge
          modules = modules_gained
          letters = ('a'..'z').to_a
          (awarded..badge.levels.last).reverse_each do |level|
            return level if modules.include?(letters[level - 1])
          end
        end
        return 0
      end


      # Check if this badge has been started
      # @return [Boolean] whether the badge has been started by the member (always false if the badge has been completed)
      def started?
        if badge.has_levels?
          return (started > due)
        end
        return false if due?
        requirements.each do |key, value|
          return true if requirement_met?(key)
        end
        return false
      end


      # Get which stage has been started
      # @return [Fixnum] which stage of the badge has been started by the member (lowest)
      def started
        unless badge.has_levels?
          return started? ? 1 : 0
        end
        unless badge.show_level_letters
          # Nights, Hikes or Water
          done = requirements[badge.level_requirement].to_i
          levels = badge.levels                    # e.g. [0,1,2,3,4,5,10]
          return 0 if levels.include?(done)        # Has achieved a level (and not started next )
          return 0 if done >= levels.last          # No more levels to do
          (1..(levels.size-1)).to_a.reverse_each do |i|  # indexes from last to 2nd
            this_level = levels[i]
            previous_level = levels[i-1]
            return this_level if (done < this_level && done > previous_level) # this_level has been started (and not finished)
          end
          return 0 # No reason we should ever get here
        else
          # 'Normal' staged
          letters = ('a'..'z').to_a
          top_level = badge.levels.last
          return 0 if due == top_level || awarded == top_level # No more levels to do
          ((due + 1)..top_level).reverse_each do |level|
            badge.requirements.each do |requirement|
              next unless requirement.mod.letter.eql?(letters[level - 1]) # Not interested in other levels
              return level if requirement_met?(requirement.id)
            end
          end
          return 0 # No levels started
        end
      end


      # Mark the badge as awarded in OSM
      # @param [Osm::Api] api The api to use to make the request
      # @param [Date] date The date to mark the badge as awarded
      # @param [Fixnum] level The level of the badge to award (1 for non-staged badges), setting the level to 0 unawards the badge
      # @return [Boolean] whether the data was updated in OSM
      def mark_awarded(api, date=Date.today, level=due)
        fail ArgumentError, 'date is not a Date' unless date.is_a?(Date)
        fail ArgumentError, 'level can not be negative' if level < 0
        section = Osm::Section.get(api, section_id)
        require_ability_to(api, :write, :badge, section)

        date_formatted = date.strftime(Osm::OSM_DATE_FORMAT)
        entries = [{
          'badge_id' => badge.id.to_s,
          'badge_version' => badge.version.to_s,
          'scout_id' => member_id.to_s,
          'level' => level.to_s
        }]

        result = api.perform_query("ext/badges/records/?action=awardBadge", {
          'date' => date_formatted,
          'sectionid' => section_id,
          'entries' => entries.to_json
        })
        updated = result.is_a?(Hash) &&
                  (result['scoutid'].to_i == member_id) &&
                  (result['awarded'].to_i == level) &&
                  (result['awardeddate'] == date_formatted)

        if updated
          awarded = level
          awarded_date = date
        end
        return updated
      end

      # Mark the badge as not awarded in OSM
      # @param [Osm::Api] api The api to use to make the request
      # @return [Boolean] whether the data was updated in OSM
      def mark_not_awarded(api)
        mark_awarded(api, Date.today, 0)
      end


      # Mark the badge as due in OSM
      # @param [Osm::Api] api The api to use to make the request
      # @param [Fixnum] level The level of the badge to award (1 for non-staged badges), setting the level to 0 unawards the badge
      # @return [Boolean] whether the data was updated in OSM
      def mark_due(api, level=earnt)
        fail ArgumentError, 'level can not be negative' if level < 0
        section = Osm::Section.get(api, section_id)
        require_ability_to(api, :write, :badge, section)

        result = api.perform_query("ext/badges/records/?action=overrideCompletion", {
          'section_id' => section.id,
          'badge_id' => badge.id,
          'badge_version' => badge.version,
          'scoutid' => member_id,
          'level' => level
        })
        updated = result.is_a?(Hash) &&
                  (result['scoutid'].to_i == member_id) &&
                  (result['completed'].to_i == level)
        return updated
      end

      # Mark the badge as not due in OSM
      # @param [Osm::Api] api The api to use to make the request
      # @return [Boolean] whether the data was updated in OSM
      def mark_not_due(api)
        mark_due(api, 0)
      end

      # Update data in OSM
      # @param [Osm::Api] api The api to use to make the request
      # @return [Boolean] whether the data was updated in OSM
      # @raise [Osm::ObjectIsInvalid] If the Data is invalid
      def update(api)
        fail Osm::ObjectIsInvalid, 'data is invalid' unless valid?
        section = Osm::Section.get(api, section_id)
        require_ability_to(api, :write, :badge, section)

        # Update requirements that changed
        requirements_updated = true
        editable_requirements = badge.requirements.select{ |r| r.editable }.map{ |r| r.id }
        requirements.changes.each do |requirement, (was,now)|
          if editable_requirements.include?(requirement)
            result = api.perform_query("ext/badges/records/?action=updateSingleRecord", {
              'scoutid' => member_id,
              'section_id' => section_id,
              'badge_id' => badge.id,
              'badge_version' => badge.version,
              'field' => requirement,
              'value' => now
            })
            requirements_updated = false unless result.is_a?(Hash) &&
                                   (result['scoutid'].to_i == member_id) &&
                                   (result[requirement.to_s].to_s == now.to_s)
          end
        end

        if requirements_updated
          requirements.clean_up!
        end

        # Update due if it changed
        due_updated = true
        if changed_attributes.include?('due')
          due_updated = mark_due(api, due)
        end

        # Update awarded if it changed 
        awarded_updated = true
        if changed_attributes.include?('awarded') || changed_attributes.include?('awarded_date')
          awarded_updated = mark_awarded(api, awarded_date, awarded)
        end

        # reset changed attributes if everything was updated ok
        if due_updated && awarded_updated
          reset_changed_attributes
        end

        return requirements_updated && due_updated && awarded_updated
      end

      def inspect
        Osm.inspect_instance(self, {:replace_with => {'badge' => :name}})
      end

      # Work out if the requirmeent has been met
      # @param [Fixnum, #to_i] requirement_id The id of the requirement to evaluate (e.g. "12", "xSomething", "Yes" or "")
      # @return [Boolean] whether the requirmeent has been met
      def requirement_met?(requirement_id)
        data = requirements[requirement_id.to_i].to_s
        return false if data == '0'
        !(data.blank? || data[0].downcase.eql?('x'))
      end

    end # Class Data

  end # Class Badge


  class CoreBadge < Osm::Badge
    private
    def self.type
      :core
    end
    def self.type_id
      4
    end
  end # Class CoreBadge

  class ChallengeBadge < Osm::Badge
    private
    def self.type
      :challenge
    end
    def self.type_id 
      1
    end
  end # Class ChallengeBadge

  class StagedBadge < Osm::Badge
    private
    def self.type
      :staged
    end
    def self.type_id 
      3
    end
  end # Class StagedBadge

  class ActivityBadge < Osm::Badge
    private
    def self.type
      :activity
    end
    def self.type_id 
      2
    end
    def self.subscription_required
      :silver
    end
  end # Class ActivityBadge

end # Module
