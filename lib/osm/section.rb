module Osm

  class Section

    attr_reader :id, :name, :subscription_level, :subscription_expires, :type, :num_scouts, :column_names, :fields, :intouch_fields, :mobile_fields, :flexi_records, :role
    # @!attribute [r] id
    #   @return [Fixnum] the id for the section
    # @!attribute [r] name
    #   @return [String] the section name
    # @!attribute [r] subscription_level
    #   @return [Symbol] what subscription the section has to OSM (:bronze, :silver or :gold)
    # @!attribute [r] subscription_expires
    #   @return [Date] when the section's subscription to OSM expires
    # @!attribute [r] type
    #   @return [Symbol] the section type (:beavers, :cubs, :scouts, :exporers, :adults, :waiting, :unknown)
    # @!attribute [r] num_scouts
    #   @return [Fixnum] how many members the section has
    # @!attribute [r] column_names
    #   @return [Hash] custom names to use for the data columns
    # @!attribute [r] fields
    #   @return [Hash] which columns are shown in OSM
    # @!attribute [r] intouch_fields
    #   @return [Hash] which columns are shown in OSM's in touch reports
    # @!attribute [r] mobile_fields
    #   @return [Hash] which columns are shown in the OSM mobile app
    # @!attribute [r] flexi_records
    #   @return [Array<FlexiRecord>] list of the extra records the section has
    # @!attribute [r] role
    #   @return [Osm::Role] the role linking the user to this section


    # Initialize a new Section
    # @param [Hash] attributes the hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)
    def initialize(attributes={})
      raise ArgumentError, ':id must be nil or a Fixnum > 0' unless attributes[:id].nil? || (attributes[:id].is_a?(Fixnum) && attributes[:id] > 0)
      raise ArgumentError, ':section_name must be nil or a String' unless attributes[:section_name].nil? || attributes[:section_name].is_a?(String)
      raise ArgumentError, ':num_scouts must be nil or a Fixnum >= 0' unless attributes[:num_scouts].nil? || (attributes[:num_scouts].is_a?(Fixnum) && attributes[:num_scouts] > 0)
      [:column_names, :fields, :intouch_fields, :mobile_fields].each do |attribute|
        raise ArgumentError, ":#{attribute} must be nil or a Hash" unless attributes[attribute].nil? || attributes[attribute].is_a?(Hash)
      end
      [:type, :subscription_level].each do |attribute|
        raise ArgumentError, ":#{attribute} must be nil or a Symbol" unless attributes[attribute].nil? || attributes[attribute].is_a?(Symbol)
      end
      raise ArgumentError, ':flexi_records must be nil or an Array' unless attributes[:flexi_records].nil? || attributes[:flexi_records].is_a?(Array)

      attributes.each { |k,v| instance_variable_set("@#{k}", v) }

      @section_name ||= ''
      @column_names ||= {}
      @fields ||= {}
      @intouch_fields ||= {}
      @mobile_fields ||= {}
      @flexi_records ||= []
      @subscription_level ||= :unknown
      @type ||= :unknown
    end


    # Initialize a new Sections from api data
    # @param [Fixnum] id the section ID used by the API to refer to this section
    # @param [String] name the name given to the sction in OSM
    # @param [Hash] data the hash of data for the object returned by the API
    # @param {Osm::Role] role the Osm::Role linked with this section
    def self.from_api(id, name, data, role)
      subscription_levels = [:bronze, :silver, :gold]
      subscription_level = data['subscription_level'].to_i - 1

      attributes = {
        :id => Osm::to_i_or_nil(id),
        :name => name,
        :subscription_level => (subscription_levels[subscription_level] unless subscription_level < 0) || :unknown,
        :subscription_expires => data['subscription_expires'] ? Date.parse(data['subscription_expires'], 'yyyy-mm-dd') : nil,
        :type => !data['sectionType'].nil? ? data['sectionType'].to_sym : :unknown,
        :num_scouts => data['numscouts'],
        :column_names => data['columnNames'].is_a?(Hash) ? Osm::symbolize_hash(data['columnNames']) : {},
        :fields => data['fields'].is_a?(Hash) ? Osm::symbolize_hash(data['fields']) : {},
        :intouch_fields => data['intouch'].is_a?(Hash) ? Osm::symbolize_hash(data['intouch']) : {},
        :mobile_fields => data['mobFields'].is_a?(Hash) ? Osm::symbolize_hash(data['mobFields']) : {},
        :role => role,
        :flexi_records => [],
      }


      # Populate arrays
      (data['extraRecords'].is_a?(Array) ? data['extraRecords'] : []).each do |record_data|
        attributes[:flexi_records].push FlexiRecord.from_api(record_data)
      end
      attributes[:flexi_records].freeze

      new(attributes)
    end

    # Check if this section is one of the youth sections
    # @return [Boolean]
    def youth_section?
      [:beavers, :cubs, :scouts, :explorers].include?(@type)
    end

    # Custom section type checkers
    # @!method beavers?
    #   Check if this is a Beavers section
    #   @return (Boolean)
    # @!method cubs?
    #   Check if this is a Cubs section
    #   @return (Boolean)
    # @!method scouts?
    #   Check if this is a Scouts section
    #   @return (Boolean)
    # @!method explorers?
    #   Check if this is an Explorers section
    #   @return (Boolean)
    # @!method adults?
    #   Check if this is an Adults section
    #   @return (Boolean)
    # @!method waiting?
    #   Check if this is a waiting list
    #   @return (Boolean)
    [:beavers, :cubs, :scouts, :explorers, :adults, :waiting].each do |attribute|
      define_method "#{attribute}?" do
        @type == attribute
      end
    end

    def <=>(another_section)
      self.role <=> another_section.try(:role)
    end

    def ==(another_section)
      self.id == another_section.try(:id)
    end



    private
    class FlexiRecord

      attr_reader :id, :name
      # @!attribute [r] id
      #   @return [Fixnum] the aid of the flexi-record
      # @!attribute [r] name
      #   @return [String] the name given to the flexi-record
  
      # Initialize a new ApiAccess
      # @param [Hash] attributes the hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)
      def initialize(attributes={})
        raise ArgumentError, ':id must be a Fixnum > 0' unless (attributes[:id].is_a?(Fixnum) && attributes[:id] > 0)
        raise ArgumentError, ':name must be a String' unless attributes[:name].is_a?(String)
  
        attributes.each { |k,v| instance_variable_set("@#{k}", v) }
      end
  
  
      # Initialize a new ApiAccess from api data
      # @param [Hash] data the hash of data provided by the API
      def self.from_api(data)
        # Expect item to be: {:name=>String, :extraid=>Fixnum}
        # Sometimes get item as: [String, {"name"=>String, "extraid"=>Fixnum}]
        data = data[1] if data.is_a?(Array)

        new({
          :id => Osm::to_i_or_nil(data['extraid']),
          :name => data['name'],
        })
      end
    end # FlexiRecord

  end # Section

end # Module
