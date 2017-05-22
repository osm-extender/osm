module Osm

  class Grouping < Osm::Model
    # @!attribute [rw] id
    #   @return [Integer] the id for grouping
    # @!attribute [rw] section_id
    #   @return [Integer] the id for the section this grouping belongs to
    # @!attribute [rw] name
    #   @return [String] the name of the grouping
    # @!attribute [rw] active
    #   @return true, false whether the grouping is active
    # @!attribute [rw] points
    #   @return [Integer] the points awarded to the grouping

    attribute :id, type: Integer
    attribute :section_id, type: Integer
    attribute :name, type: String
    attribute :active, type: Boolean
    attribute :points, type: Integer

    validates_numericality_of :id, only_integer:true, greater_than_or_equal_to:-2
    validates_numericality_of :section_id, only_integer:true, greater_than:0
    validates_presence_of :name
    validates_numericality_of :points, only_integer:true
    validates_presence_of :active


    # Get the groupings that a section has
    # @param api [Osm::Api] The api to use to make the request
    # @param section [Integer] The section (or its ID) of the section to get groupings for
    # @!macro options_get
    # @return [Array<Osm::Grouping>, nil] An array of groupings or nil if the user can not access that section
    def self.get_for_section(api:, section:, no_read_cache: false)
      section_id = section.to_i
      require_ability_to(api: api, to: :read, on: :member, sevtion: section_id)
      cache_key = ['groupings', section_id]

      cache_fetch(api: api, key: cache_key, no_read_cache: no_read_cache) do
        data = api.post_query("users.php?action=getPatrols&sectionid=#{section_id}")

        result = Array.new
        if data.is_a?(Hash) && data['patrols'].is_a?(Array)
          data['patrols'].each do |item|
            result.push Osm::Grouping.new({
              id: Osm::to_i_or_nil(item['patrolid']),
              section_id: section_id,
              name: item['name'],
              active: (item['active'] == 1),
              points: Osm::to_i_or_nil(item['points']),
            })
          end
        end
        result
      end # cache fetch
    end


    # @!method initialize
    #   Initialize a new Term
    #   @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)


    # Update the grouping in OSM
    # @param api [Osm::Api] The api to use to make the request
    # @return [Boolan] whether the member was successfully updated or not
    # @raise [Osm::ObjectIsInvalid] If the Grouping is invalid
    def update(api)
      fail Osm::ObjectIsInvalid, 'grouping is invalid' unless valid?
      require_ability_to(api: api, to: :read, on: :member, section: section_id)

      to_update = changed_attributes
      result = true

      if to_update.include?('name') || to_update.include?('active')
        data = api.post_query("users.php?action=editPatrol&sectionid=#{section_id}", post_data: {
          'patrolid' => self.id,
          'name' => name,
          'active' => active,
        })
        result &= data.nil?
      end

      if to_update.include?('points')
        data = api.post_query("users.php?action=updatePatrolPoints&sectionid=#{section_id}", post_data: {
          'patrolid' => self.id,
          'points' => points,
        })
        result &= (data == {})
      end

      if result
        reset_changed_attributes
        # The cached groupings for the section will be out of date - remove them
        Osm::Model.cache_delete(api: api, key: ['groupings', section_id])
      end

      return result
    end

    private def sort_by
      ['section_id', 'name']
    end

  end # Class Grouping

end # Module
