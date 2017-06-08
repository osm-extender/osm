module Osm
  class Member < Osm::Model
    class SecondaryContact < Osm::Member::PrimaryContact
      GROUP_ID = Osm::Member::GID_SECONDARY_CONTACT
    end
  end
end
