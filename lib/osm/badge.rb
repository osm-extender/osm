module Osm

  class Badge < Osm::Model
    class Requirement; end # Ensure the constant exists for the validators

    # @!attribute [rw] name
    #   @return [String] the name of the badge
    # @!attribute [rw] requirement_notes
    #   @return [String] a description of the badge
    # @!attribute [rw] requirements
    #   @return [Array<Osm::Badge::Requirement>] the requirements of the badge
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

    if ActiveModel::VERSION::MAJOR < 4
      attr_accessible :name, :requirement_notes, :requirements, :id, :version, :identifier, :group_name, :latest, :sharing, :user_id, :levels
    end

    validates_presence_of :name
    validates_presence_of :requirement_notes
    validates_presence_of :id
    validates_presence_of :version
    validates_presence_of :identifier
    validates_inclusion_of :sharing, :in => [:draft, :private, :optin, :optin_locked, :default_locked]
    validates_presence_of :user_id
    validates :requirements, :array_of => {:item_type => Osm::Badge::Requirement, :item_valid => true}
    validates_inclusion_of :latest, :in => [true, false]
    validates :levels, :array_of => {:item_type => Fixnum}, :allow_nil => true


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
      raise Error, 'This method must be called on one of the subclasses (CoreBadge, ChallengeBadge, StagedBadge or ActivityBadge)' if type.nil?
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
        )

        requirements = []
        ((structure[1] || {})['rows'] || []).each do |r|
          requirements.push Osm::Badge::Requirement.new(
            :badge => badge,
            :name => r['name'],
            :description => r['tooltip'],
            :module => r['module'],
            :field => Osm::to_i_or_nil(r['field']),
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
      raise Error, 'This method must NOT be called on one of the subclasses(CoreBadge, ChallengeBadge, StagedBadge or ActivityBadge)' unless type.nil?
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
            # Possible statuses: 'Started', 'Due', 'Awarded', 'Due Lvl ?' & 'Awarded Lvl ?'
            case status[0]
              when 'S'
                new_item[badge_identifier] = :started
              when 'D'
                new_item[badge_identifier] = :due
              when 'A'
                new_item[badge_identifier] = :awarded
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
      raise Error, 'This method must be called on one of the subclasses (CoreBadge, ChallengeBadge, StagedBadge or ActivityBadge)' if type.nil?
      Osm::Model.require_ability_to(api, :read, :badge, section, options)
      section = Osm::Section.get(api, section, options) unless section.is_a?(Osm::Section)
      term_id = (term.nil? ? Osm::Term.get_current_term_for_section(api, section, options) : term).to_i
      cache_key = ['badge_data', section.id, term_id, identifier]

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
          :completed => d['completed'].to_i,
          :awarded => d['awarded'].to_i,
          :awarded_date => Osm.parse_date(d['awardeddate']),
          :requirements => Hash[d.select{ |k,v| k.match(/\A\d+\Z/) }.map{ |k,v| [k.to_i, v] }],
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

    # Compare Badge based on name then id then version (desc)
    def <=>(another)
      result = self.name <=> another.try(:name)
      result = self.id <=> another.try(:id) if result == 0
      result = another.try(:version) <=> self.version if result == 0
      return result
    end


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
      include ActiveModel::MassAssignmentSecurity if ActiveModel::VERSION::MAJOR < 4
      include ActiveAttr::Model

      # @!attribute [rw] badge
      #   @return [Osm::Badge] the badge the requirement belongs to
      # @!attribute [rw] name
      #   @return [String] the name of the badge
      # @!attribute [rw] description
      #   @return [String] a description of the badge
      # @!attribute [rw] field
      #   @return [Fixnum] the field for the requirement (passed to OSM)
      # @!attribute [rw] editable
      #   @return [Boolean]

      attribute :badge, :type => Object
      attribute :name, :type => String
      attribute :description, :type => String
      attribute :module, :type => String
      attribute :field, :type => Integer
      attribute :editable, :type => Boolean

      if ActiveModel::VERSION::MAJOR < 4
        attr_accessible :name, :description, :field, :editable, :badge, :module
      end

      validates_presence_of :name
      validates_presence_of :description
      validates_presence_of :module
      validates_presence_of :field
      validates_presence_of :badge
      validates_inclusion_of :editable, :in => [true, false]

      # @!method initialize
      #   Initialize a new Badge
      #   @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)

      # Compare Badge::Requirement based on badge then field
      def <=>(another)
        result = self.badge <=> another.try(:badge)
        result = self.field <=> another.try(:field) if result == 0
        return result
      end

      def inspect
        Osm.inspect_instance(self, options={:replace_with => {'badge' => :identifier}})
      end

    end # Class Requirement


    class Data < Osm::Model
      # @!attribute [rw] member_id
      #   @return [Fixnum] ID of the member this data relates to
      # @!attribute [rw] first_name
      #   @return [Fixnum] the member's first name
      # @!attribute [rw] last_name
      #   @return [Fixnum] Ithe member's last name
      # @!attribute [rw] completed
      #   @return [Fixnum] whether this badge has been completed (i.e. it is due?), number indicates stage if appropriate
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
      attribute :completed, :type => Integer, :default => 0
      attribute :awarded, :type => Integer, :default => 0
      attribute :awarded_date, :type => Date, :default => nil
      attribute :requirements, :type => Object, :default => DirtyHashy.new
      attribute :section_id, :type => Integer
      attribute :badge, :type => Object

      if ActiveModel::VERSION::MAJOR < 4
        attr_accessible :member_id, :first_name, :last_name, :completed, :awarded, :awarded_date, :requirements, :section_id, :badge
      end

      validates_presence_of :badge
      validates_presence_of :first_name
      validates_presence_of :last_name
      validates_numericality_of :completed, :only_integer=>true, :greater_than_or_equal_to=>0
      validates_numericality_of :awarded, :only_integer=>true, :greater_than_or_equal_to=>0
      validates_numericality_of :member_id, :only_integer=>true, :greater_than=>0
      validates_numericality_of :section_id, :only_integer=>true, :greater_than=>0
      validates :requirements, :hash => {:key_type => String, :value_type => String}

      STAGES = {
        'nightsaway' => [1, 2, 3, 4, 5, 10, 15, 20, 35, 50, 75, 100, 125, 150, 175, 200],
        'hikes' => [1, 2, 5, 10, 15, 20, 35, 50],
        'timeonthewater' => [1, 2, 5, 10, 15, 20, 35, 50],
      }

      # @!method initialize
      #   Initialize a new Badge
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
        requirements.each do |field, data|
          next unless reguiremet_met?(data)
          count += 1
        end
        return count
      end

      # Get the total number of sections gained
      # @return [Hash]
      def sections_gained
        required = badge.needed_from_section
        gained = gained_in_sections
        count = 0

        required.each do |section, needed|
          next if gained[section] < needed
          count += 1
        end
        return count
      end

      # Get the number of requirements gained in each section
      # @return [Hash]
      def gained_in_sections
        count = {}
        requirements.each do |field, data|
          field = field.split('_')[0]
          unless field.eql?('y')
            count[field] ||= 0
            next unless reguiremet_met?(data)
            count[field] += 1
          else
            # A total 'section'
            count['y'] = data.to_i
          end
        end
        return count
      end

      # Check if this badge is due (according data retrieved from OSM)
      # @return [Boolean] whether the badge is due to the member
      def due?
        completed > awarded
      end


      # Check if this badge has been earnt
      # @return [Boolean] whether the badge is due to the member
      def earnt?
        if badge.type == :staged
          return (earnt > awarded)
        end
        return false if (completed.eql?(1) && awarded.eql?(1))
        return true if (completed.eql?(1) && awarded.eql?(0))
        if badge.sections_needed == -1 # require all sections
          return (sections_gained == badge.needed_from_section.keys.size)
        else
          return (total_gained >= badge.total_needed) && (sections_gained >= badge.sections_needed)
        end
      end

      # Get what stage which has most recently been earnt
      # (using #earnt? will tell you if it's still due (not yet awarded))
      # @return [Fixnum] the stage which has most recently been due
      def earnt
        unless badge.type == :staged
          return earnt? ? 1 : 0
        end
        if STAGES.keys.include?(badge.osm_key)
          total_done = requirements['y_01']
          stages = STAGES[badge.osm_key]
          stages.reverse_each do |stage|
            return stage if total_done >= stage
          end
        else
          (awarded..5).reverse_each do |stage|
            group = 'abcde'[stage - 1]
            if gained_in_sections[group] >= badge.needed_from_section[group]
              return stage
            end
          end
        end
        return 0
      end

      # Check if this badge has been started
      # @return [Boolean] whether the badge has been started by the member (always false if the badge has been completed)
      def started?
        return (started > completed) if badge.type.eql?(:staged) # It's a staged badge
        return false if completed?
        requirements.each do |key, value|
          case key.split('_')[0]
            when 'a'
              return true if reguiremet_met?(value)
            when 'y'
              return true if (value.to_i > 0)
          end
        end
        return false
      end

      # Get which stage has been started
      # @return [Fixnum] which stage of the badge has been started by the member (lowest)
      def started
        unless badge.type == :staged
          return started? ? 1 : 0
        else
          # Staged badge
          if STAGES.keys.include?(badge.osm_key) # Special staged badges
            stages = STAGES[badge.osm_key]
            done = requirements['y_01'].to_i
            return 0 if done < stages[0]                # Not started the first stage
            return 0 if done >= stages[stages.size - 1] # No more stages can be started
            (1..stages.size-1).reverse_each do |index|
              if (done < stages[index]) && (done > stages[index-1])
                return stages[index]
              end
            end
          else
            # 'Normal' staged badge
            return 0 if completed == 5 || awarded == 5 # No more stages can be started
            start_group = 'abcde'[completed] # Requirements use the group letter to denote stage
            started = 'z'
            requirements.each do |key, value|
              next if key[0] < start_group # This stage is marked as completed
              next if key[0] > started     # This stage is after the stage currently started
              started = key[0] unless value.blank? || value.to_s[0].downcase.eql?('x')
            end
            return started.eql?('z') ? 0 : 'abcde'.index(started)+1
          end
          return 0
        end
      end

      # Mark the badge as awarded in OSM
      # @param [Osm::Api] api The api to use to make the request
      # @param [Date] date The date to mark the badge as awarded
      # @param [Fixnum] level The level of the badge to award (1 for non-staged badges), setting the level to 0 unawards the badge
      # @return [Boolean] whether the data was updated in OSM
      def mark_awarded(api, date=Date.today, level=completed)
        raise ArgumentError, 'date is not a Date' unless date.is_a?(Date)
        raise ArgumentError, 'level can not be negative' if level < 0
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
      # @param [Date] date The date to mark the badge as unawarded
      # @return [Boolean] whether the data was updated in OSM
      def mark_not_awarded(api, date=Date.today)
        mark_awarded(api, date, 0)
      end


      # Mark the badge as due in OSM
      # @param [Osm::Api] api The api to use to make the request
      # @param [Fixnum] level The level of the badge to mark as due (1 for non-staged badges)
      # @return [Boolean] whether the data was updated in OSM
      def mark_due(api, level)
        mark_awarded(api, Date.today, level, :due)
      end

      # Update data in OSM
      # @param [Osm::Api] api The api to use to make the request
      # @return [Boolean] whether the data was updated in OSM
      # @raise [Osm::ObjectIsInvalid] If the Data is invalid
      def update(api)
        raise Osm::ObjectIsInvalid, 'data is invalid' unless valid?
        section = Osm::Section.get(api, section_id)
        require_ability_to(api, :write, :badge, section)

        updated = true
        editable_fields = badge.requirements.select{ |r| r.editable }.map{ |r| r.field}
        requirements.changes.each do |field, (was,now)|
          if editable_fields.include?(field)
            result = api.perform_query("challenges.php?type=#{badge.class.type}&section=#{section.type}", {
              'action' => 'updatesingle',
              'id' => member_id,
              'col' => field,
              'value' => now,
              'chal' => badge.osm_key,
              'sectionid' => section_id,
            })
            updated = false unless result.is_a?(Hash) &&
                                   (result['sid'].to_i == member_id) &&
                                   (result[field] == now)
          end
        end

        if updated
          requirements.clean_up!
        end

        if changed_attributes.include?('awarded') || changed_attributes.include?('awarded_date')
          if mark_awarded(api, awarded_date, awarded)
            reset_changed_attributes
          else
            updated = false
          end
        end

        return updated
      end

      # Compare Badge::Data based on badge, section_id then member_id
      def <=>(another)
        result = self.badge <=> another.try(:badge)
        result = self.section_id <=> another.try(:section_id) if result == 0
        result = self.member_id <=> another.try(:member_id) if result == 0
        return result
      end

      def inspect
        Osm.inspect_instance(self, options={:replace_with => {'badge' => :osm_key}})
      end

      private
      def reguiremet_met?(data)
        return false if data == 0
        !(data.blank? || data.to_s[0].downcase.eql?('x'))
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
