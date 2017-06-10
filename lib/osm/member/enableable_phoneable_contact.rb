module Osm
  class Member < Osm::Model
    module Osm::Member::EnableablePhoneableContact

      # Get an array of enabled phone numbers for the contact
      def enabled_phones
        phones = []
        phones.push phone_1.gsub(/[^\d\+]/, '') if receive_phone_1
        phones.push phone_2.gsub(/[^\d\+]/, '') if receive_phone_2
        phones.select { |n| !n.blank? }.map { |n| n }
      end

    end
  end
end
