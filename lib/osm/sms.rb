module Osm

  class Sms

    # Send an SMS to some members on their enabled numbers
    # @param [Osm::Api] api The api to use to make the request
    # @param [Osm::Section, Fixnum, #to_i] section The section (or its ID) to send the message to
    # @param [Array<Osm::Member, Fixnum, #to_i>, Osm::Member, Fixnum, #to_i] members The members (or their IDs) to send the message to
    # @param [String, #to_s] source_address The number to claim the message is from
    # @param [String, #to_s] message The text of the message to send
    # @return [Boolean] whether the messages were sent
    # @raise [Osm::Error] If the section doesn't have enough credits to send the message
    def self.send_sms(api, section, members, source_address, message)
      Osm::Model.require_access_to_section(api, section)
      raise Osm::Error, 'You do not have enough credits to send that message.' if number_selected(api, section, members) > remaining_credits(api, section) 

      members = [*members]
      data = api.perform_query("ext/members/sms/?action=sendText&sectionid=#{section.to_i}", {
        'msg' => message,
        'scouts' => [*members.map{ |m| m.to_i }].join(','),
        'source' => source_address,
        'type' => '',
      })

      if data.is_a?(Hash) && data['result']
        Osm::Model.cache_write(api, ['sms_credits', section.to_i], data['msg'].match(/\A[^\d]*(\d+)[^\d]*\Z/)[1])
        return true
      end
      return false
    end

    # Get the number of remaining SMS credits for a section
    # @param [Osm::Api] api The api to use to make the request
    # @param [Osm::Section, Fixnum, #to_i] section The section (or its ID) to send the message to
    # @!macro options_get
    # @return [Fixnum] the number of remaining SMS credits for the section
    def self.remaining_credits(api, section, options={})
      Osm::Model.require_access_to_section(api, section) 
      cache_key = ['sms_credits', section.to_i]

      if !options[:no_cache] && Osm::Model.cache_exist?(api, cache_key)
        return Osm::Model.cache_read(api, cache_key)
      end

      data = api.perform_query("ext/members/sms/?action=getNumbers&sectionid=#{section.to_i}&type=", {
        'scouts' => '0'
      })
      data = data['sms_remaining']

      Osm::Model.cache_write(api, cache_key, data)
      return data
    end

    # Get the number of SMS credits which will be used sending a message to the passed members
    # @param [Osm::Api] api The api to use to make the request
    # @param [Osm::Section, Fixnum, #to_i] section The section (or its ID) to send the message to
    # @param [Array<Osm::Member, Fixnum, #to_i>, Osm::Member, Fixnum, #to_i] members The members (or their IDs) to send the message to
    # @return [Fixnum] the number of SMS credits which will be used
    def self.number_selected(api, section, members)
      Osm::Model.require_access_to_section(api, section) 

      members = [*members]
      data = api.perform_query("ext/members/sms/?action=getNumbers&sectionid=#{section.to_i}&type=", {
        'scouts' => [*members.map{ |m| m.to_i }].join(',')
      })

      Osm::Model.cache_write(api, ['sms_credits', section.to_i], data['sms_remaining'])
      return data['numbers']
    end

    class DeliveryReport < Osm::Model
      VALID_STATUSES = [:sent, :not_sent, :delivered, :not_delivered, :invalid_destination_address, :invalid_source_address, :invalid_message_format, :route_not_available, :not_allowed]

      # @!attribute [rw] sms_id
      #   @return [Fixnum] the id of the SMS
      # @!attribute [rw] user_id
      #   @return [Fixnum] the id of the OSM user who sent the SMS
      # @!attribute [rw] member_id
      #   @return [Fixnum] the id of the member the SMS was sent to
      # @!attribute [rw] section_id
      #   @return [Fixnum] the id of the section 'owning' the SMS
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
      #   @return [Fixnum] thow many credits the SMS cost
      # @!attribute [rw] status
      #   @return [Symbol] the status of the SMS (usually :sent, :delivered, :not_delivered, :invalid_destination_address or :not_sent)

      attribute :sms_id, :type => Integer
      attribute :user_id, :type => Integer
      attribute :member_id, :type => Integer
      attribute :section_id, :type => Integer
      attribute :from_name, :type => String
      attribute :from_number, :type => String
      attribute :to_name, :type => String
      attribute :to_number, :type => String
      attribute :message, :type => String
      attribute :scheduled, :type => DateTime
      attribute :last_updated, :type => DateTime
      attribute :credits, :type => Integer
      attribute :status, :type => Object

      if ActiveModel::VERSION::MAJOR < 4
        attr_accessible :sms_id, :user_id, :member_id, :section_id, :from_name, :from_number, :to_name, :to_number, :message, :scheduled, :last_updated, :credits, :status
      end

      validates_numericality_of :sms_id, :only_integer=>true, :greater_than_or_equal_to=>0
      validates_numericality_of :user_id, :only_integer=>true, :greater_than_or_equal_to=>0
      validates_numericality_of :member_id, :only_integer=>true, :greater_than_or_equal_to=>0
      validates_numericality_of :section_id, :only_integer=>true, :greater_than_or_equal_to=>0
      validates_numericality_of :credits, :only_integer=>true, :greater_than_or_equal_to=>0
      validates_presence_of :from_name
      validates_presence_of :from_number
      validates_presence_of :to_name
      validates_presence_of :to_number
      validates_presence_of :message
      validates_presence_of :scheduled
      validates_presence_of :last_updated
      validates_inclusion_of :status, :in => VALID_STATUSES


      # @!method initialize
      #   Initialize a new Badge
      #   @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)


      # Get delivery reports
      # @param [Osm::Api] api The api to use to make the request
      # @param [Osm::Section, Fixnum, #to_i] section The section (or its ID) to get the reports for
      # @!macro options_get
      # @return [Array<Osm::Sms::DeliveryReport>]
      def self.get_for_section(api, section, options={})
        require_access_to_section(api, section, options)
        section_id = section.to_i
        cache_key = ['sms_delivery_reports', section_id]

        if !options[:no_cache] && Osm::Model.cache_exist?(api, cache_key)
          return cache_read(api, cache_key)
        end

        reports = []
        get_name_number_regex = /\A(?<name>.*\w)\W+(?<number>\d*)\Z/
        data = api.perform_query("sms.php?action=deliveryReports&sectionid=#{section_id}&dateFormat=generic")
        data['items'].each do |report|
          from = report['from'].match(get_name_number_regex)
          to = report['to'].match(get_name_number_regex)
          reports.push new(
            :sms_id => Osm.to_i_or_nil(report['smsid']),
            :user_id => Osm.to_i_or_nil(report['userid']),
            :member_id => Osm.to_i_or_nil(report['scoutid']),
            :section_id => Osm.to_i_or_nil(report['sectionid']),
            :from_name => from[:name],
            :from_number => "+#{from[:number]}",
            :to_name => to[:name],
            :to_number => "+#{to[:number]}",
            :message => report['message'],
            :scheduled => Osm.parse_datetime(report['schedule']),
            :last_updated => Osm.parse_datetime(report['lastupdated']),
            :credits => Osm.to_i_or_nil(report['credits']),
            :status => (report['status'] || 'error').downcase.to_sym,
          )
        end

        cache_write(api, cache_key, reports)
        return reports
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
