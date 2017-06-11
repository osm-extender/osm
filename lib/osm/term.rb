module Osm

  class Term < Osm::Model
    # @!attribute [rw] id
    #   @return [Integer] the id for the term
    # @!attribute [rw] section_id
    #   @return [Integer] the section the term belongs to
    # @!attribute [rw] name
    #   @return [Integer] the name of the term
    # @!attribute [rw] start
    #   @return [Date] when the term starts
    # @!attribute [rw] finish
    #   @return [Date] when the term finishes

    attribute :id, type: Integer
    attribute :section_id, type: Integer
    attribute :name, type: String
    attribute :start, type: Date
    attribute :finish, type: Date

    validates_numericality_of :id, only_integer: true, greater_than: 0
    validates_numericality_of :section_id, only_integer: true, greater_than: 0
    validates_presence_of :name
    validates_presence_of :start
    validates_presence_of :finish


    # Get the terms that the OSM user can access
    # @param api [Osm::Api] The api to use to make the request
    # @!macro options_get
    # @return [Array<Osm::Term>]
    def self.get_all(api, no_read_cache: false)
      cache_key = ['terms', api.user_id]

      if cache_exist?(api: api, key: cache_key, no_read_cache: no_read_cache)
        ids = cache_read(api: api, key: cache_key)
        return get_from_ids(api: api, ids: ids, key_base: 'term', method: :get_all, no_read_cache: no_read_cache)
      end

      data = api.post_query('api.php?action=getTerms')

      terms = Array.new
      ids = Array.new
      data.each_key do |key|
        data[key].each do |term_data|
          term = Osm::Term.new(
            id: Osm.to_i_or_nil(term_data['termid']),
            section_id: Osm.to_i_or_nil(term_data['sectionid']),
            name: term_data['name'],
            start: Osm.parse_date(term_data['startdate']),
            finish: Osm.parse_date(term_data['enddate'])
          )
          terms.push term
          ids.push term.id
          cache_write(api: api, key: ['term', term.id], data: term)
        end
      end

      cache_write(api: api, key: cache_key, data: ids)
      terms
    end

    # Get the terms that the OSM user can access for a given section
    # @param api [Osm::Api] The api to use to make the request
    # @param section [Integer] The section (or its ID) of the section to get terms for
    # @!macro options_get
    # @return [Array<Osm::Term>, nil] An array of terms or nil if the user can not access that section
    def self.get_for_section(api:, section:, no_read_cache: false)
      require_access_to_section(api: api, section: section, no_read_cache: no_read_cache)
      section_id = section.to_i
      get_all(api, no_read_cache: no_read_cache).select { |term| term.section_id == section_id }
    end

    # Get a term
    # @param api [Osm::Api] The api to use to make the request
    # @param id [Integer] The id of the required term
    # @!macro options_get
    # @return nil if an error occured or the user does not have access to that term
    # @return [Osm::Term]
    def self.get(api:, id:, no_read_cache: false)
      cache_key = ['term', id]

      if cache_exist?(api: api, key: cache_key, no_read_cache: no_read_cache)
        term = cache_read(api: api, key: cache_key)
        return term
      end

      terms = get_all(api, no_read_cache: no_read_cache)
      return nil unless terms.is_a? Array

      terms.each do |term|
        if term.id == id
          return term
        end
      end
      nil
    end

    # Get the current term for a given section
    # @param api [Osm::Api] The api to use to make the request
    # @param section [Osm::Section, Integer, #to_i] The section (or its ID)  to get terms for
    # @!macro options_get
    # @return [Osm::Term, nil] The current term or nil if the user can not access that section
    # @raise [Osm::Error::NoCurrentTerm] If the Section doesn't have a Term which is current
    def self.get_current_term_for_section(api:, section:, no_read_cache: false)
      terms = get_for_section(api: api, section: section, no_read_cache: no_read_cache)
      return nil if terms.nil?
      terms.each do |term|
        return term if term.current?
      end

      fail Osm::Error::NoCurrentTerm.new('There is no current term for the section.', section)
    end

    # Create a term in OSM
    # @param api [Osm::Api] The api to use to make the request
    # @param section [Osm::Section, Integer] (required) section or section_id to add the term to
    # @param name [String] (required) the name for the term
    # @param start [Date, #strftime] (required) the date for the start of term
    # @param finish [Date, #strftime] (required) the date for the finish of term
    # @return true, false if the operation suceeded or not
    def self.create(api:, section:, name:, start:, finish:)
      require_access_to_section(api: api, section: section)

      data = api.post_query("users.php?action=addTerm&sectionid=#{section.to_i}", post_data: {
        'term' => name,
        'start' => start.strftime(Osm::OSM_DATE_FORMAT),
        'end' => finish.strftime(Osm::OSM_DATE_FORMAT),
        'termid' => '0'
      })

      # The cached terms for the section will be out of date - remove them
      get_all(api).each do |term|
        cache_delete(api: api, key: ['term', term.id]) if term.section_id == section.to_i
      end
      cache_delete(api: api, key: ['terms', api.user_id])

      data.is_a?(Hash) && data['terms'].is_a?(Hash)
    end


    # Update a term in OSM
    # @param api [Osm::Api] The api to use to make the request
    # @return true, false if the operation suceeded or not
    # @raise [Osm::ObjectIsInvalid] If the Term is invalid
    def update(api)
      fail Osm::ObjectIsInvalid, 'term is invalid' unless valid?
      require_access_to_section(api: api, section: section_id)

      data = api.post_query("users.php?action=addTerm&sectionid=#{section_id}", post_data: {
        'term' => name,
        'start' => start.strftime(Osm::OSM_DATE_FORMAT),
        'end' => finish.strftime(Osm::OSM_DATE_FORMAT),
        'termid' => id
      })

      return false unless data.is_a?(Hash) && data['terms'].is_a?(Hash)
      reset_changed_attributes
      # The cached term will be out of date - remove it
      cache_delete(api: api, key: ['term', id])
      true
    end



    # @!method initialize
    #   Initialize a new Term
    #   @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)


    # Determine if the term is completly before the passed date
    # @param date [Date]
    # @return true, false if the term is completly before the passed date
    def before?(date)
      return false if finish.nil?
      finish < date.to_date
    end

    # Determine if the term is completly after the passed date
    # @param date [Date]
    # @return true, false if the term is completly after the passed date
    def after?(date)
      return false if start.nil?
      start > date.to_date
    end

    # Determine if the term is in the future
    # @return true, false if the term starts after today
    def future?
      return false if start.nil?
      start > Date.today
    end

    # Determine if the term is in the past
    # @return true, false if the term finished before today
    def past?
      return false if finish.nil?
      finish < Date.today
    end

    # Determine if the term is current
    # @return true, false if the term started before today and finishes after today
    def current?
      return false if start.nil?
      return false if finish.nil?
      (start <= Date.today) && (finish >= Date.today)
    end

    # Determine if the provided date is within the term
    # @param date [Date] The date to test
    # @return true, false if the term started before the date and finishes after the date
    def contains_date?(date)
      return false if start.nil?
      return false if finish.nil?
      (start <= date) && (finish >= date)
    end

    private def sort_by
      ['section_id', 'start', 'id']
    end

  end # Class Term

end # Module
