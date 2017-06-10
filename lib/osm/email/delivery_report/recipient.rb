module Osm
  class Email
    class DeliveryReport < Osm::Model
      class Recipient < Osm::Model
        VALID_STATUSES = [:processed, :delivered, :bounced].freeze

        # @!attribute [rw] id
        #   @return [Integer] the id of the email recipient
        # @!attribute [rw] delivery_report
        #   @return [Osm::Email::DeliveryReport] the report this recipient belongs to
        # @!attribute [rw] address
        #   @return [String] the email address of the recipient
        # @!attribute [rw] status
        #   @return [Symbol] the status of the email sent to the recipient
        # @!attribute [rw] member_id
        #   @return [Integer] the id of the member the email was sent to

        attribute :id, type: Integer
        attribute :delivery_report, type: Object
        attribute :address, type: String
        attribute :status, type: Object, default: :unknown
        attribute :member_id, type: Integer

        validates_numericality_of :id, only_integer: true, greater_than: 0
        validates_numericality_of :member_id, only_integer: true, greater_than: 0
        validates_presence_of :address
        validates_presence_of :delivery_report
        validates_inclusion_of :status, in: VALID_STATUSES


        # @!method initialize
        #   Initialize a new DeliveryReport::Recipient
        #   @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)


        # Get email contents for this recipient
        # @param api [Osm::Api] The api to use to make the request
        # @!macro options_get
        # @return [Osm::Email::DeliveryReport::Email]
        def get_email(api, no_read_cache: false)
          Osm::Model.require_access_to_section(api: api, section: delivery_report.section_id, no_read_cache: no_read_cache)
          cache_key = ['email_delivery_reports_email', delivery_report.section_id, delivery_report.id, id]

          Osm::Model.cache_fetch(api: api, key: cache_key, no_read_cache: no_read_cache) do
            Osm::Email::DeliveryReport::Email.fetch_from_osm(api: api, section: delivery_report.section_id, email: delivery_report.id, member: member_id, address: address)
          end
        end

        # Unblock email address from being sent emails
        # @param api [Osm::Api] The api to use to make the request
        # @param true, false whether removal was successful
        def unblock_address(api)
          return true unless bounced?

          data = api.post_query('ext/settings/emails/?action=unBlockEmail', post_data: {
            'section_id' => delivery_report.section_id,
            'email'      => address,
            'email_id'   => delivery_report.id
          })

          if data.is_a?(Hash)
            fail Osm::Error, data['error'].to_s unless data['error'].nil?
            return !!data['status']
          end
          false
        end

        # @!method processed?
        #   Check if the email to this recipient has been processes
        #   @return (Boolean)
        # @!method delivered?
        #   Check if the email to this recipient was delivered
        #   @return (Boolean)
        # @!method bounced?
        #   Check if the email to this recipient bounced
        #   @return (Boolean)
        VALID_STATUSES.each do |attribute|
          define_method "#{attribute}?" do
            status.eql?(attribute)
          end
        end

        def to_s
          "#{address} - #{status}"
        end

        def inspect
          Osm::inspect_instance(self, { replace_with: { 'delivery_report' => :id } })
        end

        private def sort_by
          ['delivery_report', 'id']
        end

      end
    end
  end
end
