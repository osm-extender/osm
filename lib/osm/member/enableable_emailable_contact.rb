module Osm
  class Member < Osm::Model
    module EnableableEmailableContact
      include EmailableContact

      # Get an array of enabled emails for the contact
      # @return [Array<String>]
      def enabled_emails
        emails = []
        emails.push email_1 if receive_email_1
        emails.push email_2 if receive_email_2
        emails.select{ |e| !e.blank? }
      end

      # Get an array of enabled emails for the contact in a format which includes their name
      # @return [Array<String>]
      def enabled_emails_with_name
        emails = []
        emails.push email_1 if receive_email_1
        emails.push email_2 if receive_email_2
        emails.select{ |e| !e.blank? }.map{ |e| "\"#{name}\" <#{e}>" }
      end

    end
  end
end
