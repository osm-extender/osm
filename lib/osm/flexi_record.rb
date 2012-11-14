module Osm

  class FlexiRecord

    # Get structure for a flexi record
    # @param [Osm::Api] api The api to use to make the request
    # @param [Osm::Section, Fixnum] section the section (or its ID) to get the structure for
    # @param [Fixnum] the id of the Flexi Record
    # @!macro options_get
    # @return [Array<Osm::FlexiRecordField>] representing the fields of the flexi record
    def self.get_fields(api, section, id, options={})
      section_id = section.to_i
      cache_key = ['flexi_record_fields', id]

      if !options[:no_cache] && Osm::Model.cache_exist?(api, cache_key) && Osm::Model.get_user_permission(api, section_id, :flexi).include?(:read)
        return Osm::Model.cache_read(api, cache_key)
      end

      data = api.perform_query("extras.php?action=getExtra&sectionid=#{section_id}&extraid=#{id}")

      structure = []
      data['structure'].each do |item|
        item['rows'].each do |row|
          structure.push Osm::FlexiRecord::Field.new(
            :id => row['field'],
            :name => row['name'],
            :editable => row['editable'] || false,
          )
        end
      end
      Osm::Model.cache_write(api, cache_key, structure)

      return structure
    end

    # Get data for flexi record
    # @param [Osm::Api] api The api to use to make the request
    # @param [Osm::Section, Fixnum] section the section (or its ID) to get the register for
    # @param [Fixnum] the id of the Flexi Record
    # @param [Osm::Term, Fixnum, nil] section the term (or its ID) to get the register for, passing nil causes the current term to be used
    # @!macro options_get
    # @return [Array<FlexiRecordData>]
    def self.get_data(api, section, id, term=nil, options={})
      section = Osm::Section.get(api, section) if section.is_a?(Fixnum)
      term_id = term.nil? ? Osm::Term.get_current_term_for_section(api, section).id : term.to_i
      cache_key = ['flexi_record_data', id, term_id]

      if !options[:no_cache] && Osm::Model.cache_exist?(api, cache_key) && Osm::Model.get_user_permission(api, section.id, :flexi).include?(:read)
        return Osm::Model.cache_read(api, cache_key)
      end

      data = api.perform_query("extras.php?action=getExtraRecords&sectionid=#{section.id}&extraid=#{id}&termid=#{term_id}&section=#{section.type}")

      to_return = []
      data['items'].each do |item|
        unless item['scoutid'].to_i < 0  # It's a total row
          fields = item.select { |key, value|
            ['firstname', 'lastname', 'dob', 'total', 'completed', 'age'].include?(key) || key.to_s.match(/\Af_\d+\Z/)
          }
          fields.merge!(
            'dob' => item['dob'].empty? ? nil : item['dob'],
            'total' => item['total'].empty? ? nil : item['total'],
            'completed' => item['completed'].empty? ? nil : item['completed'],
            'age' => item['age'].empty? ? nil : item['age'],
          )
  
          to_return.push Osm::FlexiRecord::Data.new(
            :member_id => Osm::to_i_or_nil(item['scoutid']),
            :grouping_id => Osm::to_i_or_nil(item['patrolid'].eql?('') ? nil : item['patrolid']),
            :fields => fields
          )
        end
      end

      Osm::Model.cache_write(api, cache_key, to_return)
      return to_return
    end




    class Field < Osm::Model
      # @!attribute [rw] id
      #   @return [String] OSM identifier for the field. Special ones are 'dob', 'total', 'completed', 'age', 'firstname' and 'lastname', user ones are of the format 'f\_NUMBER'
      # @!attribute [rw] name
      #   @return [String] Human readable name for the field
      # @!attribute [rw] editable
      #   @return [Boolean] Wether the field can be edited

      attribute :id, :type => String
      attribute :name, :type => String
      attribute :editable, :type => Boolean, :default => false

      attr_accessible :id, :name, :editable

      validates_presence_of :id
      validates_presence_of :name
      validates_inclusion_of :editable, :in => [true, false]

      # @!method initialize
      #   Initialize a new FlexiRecordField
      #   @param [Hash] attributes the hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)

    end # Class FlexiRecord::Data


    class Data < Osm::Model
      # @!attribute [rw] member_id
      #   @return [Fixnum] OSM id for the member
      # @!attribute [rw] grouping__id
      #   @return [Fixnum] OSM id for the grouping the member is in
      # @!attribute [rw] fields
      #   @return [Hash] Keys are the field's id, values are the field values

      attribute :member_id, :type => Integer
      attribute :grouping_id, :type => Integer
      attribute :fields, :default => {}

      attr_accessible :member_id, :grouping_id, :fields

      validates_numericality_of :member_id, :only_integer=>true, :greater_than=>0
      validates_numericality_of :grouping_id, :only_integer=>true, :greater_than_or_equal_to=>-2
      validates :fields, :hash => {:key_type => String}

      # @!method initialize
      #   Initialize a new FlexiRecordData
      #   @param [Hash] attributes the hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)
  
    end # Class FlexiRecord::Data

  end # Class FlexiRecord
  
end # Module
