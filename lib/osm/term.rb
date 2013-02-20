module Osm

  class Term < Osm::Model

    # @!attribute [rw] id
    #   @return [Fixnum] the id for the term
    # @!attribute [rw] section_id
    #   @return [Fixnum] the section the term belongs to
    # @!attribute [rw] name
    #   @return [Fixnum] the name of the term
    # @!attribute [rw] start
    #   @return [Date] when the term starts
    # @!attribute [rw] finish
    #   @return [Date] when the term finishes

    attribute :id, :type => Integer
    attribute :section_id, :type => Integer
    attribute :name, :type => String
    attribute :start, :type => Date
    attribute :finish, :type => Date

    attr_accessible :id, :section_id, :name, :start, :finish

    validates_numericality_of :id, :only_integer=>true, :greater_than=>0
    validates_numericality_of :section_id, :only_integer=>true, :greater_than=>0
    validates_presence_of :name
    validates_presence_of :start
    validates_presence_of :finish


    # Get the terms that the OSM user can access
    # @param [Osm::Api] api The api to use to make the request
    # @!macro options_get
    # @return [Array<Osm::Term>]
    def self.get_all(api, options={})
      cache_key = ['terms', api.user_id]

      if !options[:no_cache] && cache_exist?(api, cache_key)
        ids = cache_read(api, cache_key)
        return get_from_ids(api, ids, 'term', options, :get_all)
      end

      data = api.perform_query('api.php?action=getTerms')

      terms = Array.new
      ids = Array.new
      data.each_key do |key|
        data[key].each do |term_data|
          term = Osm::Term.new(
            :id => Osm::to_i_or_nil(term_data['termid']),
            :section_id => Osm::to_i_or_nil(term_data['sectionid']),
            :name => term_data['name'],
            :start => Osm::parse_date(term_data['startdate']),
            :finish => Osm::parse_date(term_data['enddate']),
          )
          terms.push term
          ids.push term.id
          cache_write(api, ['term', term.id], term)
        end
      end

      cache_write(api, cache_key, ids)
      return terms
    end

    # Get the terms that the OSM user can access for a given section
    # @param [Osm::Api] api The api to use to make the request
    # @param [Fixnum] section The section (or its ID) of the section to get terms for
    # @!macro options_get
    # @return [Array<Osm::Term>, nil] An array of terms or nil if the user can not access that section
    def self.get_for_section(api, section, options={})
      require_access_to_section(api, section, options)
      section_id = section.to_i
      return get_all(api, options).select{ |term| term.section_id == section_id }
    end

    # Get a term
    # @param [Osm::Api] api The api to use to make the request
    # @param [Fixnum] term_id The id of the required term
    # @!macro options_get
    # @return nil if an error occured or the user does not have access to that term
    # @return [Osm::Term]
    def self.get(api, term_id, options={})
      cache_key = ['term', term_id]

      if !options[:no_cache] && cache_exist?(api, cache_key)
        term = cache_read(api, cache_key)
        return term if can_access_section?(api, term.section_id, options)
      end

      terms = get_all(api, options)
      return nil unless terms.is_a? Array

      terms.each do |term|
        if term.id == term_id
          return (can_access_section?(api, term.section_id, options) ? term : nil)
        end
      end
      return nil
    end

    # Get the current term for a given section
    # @param [Osm::Api] api The api to use to make the request
    # @param [Osm::Section, Fixnum, #to_i] section The section (or its ID)  to get terms for
    # @!macro options_get 
    # @return [Osm::Term, nil] The current term or nil if the user can not access that section
    # @raise [Osm::Error] If the term doesn't have a Term which is current
    def self.get_current_term_for_section(api, section, options={})
      section_id = section.to_i
      terms = get_for_section(api, section_id, options)

      return nil if terms.nil?
      terms.each do |term|
        return term if term.current?
      end

      raise Osm::Error, 'There is no current term for the section.'
    end

    # Create a term in OSM
    # @param [Osm::Api] api The api to use to make the request
    # @param [Hash] options - the configuration of the new term
    #   @option options [Osm::Section, Fixnum] :section (required) section or section_id to add the term to
    #   @option options [String] :name (required) the name for the term
    #   @option options [Date] :start (required) the date for the start of term
    #   @option options [Date] :finish (required) the date for the finish of term
    # @return [Boolean] if the operation suceeded or not
    def self.create(api, options={})
      raise ArgumentError, ":section can't be nil" if options[:section].nil?
      raise ArgumentError, ":name can't be nil" if options[:name].nil?
      raise ArgumentError, ":start can't be nil" if options[:start].nil?
      raise ArgumentError, ":finish can't be nil" if options[:finish].nil?
      require_access_to_section(api, options[:section])

      api_data = {
        'term' => options[:name],
        'start' => options[:start].strftime(Osm::OSM_DATE_FORMAT),
        'end' => options[:finish].strftime(Osm::OSM_DATE_FORMAT),
        'termid' => '0'
      }

      data = api.perform_query("users.php?action=addTerm&sectionid=#{options[:section].to_i}", api_data)

      # The cached terms for the section will be out of date - remove them
      get_all(api, options).each do |term|
        cache_delete(api, ['term', term.id]) if term.section_id == section_id
      end
      cache_delete(api, ['terms', api.user_id])

      return data.is_a?(Hash) && data['terms'].is_a?(Hash)
    end


    # Update a term in OSM
    # @param [Osm::Api] api The api to use to make the request
    # @return [Boolean] if the operation suceeded or not
    # @raise [Osm::ObjectIsInvalid] If the Term is invalid
    def update(api)
      raise Osm::ObjectIsInvalid, 'term is invalid' unless valid?
      require_access_to_section(api, section_id)

      data = api.perform_query("users.php?action=addTerm&sectionid=#{section_id}", {
        'term' => name,
        'start' => start.strftime(Osm::OSM_DATE_FORMAT),
        'end' => finish.strftime(Osm::OSM_DATE_FORMAT),
        'termid' => id
      })

      if data.is_a?(Hash) && data['terms'].is_a?(Hash)
        reset_changed_attributes
        # The cached term will be out of date - remove it
        cache_delete(api, ['term', id])
        return true
      else
        return false
      end
    end



    # @!method initialize
    #   Initialize a new Term
    #   @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)


    # Determine if the term is completly before the passed date
    # @param [Date] date
    # @return [Boolean] if the term is completly before the passed date
    def before?(date)
      return finish < date.to_date
    end

    # Determine if the term is completly after the passed date
    # @param [Date] date
    # @return [Boolean] if the term is completly after the passed date
    def after?(date)
      return start > date.to_date
    end

    # Determine if the term is in the future
    # @return [Boolean] if the term starts after today
    def future?
      return start > Date.today
    end

    # Determine if the term is in the past
    # @return [Boolean] if the term finished before today
    def past?
      return finish < Date.today
    end

    # Determine if the term is current
    # @return [Boolean] if the term started before today and finishes after today
    def current?
      return (start <= Date.today) && (finish >= Date.today)
    end

    # Determine if the provided date is within the term
    # @param [Date] date The date to test
    # @return [Boolean] if the term started before the date and finishes after the date
    def contains_date?(date)
      return (start <= date) && (finish >= date)
    end

    def <=>(another_term)
      begin
        compare = self.section_id <=> another_term.section_id
        return compare unless compare == 0
  
        compare = self.start <=> another_term.start
        return compare unless compare == 0
  
        return self.id <=> another_term.id
      rescue NoMethodError
        return 0
      end
    end

    def ==(another_term)
      begin
        return self.id == another_term.id
      rescue NoMethodError
        return false
      end
    end

  end # Class Term

end # Module
