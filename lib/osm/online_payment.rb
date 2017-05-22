module Osm

  class OnlinePayment

    class Schedule < Osm::Model
      class Payment < Osm::Model; end # Ensure the constant exists for the validators
      class PaymentStatus < Osm::Model; end # Ensure the constant exists for validators

      PAY_NOW_OPTIONS = {
        -1 => 'Allowed at all times',
        0  => 'Permanently disabled',
        7  => 'Allowed within 1 week of due day',
        14 => 'Allowed within 2 weeks of due day',
        21 => 'Allowed within 3 weeks of due day',
        28 => 'Allowed within 4 weeks of due day',
        42 => 'Allowed within 6 weeks of due day',
        56 => 'Allowed within 8 weeks of due day',
      }

      # @!attribute [rw] id
      #   @return [FixNum] the schedule's ID
      # @!attribute [rw] section_id
      #   @return [FixNum] the ID of the section the schedule belongs to
      # @!attribute [rw] account_id
      #   @return [FixNum] the ID of the bank account this schedule is tied to
      # @!attribute [rw] name
      #   @return [String] the name of the schedule
      # @!attribute [rw] description
      #   @return [String] the description of what the schedule is for
      # @!attribute [rw] archived
      #   @return true, false whether the schedule has been archived
      # @!attribute [rw] gift_aid
      #   @return true, false whether payments made using this schedule are eligable for gift aid
      # @!attribute [rw] require_all
      #   @return true, false whether to require all payments within the schedule by default
      # @!attribute [rw] pay_now
      #   @return [FixNum] controls the use of the pay now feature in OSM, see the PAY_NOW_OPTIONS hash
      # @!attribute [rw] annual_limit
      #   @return [String] the maximum amount you'll be able to collect in a rolling 12 month period using this schedule
      # @!attribute [rw] payments
      #   @return [Array<Payment>] the payments which make up this schedule


      attribute :id, type: Integer
      attribute :section_id, type: Integer
      attribute :account_id, type: Integer
      attribute :name, type: String
      attribute :description, type: String, default: ''
      attribute :archived, type: Boolean
      attribute :gift_aid, type: Boolean
      attribute :require_all, type: Boolean
      attribute :pay_now, type: Integer
      attribute :annual_limit, type: String
      attribute :payments, type: Object, default: []

      validates_numericality_of :id, only_integer: true, greater_than: 0
      validates_numericality_of :section_id, only_integer: true, greater_than: 0
      validates_numericality_of :account_id, only_integer: true, greater_than: 0
      validates_presence_of :annual_limit
      validates_presence_of :name
      validates_inclusion_of :pay_now, in: PAY_NOW_OPTIONS.keys
      validates_inclusion_of :archived, in: [true, false]
      validates_inclusion_of :gift_aid, in: [true, false]
      validates_inclusion_of :require_all, in: [true, false]
      validates :payments, array_of: {item_type: Osm::OnlinePayment::Schedule::Payment, item_valid: true}


      # @!method initialize
      #   Initialize a new Schedule
      #   @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)


      # Get a simple list of schedules for a section
      # @param api [Osm::Api] The api to use to make the request
      # @param section [Osm::Section, Integer, #to_i] The section (or its ID) to get the due badges for
      # @!macro options_get
      # @return [Array<Hash>]
      def self.get_list_for_section(api:, section:, no_read_cache: false)
        require_ability_to(api: api, to: :read, on: :finance, section: section, no_read_cache: no_read_cache)
        section_id = section.to_i
        cache_key = ['online_payments', 'schedule_list', section_id]

        cache_fetch(api: api, key: cache_key, no_read_cache: no_read_cache) do
          data = api.post_query("ext/finances/onlinepayments/?action=getSchemes&sectionid=#{section_id}")
          data = data.is_a?(Hash) ? data['items'] : nil
          data ||= []
          data.map!{ |i| {id: Osm::to_i_or_nil(i['schemeid']), name: i['name'].to_s } }
        end
      end


      # Get all payment schedules for a section
      # @param api [Osm::Api] The api to use to make the request
      # @param section [Osm::Section, Integer, #to_i] The section (or its ID) to get the due badges for
      # @!macro options_get
      # @return [Array<Osm::OnlinePayment::Schedule>]
      def self.get_for_section(api:, section:, no_read_cache: false)
        require_ability_to(api: api, to: :read, on: :finance, section: section, no_read_cache: no_read_cache)

        get_list_for_section(api: api, section: section, no_read_cache: no_read_cache).map do |schedule|
          get(api: api, section: section, schedule: schedule[:id], no_read_cache: no_read_cache)
        end
      end


      # Get a payment schedules for a section
      # @param api [Osm::Api] The api to use to make the request
      # @param section [Osm::Section, Integer, #to_i] The section (or its ID) to get the due badges for
      # @param schedule [Osm::OnlinePayment::Schedule, Integer, #to_i] The ID of the payment schedule to get
      # @!macro options_get
      # @return [Array<Osm::OnlinePayment::Schedule>]
      def self.get(api:, section:, schedule:, no_read_cache: false)
        require_ability_to(api: api, to: :read, on: :finance, section: section, no_read_cache: no_read_cache)
        section_id = section.to_i
        schedule_id = schedule.to_i
        cache_key = ['online_payments', 'schedule', schedule_id]

        cache_fetch(api: api, key: cache_key, no_read_cache: no_read_cache) do
          data = api.post_query("ext/finances/onlinepayments/?action=getPaymentSchedule&sectionid=#{section_id}&schemeid=#{schedule_id}&allpayments=true")
          schedule = new(
            id:            Osm::to_i_or_nil(data['schemeid']),
            section_id:    section_id,
            account_id:    Osm::to_i_or_nil(data['accountid']),
            name:          data['name'],
            description:   data['description'],
            archived:      data['archived'].eql?('1'),
            gift_aid:      data['giftaid'].eql?('1'),
            require_all:   data['defaulton'].eql?('1'),
            pay_now:       data['paynow'],
            annual_limit:  data['preauth_amount'],
          )

          (data['payments'] || []).each do |payment_data|
            payment = Payment.new(
              amount:   payment_data['amount'],
              archived: payment_data['archived'].eql?('1'),
              due_date: Osm::parse_date(payment_data['date']),
              name:     payment_data['name'].to_s,
              id:       Osm::to_i_or_nil(payment_data['paymentid']),
              schedule: schedule,
            )
            schedule.payments.push payment
          end
          schedule
        end
      end


      # Get payments made by members for the schedule
      # @param api [Osm::Api] The api to use to make the request
      # @param term [Osm::Term, Integer, #to_i] The term (or it's id) to get details for (defaults to current term)
      # @!macro options_get
      # @return [Array<Osm::OnlinePayment::Schedule::PaymentsForMember>]
      def get_payments_for_members(api:, term: nil, no_read_cache: false)
        require_ability_to(api: api, to: :read, on: :finance, section: section_id, no_read_cache: no_read_cache)

        if term.nil?
          section = Osm::Section.get(api: api, section: section_id, no_read_cache: no_read_cache)
          term = section.waiting? ? -1 : Osm::Term.get_current_term_for_section(api: api, section: section)
        end

        cache_key = ['online_payments', 'for_members', id, term.to_i]
        cache_fetch(api: api, key: cache_key, no_read_cache:no_read_cache) do
          data = api.post_query("ext/finances/onlinepayments/?action=getPaymentStatus&sectionid=#{section_id}&schemeid=#{id}&termid=#{term.to_i}")
          data = data['items'] || []
          data.map! do |item|
            payments_data = {}
            payments.each do |payment|
              unless item[payment.id.to_s].nil?
                payments_data[payment.id] = PaymentStatus.build_from_json(item[payment.id.to_s], payment)
              end
            end

            PaymentsForMember.new(
              member_id:      Osm::to_i_or_nil(item['scoutid']),
              section_id:     section_id,
              grouping_id:    Osm::to_i_or_nil(item['patrolid']),
              first_name:     item['firstname'],
              last_name:      item['lastname'],
              start_date:     require_all ? Osm::parse_date(item['startdate']) : nil,
              direct_debit:   item['directdebit'].downcase.to_sym,
              payments:       payments_data,
              schedule:       self,
            )
          end
          data
        end
      end



      # Get unarchived payments for the schedule
      # @return [Array<Osm::OnlinePayment::Schedule::Payment>]
      def current_payments
        payments.select{ |p| !p.archived? }
      end
      # Check if there are any unarchived payments for the schedule
      # @return true, false
      def current_payments?
        payments.any?{ |p| !p.archived? }
      end

      # Get archived payments for the schedule
      # @return [Array<Osm::OnlinePayment::Schedule::Payment>]
      def archived_payments
        payments.select{ |p| p.archived? }
      end
      # Check if there are any archived payments for the schedule
      # @return true, false
      def archived_payments?
        payments.any?{ |p| p.archived? }
      end

      def to_s
        "#{id} -> #{name}"
      end
      
      def sort_by
        [:section_id, :name, :id]
      end

      class Payment < Osm::Model
        # @!attribute [rw] id
        #   @return [FixNum] the payment's ID
        # @!attribute [rw] amount
        #   @return [Sreing] the amount of the payment
        # @!attribute [rw] name
        #   @return [String] the name given to the payment
        # @!attribute [rw] archived
        #   @return true, false whether the payment has been archived
        # @!attribute [rw] date
        #   @return [Date] the payment's due date
        # @!attribute [rw] schedule
        #   @return [Osm::OnlnePayment::Schedule] the schedule the payment belongs to

        attribute :id, type: Integer
        attribute :amount, type: String
        attribute :name, type: String
        attribute :archived, type: Boolean
        attribute :due_date, type: Object
        attribute :schedule, type: Object

        validates_numericality_of :id, only_integer: true, greater_than: 0
        validates_presence_of :amount
        validates_presence_of :name
        validates_presence_of :due_date
        validates_presence_of :schedule
        validates_inclusion_of :archived, in: [true, false]


        # @!method initialize
        #   Initialize a new Payment
        #   @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)


        # Check if the payment is past due (or will be past due on the passed date)
        # @param date [Date] The date to check for (defaults to today)
        # @return true, false
        def past_due?(date=Date.today)
          date > due_date
        end

        def inspect
          Osm.inspect_instance(self, {replace_with: {'schedule' => :to_s}})
        end

      end # Schedule::Payment class


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
        validates :payments, hash: {key_type: Integer, value_type: Array}


        # @!method initialize
        #   Initialize a new Schedule
        #   @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)


        # Get the most recent status for a member's payment
        # @param payment [Osm::OnlinePayment::Schedule::Payment, Integer, #to_i] The payment (or it's ID) to check
        # @return true, false
        def latest_status_for(payment)
          @latest_status ||= payments.map{ |k,v| [k, v.sort.first] }.to_h
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
            paid_manually:  'Paid manually',
          }[status]

          data = api.post_query("ext/finances/onlinepayments/?action=updatePaymentStatus", post_data: {
            'sectionid' => schedule.section_id,
            'schemeid' => schedule.id,
            'scoutid' => member_id,
            'paymentid' => payment_id,
            'giftaid' => gift_aid,
            'value' => api_status,
          })

          data = data[payment_id.to_s]
          return false if data.nil?                     # No data (at all) for this payment
          data = PaymentStatus.build_from_json(data)
          return false if data.nil?                     # No history for payment so it didn't get updated
          data = data.sort.first
          return false if data.nil?                     # No history for payment so it didn't get updated
          return false unless data.status.eql?(status)  # Latest status is not what we set
          return true
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

      end # Schedule::PaymentsForMember class


      class PaymentStatus < Osm::Model
        VALID_STATUSES = [:required, :not_required, :initiated, :paid, :received, :paid_manually]

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
          Osm.inspect_instance(self, {replace_with: {'payment' => :id}})
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
              id:             Osm::to_i_or_nil(item['statusid']),
              payment:        payment,
              timestamp:      Time.strptime(item['statustimestamp'], '%d/%m/%Y %H:%M'),
              status:         status_map[item['status']],
              details:        item['details'],
              updated_by:     item['firstname'],
              updated_by_id:  item['who'].to_i,
            )
          end
        end

      end # Schedule::PaymentStatus class

    end # Schedule class

  end
   
end
