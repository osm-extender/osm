module Osm

  class Section
    class FlexiRecord; end # Ensure the constant exists for the validators

    include ::ActiveAttr::MassAssignmentSecurity
    include ::ActiveAttr::Model

    # @!attribute [rw] id
    #   @return [Fixnum] the id for the section
    # @!attribute [rw] name
    #   @return [String] the section name
    # @!attribute [rw] subscription_level
    #   @return [Symbol] what subscription the section has to OSM (:bronze, :silver or :gold)
    # @!attribute [rw] subscription_expires
    #   @return [Date] when the section's subscription to OSM expires
    # @!attribute [rw] type
    #   @return [Symbol] the section type (:beavers, :cubs, :scouts, :exporers, :adults, :waiting, :unknown)
    # @!attribute [rw] num_scouts
    #   @return [Fixnum] how many members the section has
    # @!attribute [rw] column_names
    #   @return [Hash] custom names to use for the data columns
    # @!attribute [rw] fields
    #   @return [Hash] which columns are shown in OSM
    # @!attribute [rw] intouch_fields
    #   @return [Hash] which columns are shown in OSM's in touch reports
    # @!attribute [rw] mobile_fields
    #   @return [Hash] which columns are shown in the OSM mobile app
    # @!attribute [rw] flexi_records
    #   @return [Array<FlexiRecord>] list of the extra records the section has
    # @!attribute [rw] role
    #   @return [Osm::Role] the role linking the user to this section

    attribute :id, :type => Integer
    attribute :name, :type => String
    attribute :subscription_level, :default => :unknown
    attribute :subscription_expires, :type => Date
    attribute :type, :default => :unknown
    attribute :num_scouts, :type => Integer
    attribute :column_names, :default => {}
    attribute :fields, :default => {}
    attribute :intouch_fields, :default => {}
    attribute :mobile_fields, :default => {}
    attribute :flexi_records, :default => []
    attribute :role

    attr_accessible :id, :name, :subscription_level, :subscription_expires, :type, :num_scouts, :column_names, :fields, :intouch_fields, :mobile_fields, :flexi_records, :role

    validates_numericality_of :id, :only_integer=>true, :greater_than=>0, :allow_nil => true
    validates_numericality_of :num_scouts, :only_integer=>true, :greater_than_or_equal_to=>0
    validates_presence_of :subscription_level
    validates_presence_of :subscription_expires
    validates_presence_of :type
    validates_presence_of :column_names, :unless => Proc.new { |a| a.column_names == {} }
    validates_presence_of :fields, :unless => Proc.new { |a| a.fields == {} }
    validates_presence_of :intouch_fields, :unless => Proc.new { |a| a.intouch_fields == {} }
    validates_presence_of :mobile_fields, :unless => Proc.new { |a| a.mobile_fields == {} }
    validates_presence_of :flexi_records, :unless => Proc.new { |a| a.flexi_records == [] }
    validates_presence_of :role

    validates_inclusion_of :subscription_level, :in => [:bronze, :silver, :gold, :unknown], :message => 'is not a valid level'

    validates :column_names, :hash => {:key_type => Symbol, :value_type => String}
    validates :fields, :hash => {:key_type => Symbol, :value_type => String}
    validates :intouch_fields, :hash => {:key_type => Symbol, :value_type => String}
    validates :mobile_fields, :hash => {:key_type => Symbol, :value_type => String}


    # @!method initialize
    #   Initialize a new Section
    #   @param [Hash] attributes the hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)


    # Initialize a new Sections from api data
    # @param [Fixnum] id the section ID used by the API to refer to this section
    # @param [String] name the name given to the sction in OSM
    # @param [Hash] data the hash of data for the object returned by the API
    # @param [Osm::Role] role the Osm::Role linked with this section
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
      fr = []
      fr = data['extraRecords'] if data['extraRecords'].is_a?(Array)
      fr = data['extraRecords'].values if data['extraRecords'].is_a?(Hash)
      fr.each do |record_data|
        attributes[:flexi_records].push FlexiRecord.from_api(record_data)
      end

      new(attributes)
    end

    # Check if this section is one of the youth sections
    # @return [Boolean]
    def youth_section?
      [:beavers, :cubs, :scouts, :explorers].include?(type)
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
        type == attribute
      end
    end

    def <=>(another_section)
      begin
        return self.role <=> another_section.role
      rescue NoMethodError
        return false
      end
    end

    def ==(another_section)
      begin
        return self.id == another_section.id
      rescue NoMethodError
        return false
      end
    end
    
    def inspect
      attribute_descriptions = attributes.merge('role' => (role.nil? ? nil : role.inspect_without_section(self)))
      return_inspect(attribute_descriptions)
    end

    def inspect_without_role(exclude_role)
      attribute_descriptions = (role == exclude_role) ? attributes.merge('role' => 'SET') : attributes
      return_inspect(attribute_descriptions)
    end


    private
    def return_inspect(attribute_descriptions)
      attribute_descriptions.sort.map { |key, value| "#{key}: #{key.eql?('role') ? value : value.inspect}" }.join(", ")
      separator = " " unless attribute_descriptions.empty?
      "#<#{self.class.name}#{separator}#{attribute_descriptions}>"
    end

    class FlexiRecord
      include ::ActiveAttr::MassAssignmentSecurity
      include ::ActiveAttr::Model

      # @!attribute [rw] id
      #   @return [Fixnum] the aid of the flexi-record
      # @!attribute [rw] name
      #   @return [String] the name given to the flexi-record

      attribute :id, :type => Integer
      attribute :name, :type => String

      attr_accessible :id, :name

      validates_numericality_of :id, :only_integer=>true, :greater_than=>0
      validates_presence_of :name


      # @!method initialize
      #   Initialize a new FlexiRecord
      #   @param [Hash] attributes the hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)


      # Initialize a new FlexiRecord from api data
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
    end # Class Section::FlexiRecord

  end # Class Section

end # Module
