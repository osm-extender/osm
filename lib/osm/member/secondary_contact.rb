module OSM
  class Member < OSM::Model
    class SecondaryContact < OSM::Member::PrimaryContact
      GROUP_ID = OSM::Member::GID_SECONDARY_CONTACT
    end
  end
end
