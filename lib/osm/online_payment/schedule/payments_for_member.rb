module Osm
  module OnlinePayment
    class Schedule < Osm::Model
      class PaymentsForMember < Osm::Model
        attribute :first_name, type: String
        attribute :last_name, type: String
        attribute :member_id, type: Integer
        attribute :direct_debit, type: Object
        attribute :start_date, type: Object
        attribute :payments, type: Object, default: {}      # payment_id -> Array of statuses
        attribute :schedule, type: Object

        validates_numericality_of :member_id, only_integer: true, greater_than: 0
        validates_presence_of :first_name
        validates_presence_of :last_name
        validates_presence_of :schedule
        validates_inclusion_of :direct_debit, in: [:active, :inactive, :cancelled]
        validates :payments, hash: { key_type: Integer, value_type: Array }


        # @!method initialize
        #   Initialize a new Schedule
        #   @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)


        # Get the most recent status for a member's payment
        # @param payment [Osm::OnlinePayment::Schedule::Payment, Integer, #to_i] The payment (or it's ID) to check
        # @return true, false
        def latest_status_for(payment)
          @latest_status ||= payments.map { |k,v| [k, v.sort.first] }.to_h
          @latest_status[payment.to_i]
        end

        # Check if the status of a member's payment is considered paid
        # @param payment [Osm::OnlinePayment::Schedule::Payment, Integer, #to_i] The payment (or it's ID) to check
        # @return [Boolean, nil]
        def paid?(payment)
          status = latest_status_for(payment.to_i)
          return nil if status.nil?
          [:paid, :paid_manually, :received, :initiated].include?(status.status)
        end

        # Check if the status of a member's payment is considered unpaid
        # @param payment [Osm::OnlinePayment::Schedule::Payment, Integer, #to_i] The payment (or it's ID) to check
        # @return [Boolean, nil]
        def unpaid?(payment)
          status = latest_status_for(payment.to_i)
          return nil if status.nil?
          [:required].include?(status.status)
        end

        # Check if a payment is over due (or will be over due on the passed date)
        # @param payment [Osm::OnlinePayment::Schedule::Payment, Integer, #to_i] The payment (or it's ID) to check
        # @param date [Date] The date to check for (defaults to today)
        # @return true, false whether the member's payment is unpaid and the payment's due date has passed
        def over_due?(payment, date=nil)
          unpaid?(payment) && payment.past_due?(date)
        end

        # Check if the member has an active direct debit for this schedule
        # @return true, false
        def active_direct_debit?
          direct_debit.eql?(:active)
        end

        # Update the status of a payment for the member in OSM
        # @param api [Osm::Api] The api to use to make the request
        # @param payment [Osm::OnlinePayment::Schedule::Payment, Integer, #to_i] The payment (or it's ID) to update
        # @param status [Symbol] What to update the status to (:required, :not_required or :paid_manually)
        # @param gift_aid true, false Whether to update the gift aid record too (only relevant when setting to :paid_manually)
        # @return true, false whether the update was made in OSM
        def update_payment_status(api:, payment:, status:, gift_aid: false)
          payment_id = payment.to_i
          fail ArgumentError, "#{payment_id} is not a valid payment for the schedule." unless schedule.payments.map(&:id).include?(payment_id)
          fail ArgumentError, "status must be either :required, :not_required or :paid_manually. You passed in #{status.inspect}" unless [:required, :not_required, :paid_manually].include?(status)

          gift_aid = false unless payment.schedule.gift_aid?
          api_status = {
            required:       'Payment required',
            not_required:   'Payment not required',
            paid_manually:  'Paid manually'
          }[status]

          data = api.post_query('ext/finances/onlinepayments/?action=updatePaymentStatus', post_data: {
            'sectionid' => schedule.section_id,
            'schemeid' => schedule.id,
            'scoutid' => member_id,
            'paymentid' => payment_id,
            'giftaid' => gift_aid,
            'value' => api_status
          })

          data = data[payment_id.to_s]
          return false if data.nil?                     # No data (at all) for this payment
          data = PaymentStatus.build_from_json(data)
          return false if data.nil?                     # No history for payment so it didn't get updated
          data = data.sort.first
          return false if data.nil?                     # No history for payment so it didn't get updated
          return false unless data.status.eql?(status)  # Latest status is not what we set
          true
        end

        # Mark a payment as required by the member
        # @param api [Osm::Api] The api to use to make the request
        # @param payment [Osm::OnlinePayment::Schedule::Payment, Integer, #to_i] The payment (or it's ID) to update
        # @return true, false whether the update was made in OSM
        def mark_payment_required(api:, payment:)
          update_payment_status(api: api, payment: payment, status: :required)
        end

        # Mark a payment as not required by the member
        # @param api [Osm::Api] The api to use to make the request
        # @param payment [Osm::OnlinePayment::Schedule::Payment, Integer, #to_i] The payment (or it's ID) to update
        # @return true, false whether the update was made in OSM
        def mark_payment_not_required(api:, payment:)
          update_payment_status(api: api, payment: payment, status: :not_required)
        end

        # Mark a payment as paid by the member
        # @param api [Osm::Api] The api to use to make the request
        # @param payment [Osm::OnlinePayment::Schedule::Payment, Integer, #to_i] The payment (or it's ID) to update
        # @param gift_aid true, false Whether to update the gift aid record too
        # @return true, false whether the update was made in OSM
        def mark_payment_paid_manually(api:, payment:, gift_aid: false)
          update_payment_status(api: api, payment: payment, status: :paid_manually, gift_aid: gift_aid)
        end

      end
    end
  end
end
