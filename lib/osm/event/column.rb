module Osm
  class Event < Osm::Model
    class Column < Osm::Model
      # @!attribute [rw] id
      #   @return [String] OSM id for the column
      # @!attribute [rw] name
      #   @return [String] name for the column (displayed in OSM)
      # @!attribute [rw] label
      #   @return [String] label to display in My.SCOUT ("" prevents display in My.SCOUT)
      # @!attribute [rw] parent_required
      #   @return true, false whether the parent is required to enter something
      # @!attriute [rw] event
      #   @return [Osm::Event] the event that this column belongs to

      attribute :id, type: String
      attribute :name, type: String
      attribute :label, type: String, default: ''
      attribute :parent_required, type: Boolean, default: false
      attribute :event

      validates_presence_of :id
      validates_presence_of :name


      # @!method initialize
      #   Initialize a new Column
      #   @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)


      # Update event column in OSM
      # @param api [Osm::Api] The api to use to make the request
      # @return true, false if the operation suceeded or not
      def update(api)
        require_ability_to(api: api, to: :write, on: :events, section: event.section_id)

        data = api.post_query("events.php?action=renameColumn&sectionid=#{event.section_id}&eventid=#{event.id}", post_data: {
          'columnId' => id,
          'columnName' => name,
          'pL' => label,
          'pR' => (parent_required ? 1 : 0),
        })

        (JSON.parse(data['config']) || []).each do |i|
          if i['id'] == id
            if i['name'].eql?(name) && (i['pL'].nil? || i['pL'].eql?(label)) && (i['pR'].eql?('1') == parent_required)
              reset_changed_attributes
                # The cached event will be out of date - remove it
                cache_delete(api: api, key: ['event', event.id])
                # The cached event attedance will be out of date
                cache_delete(api: api, key: ['event_attendance', event.id])
              return true
            end
          end
        end
        false
      end

      # Delete event column from OSM
      # @param api [Osm::Api] The api to use to make the request
      # @return true, false whether the delete succedded
      def delete(api)
        require_ability_to(api: api, to: :write, on: :events, section: event.section_id)

        data = api.post_query("events.php?action=deleteColumn&sectionid=#{event.section_id}&eventid=#{event.id}", post_data: {
          'columnId' => id
        })

        (JSON.parse(data['config']) || []).each do |i|
          return false if i['id'] == id
        end

        new_columns = []
        event.columns.each do |column|
          new_columns.push(column) unless column == self
        end
        event.columns = new_columns

        cache_write(api: api, key: ['event', event.id], data: event)
        true
      end

      def inspect
        Osm.inspect_instance(self, options={ replace_with: { 'event' => :id } })
      end

      private
      def sort_by
        ['event', 'id']
      end

    end
  end
end
