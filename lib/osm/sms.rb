module Osm
  class Sms

    # Send an SMS to some members on their enabled numbers
    # @param api [Osm::Api] the api to use to make the request
    # @param section [Osm::Section, Integer, #to_i] the section (or its ID) to send the message to
    # @param members [Array<Osm::Member, Integer, #to_i>, Osm::Member, Integer, #to_i] the members (or their IDs) to send the message to
    # @param source_address[String, #to_s] the number to claim the message is from
    # @param message [String, #to_s] the text of the message to send
    # @return true, false whether the messages were sent
    # @raise [Osm::Error] if the section doesn't have enough credits to send the message
    def self.send_sms(api:, section:, members:, source_address:, message:)
      Osm::Model.require_access_to_section(api: api, section: section)
      fail Osm::Error, 'You do not have enough credits to send that message.' if number_selected(api: api, section: section, members: members) > remaining_credits(api: api, section: section) 

      members = [*members]
      data = api.post_query("ext/members/sms/?action=sendText&sectionid=#{section.to_i}", post_data: {
        'msg' => message,
        'scouts' => [*members.map{ |m| m.to_i }].join(','),
        'source' => source_address,
        'type' => '',
      })

      if data.is_a?(Hash) && data['result']
        Osm::Model.cache_write(api: api, key: ['sms_credits', section.to_i], data: data['msg'].match(/\A[^\d]*(\d+)[^\d]*\Z/)[1])
        return true
      end
      return false
    end

    # Get the number of remaining SMS credits for a section
    # @param api [Osm::Api] the api to use to make the request
    # @param section [Osm::Section, Integer, #to_i] the section (or its ID) to send the message to
    # @!macro options_get
    # @return [Integer] the number of remaining SMS credits for the section
    def self.remaining_credits(api:, section:, no_read_cache: false)
      Osm::Model.require_access_to_section(api, section)
      cache_key = ['sms_credits', section.to_i]

      Osm::Model.cache_fetch(api: api, key: cache_key, no_read_cache: no_read_cache) do
        data = api.post_query("ext/members/sms/?action=getNumbers&sectionid=#{section.to_i}&type=", post_data: {
          'scouts' => '0'
        })
        data['sms_remaining']
      end # cache fetch
    end

    # Get the number of SMS credits which will be used sending a message to the passed members
    # @param api [Osm::Api] the api to use to make the request
    # @param section [Osm::Section, Integer, #to_i] the section (or its ID) to send the message to
    # @param members [Array<Osm::Member, Integer, #to_i>, Osm::Member, Integer, #to_i] the members (or their IDs) to send the message to
    # @return [Integer] the number of SMS credits which will be used
    def self.number_selected(api:, section:, members:)
      Osm::Model.require_access_to_section(api: api, section: section) 

      members = [*members]
      data = api.post_query("ext/members/sms/?action=getNumbers&sectionid=#{section.to_i}&type=", post_data: {
        'scouts' => [*members.map{ |m| m.to_i }].join(',')
      })

      Osm::Model.cache_write(api: api, key: ['sms_credits', section.to_i], data: data['sms_remaining'])
      return data['numbers']
    end

  end
end
