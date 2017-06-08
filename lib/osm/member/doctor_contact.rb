module Osm
  class Member < Osm::Model
    class DoctorContact < Osm::Member::Contact
      GROUP_ID = Osm::Member::GID_DOCTOR_CONTACT

      # @!attribute [rw] surgery
      #   @return [String] the surgery name
      attribute :surgery, type: String
    end
  end
end
