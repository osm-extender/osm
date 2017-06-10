module Osm
  class FlexiRecord < Osm::Model
    # @!attribute [rw] id
    #   @return [Integer] the id for the flexi_record
    # @!attribute [rw] section_id
    #   @return [Integer] the section the member belongs to
    # @!attribute [rw] name
    #   @return [String] the flexi record's name name

    attribute :id, type: Integer
    attribute :section_id, type: Integer
    attribute :name, type: String

    validates_numericality_of :id, only_integer: true, greater_than: 0, unless: Proc.new { |r| r.id.nil? }
    validates_numericality_of :section_id, only_integer: true, greater_than: 0
    validates_presence_of :name


    # Get structure for the flexi record
    # @param api [Osm::Api] The api to use to make the request
    # @!macro options_get
    # @return [Array<Osm::FlexiRecordColumn>] representing the columns of the flexi record
    def get_columns(api, no_read_cache: false)
      require_ability_to(api: api, to: :read, on: :flexi, section: section_id, no_read_cache: no_read_cache)
      cache_key = ['flexi_record_columns', self.id]

      Osm::Model.cache_fetch(api: api, key: cache_key, no_read_cache: no_read_cache) do
        data = api.post_query("extras.php?action=getExtra&sectionid=#{self.section_id}&extraid=#{self.id}")
        structure = []
        data['structure'].each do |item|
          item['rows'].each do |row|
            structure.push Osm::FlexiRecord::Column.new(
              id: row['field'],
              name: row['name'],
              editable: row['editable'] || false,
              flexi_record: self,
            )
          end
        end
        structure
      end # cache fetch
    end

    # Add a column in OSM
    # @param api [Osm::Api] The api to use to make the request
    # @param name [String] The name for the created column
    # @return true, false whether the column was created in OSM
    def add_column(api:, name:)
      require_ability_to(api: api, to: :write, on: :flexi, section: section_id)
      fail ArgumentError, 'name is invalid' if name.blank?

      data = api.post_query("extras.php?action=addColumn&sectionid=#{section_id}&extraid=#{id}", post_data: {
        'columnName' => name,
      })

      if (data.is_a?(Hash) && data.has_key?('config'))
        JSON.parse(data['config']).each do |field|
          if field['name'] == name
            # The cached fields for the flexi record will be out of date - remove them
            cache_delete(api: api, key: ['flexi_record_columns', id])
            return true
          end
        end
      end
      return false
    end

    # Get data for flexi record
    # @param api [Osm::Api] The api to use to make the request
    # @param term [Osm::Term, Integer, #to_i, nil] The term (or its ID) to get the register for, passing nil causes the current term to be used
    # @!macro options_get
    # @return [Array<FlexiRecordData>]
    def get_data(api:, term: nil, no_read_cache: false)
      require_ability_to(api: api, to: :read, on: :flexi, section: section_id, no_read_cache: no_read_cache)
      section = Osm::Section.get(api: api, id: self.section_id)
      term_id = term.nil? ? Osm::Term.get_current_term_for_section(api: api, section: section).id : term.to_i
      cache_key = ['flexi_record_data', id, term_id]

      Osm::Model.cache_fetch(api: api, key: cache_key, no_read_cache: no_read_cache) do
        data = api.post_query("extras.php?action=getExtraRecords&sectionid=#{section.id}&extraid=#{id}&termid=#{term_id}&section=#{section.type}")

        datas = []
        data['items'].each do |item|
          unless item['scoutid'].to_i < 0  # It's a total row
            fields = item.select { |key, value|
              ['firstname', 'lastname', 'dob', 'total', 'completed', 'age'].include?(key) || key.to_s.match(/\Af_\d+\Z/)
            }
            fields.merge!(
              'dob' => item['dob'].empty? ? nil : item['dob'],
              'total' => item['total'].to_s.empty? ? nil : item['total'],
              'completed' => item['completed'].to_s.empty? ? nil : item['completed'],
              'age' => item['age'].empty? ? nil : item['age'],
            )
  
            datas.push Osm::FlexiRecord::Data.new(
              member_id: Osm::to_i_or_nil(item['scoutid']),
              grouping_id: Osm::to_i_or_nil(item['patrolid'].eql?('') ? nil : item['patrolid']),
              fields: fields,
              flexi_record: self,
            )
          end # unless a total row
        end # each item in data
        datas
      end # cache fetch
    end


    private
    def sort_by
      ['section_id', 'name']
    end

  end
end
