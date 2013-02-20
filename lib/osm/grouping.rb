module Osm

  class Grouping < Osm::Model

    # @!attribute [rw] id
    #   @return [Fixnum] the id for grouping
    # @!attribute [rw] section_id
    #   @return [Fixnum] the id for the section this grouping belongs to
    # @!attribute [rw] name
    #   @return [String] the name of the grouping
    # @!attribute [rw] active
    #   @return [Boolean] whether the grouping is active
    # @!attribute [rw] points
    #   @return [Fixnum] the points awarded to the grouping

    attribute :id, :type => Integer
    attribute :section_id, :type => Integer
    attribute :name, :type => String
    attribute :active, :type => Boolean
    attribute :points, :type => Integer

    attr_accessible :id, :section_id, :name, :active, :points

    validates_numericality_of :id, :only_integer=>true, :greater_than_or_equal_to=>-2
    validates_numericality_of :section_id, :only_integer=>true, :greater_than=>0
    validates_presence_of :name
    validates_numericality_of :points, :only_integer=>true
    validates_presence_of :active


    # Get the groupings that a section has
    # @param [Osm::Api] api The api to use to make the request
    # @param [Fixnum] section the section (or its ID) of the section to get groupings for
    # @!macro options_get
    # @return [Array<Osm::Grouping>, nil] An array of groupings or nil if the user can not access that section
    def self.get_for_section(api, section, options={})
      section_id = section.to_i
      require_ability_to(api, :read, :member, section_id)
      cache_key = ['groupings', section_id]

      if !options[:no_cache] && cache_exist?(api, cache_key)
        return cache_read(api, cache_key)
      end

      data = api.perform_query("users.php?action=getPatrols&sectionid=#{section_id}")

      result = Array.new
      if data.is_a?(Hash) && data['patrols'].is_a?(Array)
        data['patrols'].each do |item|
          result.push Osm::Grouping.new({
          :id => Osm::to_i_or_nil(item['patrolid']),
          :section_id => section_id,
          :name => item['name'],
          :active => (item['active'] == 1),
          :points => Osm::to_i_or_nil(item['points']),
        })
        end
        cache_write(api, cache_key, result)
      end

      return result
    end


    # @!method initialize
    #   Initialize a new Term
    #   @param [Hash] attributes the hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)


    # Update the grouping in OSM
    # @param [Osm::Api] api The api to use to make the request
    # @return [Boolan] whether the member was successfully updated or not
    def update(api)
      require_ability_to(api, :administer, :member, section_id)
      raise ObjectIsInvalid, 'grouping is invalid' unless valid?

      to_update = changed_attributes
      result = true

      if to_update.include?('name') || to_update.include?('active')
        data = api.perform_query("users.php?action=editPatrol&sectionid=#{section_id}", {
          'patrolid' => self.id,
          'name' => name,
          'active' => active,
        })
        result &= data.nil?
      end

      if to_update.include?('points')
        data = api.perform_query("users.php?action=updatePatrolPoints&sectionid=#{section_id}", {
          'patrolid' => self.id,
          'points' => points,
        })
        result &= (data == {})
      end

      if result
        # The cached groupings for the section will be out of date - remove them
        Osm::Model.cache_delete(api, ['groupings', section_id])
      end

      return result
    end


  end # Class Grouping

end # Module
