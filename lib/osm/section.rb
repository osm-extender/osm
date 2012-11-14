module Osm

  class Section < Osm::Model
    class FlexiRecord; end # Ensure the constant exists for the validators

    # @!attribute [rw] id
    #   @return [Fixnum] the id for the section
    # @!attribute [rw] name
    #   @return [String] the section name
    # @!attribute [rw] group_id
    #   @return [Fixnum] the id for the group
    # @!attribute [rw] group_name
    #   @return [String] the group name
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

    attribute :id, :type => Integer
    attribute :name, :type => String
    attribute :group_id, :type => Integer
    attribute :group_name, :type => String
    attribute :subscription_level, :default => :unknown
    attribute :subscription_expires, :type => Date
    attribute :type, :default => :unknown
    attribute :num_scouts, :type => Integer
    attribute :column_names, :default => {}
    attribute :fields, :default => {}
    attribute :intouch_fields, :default => {}
    attribute :mobile_fields, :default => {}
    attribute :flexi_records, :default => []

    attr_accessible :id, :name, :group_id, :group_name, :subscription_level, :subscription_expires, :type,
                    :num_scouts, :column_names, :fields, :intouch_fields, :mobile_fields, :flexi_records

    validates_numericality_of :id, :only_integer=>true, :greater_than=>0, :allow_nil => true
    validates_numericality_of :group_id, :only_integer=>true, :greater_than=>0, :allow_nil => true
    validates_numericality_of :num_scouts, :only_integer=>true, :greater_than_or_equal_to=>0
    validates_presence_of :name
    validates_presence_of :group_name
    validates_presence_of :subscription_level
    validates_presence_of :subscription_expires
    validates_presence_of :type
    validates_presence_of :column_names, :unless => Proc.new { |a| a.column_names == {} }
    validates_presence_of :fields, :unless => Proc.new { |a| a.fields == {} }
    validates_presence_of :intouch_fields, :unless => Proc.new { |a| a.intouch_fields == {} }
    validates_presence_of :mobile_fields, :unless => Proc.new { |a| a.mobile_fields == {} }
    validates_presence_of :flexi_records, :unless => Proc.new { |a| a.flexi_records == [] }

    validates_inclusion_of :subscription_level, :in => [:bronze, :silver, :gold, :unknown], :message => 'is not a valid level'

    validates :column_names, :hash => {:key_type => Symbol, :value_type => String}
    validates :fields, :hash => {:key_type => Symbol, :value_in => [true, false]}
    validates :intouch_fields, :hash => {:key_type => Symbol, :value_in => [true, false]}
    validates :mobile_fields, :hash => {:key_type => Symbol, :value_in => [true, false]}


    # @!method initialize
    #   Initialize a new Section
    #   @param [Hash] attributes the hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)


    # Get the user's sections
    # @param [Osm::Api] The api to use to make the request
    # @!macro options_get
    # @return [Array<Osm::Section>]
    def self.get_all(api, options={})
      cache_key = ['sections', api.user_id]
      subscription_levels = {
        1 => :bronze,
        2 => :silver,
        3 => :gold,
      }

      if !options[:no_cache] && cache_exist?(api, cache_key)
        return cache_read(api, cache_key)
      end

      data = api.perform_query('api.php?action=getUserRoles')

      result = Array.new
      permissions = Hash.new
      data.each do |role_data|
        unless role_data['section'].eql?('discount')  # It's not an actual section
          section_data = ActiveSupport::JSON.decode(role_data['sectionConfig'])

          # Make sense of flexi records
          fr_data = []
          flexi_records = []
          fr_data = section_data['extraRecords'] if section_data['extraRecords'].is_a?(Array)
          fr_data = section_data['extraRecords'].values if section_data['extraRecords'].is_a?(Hash)
          fr_data.each do |record_data|
            # Expect item to be: {:name=>String, :extraid=>Fixnum}
            # Sometimes get item as: [String, {"name"=>String, "extraid"=>Fixnum}]
            record_data = record_data[1] if record_data.is_a?(Array)
            flexi_records.push FlexiRecord.new(
              :id => Osm::to_i_or_nil(record_data['extraid']),
              :name => record_data['name'],
            )
          end

          section = new(
            :id => Osm::to_i_or_nil(role_data['sectionid']),
            :name => role_data['sectionname'],
            :subscription_level => (subscription_levels[section_data['subscription_level']] || :unknown),
            :subscription_expires => Osm::parse_date(section_data['subscription_expires']),
            :type => !section_data['sectionType'].nil? ? section_data['sectionType'].to_sym : (!section_data['section'].nil? ? section_data['section'].to_sym : :unknown),
            :num_scouts => section_data['numscouts'],
            :column_names => section_data['columnNames'].is_a?(Hash) ? Osm::symbolize_hash(section_data['columnNames']) : {},
            :fields => section_data['fields'].is_a?(Hash) ? Osm::symbolize_hash(section_data['fields']) : {},
            :intouch_fields => section_data['intouch'].is_a?(Hash) ? Osm::symbolize_hash(section_data['intouch']) : {},
            :mobile_fields => section_data['mobFields'].is_a?(Hash) ? Osm::symbolize_hash(section_data['mobFields']) : {},
            :flexi_records => flexi_records.sort,
            :group_id => role_data['groupid'],
            :group_name => role_data['groupname'],
          )

          result.push section
          cache_write(api, ['section', section.id], section)
          permissions.merge!(section.id => make_permissions_hash(role_data['permissions']))
        end
      end

      set_user_permissions(api, get_user_permissions(api).merge(permissions))
      cache_write(api, cache_key, result)
      return result
    end


    # Get a section
    # @param [Osm::Api] The api to use to make the request
    # @param [Fixnum] section_id the section id of the required section
    # @!macro options_get
    # @return nil if an error occured or the user does not have access to that section
    # @return [Osm::Section]
    def self.get(api, section_id, options={})
      cache_key = ['section', section_id]

      if !options[:no_cache] && cache_exist?(api, cache_key) && get_user_permissions(api).keys.include?(section_id)
        return cache_read(api, cache_key)
      end

      sections = get_all(api, options)
      return nil unless sections.is_a? Array

      sections.each do |section|
        return section if section.id == section_id
      end
      return nil
    end


    # Get API user's permissions
    # @param [Osm::Api] The api to use to make the request
    # @!macro options_get
    # @return nil if an error occured or the user does not have access to that section
    # @return [Hash] {section_id => permissions_hash}
    def self.fetch_user_permissions(api, options={})
      cache_key = ['permissions', api.user_id]

      if !options[:no_cache] && cache_exist?(api, cache_key)
        return cache_read(api, cache_key)
      end

      data = api.perform_query('api.php?action=getUserRoles')

      all_permissions = Hash.new
      data.each do |item|
        unless item['section'].eql?('discount')  # It's not an actual section
          all_permissions.merge!(Osm::to_i_or_nil(item['sectionid']) => make_permissions_hash(item['permissions']))
        end
      end
      cache_write(api, cache_key, all_permissions)
      return all_permissions
    end


    # Get the section's notepads
    # @param [Osm::Api] The api to use to make the request
    # @!macro options_get
    # @return [String] the section's notepad
    def get_notepad(api, options={})
      cache_key = ['notepad', id]

      if !options[:no_cache] && cache_exist?(api, cache_key) && get_user_permissions(api).keys.include?(section_id)
        return cache_read(api, cache_key)
      end

      notepads = api.perform_query('api.php?action=getNotepads')
      return '' unless notepads.is_a?(Hash)

      notepad = ''
      notepads.each do |key, value|
        cache_write(api, ['notepad', key.to_i], value)
        notepad = value if key.to_i == id
      end

      return notepad
    end

    # Get badge stock levels
    # @param [Osm::Api] The api to use to make the request
    # @param [Osm::Term, Fixnum, nil] section the term (or its ID) to get the stock levels for, passing nil causes the current term to be used
    # @!macro options_get
    # @return Hash
    def get_badge_stock(api, term=nil, options={})
      term_id = term.nil? ? Osm::Term.get_current_term_for_section(api, self).id : term.to_i
      cache_key = ['badge_stock', id, term_id]

      if !options[:no_cache] && cache_exist?(api, cache_key) && get_user_permission(api, self, :badge).include?(:read)
        return cache_read(api, cache_key)
      end

      data = api.perform_query("challenges.php?action=getInitialBadges&type=core&sectionid=#{id}&section=#{type}&termid=#{term_id}")
      data = (data['stock'] || {}).select{ |k,v| !k.eql?('sectionid') }.
                                   inject({}){ |new_hash,(badge, level)| new_hash[badge] = level.to_i; new_hash }

      cache_write(api, cache_key, data)
      return data
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

    def <=>(another)
      begin
        compare_group_name = group_name <=> another.group_name
        return compare_group_name unless compare_group_name == 0
  
        return 0 if type == another.type
        [:beavers, :cubs, :scouts, :explorers, :waiting, :adults].each do |type|
          return -1 if type == type
          return 1 if another.type == type
        end
      rescue NoMethodError
        return 1
      end
    end

    def ==(another)
      begin
        return self.id == another.id
      rescue NoMethodError
        return false
      end
    end


    private
    def self.make_permissions_hash(permissions)
      return {} unless permissions.is_a?(Hash)

      permissions_map = {
        10  => [:read],
        20  => [:read, :write],
        100 => [:read, :write, :administer],
      }

      return permissions.inject({}) do |new_hash, (key, value)|
        new_hash[key.to_sym] = (permissions_map[value.to_i] || [])
        new_hash
      end
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

      def <=>(another)
        begin
          return self.name <=> another.name
        rescue NoMethodError
          return 1
        end
      end

    end # Class Section::FlexiRecord

  end # Class Section

end # Module
