module Osm
  class Event < Osm::Model
    class Attendance < Osm::Model
      # @!attribute [rw] member_id
      #   @return [Integer] OSM id for the member
      # @!attribute [rw] grouping__id
      #   @return [Integer] OSM id for the grouping the member is in
      # @!attribute [rw] fields
      #   @return [Hash] Keys are the field's id, values are the field values
      # @!attribute [rw] row
      #   @return [Integer] part of the OSM API
      # @!attriute [rw] event
      #   @return [Osm::Event] the event that this attendance applies to
      # @!attribute [rw] first_name
      #   @return [String] the member's first name
      # @!attribute [rw] last_name
      #   @return [String] the member's last name
      # @!attribute [rw] date_of_birth
      #   @return [Date] the member's date of birth
      # @!attribute [rw] attending
      #   @return [Symbol] whether the member is attending (either :yes, :no, :invited, :shown, :reserved or nil)
      # @!attribute [rw] payments
      #   @return [Hash] keys are the payment's id, values are the payment state
      # @!attribute [rw] payment_control
      #   @return [Symbol] whether payments are done manually or automatically (either :manual, :automatic or nil)

      attribute :row, type: Integer
      attribute :member_id, type: Integer
      attribute :grouping_id, type: Integer
      attribute :fields, default: {}
      attribute :event
      attribute :first_name, type: String
      attribute :last_name, type: String
      attribute :date_of_birth, type: Date
      attribute :attending
      attribute :payments, default: {}
      attribute :payment_control

      validates_numericality_of :row, only_integer: true, greater_than_or_equal_to: 0
      validates_numericality_of :member_id, only_integer: true, greater_than: 0
      validates_numericality_of :grouping_id, only_integer: true, greater_than_or_equal_to: -2
      validates :fields, hash: { key_type: Integer, value_type: String }
      validates :payments, hash: { key_type: Integer, value_type: String }
      validates_each :event do |record, attr, value|
        record.event.valid?
      end
      validates_presence_of :first_name
      validates_presence_of :last_name
      validates_presence_of :date_of_birth
      validates_inclusion_of :payment_control, in: [:manual, :automatic, nil]
      validates_inclusion_of :attending, in: [:yes, :no, :invited, :shown, :reserved, nil]


      # @!method initialize
      #   Initialize a new Attendance
      #   @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)
      old_initialize = instance_method(:initialize)
      define_method :initialize do |*args|
        ret_val = old_initialize.bind(self).call(*args)
        self.fields = DirtyHashy.new(fields)
        fields.clean_up!
        return ret_val
      end


      # Update event attendance
      # @param api [Osm::Api] The api to use to make the request
      # @return true, false if the operation suceeded or not
      def update(api)
        require_ability_to(api: api, to: :write, on: :events, section: event.section_id)

        payment_values = {
          manual: 'Manual',
          automatic: 'Automatic'
        }
        attending_values = {
          yes: 'Yes',
          no: 'No',
          invited: 'Invited',
          shown: 'Show in My.SCOUT',
          reserved: 'Reserved'
        }

        updated = true
        fields.changes.each do |field, (was, now)|
          data = api.post_query('events.php?action=updateScout', post_data: {
            'scoutid' => member_id,
            'column' => "f_#{field}",
            'value' => now,
            'sectionid' => event.section_id,
            'row' => row,
            'eventid' => event.id
          })
          updated = false unless data.is_a?(Hash)
        end

        if changed_attributes.include?('payment_control')
          data = api.post_query('events.php?action=updateScout', post_data: {
            'scoutid' => member_id,
            'column' => 'payment',
            'value' => payment_values[payment_control],
            'sectionid' => event.section_id,
            'row' => row,
            'eventid' => event.id
          })
          updated = false unless data.is_a?(Hash)
        end
        if changed_attributes.include?('attending')
          data = api.post_query('events.php?action=updateScout', post_data: {
            'scoutid' => member_id,
            'column' => 'attending',
            'value' => attending_values[attending],
            'sectionid' => event.section_id,
            'row' => row,
            'eventid' => event.id
          })
          updated = false unless data.is_a?(Hash)
        end

        if updated
          reset_changed_attributes
          fields.clean_up!
          # The cached event attedance will be out of date
          cache_delete(api: api, key: ['event_attendance', event.id])
        end
        updated
      end

      # Get audit trail
      # @param api [Osm::Api] The api to use to make the request
      # @!macro options_get
      # @return [Array<Hash>]
      def get_audit_trail(api, no_read_cache: false)
        require_ability_to(api: api, to: :read, on: :events, section: event.section_id, no_read_cache: no_read_cache)
        cache_key = ['event\_attendance\_audit', event.id, member_id]

        cache_fetch(api: api, key: cache_key, no_read_cache: no_read_cache) do
          data = api.post_query("events.php?action=getEventAudit&sectionid=#{event.section_id}&scoutid=#{member_id}&eventid=#{event.id}")
          data ||= []

          attending_values = {
            'Yes' => :yes,
            'No' => :no,
            'Invited' => :invited,
            'Show in My.SCOUT' => :shown,
            'Reserved' => :reserved
          }

          trail = []
          data.each do |item|
            this_item = {
              at: DateTime.strptime(item['date'], '%d/%m/%Y %H:%M'),
              by: item['updatedby'].strip,
              type: item['type'].to_sym,
              description: item['desc'],
              event_id: event.id,
              member_id: member_id,
              event_attendance: self
            }
            if this_item[:type].eql?(:detail)
              results = this_item[:description].match(/\ASet '(?<label>.+)' to '(?<value>.+)'\Z/)
              this_item[:label] = results[:label]
              this_item[:value] = results[:value]
            end
            if this_item[:type].eql?(:attendance)
              results = this_item[:description].match(/\AAttendance: (?<attending>.+)\Z/)
              this_item[:attendance] = attending_values[results[:attending]]
            end
            trail.push this_item
          end # each data
          trail
        end # cache fetch
      end

      # @! method automatic_payments?
      #  Check wether payments are made automatically for this member
      #  @return true, false
      # @! method manual_payments?
      #  Check wether payments are made manually for this member
      #  @return true, false
      [:automatic, :manual].each do |payment_control_type|
        define_method "#{payment_control_type}_payments?" do
          payments == payment_control_type
        end
      end

      # @! method is_attending?
      #  Check wether the member has said they are attending the event
      #  @return true, false
      # @! method is_not_attending?
      #  Check wether the member has said they are not attending the event
      #  @return true, false
      # @! method is_invited?
      #  Check wether the member has been invited to the event
      #  @return true, false
      # @! method is_shown?
      #  Check wether the member can see the event in My.SCOUT
      # @! method is_reserved?
      #  Check wether the member has reserved a space when one becomes availible
      #  @return true, false
      [:attending, :not_attending, :invited, :shown, :reserved].each do |attending_type|
        define_method "is_#{attending_type}?" do
          attending == attending_type
        end
      end

      def inspect
        Osm.inspect_instance(self, options = { replace_with: { 'event' => :id } })
      end

      private

      def sort_by
        ['event', 'row']
      end

    end
  end
end
