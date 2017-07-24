module OSM
  class Member < OSM::Model
    class DoctorContact < OSM::Member::Contact
      GROUP_ID = OSM::Member::GID_DOCTOR_CONTACT

      # @!attribute [rw] surgery
      #   @return [String] the surgery name
      attribute :surgery, type: String
    end
  end
end
