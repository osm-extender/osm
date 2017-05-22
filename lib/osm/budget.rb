module Osm

  class Budget < Osm::Model
    # @!attribute [rw] id
    #   @return [Integer] The OSM ID for the budget
    # @!attribute [rw] section_id
    #   @return [Integer] The OSM ID for the section the budget belongs to
    # @!attribute [rw] name
    #   @return [String] The name of the budget

    attribute :id, :type => Integer
    attribute :section_id, :type => Integer
    attribute :name, :type => String

    validates_numericality_of :id, :only_integer=>true, :greater_than=>0, :unless => Proc.new { |r| r.id.nil? }
    validates_numericality_of :section_id, :only_integer=>true, :greater_than=>0
    validates_presence_of :name


    # @!method initialize
    #   Initialize a new Budget
    #   @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)


    # Get budgets for a section
    # @param api [Osm::Api] The api to use to make the request
    # @param section [Osm::Section, Integer, #to_i] The section (or its ID) to get the structure for
    # @!macro options_get
    # @return [Array<Osm::Budget>] representing the donations made
    def self.get_for_section(api:, section:, no_read_cache: false)
      Osm::Model.require_ability_to(api: api, to: :read, on: :finance, section: section, no_read_cache: no_read_cache)
      section_id = section.to_i
      cache_key = ['budgets', section_id]

      Osm::Model.cache_fetch(api: api, key: cache_key, no_read_cache: no_read_cache) do
        data = api.post_query("finances.php?action=getCategories&sectionid=#{section_id}")

        data = data['items']
        data.map do |budget|
          Budget.new(
            :id => Osm::to_i_or_nil(budget['categoryid']),
            :section_id => Osm::to_i_or_nil(budget['sectionid']),
            :name => budget['name'],
          )
        end # data.map
      end # cache fetch
    end


    # Create the budget in OSM
    # @param api [Osm::Api] The api to use to make the request
    # @return [Boolean] whether the budget was created
    # @raise [Osm::ObjectIsInvalid] If the Budget is invalid
    # @raise [Osm::Error] If the budget already exists in OSM
    def create(api)
      fail Osm::Error, 'the budget already exists in OSM' unless id.nil?
      fail Osm::ObjectIsInvalid, 'budget is invalid' unless valid?
      Osm::Model.require_ability_to(api: api, to: :write, on: :finance, section: section_id)

      data = api.post_query("finances.php?action=addCategory&sectionid=#{section_id}")
      if data.is_a?(Hash) && data['ok'].eql?(true)
        # The cached budgets for the section will be out of date - remove them
        cache_delete(api: api, key: ['budgets', section_id])
        budgets = Budget.get_for_section(api: api, section: section_id, no_read_cache: true)
        budget = budgets.sort.select{ |b| b.name.eql?('** Unnamed **') }.last
        return false if budget.nil? # a new blank budget was NOT created
        budget.name = name
        if budget.update(api)
          self.id = budget.id
          return true
        end
      end
      return false
    end

    # Update budget in OSM
    # @param api [Osm::Api] The api to use to make the request
    # @return [Boolean] whether the budget was updated
    # @raise [Osm::ObjectIsInvalid] If the Budget is invalid
    def update(api)
      fail Osm::ObjectIsInvalid, 'budget is invalid' unless valid?
      Osm::Model.require_ability_to(api: api, to: :write, on: :finance, section: section_id)

      data = api.post_query("finances.php?action=updateCategory&sectionid=#{section_id}", post_data: {
        'categoryid' => id,
        'column' => 'name',
        'value' => name,
        'section_id' => section_id,
        'row' => 0,
      })
      if (data.is_a?(Hash) && data['ok'].eql?(true))
        # The cached budgets for the section will be out of date - remove them
        cache_delete(api: api, key: ['budgets', section_id])
        return true
      end
      return false
    end

    # Delete budget from OSM
    # @param api [Osm::Api] The api to use to make the request
    # @return [Boolean] whether the budget was deleted
    def delete(api)
      Osm::Model.require_ability_to(api: api, to: :write, on: :finance, section: section_id)

      data = api.post_query("finances.php?action=deleteCategory&sectionid=#{section_id}", post_data: {
        'categoryid' => id,
      })
      if (data.is_a?(Hash) && data['ok'].eql?(true))
        # The cached budgets for the section will be out of date - remove them
        cache_delete(api: api, key: ['budgets', section_id])
        return true
      end
      return false
    end

    private def sort_by
      ['section_id', 'name']
    end

  end # Class Budget

end
