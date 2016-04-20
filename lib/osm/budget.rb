module Osm

  class Budget < Osm::Model
    SORT_BY = [:section_id, :name]

    # @!attribute [rw] id
    #   @return [Fixnum] The OSM ID for the budget
    # @!attribute [rw] section_id
    #   @return [Fixnum] The OSM ID for the section the budget belongs to
    # @!attribute [rw] name
    #   @return [String] The name of the budget

    attribute :id, :type => Integer
    attribute :section_id, :type => Integer
    attribute :name, :type => String

    if ActiveModel::VERSION::MAJOR < 4
      attr_accessible :id, :section_id, :name
    end

    validates_numericality_of :id, :only_integer=>true, :greater_than=>0, :unless => Proc.new { |r| r.id.nil? }
    validates_numericality_of :section_id, :only_integer=>true, :greater_than=>0
    validates_presence_of :name


    # @!method initialize
    #   Initialize a new Budget
    #   @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)


    # Get budgets for a section
    # @param [Osm::Api] api The api to use to make the request
    # @param [Osm::Section, Fixnum, #to_i] section The section (or its ID) to get the structure for
    # @!macro options_get
    # @return [Array<Osm::Budget>] representing the donations made
    def self.get_for_section(api, section, options={})
      Osm::Model.require_ability_to(api, :read, :finance, section, options)
      section_id = section.to_i
      cache_key = ['budgets', section_id]

      if !options[:no_cache] && Osm::Model.cache_exist?(api, cache_key)
        return Osm::Model.cache_read(api, cache_key)
      end

      data = api.perform_query("finances.php?action=getCategories&sectionid=#{section_id}")

      budgets = []
      data = data['items']
      if data.is_a?(Array)
        data.each do |budget|
          budgets.push Budget.new(
            :id => Osm::to_i_or_nil(budget['categoryid']),
            :section_id => Osm::to_i_or_nil(budget['sectionid']),
            :name => budget['name'],
          )
        end
      end

      Osm::Model.cache_write(api, cache_key, budgets) unless budgets.nil?
      return budgets
    end


    # Create the budget in OSM
    # @param [Osm::Api] api The api to use to make the request
    # @return [Boolean] whether the budget was created
    # @raise [Osm::ObjectIsInvalid] If the Budget is invalid
    # @raise [Osm::Error] If the budget already exists in OSM
    def create(api)
      raise Osm::Error, 'the budget already exists in OSM' unless id.nil?
      raise Osm::ObjectIsInvalid, 'budget is invalid' unless valid?
      Osm::Model.require_ability_to(api, :write, :finance, section_id)

      data = api.perform_query("finances.php?action=addCategory&sectionid=#{section_id}")
      if data.is_a?(Hash) && data['ok'].eql?(true)
        # The cached budgets for the section will be out of date - remove them
        cache_delete(api, ['budgets', section_id])
        budgets = Budget.get_for_section(api, section_id, {:no_cache => true})
        budget = budgets.sort.select{ |b| b.name.eql?('** Unnamed **') }[-1]
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
    # @param [Osm::Api] api The api to use to make the request
    # @return [Boolean] whether the budget was updated
    # @raise [Osm::ObjectIsInvalid] If the Budget is invalid
    def update(api)
      raise Osm::ObjectIsInvalid, 'budget is invalid' unless valid?
      Osm::Model.require_ability_to(api, :write, :finance, section_id)

      data = api.perform_query("finances.php?action=updateCategory&sectionid=#{section_id}", {
        'categoryid' => id,
        'column' => 'name',
        'value' => name,
        'section_id' => section_id,
        'row' => 0,
      })
      if (data.is_a?(Hash) && data['ok'].eql?(true))
        # The cached budgets for the section will be out of date - remove them
        cache_delete(api, ['budgets', section_id])
        return true
      end
      return false
    end

    # Delete budget from OSM
    # @param [Osm::Api] api The api to use to make the request
    # @return [Boolean] whether the budget was deleted
    def delete(api)
      Osm::Model.require_ability_to(api, :write, :finance, section_id)

      data = api.perform_query("finances.php?action=deleteCategory&sectionid=#{section_id}", {
        'categoryid' => id,
      })
      if (data.is_a?(Hash) && data['ok'].eql?(true))
        # The cached budgets for the section will be out of date - remove them
        cache_delete(api, ['budgets', section_id])
        return true
      end
      return false
    end

  end # Class Budget

end
