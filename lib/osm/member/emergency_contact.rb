module OSM
  class Member < OSM::Model
    class EmergencyContact < OSM::Member::Contact
      include EmailableContact

      GROUP_ID = OSM::Member::GID_EMERGENCY_CONTACT

      # @!attribute [rw] email_1
      #   @return [String] the primary email address for the contact
      # @!attribute [rw] email_2
      #   @return [String] the secondary email address for the contact
      attribute :email_1, type: String
      attribute :email_2, type: String
    end
  end
end
