module Osm

  class Badge < Osm::Model
    class Requirement; end # Ensure the constant exists for the validators

    # @!attribute [rw] name
    #   @return [String] the name of the badge
    # @!attribute [rw] requirement_notes
    #   @return [String] a description of the badge
    # @!attribute [rw] osm_key
    #   @return [String] the key for the badge in OSM
    # @!attribute [rw] sections_needed
    #   @return [Fixnum]
    # @!attribute [rw] total_needed
    #   @return [Fixnum]
    # @!attribute [rw] needed_from_section
    #   @return [Hash]
    # @!attribute [rw] requirements
    #   @return [Array<Osm::Badge::Requirement>]

    attribute :name, :type => String
    attribute :requirement_notes, :type => String
    attribute :osm_key, :type => String
    attribute :sections_needed, :type => Integer
    attribute :total_needed, :type => Integer
    attribute :needed_from_section, :type => Object
    attribute :requirements, :type => Object

    attr_accessible :name, :requirement_notes, :osm_key, :sections_needed, :total_needed, :needed_from_section, :requirements

    validates_numericality_of :sections_needed, :only_integer=>true, :greater_than_or_equal_to=>-1
    validates_numericality_of :total_needed, :only_integer=>true, :greater_than_or_equal_to=>-1
    validates_presence_of :name
    validates_presence_of :requirement_notes
    validates_presence_of :osm_key
    validates :needed_from_section, :hash => {:key_type => String, :value_type => Fixnum}
    validates :requirements, :array_of => {:item_type => Osm::Badge::Requirement, :item_valid => true}


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

      data = api.perform_query("challenges.php?action=getInitialBadges&type=#{type}&sectionid=#{section.id}&section=#{section_type}&termid=#{term_id}")
      badge_order = data["badgeOrder"].to_s.split(',')
      structures = data["structure"] || {}
      details = data["details"] || {}
      badge_order.each do |b|
        structure = structures[b]
        detail = details[b]
        config = ActiveSupport::JSON.decode(detail['config'] || '{}')

        badge = new(
          :name => detail['name'],
          :requirement_notes => detail['description'],
          :osm_key => detail['shortname'],
          :sections_needed => config['sectionsneeded'].to_i,
          :total_needed => config['totalneeded'].to_i,
          :needed_from_section => (config['sections'] || {}).inject({}) { |h,(k,v)| h[k] = v.to_i; h },
        )

        requirements = []
        ((structure[1] || {})['rows'] || []).each do |r|
          requirements.push Osm::Badge::Requirement.new(
            :badge => badge,
            :name => r['name'],
            :description => r['tooltip'],
            :field => r['field'],
            :editable => r['editable'].eql?('true'),
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
      raise Error, 'This method must be called on one of the subclasses (CoreBadge, ChallengeBadge, StagedBadge or ActivityBadge)' if type.nil?
      require_ability_to(api, :read, :badge, section, options)
      section = Osm::Section.get(api, section, options) unless section.is_a?(Osm::Section)
      term_id = (term.nil? ? Osm::Term.get_current_term_for_section(api, section, options) : term).to_i
      cache_key = ['badge-summary', section.id, term_id, type]

      if !options[:no_cache] && Osm::Model.cache_exist?(api, cache_key)
        return cache_read(api, cache_key)
      end

      summary = []
      data = api.perform_query("challenges.php?action=summary&section=#{section.type}&sectionid=#{section.id}&termid=#{term_id}&type=#{type}")
      data['items'].each do |item|
        new_item = {
          :first_name => item['firstname'],
          :last_name => item['lastname'],
        }
        (item.keys - ['firstname', 'lastname']).each do |key|
          new_item[key] = item[key]
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
      cache_key = ['badge_data', section.id, term_id, osm_key]

      if !options[:no_cache] && cache_exist?(api, cache_key)
        return cache_read(api, cache_key)
      end

      datas = []
      data = api.perform_query("challenges.php?termid=#{term_id}&type=#{type}&section=#{section.type}&c=#{osm_key}&sectionid=#{section.id}")
      data['items'].each do |d|
        datas.push Osm::Badge::Data.new(
          :member_id => d['scoutid'],
          :first_name => d['firstname'],
          :last_name => d['lastname'],
          :completed => d['completed'].to_i,
          :awarded => d['awarded'].to_i,
          :awarded_date => Osm.parse_date(d['awardeddate']),
          :requirements => d.select{ |k,v| k.include?('_') },
          :section_id => section.id,
          :badge => self,
        )
      end

      cache_write(api, cache_key, datas)
      return datas
    end

    # Compare Badge based on name then osm_key
    def <=>(another)
      result = self.name <=> another.try(:name)
      result = self.osm_key <=> another.try(:osm_key) if result == 0
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
      include ::ActiveAttr::MassAssignmentSecurity
      include ::ActiveAttr::Model

      # @!attribute [rw] badge
      #   @return [Osm::Badge] the badge the requirement belongs to
      # @!attribute [rw] name
      #   @return [String] the name of the badge
      # @!attribute [rw] description
      #   @return [String] a description of the badge
      # @!attribute [rw] field
      #   @return [String] the field for the requirement (passed to OSM)
      # @!attribute [rw] editable
      #   @return [Boolean]

      attribute :badge, :type => Object
      attribute :name, :type => String
      attribute :description, :type => String
      attribute :field, :type => String
      attribute :editable, :type => Boolean

      attr_accessible :name, :description, :field, :editable, :badge

      validates_presence_of :name
      validates_presence_of :description
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
        Osm.inspect_instance(self, options={:replace_with => {'badge' => :osm_key}})
      end

    end # Class Requirement


    class Data
      include ::ActiveAttr::MassAssignmentSecurity
      include ::ActiveAttr::Model

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

      attr_accessible :member_id, :first_name, :last_name, :completed, :awarded, :awarded_date, :requirements, :section_id, :badge

      validates_presence_of :badge
      validates_presence_of :first_name
      validates_presence_of :last_name
      validates_numericality_of :completed, :only_integer=>true, :greater_than_or_equal_to=>0
      validates_numericality_of :awarded, :only_integer=>true, :greater_than_or_equal_to=>0
      validates_numericality_of :member_id, :only_integer=>true, :greater_than=>0
      validates_numericality_of :section_id, :only_integer=>true, :greater_than=>0
      validates :requirements, :hash => {:key_type => String, :value_type => String}

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
          next if data.blank? || data[0].downcase.eql?('x')
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
          next if gained[section] >= needed
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
          count[field] ||= 0
          next if data.blank? || data[0].downcase.eql?('x')
          count[field] += 1
        end
        return count
      end

      # Check if this badge is due
      # @return [Boolean] whether the badge is due to the member
      def due?
        completed > awarded
      end

      # Check if this badge has been started
      # @return [Boolean] whether the badge has been started by the member (always false if the badge has been completed)
      def started?
        unless badge.type == :staged
          return false if completed?
          requirements.each do |key, value|
            return true unless value.blank? || value[0].downcase.eql?('x')
          end
        else
          # Staged badge
          return (started > completed)
        end
        return false
      end

      # Get shich stage has been started
      # @return [Fixnum] which stage of the badge has been started by the member (lowest)
      def started
        unless badge.type == :staged
          return started? ? 1 : 0
        else
          # Staged badge
          if ['nightsaway', 'hikes'].include?(badge.osm_key) # Special staged badges
            stages = [1, 5, 10, 20, 35, 50, 75, 100, 125, 150, 175, 200] if badge.osm_key.eql?('nightsaway')
            stages = [1, 5, 10, 20, 35, 50] if badge.osm_key.eql?('hikes')
            done = requirements['y_01'].to_i
            return 0 if done < stages[0]                # Not started the first stage
            return 0 if done >= stages[stages.size - 1] # No more stages can be started
            (1..stages.size-1).reverse_each do |index|
              if (done < stages[index]) && (done > stages[index-1])
                return stages[index]
              end
            end
          else
            start_group = 'abcde'[completed] # Requirements use the group letter to denote stage
            started = 'z'
            requirements.each do |key, value|
              next if key[0] < start_group # This stage is marked as completed
              next if key[0] > started     # This stage is after the stage currently started
              started = key[0] unless value.blank? || value[0].downcase.eql?('x')
            end
            return started.eql?('z') ? 0 : 'abcde'.index(started)+1
          end
          return 0
        end
      end

      # Update data in OSM
      # @param [Osm::Api] api The api to use to make the request
      # @return [Boolean] whether the data was updated in OSM
      # @raise [Osm::ObjectIsInvalid] If the Data is invalid
      def update(api)
        raise Osm::ObjectIsInvalid, 'data is invalid' unless valid?
        section = Osm::Section.get(api, section_id)
        Osm::Model.require_ability_to(api, :write, :badge, section)

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

    end # Class Data

  end # Class Badge


  class CoreBadge < Osm::Badge
    private
    def self.type
      :core
    end
  end # Class CoreBadge

  class ChallengeBadge < Osm::Badge
    private
    def self.type
      :challenge
    end
  end # Class ChallengeBadge

  class StagedBadge < Osm::Badge
    private
    def self.type
      :staged
    end
  end # Class StagedBadge

  class ActivityBadge < Osm::Badge
    private
    def self.type
      :activity
    end
    def self.subscription_required
      :silver
    end
  end # Class ActivityBadge

end # Module
