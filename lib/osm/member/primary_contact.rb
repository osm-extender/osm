module OSM
  class Member < OSM::Model
    class PrimaryContact < OSM::Member::Contact
      include EnableableEmailableContact
      include EnableablePhoneableContact

      GROUP_ID = OSM::Member::GID_PRIMARY_CONTACT

      # @!attribute [rw] email_1
      #   @return [String] the primary email address for the contact
      # @!attribute [rw] email_2
      #   @return [String] the secondary email address for the contact
      # @!attribute [rw] receive_email_1
      #   @return true, false whether the contact should receive emails from leaders on their primary email address
      # @!attribute [rw] receive_email_2
      #   @return true, false whether the contact should receive emails from leaders on their secondary email address
      # @!attribute [rw] receive_phone_1
      #   @return true, false whether the contact should receive SMSs from leaders on their primary phone number
      # @!attribute [rw] receive_phone_2
      #   @return true, false whether the contact should receive SMSs from leaders on their secondary phone number

      attribute :email_1, type: String
      attribute :receive_email_1, type: Boolean, default: false
      attribute :email_2, type: String
      attribute :receive_email_2, type: Boolean, default: false
      attribute :receive_phone_1, type: Boolean, default: false
      attribute :receive_phone_2, type: Boolean, default: false

      validates_inclusion_of :receive_email_1, in: [true, false]
      validates_inclusion_of :receive_email_2, in: [true, false]
      validates_inclusion_of :receive_phone_1, in: [true, false]
      validates_inclusion_of :receive_phone_2, in: [true, false]
    end
  end
end
