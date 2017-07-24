module OSM

  class Term < OSM::Model
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
    # @param api [OSM::Api] The api to use to make the request
    # @!macro options_get
    # @return [Array<OSM::Term>]
    def self.get_all(api, no_read_cache: false)
      cache_key = ['terms', api.user_id]

      cache_fetch(api: api, key: cache_key, no_read_cache: no_read_cache) do
        data = api.post_query('api.php?action=getTerms')
        # data is of the form {"section_id_1" => [[term_data_1],[term_data_2], "section_id_3" => [term_data_3]}}
        data.values.flatten.map do |term_data|
          OSM::Term.new(
            id: term_data.fetch('termid').to_i,
            section_id: term_data.fetch('sectionid').to_i,
            name: term_data['name'],
            start: OSM.parse_date(term_data['startdate']),
            finish: OSM.parse_date(term_data['enddate'])
          )
        end
      end # cache_fetch
    end

    # Get the terms that the OSM user can access for a given section
    # @param api [OSM::Api] The api to use to make the request
    # @param section [Integer] The section (or its ID) of the section to get terms for
    # @!macro options_get
    # @return [Array<OSM::Term>, nil] An array of terms or nil if the user can not access that section
    def self.get_for_section(section:, api:, **options)
      section_id = section.to_i
      get_all(api, **options).select { |term| term.section_id == section_id }
    end

    # Get a term
    # @param api [OSM::Api] The api to use to make the request
    # @param id [Integer] The id of the required term
    # @!macro options_get
    # @return nil if an error occured or the user does not have access to that term
    # @return [OSM::Term]
    def self.get(id:, api:, **options)
      term_id = id.to_i
      get_all(api, **options).find { |term| term.id == term_id }
    end

    # Get the current term for a given section
    # @param api [OSM::Api] The api to use to make the request
    # @param section [OSM::Section, Integer, #to_i] The section (or its ID)  to get terms for
    # @!macro options_get
    # @return [OSM::Term, nil] The current term or nil if the user can not access that section
    # @raise [OSM::Error::NoCurrentTerm] If the Section doesn't have a Term which is current
    def self.get_current_term_for_section(api:, section:, no_read_cache: false)
      terms = get_for_section(api: api, section: section, no_read_cache: no_read_cache)
      return nil if terms.nil?
      terms.each do |term|
        return term if term.current?
      end

      fail OSM::OSMError::NoCurrentTerm.new('There is no current term for the section.', section)
    end

    # Create a term in OSM
    # @param api [OSM::Api] The api to use to make the request
    # @param section [OSM::Section, Integer] (required) section or section_id to add the term to
    # @param name [String] (required) the name for the term
    # @param start [Date, #strftime] (required) the date for the start of term
    # @param finish [Date, #strftime] (required) the date for the finish of term
    # @return true, false if the operation suceeded or not
    def self.create(api:, section:, name:, start:, finish:)
      require_access_to_section(api: api, section: section)

      data = api.post_query("users.php?action=addTerm&sectionid=#{section.to_i}", post_data: {
        'term' => name,
        'start' => start.strftime(OSM::OSM_DATE_FORMAT),
        'end' => finish.strftime(OSM::OSM_DATE_FORMAT),
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
    # @param api [OSM::Api] The api to use to make the request
    # @return true, false if the operation suceeded or not
    # @raise [OSM::ObjectIsInvalid] If the Term is invalid
    def update(api)
      fail OSM::Error::InvalidObject, 'term is invalid' unless valid?
      require_access_to_section(api: api, section: section_id)

      data = api.post_query("users.php?action=addTerm&sectionid=#{section_id}", post_data: {
        'term' => name,
        'start' => start.strftime(OSM::OSM_DATE_FORMAT),
        'end' => finish.strftime(OSM::OSM_DATE_FORMAT),
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
