module Osm
  class Member < Osm::Model
    class Contact < Osm::Model
      # @!attribute [rw] first_name
      #   @return [String] the contact's first name
      # @!attribute [rw] last_name
      #   @return [String] the contact's last name
      # @!attribute [rw] address_1
      #   @return [String] the 1st line of the address
      # @!attribute [rw] address_2
      #   @return [String] the 2nd line of the address
      # @!attribute [rw] address_3
      #   @return [String] the 3rd line of the address
      # @!attribute [rw] address_4
      #   @return [String] the 4th line of the address
      # @!attribute [rw] postcode
      #   @return [String] the postcode of the address
      # @!attribute [rw] phone_1
      #   @return [String] the primary phone number
      # @!attribute [rw] phone_2
      #   @return [String] the secondary phone number
      # @!attribute [rw] additional_information
      #   @return [DirtyHashy] the additional information (key is OSM's variable name, value is the data)
      # @!attribute [rw] additional_information_labels
      #   @return [DirtyHashy] the labels for the additional information (key is OSM's variable name, value is the label)

      attribute :first_name, type: String
      attribute :last_name, type: String
      attribute :address_1, type: String
      attribute :address_2, type: String
      attribute :address_3, type: String
      attribute :address_4, type: String
      attribute :postcode, type: String
      attribute :phone_1, type: String
      attribute :phone_2, type: String
      attribute :additional_information, type: Object, default: DirtyHashy.new
      attribute :additional_information_labels, type: Object, default: DirtyHashy.new

      # @!method initialize
      #   Initialize a new Contact
      #   @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)

      # Get the full name
      # @param seperator [String] What to split the contact's first name and last name with
      # @return [String] this scout's full name seperated by the optional seperator
      def name(seperator=' ')
        [first_name, last_name].select { |i| !i.blank? }.join(seperator)
      end

      # Get an array of all phone numbers for the contact
      # @return [Array<String>]
      def all_phones
        [phone_1, phone_2].select { |n| !n.blank? }.map { |n| n.gsub(/[^\d\+]/, '') }
      end

      # Update the contact in OSM
      # @param api [Osm::Api] The api to use to make the request
      # @param section [Osm::Member] The member to update the contact for
      # @param force true, false Whether to force updates (ie tell OSM every attribute changed even if we don't think it did)
      # @return true, false whether the member was successfully updated or not
      # @raise [Osm::ObjectIsInvalid] If the Contact is invalid
      def update(api:, member:, force: false)
        fail Osm::ObjectIsInvalid, 'member is invalid' unless valid?
        require_ability_to(api, :write, :member, member.section_id)

        attribute_map = {
          'first_name' => 'data[firstname]',
          'last_name' => 'data[lastname]',
          'surgery' => 'data[surgery]',
          'address_1' => 'data[address1]',
          'address_2' => 'data[address2]',
          'address_3' => 'data[address3]',
          'address_4' => 'data[address4]',
          'postcode' => 'data[postcode]',
          'phone_1' => 'data[phone1]',
          'receive_phone_1' => 'data[phone1_sms]',
          'phone_2' => 'data[phone2]',
          'receive_phone_2' => 'data[phone2_sms]',
          'email_1' => 'data[email1]',
          'receive_email_1' => 'data[email1_leaders]',
          'email_2' => 'data[email2]',
          'receive_email_2' => 'data[email2_leaders]'
        } # our name => OSM name

        data = {}
        attributes.keys.select { |a| !['additional_information', 'additional_information_labels'].include?(a) }.select { |a| force || changed_attributes.include?(a) }.each do |attr|
          value = send(attr)
          value = 'yes' if value.eql?(true)
          data[attribute_map[attr]] = value
        end
        additional_information.keys.select { |a| force || additional_information.changes.keys.include?(a) }.each do |attr|
          data["data[#{attr}]"] = additional_information[attr]
        end

        updated = true
        unless data.empty?
          result = api.post_query("ext/customdata/?action=update&section_id=#{member.section_id}", post_data: {
            'associated_id' => member.id,
            'associated_type' => 'member',
            'context' => 'members',
            'group_id' => self.class::GROUP_ID
          }.merge(data))
          updated = result.is_a?(Hash) && result['status'].eql?(true)
        end

        # Finish off
        if updated
          reset_changed_attributes
          additional_information.clean_up!
        end
        updated
      end

    end
  end
end
