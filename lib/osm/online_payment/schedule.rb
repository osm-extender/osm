module Osm
  module OnlinePayment
    class Schedule < Osm::Model
      PAY_NOW_OPTIONS = {
        -1 => 'Allowed at all times',
        0  => 'Permanently disabled',
        7  => 'Allowed within 1 week of due day',
        14 => 'Allowed within 2 weeks of due day',
        21 => 'Allowed within 3 weeks of due day',
        28 => 'Allowed within 4 weeks of due day',
        42 => 'Allowed within 6 weeks of due day',
        56 => 'Allowed within 8 weeks of due day'
      }.freeze

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
      validates :payments, array_of: { item_type: Osm::OnlinePayment::Schedule::Payment, item_valid: true }


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
          data.map! { |i| { id: Osm.to_i_or_nil(i['schemeid']), name: i['name'].to_s } }
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
            id:            Osm.to_i_or_nil(data['schemeid']),
            section_id:    section_id,
            account_id:    Osm.to_i_or_nil(data['accountid']),
            name:          data['name'],
            description:   data['description'],
            archived:      data['archived'].eql?('1'),
            gift_aid:      data['giftaid'].eql?('1'),
            require_all:   data['defaulton'].eql?('1'),
            pay_now:       data['paynow'],
            annual_limit:  data['preauth_amount']
          )

          (data['payments'] || []).each do |payment_data|
            payment = Payment.new(
              amount:   payment_data['amount'],
              archived: payment_data['archived'].eql?('1'),
              due_date: Osm.parse_date(payment_data['date']),
              name:     payment_data['name'].to_s,
              id:       Osm.to_i_or_nil(payment_data['paymentid']),
              schedule: schedule
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
        cache_fetch(api: api, key: cache_key, no_read_cache: no_read_cache) do
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
              member_id:      Osm.to_i_or_nil(item['scoutid']),
              section_id:     section_id,
              grouping_id:    Osm.to_i_or_nil(item['patrolid']),
              first_name:     item['firstname'],
              last_name:      item['lastname'],
              start_date:     require_all ? Osm.parse_date(item['startdate']) : nil,
              direct_debit:   item['directdebit'].downcase.to_sym,
              payments:       payments_data,
              schedule:       self
            )
          end
          data
        end
      end



      # Get unarchived payments for the schedule
      # @return [Array<Osm::OnlinePayment::Schedule::Payment>]
      def current_payments
        payments.select { |p| !p.archived? }
      end
      # Check if there are any unarchived payments for the schedule
      # @return true, false
      def current_payments?
        payments.any? { |p| !p.archived? }
      end

      # Get archived payments for the schedule
      # @return [Array<Osm::OnlinePayment::Schedule::Payment>]
      def archived_payments
        payments.select(&:archived?)
      end
      # Check if there are any archived payments for the schedule
      # @return true, false
      def archived_payments?
        payments.any?(&:archived?)
      end

      def to_s
        "#{id} -> #{name}"
      end
      
      def sort_by
        [:section_id, :name, :id]
      end

    end
  end
end
