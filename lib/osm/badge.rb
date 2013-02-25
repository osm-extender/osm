module Osm
  
  class Badge < Osm::Model
    class Requirement; end # Ensure the constant exists for the validators

    # @!attribute [rw] name
    #   @return [String] the name of the badge
    # @!attribute [rw] requirement_notes
    #   @return [String] a description of the badge
    # @!attribute [rw] key
    #   @return [String] the key for the badge (passed to OSM)
    # @!attribute [rw] sections_needed
    #   @return [Fixnum]
    # @!attribute [rw] total_needed
    #   @return [Fixnum]
    # @!attribute [rw] needed_from_section
    #   @return [Hash]
    # @!attribute [rw] requirements
    #   @return [Array<Osm::Badges::Badge::Requirement>]

    attribute :name, :type => String
    attribute :requirement_notes, :type => String
    attribute :key, :type => String
    attribute :sections_needed, :type => Integer
    attribute :total_needed, :type => Integer
    attribute :needed_from_section, :type => Object
    attribute :requirements, :type => Object

    attr_accessible :name, :requirement_notes, :key, :sections_needed, :total_needed, :needed_from_section, :requirements

    validates_numericality_of :sections_needed, :only_integer=>true, :greater_than_or_equal_to=>-1
    validates_numericality_of :total_needed, :only_integer=>true, :greater_than_or_equal_to=>-1
    validates_presence_of :name
    validates_presence_of :requirement_notes
    validates_presence_of :key
    validates :needed_from_section, :hash => {:key_type => String, :value_type => Fixnum}
    validates :requirements, :array_of => {:item_type => Osm::Badge::Requirement, :item_valid => true}


    # @!method initialize
    #   Initialize a new Badge
    #   @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)


    # Get badges
    # @param [Osm::Api] api The api to use to make the request
    # @param [Osm::Section, Fixnum, #to_i] section The section (or its ID) to get the due badges for
    # @!macro options_get
    # @return [Array<Osm::Badge>]
    def self.get_badges_for_section(api, section, options={})
      raise Error, 'This method must be called on one of the subclasses (CoreBadge, ChallengeBadge, StagedBadge or ActivityBadge)' if badge_type.nil?
      require_ability_to(api, :read, :badge, section, options)
      section = Osm::Section.get(api, section, options) unless section.is_a?(Osm::Section)
      cache_key = ['badges', section.type, badge_type]

      if !options[:no_cache] && Osm::Model.cache_exist?(api, cache_key)
        return cache_read(api, cache_key)
      end

      term_id = Osm::Term.get_current_term_for_section(api, section, options).to_i
      badges = []

      data = api.perform_query("challenges.php?action=getInitialBadges&type=#{badge_type}&sectionid=#{section.id}&section=#{section.type}&termid=#{term_id}")
      badge_order = data["badgeOrder"].to_s.split(',')
      structures = data["structure"] || {}
      details = data["details"] || {}
      badge_order.each do |b|
        structure = structures[b]
        detail = details[b]
        requirements = []
        config = ActiveSupport::JSON.decode(detail['config'] || '{}')

        ((structure[1] || {})['rows'] || []).each do |r|
          requirements.push Osm::Badge::Requirement.new(
            :badge_key => detail['table'],
            :name => r['name'],
            :description => r['tooltip'],
            :field => r['field'],
            :editable => r['editable'].eql?('true'),
          )
        end

        badges.push new(
          :name => detail['name'],
          :requirement_notes => detail['description'],
          :key => detail['table'],
          :sections_needed => config['sectionsneeded'].to_i,
          :total_needed => config['totalneeded'].to_i,
          :needed_from_section => (config['sections'] || {}).inject({}) { |h,(k,v)| h[k] = v.to_i; h },
          :requirements => requirements,
        )
      end

      cache_write(api, cache_key, badges)
      return badges
    end


    private
    def self.badge_type
      nil
    end
    def self.subscription_required
      :bronze
    end


    class Requirement
      include ::ActiveAttr::MassAssignmentSecurity
      include ::ActiveAttr::Model

      # @!attribute [rw] badge_key
      #   @return [String] passed to OSM
      # @!attribute [rw] name
      #   @return [String] the name of the badge
      # @!attribute [rw] description
      #   @return [String] a description of the badge
      # @!attribute [rw] field
      #   @return [String] the field for the requirement (passed to OSM)
      # @!attribute [rw] editable
      #   @return [Boolean]

      attribute :badge_key, :type => String
      attribute :name, :type => String
      attribute :description, :type => String
      attribute :field, :type => String
      attribute :editable, :type => Boolean

      attr_accessible :name, :description, :field, :editable, :badge_key

      validates_presence_of :name
      validates_presence_of :description
      validates_presence_of :field
      validates_presence_of :badge_key
      validates_inclusion_of :editable, :in => [true, false]

      # @!method initialize
      #   Initialize a new Badge
      #   @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)

    end # Class Requirement

  end # Class Badge


  class CoreBadge < Osm::Badge
    private
    def self.badge_type
      :core
    end
  end # Class CoreBadge

  class ChallengeBadge < Osm::Badge
    private
    def self.badge_type
      :challenge
    end
  end # Class ChallengeBadge

  class StagedBadge < Osm::Badge
    private
    def self.badge_type
      :staged
    end
  end # Class StagedBadge

  class ActivityBadge < Osm::Badge
    private
    def self.badge_type
      :activity
    end
    def self.subscription_required
      :silver
    end
  end # Class ActivityBadge

end # Module
