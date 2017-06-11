module Osm
  class FlexiRecord < Osm::Model
    class Column < Osm::Model
      # @!attribute [rw] flexi_record
      #   @return true, false The FlexiRecord this column belongs to
      # @!attribute [rw] id
      #   @return [String] OSM identifier for the field. Special ones are 'dob', 'total', 'completed', 'age', 'firstname' and 'lastname', user ones are of the format 'f\_NUMBER'
      # @!attribute [rw] name
      #   @return [String] Human readable name for the field
      # @!attribute [rw] editable
      #   @return true, false Wether the field can be edited

      attribute :flexi_record, type: Object
      attribute :id, type: String
      attribute :name, type: String
      attribute :editable, type: Boolean, default: false

      validates_presence_of :flexi_record
      validates_presence_of :id
      validates_presence_of :name
      validates_inclusion_of :editable, in: [true, false]

      # @!method initialize
      #   Initialize a new FlexiRecord::Column
      #   @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)


      # Update a column in OSM
      # @param api [Osm::Api] The api to use to make the request
      # @return true, false whether the column was updated in OSM
      # @raise [Osm::ObjectIsInvalid] If the Column is invalid
      # @raise [Osm::Forbidden] If the COlumn is not editable
      def update(api)
        fail Osm::ObjectIsInvalid, 'column is invalid' unless valid?
        require_ability_to(api: api, to: :write, on: :flexi, section: flexi_record.section_id)
        fail Osm::Forbidden, 'this column is not editable' unless editable

        data = api.post_query("extras.php?action=renameColumn&sectionid=#{flexi_record.section_id}&extraid=#{flexi_record.id}", post_data: {
          'columnId' => id,
          'columnName' => name
        })

        if data.is_a?(Hash) && data.key?('config')
          JSON.parse(data['config']).each do |f|
            next unless (f['id'] == id) && (f['name'] == name)
            reset_changed_attributes
            # The cached columns for the flexi record will be out of date - remove them
            cache_delete(api: api, key: ['flexi_record_columns', flexi_record.id])
            return true
          end
        end
        false
      end

      # Delete a column in OSM
      # @param api [Osm::Api] The api to use to make the request
      # @return true, false whether the column was deleted from OSM
      # @raise [Osm::Forbidden] If this Column is not editable
      def delete(api)
        require_ability_to(api: api, to: :write, on: :flexi, section: flexi_record.section_id)
        fail Osm::Forbidden, 'this column is not editable' unless editable

        data = api.post_query("extras.php?action=deleteColumn&sectionid=#{flexi_record.section_id}&extraid=#{flexi_record.id}", post_data: {
          'columnId' => id
        })

        if data.is_a?(Hash) && data.key?('config')
          JSON.parse(data['config']).each do |f|
            if f['id'] == id
              # It wasn't deleted
              return false
            end
          end
        end

        # The cached columns for the flexi record will be out of date - remove them
        cache_delete(api: api, key: ['flexi_record_columns', flexi_record.id])
        true
      end

      # Is this column a user column
      # @return [true, false]
      def user_column?
        id.match(/\Af_\d+\Z/)
      end

      # Is this column a system column
      # @return [true, false]
      def system_column?
        !user_column?
      end

      # Compare Column based on flexi_record then id
      def <=>(other)
        result = flexi_record <=> other.try(:flexi_record)
        if result.zero?
          return 1 if user_column? && other.try(:system_column?)
          return -1 if system_column? && other.try(:user_column?)
          return id <=> other.try(:id)
        end
        result
      end

      def inspect
        Osm.inspect_instance(self, options = { replace_with: { 'flexi_record' => :id } })
      end

    end
  end
end
