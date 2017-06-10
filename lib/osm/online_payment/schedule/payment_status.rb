module Osm
  module OnlinePayment
    class Schedule < Osm::Model
      class PaymentStatus < Osm::Model
        VALID_STATUSES = [:required, :not_required, :initiated, :paid, :received, :paid_manually].freeze

        attribute :id, type: Integer
        attribute :payment, type: Object
        attribute :timestamp, type: Object
        attribute :status, type: Object
        attribute :details, type: String
        attribute :updated_by, type: String
        attribute :updated_by_id, type: Integer

        validates_numericality_of :id, only_integer: true, greater_than: 0
        validates_numericality_of :updated_by_id, only_integer: true, greater_than_or_equal_to: -2
        validates_presence_of :payment
        validates_presence_of :timestamp
        validates_presence_of :updated_by
        validates_inclusion_of :status, in: VALID_STATUSES


        # @!method initialize
        #   Initialize a new PaymentStatus
        #   @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)


        # @!method required?
        #   Whether the status is :required
        #   @return (Boolean)
        # @!method not_required?
        #   Whether the status is :not_required
        #   @return (Boolean)
        # @!method initiated?
        #   Whether the status is :initiated
        #   @return (Boolean)
        # @!method paid?
        #   Whether the status is :paid
        #   @return (Boolean)
        # @!method received?
        #   Whether the status is :received
        #   @return (Boolean)
        # @!method paid_manually?
        #   Whether the status is :paid_manually
        #   @return (Boolean)
        VALID_STATUSES.each do |attribute|
          define_method "#{attribute}?" do
            status.eql?(attribute)
          end
        end

        def sort_by
          ['-timestamp', :payment, :id]
        end

        def inspect
          Osm.inspect_instance(self, replace_with: { 'payment' => :id })
        end

        protected

        def self.build_from_json(json, payment=nil)
          data = JSON.parse(json)
          return [] unless data.is_a?(Hash)
          data = data['status']
          return [] unless data.is_a?(Array)

          status_map = {
            'Payment required' => :required,
            'Payment not required' => :not_required,
            'Initiated' => :initiated,
            'Paid' => :paid,
            'Received' => :received,
            'Paid manually' => :paid_manually,
          }

          data.map! do |item|
            new(
              id:             Osm.to_i_or_nil(item['statusid']),
              payment:        payment,
              timestamp:      Time.strptime(item['statustimestamp'], '%d/%m/%Y %H:%M'),
              status:         status_map[item['status']],
              details:        item['details'],
              updated_by:     item['firstname'],
              updated_by_id:  item['who'].to_i
            )
          end
        end

      end
    end
  end
end
