module OSM
  class Member < OSM::Model
    module OSM::Member::EmailableContact

      # Get an array of all emails for the contact
      # @return [Array<String>]
      def all_emails
        [email_1, email_2].select { |e| !e.blank? }
      end

      # Get an array of all emails for the contact in a format which includes their name
      # @return [Array<String>]
      def all_emails_with_name
        [email_1, email_2].reject { |e| e.blank? }.map { |e| "\"#{name}\" <#{e}>" }
      end

    end
  end
end
