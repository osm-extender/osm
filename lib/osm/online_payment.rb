module Osm

  class OnlinePayment

    class Schedule < Osm::Model
      class Payment < Osm::Model; end # Ensure the constant exists for the validators

      SORT_BY = [:section_id, :name, :id]
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
      #   @return [Boolean] whether the schedule has been archived
      # @!attribute [rw] gift_aid
      #   @return [Boolean] whether payments made using this schedule are eligable for gift aid
      # @!attribute [rw] require_all
      #   @return [Boolean] whether to require all payments within the schedule by default
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

      if ActiveModel::VERSION::MAJOR < 4
        attr_accessible :id, :section_id, :account_id, :name, :description, :archived, :gift_aid,
                        :require_all, :pay_now, :annual_limit, :payments
      end

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
      # @param [Osm::Api] api The api to use to make the request
      # @param [Osm::Section, Fixnum, #to_i] section The section (or its ID) to get the due badges for
      # @!macro options_get
      # @return [Array<Hash>]
      def self.get_list_for_section(api, section, options={})
        require_ability_to(api, :read, :finance, section, options)
        section_id = section.to_i
        cache_key = ['online_payments', 'schedule_list', section_id]

        if !options[:no_cache] && Osm::Model.cache_exist?(api, cache_key)
          return cache_read(api, cache_key)
        end

        data = api.perform_query("ext/finances/onlinepayments/?action=getSchemes&sectionid=#{section_id}")
        data = data.is_a?(Hash) ? data['items'] : nil
        data ||= []
        data.map!{ |i| {id: Osm::to_i_or_nil(i['schemeid']), name: i['name'].to_s } }

        cache_write(api, cache_key, data)
        return data
      end


      # Get all payment schedules for a section
      # @param [Osm::Api] api The api to use to make the request
      # @param [Osm::Section, Fixnum, #to_i] section The section (or its ID) to get the due badges for
      # @!macro options_get
      # @return [Array<Osm::OnlinePayment::Schedule>]
      def self.get_for_section(api, section, options={})
        require_ability_to(api, :read, :finance, section, options)

        get_list_for_section(api, section, options).map do |schedule|
          get(api, section, schedule[:id], options)
        end
      end


      # Get a payment schedules for a section
      # @param [Osm::Api] api The api to use to make the request
      # @param [Osm::Section, Fixnum, #to_i] section The section (or its ID) to get the due badges for
      # @param [Fixnum, #to_i] schedule The ID of the payment schedule to get
      # @!macro options_get
      # @return [Array<Osm::OnlinePayment::Schedule>]
      def self.get(api, section, schedule, options={})
        require_ability_to(api, :read, :finance, section, options)
        section_id = section.to_i
        schedule_id = schedule.to_i
        cache_key = ['online_payments', 'schedule', schedule_id]

        if !options[:no_cache] && cache_exist?(api, cache_key)
          data = cache_read(api, cache_key)
          return data if data.section_id.eql?(section_id)
        end

        data = api.perform_query("ext/finances/onlinepayments/?action=getPaymentSchedule&sectionid=#{section_id}&schemeid=#{schedule_id}&allpayments=true")
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

        cache_write(api, cache_key, schedule)
        return schedule
      end

      # Get unarchived payments for the schedule
      # @return [Array<Osm::OnlinePayment::Schedule::Payment>]
      def current_payments
        payments.select{ |p| !p.archived? }
      end
      # Check if there are any unarchived payments for the schedule
      # @return [Boolean]
      def current_payments?
        payments.any?{ |p| !p.archived? }
      end

      # Get archived payments for the schedule
      # @return [Array<Osm::OnlinePayment::Schedule::Payment>]
      def archived_payments
        payments.select{ |p| p.archived? }
      end
      # Check if there are any archived payments for the schedule
      # @return [Boolean]
      def archived_payments?
        payments.any?{ |p| p.archived? }
      end

      def to_s
        "#{id} -> #{name}"
      end


      class Payment < Osm::Model
        # @!attribute [rw] id
        #   @return [FixNum] the payment's ID
        # @!attribute [rw] amount
        #   @return [Sreing] the amount of the payment
        # @!attribute [rw] name
        #   @return [String] the name given to the payment
        # @!attribute [rw] archived
        #   @return [Boolean] whether the payment has been archived
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

        if ActiveModel::VERSION::MAJOR < 4
          attr_accessible :id, :amount, :name, :archived, :due_date, :schedule
        end

        validates_numericality_of :id, only_integer: true, greater_than: 0
        validates_presence_of :amount
        validates_presence_of :name
        validates_presence_of :due_date
        validates_presence_of :schedule
        validates_inclusion_of :archived, in: [true, false]


        # @!method initialize
        #   Initialize a new Payment
        #   @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)


        # Check if the payment is past die (or will be past die on the passed date)
        # @param [Date] date The date to check for (defaults to today)
        # @return [Boolean]
        def past_due?(date=Date.today)
          date > due_date
        end

        def inspect
          Osm.inspect_instance(self, {:replace_with => {'schedule' => :to_s}})
        end

      end # Schedule::Payment class


    end # Schedule class

  end
   
end
