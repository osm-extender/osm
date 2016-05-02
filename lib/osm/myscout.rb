module Osm

  class Myscout

    class ParentLoginHistory < Osm::Model
      SORT_BY= [:last_name, :first_name, :member_id]

      # @!attribute [rw] member_id
      #   @return [Fixnum] the id for the member
      # @!attribute [rw] first_name
      #   @return [String] the member's first name
      # @!attribute [rw] last_name
      #   @return [String] the member's last name
      # @!attribute [rw] logins
      #   @return [Fixnum] the total number of logins
      # @!attribute [rw] last_login
      #   @return [DateTime] the time and date of the last login

      attribute :member_id, type: Integer
      attribute :first_name, type: String
      attribute :last_name, type: String
      attribute :logins, type: Integer
      attribute :last_login, type: DateTime

      validates_presence_of :first_name
      validates_presence_of :last_name
      validates_numericality_of :member_id, only_integer: true, greater_than: 0
      validates_numericality_of :logins, only_integer: true, greater_than_or_equal_to: 0


      # @!method initialize
      #   Initialize a new Member
      #   @param [Hash] attributes The hash of attributes (see attributes for descriptions, use Symbol of attribute name as the key)


      # Get parent login history
      # @param [Osm::Api] api The api to use to make the request
      # @param [Osm::Section, Fixnum, #to_i] section The section (or its ID) to get login history for
      # @!macro options_get
      # @return [Array<Osm::Myscout::ParentLoginHistory>]
      def self.get_for_section(api, section, options={})
        section_id = section.to_i
        require_ability_to(api, :read, :member, section, options)
        cache_key = ['myscout', 'parent_login_history', section_id]

        if !options[:no_cache] && cache_exist?(api, cache_key)
          return cache_read(api, cache_key)
        end

        data = api.perform_query("ext/settings/parents/loginhistory/?action=getLoginHistory&sectionid=#{section_id}")
        return [] unless data.is_a?(Hash)
        data = data['items']
        return [] unless data.is_a?(Array)

        data.map! do |item|
          new(
            member_id:    Osm::to_i_or_nil(item['scoutid']),
            first_name:   item['firstname'],
            last_name:    item['lastname'],
            logins:       Osm::to_i_or_nil(item['numlogins']),
            last_login:   get_last_login_date(item['lastlogin'],)
          )
        end

        cache_write(api, cache_key, data)
        return data
      end

      private
      def self.get_last_login_date(date_str)
        return nil if date_str.nil?
        return nil if date_str.eql?('Invitation not sent')
        Time.strptime(date_str, '%d/%m/%Y %H:%M')
      end

    end # class Myscout::ParentLoginHistory


    class Template < Osm::Model
      SORT_BY = [:key]

      TEMPLATES = [
        {title: "First payment email", id: "email-first", description: "This email is sent to the parents the first time that you request a payment from them. The message should introduce the system to them, explain the benefits that the parents and you get, and provide account details (by using the tags).", tags:[
          {id: "DIRECT_LINK", required: true, description: "A direct link to the payments page that avoids the need for the parents to login."},
          {id: "SCHEDULE_NAME", required: true, description: "The name of the first payment schedule that you have asked the parents to pay."},
          {id: "SCHEDULE_DESCRIPTION", required: false, description: "The description of the first payment schedule that you have asked the parents to pay."},
          {id: "SCHEDULE_PREAUTH", required: false, description: "The amount you are asking parents to pre-authorise."},
          {id: "MEMBER_FIRSTNAME", required: false, description: "The member's first name."},
          {id: "MEMBER_LASTNAME", required: false, description: "The member's last name."},
        ]},
        {title: "New schedule", id: "email-subsequent", description: "This email is sent every time you request the parents sign up to a payment schedule.", tags:[
          {id: "DIRECT_LINK", required: true, description: "A direct link to the payments page that avoids the need for the parents to login."},
          {id: "MEMBER_FIRSTNAME", required: false, description: "The member's first name."},
          {id: "MEMBER_LASTNAME", required: false, description: "The member's last name."},
          {id: "SCHEDULE_NAME", required: true, description: "The name of the payment schedule that you have asked the parents to pay."},
          {id: "SCHEDULE_DESCRIPTION", required: false, description: "The description of the payment schedule that you have asked the parents to pay."},
          {id: "SCHEDULE_PREAUTH", required: false, description: "The amount you are asking parents to pre-authorise."},
        ]},
        {title: "New payment (direct debit already setup)", id: "email-specificpayment-dd", description: "This email is sent to parents (who have already set up a direct debit) when their child has been set to pay a payment on a schedule that contains optional payments (i.e. events). It should simply notify them of the upcoming payment and give a link to the system.", tags:[
          {id: "DIRECT_LINK", required: true, description: "A direct link to the payments page that avoids the need for the parents to login."},
          {id: "MEMBER_FIRSTNAME", required: false, description: "The member's first name."},
          {id: "MEMBER_LASTNAME", required: false, description: "The member's last name."},
          {id: "PAYMENT_NAME", required: true, description: "The name of the specific payment (this is different to the schedule name)."},
          {id: "PAYMENT_DATE", required: true, description: "The date the payment process will be initiated."},
          {id: "PAYMENT_AMOUNT", required: true, description: "The amount that will be taken (a pound sign is automatically inserted)."},
          {id: "SCHEDULE_NAME", required: false, description: "The name of the payment schedule that you have asked the parents to pay."},
          {id: "SCHEDULE_DESCRIPTION", required: false, description: "The description of the payment schedule that you have asked the parents to pay."},
          {id: "SCHEDULE_PREAUTH", required: false, description: "The amount you are asking parents to pre-authorise."},
        ]},
        {title: "Payment notification for overdue payment", id: "email-immediatepayment-dd", description: "This email is sent to parents who have an active direct debit when their child has been marked as requiring a payment in the past to let them know that they are being charged immediately.", tags:[
          {id: "DIRECT_LINK", required: true, description: "A direct link to the payments page that avoids the need for the parents to login."},
          {id: "MEMBER_FIRSTNAME", required: false, description: "The member's first name."},
          {id: "MEMBER_LASTNAME", required: false, description: "The member's last name."},
          {id: "PAYMENT_NAME", required: true, description: "The name of the specific payment (this is different to the schedule name)."},
          {id: "PAYMENT_DATE", required: false, description: "The date the payment process will be initiated."},
          {id: "PAYMENT_AMOUNT", required: true, description: "The amount that will be taken (a pound sign is automatically inserted)."},
          {id: "SCHEDULE_NAME", required: false, description: "The name of the payment schedule that you have asked the parents to pay."},
          {id: "SCHEDULE_DESCRIPTION", required: false, description: "The description of the payment schedule that you have asked the parents to pay."},
          {id: "SCHEDULE_PREAUTH", required: false, description: "The amount you are asking parents to pre-authorise."},
        ]},
        {title: "Immediate payment request for overdue payment", id: "email-immediatepayment-nodd", description: "This email is sent to parents who have not got an active direct debit when their child has been marked as requiring a payment in the past to let them know that they need to pay immediately.", tags:[
          {id: "DIRECT_LINK", required: true, description: "A direct link to the payments page that avoids the need for the parents to login."},
          {id: "MEMBER_FIRSTNAME", required: false, description: "The member's first name."},
          {id: "MEMBER_LASTNAME", required: false, description: "The member's last name."},
          {id: "PAYMENT_NAME", required: true, description: "The name of the specific payment (this is different to the schedule name)."},
          {id: "PAYMENT_DATE", required: false, description: "The date the payment process will be initiated."},
          {id: "PAYMENT_AMOUNT", required: true, description: "The amount that will be taken (a pound sign is automatically inserted)."},
          {id: "SCHEDULE_NAME", required: false, description: "The name of the payment schedule that you have asked the parents to pay."},
          {id: "SCHEDULE_DESCRIPTION", required: false, description: "The description of the payment schedule that you have asked the parents to pay."},
          {id: "SCHEDULE_PREAUTH", required: false, description: "The amount you are asking parents to pre-authorise."},
        ]},
        {title: "New payment (direct debit not setup)", id: "email-specificpayment-nodd", description: "This email is sent to parents (who have *not* set up a direct debit) when their child has been asked to pay for an individual entry on a schedule. The message should ask the parents to sign up to a direct debit, or optionally, remind them to pay you via cash/cheque etc.", tags:[
          {id: "DIRECT_LINK", required: true, description: "A direct link to the payments page that avoids the need for the parents to login."},
          {id: "MEMBER_FIRSTNAME", required: false, description: "The member's first name."},
          {id: "MEMBER_LASTNAME", required: false, description: "The member's last name."},
          {id: "PAYMENT_NAME", required: true, description: "The name of the specific payment (this is different to the schedule name)."},
          {id: "PAYMENT_DATE", required: true, description: "The date the payment is due."},
          {id: "PAYMENT_AMOUNT", required: true, description: "The amount that will be taken (a pound sign is automatically inserted)."},
          {id: "SCHEDULE_NAME", required: false, description: "The name of the payment schedule that you have asked the parents to pay."},
          {id: "SCHEDULE_DESCRIPTION", required: false, description: "The description of the payment schedule that you have asked the parents to pay."},
          {id: "SCHEDULE_PREAUTH", required: false, description: "The amount you are asking parents to pre-authorise."},
        ]},
        {title: "Payment initiated", id: "email-initiated", description: "This email is sent to parents when a payment is initiated by the system.", tags:[
          {id: "DIRECT_LINK", required: true, description: "A direct link to the payments page that avoids the need for the parents to login."},
          {id: "MEMBER_FIRSTNAME", required: false, description: "The member's first name."},
          {id: "MEMBER_LASTNAME", required: false, description: "The member's last name."},
          {id: "PAYMENT_NAME", required: false, description: "The name of the specific payment (this is different to the schedule name)."},
          {id: "PAYMENT_DATE", required: false, description: "The date the payment is due."},
          {id: "PAYMENT_AMOUNT", required: false, description: "The amount that will be taken (a pound sign is automatically inserted)."},
          {id: "SCHEDULE_NAME", required: false, description: "The name of the payment schedule that you have asked the parents to pay."},
          {id: "SCHEDULE_DESCRIPTION", required: false, description: "The description of the payment schedule that you have asked the parents to pay."},
          {id: "SCHEDULE_PREAUTH", required: false, description: "The amount you are asking parents to pre-authorise."},
        ]},
        {title: "Payment reminder", id: "email-paymentreminder", description: "This is send periodically after the due date when the payment has not been made. The frequency of the emails is configurable in the My.SCOUT section of the site.", tags:[
          {id: "DIRECT_LINK", required: true, description: "A direct link to the payments page that avoids the need for the parents to login."},
          {id: "MEMBER_FIRSTNAME", required: false, description: "The member's first name."},
          {id: "MEMBER_LASTNAME", required: false, description: "The member's last name."},
          {id: "PAYMENT_NAME", required: false, description: "The name of the specific payment (this is different to the schedule name)."},
          {id: "PAYMENT_DATE", required: false, description: "The date the payment is due."},
          {id: "PAYMENT_AMOUNT", required: false, description: "The amount that will be taken (a pound sign is automatically inserted)."},
          {id: "SCHEDULE_NAME", required: false, description: "The name of the payment schedule that you have asked the parents to pay."},
          {id: "SCHEDULE_DESCRIPTION", required: false, description: "The description of the payment schedule that you have asked the parents to pay."},
          {id: "SCHEDULE_PREAUTH", required: false, description: "The amount you are asking parents to pre-authorise."},
        ]},
        {title: "Introduction to payment system", id: "website-payments-index", description: "This text is shown on the parent website under the words \"What is this?\". It should be used to explain about this system and the benefits that the parents and leaders will get, and reassure the parents that it is a safe and secure system.", tags:[]},
        {title: "Instructions to click Pay Now/Subscribe", id: "website-payments-schedule", description: "This text is shown on the parent website on a payment schedules pages, above the subscribe button. It should direct the parents to click the Subscribe button to set up a direct debit, or Pay falsew buttons to pay for things individually.", tags:[]},
        {title: "Event invitation", id: "email-event", description: "This email is sent to the parents when you invite children to events in the Your Events area.", tags:[
          {id: "DIRECT_LINK", required: true, description: "A direct link to the payments page that avoids the need for the parents to login."},
          {id: "EVENT_NAME", required: false, description: "The name of the event"},
          {id: "EVENT_LOCATION", required: false, description: "The location of the event"},
          {id: "EVENT_COST", required: false, description: "The cost of the event"},
          {id: "EVENT_DATES", required: false, description: "The event dates - this will be formatted properly into \"DATE\", \"DATE at TIME\", \"From DATE to DATE\", \"From DATE at TIME to DATE at TIME\" etc."},
          {id: "EVENT_DETAILS", required: false, description: "This is the \"Details for My.SCOUT\" section of the event"},
          {id: "CONFIRMATION_DEADLINE", required: false, description: "The confirmation deadline - beyond which, parents will not be able to sign up through My.SCOUT"},
          {id: "MEMBER_FIRSTNAME", required: false, description: "The member's first name."},
          {id: "MEMBER_LASTNAME", required: false, description: "The member's last name."},
        ]},
        {title: "Event invitation reminder", id: "email-event-reminder", description: "This is a reminder email to ask the parents to let you know if their child is attending - the frequency and number of reminders is customisable in the My.SCOUT settings page.", tags:[
          {id: "DIRECT_LINK", required: true, description: "A direct link to the events page that avoids the need for the parents to login."},
          {id: "EVENT_NAME", required: false, description: "The name of the event"},
          {id: "EVENT_LOCATION", required: false, description: "The location of the event"},
          {id: "EVENT_COST", required: false, description: "The cost of the event"},
          {id: "EVENT_DATES", required: false, description: "The event dates - this will be formatted properly into \"on DATE\", \"on DATE at TIME\", \"from DATE to DATE\", \"from DATE at TIME to DATE at TIME\" etc."},
          {id: "EVENT_DETAILS", required: false, description: "This is the \"Details for My.SCOUT\" section of the event"},
          {id: "CONFIRMATION_DEADLINE", required: false, description: "The confirmation deadline - beyond which, parents will not be able to sign up through My.SCOUT"},
          {id: "MEMBER_FIRSTNAME", required: false, description: "The member's first name."},
          {id: "MEMBER_LASTNAME", required: false, description: "The member's last name."},
        ]},
        {title: "Event attendance reminder", id: "email-event-attendancereminder", description: "This is a reminder email to tell parents that their child is attending the event - the number of days before the event that this email is sent is customisable on a per-event basis on each event page.", tags:[
          {id: "DIRECT_LINK", required: false, description: "A direct link to the events page that avoids the need for the parents to login."},
          {id: "EVENT_NAME", required: false, description: "The name of the event"},
          {id: "EVENT_LOCATION", required: false, description: "The location of the event"},
          {id: "EVENT_DATES", required: false, description: "The event dates - this will be formatted properly into \"on DATE\", \"on DATE at TIME\", \"from DATE to DATE\", \"from DATE at TIME to DATE at TIME\" etc."},
          {id: "EVENT_DETAILS", required: false, description: "This is the \"Details for My.SCOUT\" section of the event"},
          {id: "CONFIRMATION_DEADLINE", required: false, description: "The confirmation deadline - beyond which, parents will not be able to sign up through My.SCOUT"},
          {id: "MEMBER_FIRSTNAME", required: false, description: "The member's first name."},
          {id: "MEMBER_LASTNAME", required: false, description: "The member's last name."},
        ]},
        {title: "Invitation to system", id: "email-invitation", description: "This email is sent to invite parents into the system - they will receive a private link that avoids the need to login.", tags:[
          {id: "DIRECT_LINK", required: true, description: "A direct link into the parent system that avoids the need for the parents to login."},
          {id: "MEMBER_FIRSTNAME", required: false, description: "The member's first name."},
          {id: "MEMBER_LASTNAME", required: false, description: "The member's last name."},
        ]},
        {title: "Parent rota reminder email", id: "email-rota-reminder", description: "This email informs parents that they are signed up to the rota and is sent the day before the meeting", tags:[
          {id: "PROGRAMME_TITLE", required: false, description: "The title of programme"},
          {id: "PROGRAMME_falseTES", required: false, description: "falsetes for parents"},
          {id: "PROGRAMME_WHEN", required: false, description: "Dates and if specified time of the programme meeting."},
          {id: "DIRECT_LINK", required: false, description: "A direct link to the programme page that avoids the need for the parents to login."},
          {id: "MEMBER_FIRSTNAME", required: false, description: "The member's first name."},
          {id: "MEMBER_LASTNAME", required: false, description: "The member's last name."},
        ]},
        {title: "Badge awarded email", id: "email-badge-awarded", description: "This email is sent to parents whenever badges have been awarded.", tags:[
          {id: "BADGE_LIST", required: true, description: "The list of badges that have been awarded."},
          {id: "DIRECT_LINK", required: false, description: "A direct link to the badges page on My.SCOUT that avoids the need for the parents to login."},
          {id: "MEMBER_FIRSTNAME", required: false, description: "The member's first name."},
          {id: "MEMBER_LASTNAME", required: false, description: "The member's last name."},
        ]},
        {title: "Request for census information", id: "email-census", description: "This is only sent when a leader clicks the 'Send My.SCOUT email' button in the census aggregator pages.", tags:[
          {id: "DIRECT_LINK", required: true, description: "A direct link to the census."},
          {id: "MEMBER_FIRSTNAME", required: true, description: "The member's first name."},
          {id: "MEMBER_LASTNAME", required: false, description:"The member's last name."},
        ]},
        {title: "Gift Aid Declaration", id: "email-giftaid", description: "This email asks parents to update their Gift Aid declaration details on My.SCOUT (this is a free feature for Gold users)", tags:[
          {id: "DIRECT_LINK", required: false, description: "A direct link to the programme page that avoids the need for the parents to login."},
          {id: "MEMBER_FIRSTNAME", required: false, description: "The member's first name."},
          {id: "MEMBER_LASTNAME", required: false, description: "The member's last name."},
        ]},
      ]

      VALID_TEMPLATE_IDS = TEMPLATES.map{ |t| t[:id] }


      # Get a template
      # @param [Osm::Api] api The api to use to make the request
      # @param [Osm::Section, Fixnum, #to_i] section The section (or its ID) to get login history for
      # @param [String] id The ID of the template to get
      # @!macro options_get
      # @return [String, nil]
      def self.get_template(api, section, id, options={})
        fail ArgumentError, "Invalid template ID: #{id.inspect}" unless VALID_TEMPLATE_IDS.include?(id)

        section_id = section.to_i
        require_ability_to(api, :read, :user, section, options)
        cache_key = ['myscout', 'template', section_id, id]

        if !options[:no_cache] && cache_exist?(api, cache_key)
          return cache_read(api, cache_key)
        end

        data = api.perform_query("ext/settings/parents/?action=getTemplate&key=#{id}&section_id=#{section_id}")
        content = data.is_a?(Hash) ? data['data'] : ''
        return nil if content.empty?

        cache_write(api, cache_key, content)
        return content
      end

      # Update a template in OSM
      # @param [Osm::Api] api The api to use to make the request
      # @param [Osm::Section, Fixnum, #to_i] section The section (or its ID) to get login history for
      # @param [String] id The ID of the template to get
      # @param [String] content The new content of the template
      # @return [Boolean] Wheter OSM reported the template as updated 
      def self.update_template(api, section, id, content)
        fail ArgumentError, "Invalid template ID: #{id.inspect}" unless VALID_TEMPLATE_IDS.include?(id)

        section_id = section.to_i
        require_ability_to(api, :write, :user, section)

        # Make sure required tags are present
        tags = Osm::Myscout::Template::TEMPLATES.find{ |t| t[:id].eql?(id) }[:tags]
        fail Osm::Error, "Couldn't find tags for template" if tags.nil?
        tags.select{ |tag| tag[:required] }.each do |tag|
          unless content.include?("[#{tag[:id]}]")
            message = "Required tag [#{tag[:id]}] not found in template content."
            fail ArgumentError, message
          end
        end

        data = api.perform_query('ext/settings/parents/?action=updateTemplate', {
          'section_id' => section_id,
          'key' =>        id,
          'value' =>      content
        })

        if data.is_a?(Hash) && data['status'] && data['data']
          cache_key = ['myscout', 'template', section_id, id]
          cache_write(api, cache_key, content)
          return true
        end

        return false
      end

      # Restore a template to OSM's default for it
      # @param [Osm::Api] api The api to use to make the request
      # @param [Osm::Section, Fixnum, #to_i] section The section (or its ID) to get login history for
      # @param [String] id The ID of the template to get
      # @param [String] content The new content of the template
      # @return [String, nil] The content of the template (nil if not restored)
      def self.restore_template(api, section, id)
        fail ArgumentError, "Invalid template ID: #{id.inspect}" unless VALID_TEMPLATE_IDS.include?(id)

        section_id = section.to_i
        require_ability_to(api, :write, :user, section)

        data = api.perform_query('ext/settings/parents/?action=restoreTemplate', {
          'section_id' => section_id,
          'key' =>        id,
        })

        if data.is_a?(Hash) && data['status']
          content = data['data']
          cache_key = ['myscout', 'template', section_id, id]
          cache_write(api, cache_key, content)
          return content
        end

        return nil
      end

    end # class Myscout::Template

  end
   
end
