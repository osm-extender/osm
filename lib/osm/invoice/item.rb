module Osm
  class Invoice < Osm::Model
    class Item < Osm::Model
      # @!attribute [rw] id
      #   @return [Integer] The OSM ID for the invoice item
      # @!attribute [rw] invoice
      #   @return [Osm::Invoice] The Osm::Invoice the item belongs to
      # @!attribute [rw] record_id
      #   @return [Integer] The id of the item within the invoice
      # @!attribute [rw] date
      #   @return [Integer] The date the item was paid/received
      # @!attribute [rw] amount
      #   @return [Integer] The amount of the transaction
      # @!attribute [rw] type
      #   @return [Integer] The type of transaction (:expense or :income)
      # @!attribute [rw] payto
      #   @return [Integer] Who paid/reimbursed
      # @!attribute [rw] description
      #   @return [Integer] A description for the transaction
      # @!attribute [rw] budget_name
      #   @return [Integer] The name of the budget this item is assigned to

      attribute :id, type: Integer
      attribute :invoice, type: Object
      attribute :record_id, type: Integer
      attribute :date, type: Date, default: lambda { Date.today }
      attribute :amount, type: String, default: '0.00'
      attribute :type, type: Object
      attribute :payto, type: String
      attribute :description, type: String
      attribute :budget_name, type: String, default: 'Default'

      validates_numericality_of :id, only_integer: true, greater_than: 0, unless: Proc.new { |r| r.id.nil? }
      validates_numericality_of :record_id, only_integer: true, greater_than: 0, unless: Proc.new { |r| r.record_id.nil? }
      validates_presence_of :invoice
      validates_presence_of :date
      validates_presence_of :payto
      validates_presence_of :description
      validates_presence_of :budget_name
      validates_inclusion_of :type, in: [:expense, :income]
      validates_format_of :amount, with: /\A\d+\.\d{2}\Z/


      # @!method initialize
      #   Initialize a new Budget
      #   @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)


      # Create the item in OSM
      # @param api [Osm::Api] The api to use for the query
      # @return true, false Whether the item was created in OSM
      # @raise [Osm::ObjectIsInvalid] If the Item is invalid
      # @raise [Osm::Error] If the invoice item already exists in OSM
      def create(api)
        fail Osm::Error, 'the invoice item already exists in OSM' unless id.nil?
        fail Osm::ObjectIsInvalid, 'invoice item is invalid' unless valid?
        Osm::Model.require_ability_to(api: api, to: :write, on: :finance, section: invoice.section_id)

        last_item = invoice.get_items(api, no_read_cache: true).sort{ |a,b| a.record_id <=> b.record_id }.last

        data = api.post_query("finances.php?action=addRecord&invoiceid=#{invoice.id}&sectionid=#{invoice.section_id}")
        if data.is_a?(Hash) && data['ok'].eql?(true)
          new_item = invoice.get_items(api, no_read_cache: true).sort{ |a,b| a.record_id <=> b.record_id }.last
          if !new_item.nil? && (last_item.try(:id) != new_item.try(:id))
            # The cached invoice items for the section will be out of date - remove them
            cache_delete(api: api, key: ['invoice_items', invoice.id])
            self.id = new_item.id
            self.record_id = new_item.record_id
            # Update attributes in OSM
            [['amount', amount], ['comments', description], ['type', type.to_s.titleize], ['payto_userid', payto], ['categoryid', budget_name], ['entrydate', date.strftime(Osm::OSM_DATE_FORMAT)]].each do |osm_name, value|
              api.post_query("finances.php?action=updateRecord&sectionid=#{invoice.section_id}&dateFormat=generic", post_data: {
                'section_id' => invoice.section_id,
                'invoiceid' => invoice.id,
                'recordid' => record_id,
                'row' => 0,
                'column' => osm_name,
                'value' => value,
              })
            end
            return true
          end
        end
        false
      end

      # Update invoice item in OSM
      # @param api [Osm::Api] The api to use to make the request
      # @return true, false whether the update succedded
      # @raise [Osm::ObjectIsInvalid] If the Invoice is invalid
      def update(api)
        require_ability_to(api: api, to: :write, on: :finance, section: invoice.section_id)
        fail Osm::ObjectIsInvalid, 'invoice item is invalid' unless valid?

        updated = true
        to_update = Array.new
        to_update.push ['amount', amount] if changed_attributes.include?('amount')
        to_update.push ['comments', description] if changed_attributes.include?('description')
        to_update.push ['type', type.to_s.titleize] if changed_attributes.include?('type')
        to_update.push ['payto_userid', payto] if changed_attributes.include?('payto')
        to_update.push ['categoryid', budget_name] if changed_attributes.include?('budget_name')
        to_update.push ['entrydate', date.strftime(Osm::OSM_DATE_FORMAT)] if changed_attributes.include?('date')
        to_update.each do |osm_name, value|
          data = api.post_query("finances.php?action=updateRecord&sectionid=#{invoice.section_id}&dateFormat=generic", post_data: {
            'section_id' => invoice.section_id,
            'invoiceid' => invoice.id,
            'recordid' => record_id,
            'row' => 0,
            'column' => osm_name,
            'value' => value,
          })
          updated &&= (data.is_a?(Hash) && data[osm_name].to_s.eql?(value.to_s))
        end

        if updated
          reset_changed_attributes
          # The cached items for the invoice will be out of date - remove them
          cache_delete(api: api, key: ['invoice_items', invoice.id])
          return true
        else
          return false
        end
      end

      # Delete invoice item from OSM
      # @param api [Osm::Api] The api to use to make the request
      # @return true, false whether the delete succedded
      def delete(api)
        require_ability_to(api: api, to: :write, on: :finance, section: invoice.section_id)

        data = api.post_query("finances.php?action=deleteEntry&sectionid=#{invoice.section_id}", post_data: {
          'id' => id,
        })

        if data.is_a?(Hash) && data['ok']
          # The cached invoice items for the section will be out of date - remove them
          cache_delete(api: api, key: ['invoice_items', invoice.id])
          return true
        end
        false
      end

      # Get value of this item for easy totaling
      # @return [Float]
      def value
        return amount.to_f if type.eql?(:income)
        return -amount.to_f if type.eql?(:expense)
        0.0
      end

      private def sort_by
        ['invoice', 'date']
      end

    end
  end
end
