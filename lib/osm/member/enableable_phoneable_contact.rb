module OSM
  class Member < OSM::Model
    module OSM::Member::EnableablePhoneableContact

      # Get an array of enabled phone numbers for the contact
      def enabled_phones
        phones = []
        phones.push phone_1.gsub(/[^\d\+]/, '') if receive_phone_1
        phones.push phone_2.gsub(/[^\d\+]/, '') if receive_phone_2
        phones.reject { |n| n.blank? }.map { |n| n }
      end

    end
  end
end
