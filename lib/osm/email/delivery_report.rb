module Osm
  class Email
    class DeliveryReport < Osm::Model
      TIME_FORMAT = '%d/%m/%Y %H:%M'
      VALID_STATUSES = [:processed, :delivered, :bounced].freeze

      # @!attribute [rw] id
      #   @return [Integer] the id of the email
      # @!attribute [rw] sent_at
      #   @return [Time] when the email was sent
      # @!attribute [rw] subject
      #   @return [String] the subject line of the email
      # @!attribute [rw] recipients
      #   @return [Array<Osm::DeliveryReport::Email::Recipient>]
      # @!attribute [rw] section_id
      #   @return [Integer] the id of the section which sent the email

      attribute :id, type: Integer
      attribute :sent_at, type: DateTime
      attribute :subject, type: String
      attribute :recipients, type: Object, default: []
      attribute :section_id, type: Integer

      validates_numericality_of :id, only_integer: true, greater_than: 0
      validates_numericality_of :section_id, only_integer: true, greater_than: 0
      validates_presence_of :sent_at
      validates_presence_of :subject
      validates :recipients, array_of: { item_type: Osm::Email::DeliveryReport::Recipient, item_valid: true }


      # @!method initialize
      #   Initialize a new DeliveryReport
      #   @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)


      # Get delivery reports
      # @param api [Osm::Api] The api to use to make the request
      # @param section [Osm::Section, Integer, #to_i] The section (or its ID) to get the reports for
      # @!macro options_get
      # @return [Array<Osm::Email::DeliveryReport>]
      def self.get_for_section(api:, section:, no_read_cache: false)
        Osm::Model.require_access_to_section(api: api, section: section, no_read_cache: no_read_cache)
        section_id = section.to_i
        cache_key = ['email_delivery_reports', section_id]

        Osm::Model.cache_fetch(api: api, key: cache_key, no_read_cache: no_read_cache) do
          reports = []
          recipients = {}
          data = api.post_query("ext/settings/emails/?action=getDeliveryReport&sectionid=#{section_id}")
          data.each do |item|
            case item['type']

            when 'email'
              # Create an Osm::Email::DeliveryReport in reports array
              id = Osm::to_i_or_nil(item['id'])
              sent_at_str, subject = item['name'].to_s.split(' - ', 2).map{ |i| i.to_s.strip }
              reports.push Osm::Email::DeliveryReport.new(
                id:         id,
                sent_at:    Time.strptime(sent_at_str, TIME_FORMAT),
                subject:    subject,
                section_id: section_id,
              )
              recipients[id] = []

            when 'oneEmail'
              # Create an Osm::Email::DeliveryReport::Email::Recipient in recipients[email_id] array
              report_id, id = item['id'].to_s.strip.split('-').map{ |i| Osm::to_i_or_nil(i) }
              status = item['status_raw'].to_sym
              status = :bounced if status.eql?(:bounce)
              member_id = Osm::to_i_or_nil(item['member_id'])
              recipients[report_id].push Osm::Email::DeliveryReport::Recipient.new(
                id:         id,
                address:    item['email'],
                status:     status,
                member_id:  member_id,
              )

            end
          end # each item in data

          # Add recipients to reports
          reports.each do |report|
            recs = recipients[report.id]
            # Set report for each recipient
            recs.each do |recipient|
              recipient.delivery_report = report
            end
            report.recipients = recs
          end
        end # cache fetch
      end

      # Get email contents for this report
      # @param api [Osm::Api] The api to use to make the request
      # @!macro options_get
      # @return [Osm::Email::DeliveryReport::Email]
      def get_email(api, no_read_cache: false)
        Osm::Model.require_access_to_section(api: api, section: section_id, no_read_cache: no_read_cache)
        cache_key = ['email_delivery_reports_email', section_id, id]

        Osm::Model.cache_fetch(api: api, key: cache_key, no_read_cache: no_read_cache) do
          Osm::Email::DeliveryReport::Email.fetch_from_osm(api: api, section: section_id, email: id)
        end
      end

      # @!method processed_recipients
      #   The recipients of the message with a status of :processed
      #   @return (Array<Osm::Email::DeliveryReport::Recipient>)
      # @!method processed_recipients?
      #   Whether there are recipients of the message with a status of :processed
      #   @return (Boolean)
      # @!method delivered_recipients
      #   Count the recipients of the message with a status of :delivered
      #   @return (Array<Osm::Email::DeliveryReport::Recipient>)
      # @!method delivered_recipients?
      #   Whether there are recipients of the message with a status of :delivered
      #   @return (Boolean)
      # @!method bounced_recipients
      #   Count the recipients of the message with a status of :bounced
      #   @return (Array<Osm::Email::DeliveryReport::Recipient>)
      # @!method bounced_recipients?
      #   Whether there are recipients of the message with a status of :bounced
      #   @return (Boolean)
      VALID_STATUSES.each do |attribute|
        define_method "#{attribute}_recipients" do
          recipients.select{ |r| r.status.eql?(attribute) }
        end
        define_method "#{attribute}_recipients?" do
          send("#{attribute}_recipients").any?
        end
      end


      def to_s
        "#{sent_at.strftime(TIME_FORMAT)} - #{subject}"
      end

      private
      def sort_by
        ['sent_at', 'id']
      end

    end
  end
end
