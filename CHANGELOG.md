## Version 2.0.0

  * Osm module is now OSM
  * Error hierarchy changed:
    * APIError < RuntimeError
      * InvalidUser
      * ConnectionError
      * UnexpectedType
    * OSMError < RuntimeError
      * Forbidden
      * ReadOnly
      * NoActiveRoles
      * NoCurrentTerm
      * NotFound
    * Error < RuntimeError
      * InvalidObject < RuntimeError
  * Remove support for ruby <= 2.2.5, jruby, rails < 4
  * Add support for ruby 2.4.0
  * Remove dependancy on active_support and httparty gems
  * Model is now configured through Osm::Model.configure
  * Model now has class accessors for cache, cache_ttl and prepend_to_cache_key attributes
  * Now supports cache fetching
  * Methods now use keyword arguments except where it makes sense (ie only 1 argument)
  * Osm::ConnectionError - messages are now more descriptive
  * Osm::Api instances now have an http_user_agent attribute
  * no_cache option is now no_read_cache
  * Osm::Badges stuff has moved to Osm::Badge
  * Add rubies 2.3.2 and 2.3.3 to travis config

## Version 1.3.0

  * Add fetching of file names for events (unable to download)
  * Add fetching of payment schedules - Osm::OnlinePayment::Schedule
  * Add fetching of member's payments for a schedule
  * Add updating a member's payment status

## Version 1.2.25

  * Add fetching My.SCOUT parent login history - Osm::Myscout::ParentLoginHistory.get_for_section
  * Add fetching and updating of My.SCOUT templates
  * Add fetching of email delivery reports -> Osm::Email::Delivery class and subclasses
  * Send an email through OSM (use Osm::Email.get_emails_for_contacts method to get the value for Osm::Email.send_email method's send_to parameter).

## Version 1.2.24

  * Fix detection of no roles in api.get_user_roles!

## Version 1.2.23

  * Geting list of user roles for getting sections and permissions now done using the get_user_roles method of api instances
  * When user has no roles in OSM:
    * get_user_roles will return an empty Array
    * get_user_roles! (new method) will raise an Osm::NoActiveRoles exception
  * Fix 'undefined local method or variable fetch_from_osm' when retrieving badges

## Version 1.2.22

 * Fix marking badge as due when not passing a level

## Version 1.2.21

  * Fix updating requirement data of a Osm::Badge::Data to a blank string incorrectly returns false when the update was made into OSM
  * Fix updating additional details for a Osm::Member to a blank string incorrectly returns false when the update was made into OSM

## Version 1.2.20

  * Fix to OSM changing the URL to get API permissions from

## Version 1.2.19

  * Fix validity checks for member in rails 3

## Version 1.2.18

  * Add gem version into the cache key
  * Osm::Section - removal of column_names, fields, intouch_fields, mobile_fields and sms_* attributes
  * Osm::Member - lots of changes to reflect OSM's new structure for member's details (main ones listed below):
    * Removal of type attribute (I never could work out what it represented)
    * Removal of data attributes except:
      * id
      * section_id
      * first_name
      * last_name
      * date_of_birth
      * grouping_id
      * grouping_leader
      * age
    * Addition of attibutes:
      * gender (Symbol - :male, :female, :other or :unspecified)
      * finished_section (Date, nil)
      * additional_information (DirtyHashy) - The customisable data part from OSM
      * additional_information_labels (DirtyHashy) - The labels which belong to the data in custom
      * primary_contact, secondary_contact, emergency_contact and doctor - the relevant parts from OSM
      * grouping_label
      * grouping_leader_label
    * Renamed attributes:
      * started becomes joined_movement
      * joined becomes started_section
    * New helper methods:
      * male?
      * female?
      * current?(date=Date.today) - is the member a member of the section on the passed date
      * all_emails, all_emails_with_name, enabled_emails, enabled_emails_with_name
      * all_phones, enabled_phones
    * Validation changes:
      * age should now be in the format 'yy / mm' not 'yy/mm'
  * Osm::Sms:
    * send_sms method losses mobile_numbers argumant (OSM now sends to all enabled numbers for all contacts for the member)
    * send_sms method now just returns a boolean to indicate success/failure
    * Addition of remaining_credits(api, section, options={}) method
    * Addition of number_selected(api, section, members, options={}) method to tell how many numbers a message would be sent to
  * Add :migration as an API target

## Version 1.2.17

  * Update to match how OSM now lists activities within meetings.

## Version 1.2.16

  * Osm::Section gains instance methods:
    * bronze?
    * silver?
    * gold?
    * gold_plus?
    * subscription_at_least?(level)
  * Osm::SUBSCRIPTION_LEVEL_NAMES is now a Hash not an Array

## Version 1.2.15

  * Add support for census and giftaid link generation for members
  * Add :osm_staging as a site to point the gem at. Really only useful for gem development.
  * Update to match OSM's new badge system:
    * Retrieving badge stock
    * Updating badge stock
    * Fetching badge data
    * Fetching due badges (added stock_levels attribute, since OSM now gives it)
    * Fetching & updating badge links for Events
    * Fetching & updating badge links for Activities
    * Fetching & updating badge links for Meetings
    * Summary now returns all started/completed/awarded badges (it can't filter by type) so can only be called from Osm::Badge
    * Osm::Badge
      * osm_key, osm_long_key and competion criteria attributes are gone
      * id, version, identifier, group_name, latest, user_id, levels, sharing attributes added
      * min_modules_required, min_requirements_required, add_columns_to_module, level_requirement, other_requirements_required, badges_required, show_level_letters, requires_modules and modules attributes added
      * OSM Changed how completion criteria are retrieved (this gem now uses a special peice of OSM's API just for this purpose) so:
      * attributes sections_needed, total_needed and needed_from_section are gone
      * New methods modules, module_letters, module_ids and add_columns?
    * Osm::Badge::Data
      * mark_awarded method now only marks as awarded (the optional mark_as parameter is gone)
      * mark_not_awarded method added
      * mark_due and mark_not_due methods added
      * completed attribute renamed to due
      * sections_gained method renamed to modules_gained, now returns an array of letters
      * gained_in_sections renamed to gained_in_modules
    * Osm::Badge::Requirement gains a mod attribute to hold the Osm::Badge::RequirementModule
    * Osm::Badge::RequirementModule added
    * Osm::Event::BadgeLink
      * Attributes added: badge_name, badge_id, badge_version, requirement_id
      * Attributes removed: badge_label, badge_key, requirement_key
      * Attributes untouched: badge_type, badge_section, data, requirement_label
    * Osm::Activity::Badge attributes now match Osm::Event::BadgeLink
    * Osm::Meeting::BadgeLink attributes now match Osm::Event::badgeLink
    * Osm::Badges.get_badge_stock returns a Hash, keys are now "#{badge_id}_#{level}"
    * Osm::Badge::Data instance method requirement_met?(field_id) method made public

## Version 1.2.14

  * Fix fetching sections when user doesn't have access to any

## Version 1.2.13

  * Fix event.get_attendance ignoring term in building the cache key

## Version 1.2.12

 * Add leader? method to member (true if member is in the leaders grouping)
 * Add youth? method to member (true if member is in a non-leaders grouping)
 * Adjust Osm::Event::BadgeLink attributes (label becomes requirement_label, add badge_label)

## Version 1.2.11

 * Fix handling blank event config from OSM (JSON parse error)
 * Add retrieving of badge links to events
 * When creating an event in OSM badge links are also added
 * When updating an event in OSM badge links are also updated
 * Add get_list method to Event (get basic event details, should cutout the need to get all events all the time)

## Version 1.2.10

 * Update levels for Hikes and Nights away staged badges (released April 2014)
 * Add levels for new Time on the water staged badge (released April 2014)

## Version 1.2.9

 * Add osm_long_key to badges to make getting badge stock easier

## Version 1.2.8

  * api.get_user_permissions now includes the quartermaster permission
  * Fix administer permission level excluded from ApiAccess

## Version 1.2.7

  * Fix can't compare exception when a FlexiRecord has a nil name.

## Version 1.2.6

  * Update dependancies to allow using with a rails 4 app (rails 3 is still tested against by travis)

## Version 1.2.5

  * Fix undefined local variable or method 'section_id' in Osm::Model require_permission

## Version 1.2.4

  * Remove support for ruby 1.9.2 (listen gem requires >= 1.9.3)
  * Activity's get_badge_requirements method now will iterate through activities if there's no permission to use the existing one OSM query trick
  * Fix exception when OSM returns a number (instead of a string) for total/completed columns of a flexi record

## Version 1.2.3

  * Fix bug determining if a badge has been earnt (-1 sections required = all required)

## Version 1.2.2

  * Add base_url method to Api class and instances
  * Add get_photo method to member
  * Add earnt and earnt? methods to Osm::Badge::Data to get the stage which has been earnt (based on the requirements hash)

## Version 1.2.1

  * Add section_id read-only attribute to Osm::Error::NoCurrentTerm

## Version 1.2.0

  * Trying to fetch the currrent Term for a Section which doesn;t have one now raises an Osm::Error::NoCurrentTerm instead of an Osm::Error 
  * Add personal details options to Section:
    * myscout_details attribute [Boolean] for whether personal details are enabled
    * myscout_details_expires attribute [Date] for expiry date of subscription
    * myscout_details_email_changes_to attribute [String] where to send update emails to
  * Osm::Member
    * myscout_link method now accepts :details to get a link to the "Perosnal details" page
    * myscout_link method can now link to a specific event by also passing in the id (optional 3rd parameter)
    * Addition of myscout_link_key method to get the member's unique key for use in myscout links
  * Osm::Section
    * subscription_level_name method is marked as depricated, ready for removal in version 2.0 -> replace with Osm::SUBSCRIPTION_LEVEL_NAMES[section.subscription_level]
    * myscout_programme_show attribute added - how much of the programme do parents see?
  * Addition of two new constants:
    * Osm::SUBSCRIPTION_LEVEL_NAMES - an Array of Strings containing the human name of each subscription level (starts with "Unknown" to make indexing work nicely)
    * Osm::SUBSCRIPTION_LEVELS - an Array of Symbols for each level (starts with nil to make indexing work nicely)
  * Register - get_structure now only includes dates
  * Addition of attendance_reminder attribute to event
  * Abillity to send Sms messages to multiple numbers
  * Add Gift Aid:
    * Get Payments
    * Update Payments
    * Get Payment/Member Data
    * Update Payment/Member Data
  * Add Finances:
    * Budget (Get, Add, Update, Delete)
    * Invoices (Get, Add, Update, Delete)
    * Invoice Items (Get, Add, Update, Delete)

## Version 1.0.6

  * Add badge_links to Meeting
  * Event.add_column method gains a required attirbute (default false) to control whether parents are required to enter something
  * Event::Column gains parent_required attribute (default false)
  * Event::Attendance gains get_audit_trail(api) method

## Version 1.0.5

  * Fix undefined method youth_section? within Model.require_ability_to

## Version 1.0.4

  * Add notice board option to getting My.SCOUT link for a member (pass :notice as the parameter)
  * Model.require_ability_to now only checks subscription level for youth sections

## Version 1.0.3

  * Fix "undefined method 'downcase' for 0:Fixnum" caused by some badge requirement data being a Fixnum when a String contains just numbers.
  * Update to use ActiveAttr gem version 0.8

## Version 1.0.2

  * Fix Regex for checking dates from OSM
  * Don't use ActiveAttr >= 0.8 (incompatabillity to be fixed)

## Version 1.0.1

  * Fix Osm::Term date helping methods when term contains nil dates
  * Fix fetching event attendance when no attendance has been set for any members
  * Osm::Api exposes the debug option as a psudo class attribute

## Version 1.0.0

  * SMS text messages:
    * Section gains sms_sent_test, sms_messages_sent and sms_messages_remaining attributes
    * Add Sms class:
      * With send_sms(api, section_id, member_ids, all_or_one, source_address, message) method
      * With DeliveryReport Model subclass
        * With get_for_section(api, section) class method

## Version 0.6.3

  * Fix started? and started methods for badges with a combination of custom and normal requirements

## Version 0.6.2

  * Fix items not relevant to API appearing in permissions for a Section
  * Fix started and started? methods for staged badges which have been completly done

## Version 0.6.1

  * Fixes to adventure badges

## Version 0.6.0

  * Badge::Data
    * completed attribute is now a Fixnum not Boolean (fixes staged badges)
    * Add awarded attribute (the last level awarded)
    * Add due? method to tell if the badge is due
    * Add started? method to tell if the badge has been started
    * Add started method to tell which stage has been started
    * Add first_name and last_name attributes
    * Add mark_awarded method
    * Add mark_due method
  * Badge
    * Make get_badge_data_for_section an instance not class method (called get_data_for_section)
    * Add get_summary_for_section(api, section, term=nil, options={}) method
    * Add optional section_type parameter to get_badges_for_section method

## Version 0.5.0

  * Code breaking changes to DueBadges:
    * The by_member attribute now uses scout_id as the key
    * Addition of member_names attribute to allow fetching of members names (the old key for the by_member attribute)
    * descriptions attribute has been renamed to badge_names for consistency
  * Code breaking changes to Register and subclasses:
    * Register:
      * update_attendance - :attendance option is now a Symbol not String (:yes, :unadvised_absent or :advised_absent)
    * Register::Attendance:
      * attendance attribute is now a Hash of Date to Symbol (instead of to String)
  * Register::Attendance gains two helper methods:
    * present_on?(date)
    * absent_on?(date)
  * Add allow_booking attribute to Event
  * Add myscout_programme_times attribute to Section
  * Cost attribute of Event is now checked to be either "TBC" or formatted to /\\A\\d+\\.\\d{2}\\Z/
  * Add cost_tbc? method to Event
  * Add cost_free? method to Event

## Version 0.4.2

  * Fix undefined variable "section_id" when fetching notepad from cache

## Version 0.4.1

  * Fix not handling of Event's config not being an Array of Hash
  * Fix undefined 'Osm::FlexiRecord' from within Section (intermittent bug)

## Version 0.4.0

  * Event::Attendance
    * Move fields['firstname'] to first_name attribute
    * Move fields['lastname'] to last_name attribute
    * Move fields['dob'] to date_of_birth attribute
    * Move fields['attending'] to attending attribute
    * The keys for fields are now Fixnums not Strings
    * Addition of payment_control and payments attributes
    * Addition of automatic_payments? and manual_payments? methods
    * Addition of is_attending?, is_not_attending?, is_invited? and is_shown? methods
    * update(api, field_id) method now updates only changed fields, becoming update(api)
  * Add :network Section type
  * Add custom inspect methods for:
    * Event::Attendance (replace event with event.id if present)
    * Event::Column (replace event with event.id if present)
    * FlexiRecord::Column (replace flexi_record with flexi_record.id)
    * FlexiRecord::Data (replace flexi_record with flexi_record.id)
    * Badge::Requirement (replace badge with badge.osm_key)
    * Badge::Data (replace badge with badge.osm_key)

## Version 0.3.0

  * Removal of DueBadges
  * Removal of get_badge_stock method from sections
  * Addition of Badges model:
    * With get_due_badges(api, section, options={}) method
    * With get_stock(api, section, options={}) method
    * With update_stock(api, section, badge_key, stock_level) method
  * Addition of Badge models:
    * CoreBadge
    * ChallengeBadge
    * StagedBadge
    * ActivityBadge
    * All:
      * Inherit from Badge (do not use this class directly)
      * With get_badges_for_section(api, section, options={}) method
      * With get_badge_data_for_section(api, section, badge, term=nil, options={}) method
  * Addition of Badge::Requirements class
  * Addition of Badge::Data class
    * With update(api) method
    * With total_gained method
    * With sections_gained method
    * With gained_in_sections method
  * FlexiRecord::Data now updates only changed fields

## Version 0.2.2

  * Add comparing and sorting (using <=>, <, <=, >, >= and between?) to each model
    * Activity - id then version
    * Activity::File - activity_id then name
    * Activity::Version - activity_id then version
    * ApiAccess - id
    * Event - start, name then id (shortcuts, returning 0 if ids are equal)
    * Event::Column - event then id
    * Event::Attendance - event then row
    * FlexiRecord - section_id then name
    * FlexiRecord::Column - flexi_record then id (system ones first then user ones)
    * FlexiRecord::Data - flexi_record, grouping_id then member_id
    * Grouping - section_id then name
    * Meeting - section_id, date, start_time then id
    * Meeting::Activity - title then activity_id
    * Member - section_id, grouping_id, grouping_leader (descending), last_name then first_name
    * Register::Field - id
    * Register::Attendance - section_id, grouping_id, last_name then first_name
    * Section - group_name, type (by age) then name
    * Term - section_id, start then id

## Version 0.2.0

  * Raises Forbidden exception if:
    * You try to use a feature which requires an OSM subscription above your current one
    * You try to access a feature which you don't have the correct permissions for
    * You try to access a Section (or it's Grouping) you shouldn't be accessing
  * All Model classes:
    * Addition of changed_attributes method to get a list of attributes which have changed
    * Addition of reset_changed_attributes method to reset the list of attributes which have changed
  * Activity
    * Check user has permission to view before returning from cache
    * Addition of osm_link method to get the URL for viewing in OSM
  * Add updating of Grouping
  * Evening:
    * Rename to Meeting
    * Rename meeting_date attribute to date
    * Rename get_programme method to get_for_section
  * Event:
    * Removal of add_field method (use add_column instead)
    * Removal of fields attribute (use columns instead)
  * FlexiRecord:
    * Addition of id, section_id and name attributes (these no longer need to be passed to methods)
    * FlexiRecord::Field renamed to FlexiRecord::Column
    * The following methods are now instance not class methods:
      * get_fields (also renamed to get_columns)
      * add_field (also renamed to add_column)
      * get_data
    * The following methods have bceome instance methods of a subclasses:
      * update_field (moved to column.update)
      * delete_field (moved to column.delete)
      * update_data (moved to data.update)
  * Member:
    * Removal of grouping attribute
    * Removal of grouping_label attribute
    * Addition of myscout_link method (used to get the link to the member's My.SCOUT page)
  * Section:
    * subscription_level attribute is now a Fixnum not Symbol
    * Addition of subscription_level_name method to get the name of the subscription level for the section
    * flexi_records attribute now contains an Array of Osm::FlexiRecord
  * "Under the hood" changes:
    * Instead of caching individual items and a list of items the gem now caches a list of IDs. This should reduce the cache size.
    * When updating items requires multiple OSM requests, now only updates what changed
    * Updating of cached data when deleting/updating items from OSM
>>>>>>> dev_v_0.2.0

## Version 0.1.17

  * Add comparison to Evening
  * Passing a Term to the get_programme method of Evening is now optional

## Version 0.1.16

  * Member's grouping attribute:
    * Renamed to grouping_label
    * Virtual attribute grouping added (maps to grouping_label currently) marked as depricated as it will use a Grouping object not a String in the future
  * Fix exception when OSM returns empty string when requesting groupings for a section
  * Fix exception when OSM returns empty string when requesting register structure for a section
  * Fix updating of grouping for Member
  * Fix validation error for Member - a leader's joining_in_years is -1
  * Add spaces and spaces? methods to Event

## Version 0.1.15

  * Rename grouping_name attribute of Member to grouping

## Version 0.1.14

  * Fix grouping_name attribute of Member not being set when getting data from OSM

## Version 0.1.13

  * Add attendance limit attributes to Event:
    * attendance_limit - Fixnum, 0 = no limit
    * attendance_limit_includes_leaders Boolean
  * Add limited_attendance? method to Event
  * Add setting of a section's notepad
  * Add updating of Activity
  * Add grouping_name attribute to Member

## Version 0.1.12

  * Attribute Section.myscout_email_address_send defaults to an empty String
  * Attribute Section.myscout_email_address_copy defaults to an empty String
  * Attribute Section.myscout_email_address_send renamed to myscout_email_address_from
  * Osm::Event::Column
    * Rename parent_label attribute to label
    * Add update method to update OSM
    * Add delete method to update OSM
  * Osm::Evening
    * Add delete method to update OSM
    * Changes to create method:
      * Now takes arguments of (api, parameters)
      * Now returns an Osm::Evening on success, nil on failure
      * Will now pass start time, finish time and title to OSM
  * Add activity to programme
      * Evening.add_activity(api, activity, notes="")
      * Activity.add_to_programme(api, section, date, notes="")
  * Osm::Member
    * Add create method to update OSM
    * Add update method to update OSM
  * Osm::FlexiRecord
    * Add add_field method to add a field to the record in OSM
    * Add update_field method to rename a field in OSM
    * Add delete_field method to delete a field from OSM
    * Add update_data method to update the data in OSM

## Version 0.1.11

  * Fix "can't convert Hash into String" occuring when some section's config is a Hash not a JSON encoded Hash
  * Remove num_scouts attribute from Section (OSM always sets this to 999)
  * Add My.SCOUT related attributes to Section:
    * gocardless (Boolean) - does the section use gocardless
    * myscout_events_expires (Date) - when the subscription to Events in My.SCOUT expires
    * myscout_badges_expires (Date) - when the subscription to Badges in My.SCOUT expires
    * myscout_programme_expires (Date) - when the subscription to Badges in My.SCOUT expires
    * myscout_events (Boolean) - whether the section uses the Events part of My.SCOUT
    * myscout_badges (Boolean) - whether the section uses the Badges part of My.SCOUT
    * myscout_programme (Boolean) - whether the section uses the Programme part of My.SCOUT
    * myscout_payments (Boolean) - whether the section uses the Payments part of My.SCOUT
    * myscout_emails (Hash of Symbol to Boolean) - which email addresses are linked to MyScout for each Member
    * myscout_email_address_send (String, blank OK) - which email address to send My.SCOUT emails as
    * myscout_email_address_copy (String, blank OK) - which email address to send copys of My.SCOUT emails to
    * myscout_badges_partial (Boolean) - Whether parents can see partially completed badges
    * myscout_programme_summary (Boolean) - Whether parents can see the summary of programme items
    * myscout_event_reminder_count (Integer) - How many event reminders to send to parents who haven't responded
    * myscout_event_reminder_frequency (Integer) - How many days to leave between event reminder emails
    * myscout_payment_reminder_count (Integer) - How many payment reminders to send to parents who haven't paid yet
    * myscout_payment_reminder_frequency (Integer) - How many days to leave between payment reminder emails
  * Add new OSM attributes to Event:
    * notepad - the notepad shown in OSM
    * public_notepad - the notepad shown on My.SCOUT
    * confirm_by_date - the last day that parents can change their child's attendance details
    * allow_changes - whether parents can change their child's attendance details
    * reminders - whether reminder emails are sent
  * Osm::Event
    * Mark fields attribute as depricated
    * Add columns attribute returning an array of column details

## Version 0.1.10

  * Fix 'undefined variable' when getting an event's attendance without passing a term.

## Version 0.1.9

  * Fix fetching of members for a waiting list
  * Fix 'undefuned method' when creating an event without a start or finish datetime

## Version 0.1.8

  * Fix 'undefined local variable' when getting a section's notepad from the cache

## Version 0.1.7

  * Ignore sections of type discount - assuming they're a strange symtom of how OSM handles discount codes

## Version 0.1.6

  * Internal changes due to OSM adding total rows in register and fexi record data (the total rows are ignored)

## Version 0.1.5

  * Bug fixes.

## Version 0.1.4

  * Osm::Model has new class method get_user_permission(api, section_id, permission)
  * API may return permissions value as a string not integer

## Version 0.1.3

  * Add get_badge_stock(api) to section

## Version 0.1.2

  * Bug fixes

## Version 0.1.1

  * Add get_options Hash to Model.get_user_permissions
  * Bug fixes

## Version 0.1.0

  * Configuration is through Osm::configure not Osm::Api.configure and it takes a different Hash
  * Api.authorize returns a different Hash
  * Removal of Osm::Api methods:
    * get_*
    * update_*
    * create_*
  * EventAttendance is now Event::Attendance
  * Removal of Osm::Role
    * Osm::Section now has two new required attributes group_id and group_name
    * long_name and full_name methods should be replaced with something similar to "#{section.name} (#{section.group_name})" in your own code
    * Section has a class method fetch_user_permissions(api) which returns a Hash (section_id to permissions Hash)
  * Activity now has class method get(api, activity_id)
  * ApiAccess: now has class methods
    * get_all(api, section)
    * get(api, section, for_api)
    * get_ours(api, section) -> actually just calls get(api, section, api)
  * DueBadges now has a class method get(api, section)
  * Evening now has class methods:
    * get_programme(api, section_id, term_id)
    * create(api, parameters)
  * Evening now has instance methods:
    * update(api)
    * get_badge_requirements(api, evening)
  * Event now has class methods:
    * get_for_section(api, section)
    * get(api, section, event_id)
    * create(api)
  * Event now has instance methods:
    * update(api)
    * delete(api)
    * get_attendance(api)
    * add_field(api, label)
  * Event now has a fields attribute
  * Event::Attendance has instance method update(api, field_id)
  * FlexiRecord has class methods:
    * get_fields(api, section, flexi_record_id)
    * get_data(api, section, flexi_record_id, term)
  * Grouping now has a class method get_for_section(api, section)
  * Member now has a class method to get_for_section(api, section_id, term_id)
  * Register now has class methods:
    * get_structure(api, section)
    * get_attendance(api, section)
    * update_attendance(data)
  * Section now has class methods:
    * get_all(api)
    * get(api, section_id)
  * Section now has instance method get_notepad(api)
  * Term now has class methods:
    * get_all(api)
    * get(api, term_id)
    * get_for_section(api, section_id)
    * get_current_term_for_section(api, section_id)
    * create(api, parameters)
  * Term now has instance method update(api)

## Version 0.0.26

  * Register - Update attendance
    * Add api.get_badge_requirements_for_evening
    * Add api.update_register
  * Event:
    * Add api.ceate_event
    * Add api.update_event
    * Add api.delete_event
    * Add api.add_event_field
  * Event attendance:
    * Add api.get_event
    * Add api.get_event_fields
    * Add api.get_event_attendance
    * Add api.update_event_attendance
  * Fix "uninitialized constant Osm::Api::HTTParty"

## Version 0.0.25

  * FlexiRecordData, move these attributes to the fields hash:
    * first_name => 'firstname'
    * last_name => 'lastname'
    * age => 'age'
    * date_of_birth => 'dob'
    * completed => 'completed'
    * total => 'total'

## Version 0.0.24

  * Make Section::FlexiRecord sortable

## Version 0.0.23

  * get_badge_stock_levels now returns a hash whoose values are Fixnum not String

## Version 0.0.22

  * Adjustments so DueBadge is similar enough to badge_stock data to be useful:
    * by_member Hash -> Keys are member's name (String), values are the badge key (String)
    * descriptions Hash -> keys are the badge key (String), values are the badge name (String)
    * totals Hash -> keys are the badge key (String), values are the  number required (Fixnum)
    * Badge keys are the same as are used in getting badge stock levels
  * Add ability to get badge stock levels
  * Add ability to Create a term
  * Add ability to Update a term

## Version 0.0.21

  * Fix getting section_id and grouping_id for api.get_members

## Version 0.0.20

  * Deprecation of api_data option in api methods (raise a warning if used and adjust documentation)
  * Hide sesitive information when printing data sent to OSM in debug mode
  * Add archived attribute to Event
  * Add :include_archived option to api.get_events method
  * Add retreival of Flexi Records
  * Make set_user method of Api public

## Version 0.0.19

  * Fix caching error in api.get_register_data

## Version 0.0.18

  * Term's end attribute is now finish
  * Event's end attribute is now finish
  * Evening's evening_id attribute is now id
  * DueBadge's totals attribute is now a method (totals are calculated each time rather than during initialization)
  * Added exception ArgumentIsInvalid (raised when argument.valid? is false when updating through the API)
  * The following models now use active_attr:
    * Activity, Activity::File, Activity::Badge and Activity::Version
    * ApiAccess
    * DueBadges
    * Evening and Evening::Activity
    * Event
    * Grouping
    * Member
    * RegisterData
    * RegisterField
    * Role
    * Section and Section::FlexiRecord
    * Term

## Version 0.0.17

  * Fix try method is undefined
  * Since 1/1/1970 is the epoch used by the OSM API, this date will be treated as nil (except member's date of birth)
  * DueBadges now calculates the totals in the initialize method (no need to pass it in anymore)

## Version 0.0.16

  * -2 is a valid grouping_id value (corrected in Grouping)

## Version 0.0.15

  * Add :debug option to Api.configure
  * -2 is a valid grouping_id value
  * Fix check of :section_id in Member.initalize (apparently 0 is allowd in the API return data)
  * Fix role's section not being set from API data

## Version 0.0.14

  * Fix api.get_register_data\ returning wrong object
  * Fix check of :num_scouts in Section.initalize

## Version 0.0.13

  * Fix bug - invalid grouping_leader in member incorrectly risen for -1

## Version 0.0.12

  * EveningActivity class renamed to Evening::Activity
  * Change of method return types
    * Activity.badges now returns an array of Osm::Activity::Badge objects
    * Activity.files now returns an array of Osm::Activity::File objects
    * Activity.versions now returns an array of Osm::Activity::Version objects
    * Section.flexi_records now returns an array of Osm::Section::FlexiRecord objects
    * api.get_register_structure now returns an array of RegisterField objects
  * api.get_register becomes api.get_register_data and now returns an array of RegisterData objects
  * Attribute name changes:
    * Activity::Badge.section becomes section_type
    * Activity::File.file_id becomes id
    * Section.extra_records becomes flexi_records
    * Member.joined_in_years attribute becomes joining_in_years
  * from_api method added to:
    * Activity and sub classes
    * ApiAccess
    * DueBadges
    * Evening and Evening::Activity
    * Event
    * Grouping
    * Member
    * RegisterData
    * RegisterField
    * Role
    * Section
    * Term

## Version 0.0.11

  * Fix undefined variable in id_for_term

## Version 0.0.10

  * Fix handling an empty array being returned from OSM for fields (presumably if not allowed to view)
  * Fix undefined variable in id_for_term

## Version 0.0.9

  * Allow passing of Osm::Term objects as well as term IDs
  * Allow passing of Osm::Section objects as well as section IDs
  * Allow configuration of text prepended to keys used in the cache (:cache_prepend_to_key option to configure method)
  * Require setting of cache class to use caching (:cache option to configure method)

## version 0.0.8

  * Fix unknown variable when updating evening

## version 0.0.7

  * Work on documentation:
    * Clarify use of 'mystery' attributes
  * Rename ProgrammeItem to Evening (and move ProgrammeActivity to Evening->EveningActivity)

## Version 0.0.6

  * Usage changes:
    * When calling an api.get_\* method api_data is now passed as an additional paramter not as part of the options
  * Work on documentation:
    * Tidy up params
    * Tidy up returns
    * Add class attributes
  * Update README file:
    * Improve installation instructions
    * Add use section
    * Add versioning section

## Version 0.0.5

  * Bug fix

## Version 0.0.4

  * Bug fix

## Version 0.0.3

  * Retrieve grouping points from OSM
  * Respond to OSM chaninging how it returns member's groupings

## Version 0.0.2

  * Bug fixes

## Version 0.0.1

 * Initial release.
