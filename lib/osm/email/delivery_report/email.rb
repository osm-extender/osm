module OSM
  class Email
    class DeliveryReport < OSM::Model
      class Email < OSM::Model
        # @!attribute [rw] to
        #   @return [String] who the email was sent to (possibly nil)
        # @!attribute [rw] from
        #   @return [String] who the email was sent from
        # @!attribute [rw] subject
        #   @return [String] the subject of the email
        # @!attribute [rw] body
        #   @return [String] the body of the email

        attribute :to, type: String
        attribute :from, type: String
        attribute :subject, type: String
        attribute :body, type: String

        validates_presence_of :to
        validates_presence_of :from
        validates_presence_of :subject
        validates_presence_of :body


        # @!method initialize
        #   Initialize a new DeliveryReport::Email
        #   @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)


        def to_s
          "To: #{to}\nFrom: #{from}\n\n#{subject}\n\n#{body.gsub(%r{</?[^>]*>}, '')}"
        end

        protected

        # Get email contents
        # @param api [OSM::Api] The api to use to make the request
        # @param section [Integer, #to_i]
        # @param email [Integer, #to_i]
        # @param member [Integer, #to_i, nil]
        # @param address [String]
        # @return [OSM::Email::DeliveryReport::Email]
        def self.fetch_from_osm(api:, section:, email:, member: nil, address: '')
          member = member.to_i unless member.nil?
          OSM::Model.require_access_to_section(api: api, section: section)

          data = api.post_query("ext/settings/emails/?action=getSentEmail&section_id=#{section.to_i}&email_id=#{email.to_i}&email=#{address}&member_id=#{member}")
          fail OSM::OSMError, "Unexpected format for response - got a #{data.class}" unless data.is_a?(Hash)
          fail OSM::OSMError, data['error'].to_s unless data['status']
          fail OSM::OSMError, "Unexpected format for meta data - got a #{data.class}" unless data['data'].is_a?(Hash)

          body = api.post_query("ext/settings/emails/?action=getSentEmailContent&section_id=#{section.to_i}&email_id=#{email.to_i}&email=#{address}&member_id=#{member}")
          fail OSM::OSMError::NotFound, data if data.eql?('Email not found')

          email_data = data['data']
          new(
            to:       email_data['to'],
            from:     email_data['from'],
            subject:  email_data['subject'],
            body:     body
          )
        end

        private def sort_by
          ['subject', 'from', 'to']
        end

      end
    end
  end
end
