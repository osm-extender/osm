module Osm

  class Section

    attr_reader :id, :name, :subscription_level, :subscription_expires, :type, :num_scouts, :column_names, :fields, :intouch_fields, :mobile_fields, :extra_records, :role
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
    # @!attribute [r] extraRecords
    #   @return [Array<hash>] list of the extra records the section has
    # @!attribute [r] role
    #   @return [Osm::Role] the role linking the user to this section


    # Initialize a new SectionConfig using the hash returned by the API call
    # @param id the section ID used by the API to refer to this section
    # @param name the name given to the sction in OSM
    # @param data the hash of data for the object returned by the API
    # @param role the Osm::Role linked with this section
    def initialize(id, name, data, role)
      subscription_levels = [:bronze, :silver, :gold]
      subscription_level = data['subscription_level'].to_i - 1

      @id = Osm::to_i_or_nil(id)
      @name = name
      @subscription_level = (subscription_levels[subscription_level] unless subscription_level < 0) || :unknown
      @subscription_expires = data['subscription_expires'] ? Date.parse(data['subscription_expires'], 'yyyy-mm-dd') : nil
      @type = !data['sectionType'].nil? ? data['sectionType'].to_sym : :unknown
      @num_scouts = data['numscouts']
      @column_names = data['columnNames'].is_a?(Hash) ? Osm::symbolize_hash(data['columnNames']) : {}
      @fields = data['fields'].is_a?(Hash) ? Osm::symbolize_hash(data['fields']) : {}
      @intouch_fields = data['intouch'].is_a?(Hash) ? Osm::symbolize_hash(data['intouch']) : {}
      @mobile_fields = data['mobFields'].is_a?(Hash) ? Osm::symbolize_hash(data['mobFields']) : {}
      @extra_records = data['extraRecords'].is_a?(Array) ? data['extraRecords'] : []
      @role = role

      # Symbolise the keys in each hash of the extra_records array
      @extra_records.each do |item|
        # Expect item to be: {:name=>String, :extraid=>Fixnum}
        # Sometimes get item as: [String, {"name"=>String, "extraid"=>Fixnum}]
        if item.is_a?(Array)
          item = Osm::symbolize_hash(item[1])
        else
          item = Osm::symbolize_hash(item)
        end
      end
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

  end

end
