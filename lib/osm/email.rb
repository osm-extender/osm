module Osm
  class Email
    TAGS = [{ id: 'FIRSTNAME', description: "Member's first name" }, { id: 'LASTNAME', description: "Member's last name" }].freeze

    # Get a list of selected email address for selected members ready to pass to send_email method
    # @param api [Osm::Api] The api to use to make the request
    # @param section [Osm::Section, Integer, #to_i] The section (or its ID) to send the message to
    # @param contacts [Array<Symbol>, Symbol] The contacts to get for members (:primary, :secondary and/or :member)
    # @param members [Array<Osm::Member, Integer, #to_i>] The members (or their IDs) to get the email addresses for
    # @return [Hash] member_id -> {firstname [String], lastname [String], emails [Array<String>]}
    def self.get_emails_for_contacts(api:, section:, contacts:, members:)
      # Convert contacts into OSM's format
      contacts = [*contacts]
      fail ArgumentError, 'You must pass at least one contact' if contacts.none?
      contact_group_map = {
        primary: '"contact_primary_1"',
        secondary: '"contact_primary_2"',
        member: '"contact_primary_member"'
      }
      contacts.map! do |contact|
        mapped = contact_group_map[contact]
        fail ArgumentError, "Invalid contact - #{contact.inspect}" if mapped.nil?
        mapped
      end

      # Convert member_ids to array of numbers
      members = [*members]
      fail ArgumentError, 'You must pass at least one member' if members.none?
      members.map! { |member| member.to_i }

      data = api.post_query("/ext/members/email/?action=getSelectedEmailsFromContacts&sectionid=#{section.to_i}&scouts=#{members.join(',')}", post_data: {
        'contactGroups' => "[#{contacts.join(',')}]"
      })
      if data.is_a?(Hash)
        data = data['emails']
        return data if data.is_a?(Hash)
      end
      false
    end

    # Get a list of selected email address for selected members ready to pass to send_email method
    # @param api [Osm::Api] The api to use to make the request
    # @param section [Osm::Section, Integer, #to_i] The section (or its ID) to send the message to
    # @param to [Hash] Email addresses to send the email to: member_id -> {firstname [String], lastname [String], emails [Array<String>]}
    # @param cc [String, nil] Email address (if any) to cc
    # @param from [String] Email address to send the email from
    # @param subject [String] Email subject The subject of the email
    # @param body [String] Email body The bosy of the email
    # @return true, false Whether OSM reported the email as sent
    def self.send_email(api:, section:, to:, cc: '', from:, subject:, body:)
      data = api.post_query('ext/members/email/?action=send', post_data: {
        'sectionid' => section.to_i,
        'emails' => to.to_json,
        'scouts' => to.keys.join(','),
        'cc' => cc,
        'from' => from,
        'subject' => subject,
        'body' => body
      })

      data.is_a?(Hash) && data['ok']
    end

  end
end
