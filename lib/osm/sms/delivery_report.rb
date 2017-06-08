module Osm
  class Sms
    class DeliveryReport < Osm::Model
      VALID_STATUSES = [:sent, :not_sent, :delivered, :not_delivered, :invalid_destination_address, :invalid_source_address, :invalid_message_format, :route_not_available, :not_allowed]

      # @!attribute [rw] sms_id
      #   @return [Integer] the id of the SMS
      # @!attribute [rw] user_id
      #   @return [Integer] the id of the OSM user who sent the SMS
      # @!attribute [rw] member_id
      #   @return [Integer] the id of the member the SMS was sent to
      # @!attribute [rw] section_id
      #   @return [Integer] the id of the section 'owning' the SMS
      # @!attribute [rw] from_name
      #   @return [String] the name of the person who sent the SMS
      # @!attribute [rw] from_number
      #   @return [String] the number the SMS was 'sent from'
      # @!attribute [rw] to_name
      #   @return [String] the name of the person the message was sent to
      # @!attribute [rw] to_number
      #   @return [String] the number the SMS was sent to
      # @!attribute [rw] message
      #   @return [String] the text of the SMS
      # @!attribute [rw] scheduled
      #   @return [DateTime] when the SMS was scheduled to be sent
      # @!attribute [rw] last_updated
      #   @return [DateTime] when this report was last updated
      # @!attribute [rw] credits
      #   @return [Integer] thow many credits the SMS cost
      # @!attribute [rw] status
      #   @return [Symbol] the status of the SMS (usually :sent, :delivered, :not_delivered, :invalid_destination_address or :not_sent)

      attribute :sms_id, type: Integer
      attribute :user_id, type: Integer
      attribute :member_id, type: Integer
      attribute :section_id, type: Integer
      attribute :from_name, type: String
      attribute :from_number, type: String
      attribute :to_name, type: String
      attribute :to_number, type: String
      attribute :message, type: String
      attribute :scheduled, type: DateTime
      attribute :last_updated, type: DateTime
      attribute :credits, type: Integer
      attribute :status, type: Object

      validates_numericality_of :sms_id, only_integer:true, greater_than_or_equal_to:0
      validates_numericality_of :user_id, only_integer:true, greater_than_or_equal_to:0
      validates_numericality_of :member_id, only_integer:true, greater_than_or_equal_to:0
      validates_numericality_of :section_id, only_integer:true, greater_than_or_equal_to:0
      validates_numericality_of :credits, only_integer:true, greater_than_or_equal_to:0
      validates_presence_of :from_name
      validates_presence_of :from_number
      validates_presence_of :to_name
      validates_presence_of :to_number
      validates_presence_of :message
      validates_presence_of :scheduled
      validates_presence_of :last_updated
      validates_inclusion_of :status, in: VALID_STATUSES


      # @!method initialize
      #   Initialize a new Sms
      #   @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)


      # Get delivery reports
      # @param api [Osm::Api] the api to use to make the request
      # @param section [Osm::Section, Integer, #to_i] the section (or its ID) to get the reports for
      # @!macro options_get
      # @return [Array<Osm::Sms::DeliveryReport>]
      def self.get_for_section(api:, section:, no_read_cache: false)
        require_access_to_section(ai: api, section: section, no_read_cache: no_read_cache)
        section_id = section.to_i
        cache_key = ['sms_delivery_reports', section_id]

        cache_fetch(api: api, key: cache_key, no_read_cache: no_read_cache) do
          reports = []
          get_name_number_regex = /\A(?<name>.*\w)\W+(?<number>\d*)\Z/
          data = api.post_query("sms.php?action=deliveryReports&sectionid=#{section_id}&dateFormat=generic")
          data['items'].each do |report|
            from = report['from'].match(get_name_number_regex)
            to = report['to'].match(get_name_number_regex)
            reports.push new(
              sms_id: Osm.to_i_or_nil(report['smsid']),
              user_id: Osm.to_i_or_nil(report['userid']),
              member_id: Osm.to_i_or_nil(report['scoutid']),
              section_id: Osm.to_i_or_nil(report['sectionid']),
              from_name: from[:name],
              from_number: "+#{from[:number]}",
              to_name: to[:name],
              to_number: "+#{to[:number]}",
              message: report['message'],
              scheduled: Osm.parse_datetime(report['schedule']),
              last_updated: Osm.parse_datetime(report['lastupdated']),
              credits: Osm.to_i_or_nil(report['credits']),
              status: (report['status'] || 'error').downcase.to_sym,
            )
          end
          reports
        end # cache fetch
      end


      # @!method status_sent?
      #   Check if the SMS was sent
      #   @return (Boolean)
      # @!method status_not_sent?
      #   Check if the SMS was not sent
      #   @return (Boolean)
      # @!method status_delivered?
      #   Check if the SMS was delivered
      #   @return (Boolean)
      # @!method status_not_delivered?
      #   Check if the SMS was not delivered
      #   @return (Boolean)
      # @!method status_invalid_destination_address?
      #   Check if the SMS had an invalid destination address
      #   @return (Boolean)
      # @!method status_invalid_source_address?
      #   Check if the SMS had an invalid source address
      #   @return (Boolean)
      # @!method status_invalid_message_format?
      #   Check if the SMS message was in an invalid format
      #   @return (Boolean)
      # @!method route_not_available?
      #   Check if the SMS sending service could not route the message
      #   @return (Boolean)
      # @!method status_not_allowed?
      #   Check if the SMS sending service refused to send the message
      #   @return (Boolean)
      VALID_STATUSES.each do |attribute|
        define_method "status_#{attribute}?" do
          status == attribute
        end
      end

    end
  end
end