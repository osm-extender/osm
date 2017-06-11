module Osm
  class FlexiRecord < Osm::Model
    class Data < Osm::Model
      # @!attribute [rw] flexi_record
      #   @return true, false The FlexiRecord this column belongs to
      # @!attribute [rw] member_id
      #   @return [Integer] OSM id for the member
      # @!attribute [rw] grouping__id
      #   @return [Integer] OSM id for the grouping the member is in
      # @!attribute [rw] fields
      #   @return [DirtyHashy] Keys are the field's id, values are the field values

      attribute :flexi_record, type: Object
      attribute :member_id, type: Integer
      attribute :grouping_id, type: Integer
      attribute :fields, default: {}

      validates_presence_of :flexi_record
      validates_numericality_of :member_id, only_integer: true, greater_than: 0
      validates_numericality_of :grouping_id, only_integer: true, greater_than_or_equal_to: -2
      validates :fields, hash: { key_type: String }


      # @!method initialize
      #   Initialize a new FlexiRecord::Data
      #   @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)
      # Override initialize to set @orig_attributes
      old_initialize = instance_method(:initialize)
      define_method :initialize do |*args|
        ret_val = old_initialize.bind(self).call(*args)
        self.fields = DirtyHashy.new(fields)
        fields.clean_up!
        return ret_val
      end


      # Update data in OSM
      # @param api [Osm::Api] The api to use to make the request
      # @return true, false whether the data was updated in OSM
      # @raise [Osm::ObjectIsInvalid] If the Data is invalid
      def update(api)
        fail Osm::ObjectIsInvalid, 'data is invalid' unless valid?
        require_ability_to(api: api, to: :write, on: :flexi, section: flexi_record.section_id)

        term_id = Osm::Term.get_current_term_for_section(api: api, section: flexi_record.section_id).id

        updated = true
        editable_fields = flexi_record.get_columns(api).select(&:editable).map(&:id)
        fields.changes.each do |field, (_was, now)|
          next unless editable_fields.include?(field)
          data = api.post_query('extras.php?action=updateScout', post_data: {
            'termid' => term_id,
            'scoutid' => member_id,
            'column' => field,
            'value' => now,
            'sectionid' => flexi_record.section_id,
            'extraid' => flexi_record.id
          })
          if (data.is_a?(Hash) && data['items'].is_a?(Array))
            data['items'].each do |item|
              if item['scoutid'] == member_id.to_s  # Find this member from the list of all members
                updated = false unless item[field] == now
              end
            end
          else
            updated = false
          end
        end

        if updated
          fields.clean_up!
          # The cached datas for the flexi record will be out of date - remove them
          cache_delete(api: api, key: ['flexi_record_data', flexi_record.id])
        end

        updated
      end

      def inspect
        Osm.inspect_instance(self, options = { replace_with: { 'flexi_record' => :id } })
      end

      private def sort_by
        ['flexi_record', 'grouping_id', 'member_id']
      end

    end
  end
end
