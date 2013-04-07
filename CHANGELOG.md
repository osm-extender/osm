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
    * Add first\_name and last\_name attributes
    * Add mark\_awarded method
    * Add mark\_due method
  * Badge
    * Make get\_badge\_data\_for\_section an instance not class method (called get\_data\_for\_section)
    * Add get\_summary\_for\_section(api, section, term=nil, options={}) method
    * Add optional section\_type parameter to get\_badges\_for\_section method

## Version 0.5.0

  * Code breaking changes to DueBadges:
    * The by\_member attribute now uses scout\_id as the key
    * Addition of member\_names attribute to allow fetching of members names (the old key for the by\_member attribute)
    * descriptions attribute has been renamed to badge\_names for consistency
  * Code breaking changes to Register and subclasses:
    * Register:
      * update\_attendance - :attendance option is now a Symbol not String (:yes, :unadvised\_absent or :advised\_absent)
    * Register::Attendance:
      * attendance attribute is now a Hash of Date to Symbol (instead of to String)
  * Register::Attendance gains two helper methods:
    * present\_on?(date)
    * absent\_on?(date)
  * Add allow\_booking attribute to Event
  * Add myscout\_programme\_times attribute to Section
  * Cost attribute of Event is now checked to be either "TBC" or formatted to /\\A\\d+\\.\\d{2}\\Z/
  * Add cost\_tbc? method to Event
  * Add cost\_free? method to Event

## Version 0.4.2

  * Fix undefined variable "section\_id" when fetching notepad from cache

## Version 0.4.1

  * Fix not handling of Event's config not being an Array of Hash
  * Fix undefined 'Osm::FlexiRecord' from within Section (intermittent bug)

## Version 0.4.0

  * Event::Attendance
    * Move fields['firstname'] to first\_name attribute
    * Move fields['lastname'] to last\_name attribute
    * Move fields['dob'] to date\_of\_birth attribute
    * Move fields['attending'] to attending attribute
    * The keys for fields are now Fixnums not Strings
    * Addition of payment\_control and payments attributes
    * Addition of automatic\_payments? and manual\_payments? methods
    * Addition of is\_attending?, is\_not\_attending?, is\_invited? and is\_shown? methods
    * update(api, field\_id) method now updates only changed fields, becoming update(api)
  * Add :network Section type
  * Add custom inspect methods for:
    * Event::Attendance (replace event with event.id if present)
    * Event::Column (replace event with event.id if present)
    * FlexiRecord::Column (replace flexi\_record with flexi\_record.id)
    * FlexiRecord::Data (replace flexi\_record with flexi\_record.id)
    * Badge::Requirement (replace badge with badge.osm\_key)
    * Badge::Data (replace badge with badge.osm\_key)

## Version 0.3.0

  * Removal of DueBadges
  * Removal of get\_badge\_stock method from sections
  * Addition of Badges model:
    * With get\_due\_badges(api, section, options={}) method
    * With get\_stock(api, section, options={}) method
    * With update\_stock(api, section, badge\_key, stock\_level) method
  * Addition of Badge models:
    * CoreBadge
    * ChallengeBadge
    * StagedBadge
    * ActivityBadge
    * All:
      * Inherit from Badge (do not use this class directly)
      * With get\_badges\_for\_section(api, section, options={}) method
      * With get\_badge\_data\_for\_section(api, section, badge, term=nil, options={}) method
  * Addition of Badge::Requirements class
  * Addition of Badge::Data class
    * With update(api) method
    * With total\_gained method
    * With sections\_gained method
    * With gained\_in\_sections method
  * FlexiRecord::Data now updates only changed fields

## Version 0.2.2

  * Add comparing and sorting (using <=>, <, <=, >, >= and between?) to each model
    * Activity - id then version
    * Activity::File - activity\_id then name
    * Activity::Version - activity\_id then version
    * ApiAccess - id
    * Event - start, name then id (shortcuts, returning 0 if ids are equal)
    * Event::Column - event then id
    * Event::Attendance - event then row
    * FlexiRecord - section\_id then name
    * FlexiRecord::Column - flexi\_record then id (system ones first then user ones)
    * FlexiRecord::Data - flexi\_record, grouping\_id then member\_id
    * Grouping - section\_id then name
    * Meeting - section\_id, date, start\_time then id
    * Meeting::Activity - title then activity\_id
    * Member - section\_id, grouping\_id, grouping\_leader (descending), last\_name then first\_name
    * Register::Field - id
    * Register::Attendance - section\_id, grouping\_id, last\_name then first\_name
    * Section - group\_name, type (by age) then name
    * Term - section\_id, start then id

## Version 0.2.0

  * Raises Forbidden exception if:
    * You try to use a feature which requires an OSM subscription above your current one
    * You try to access a feature which you don't have the correct permissions for
    * You try to access a Section (or it's Grouping) you shouldn't be accessing
  * All Model classes:
    * Addition of changed\_attributes method to get a list of attributes which have changed
    * Addition of reset\_changed\_attributes method to reset the list of attributes which have changed
  * Activity
    * Check user has permission to view before returning from cache
    * Addition of osm\_link method to get the URL for viewing in OSM
  * Add updating of Grouping
  * Evening:
    * Rename to Meeting
    * Rename meeting\_date attribute to date
    * Rename get\_programme method to get\_for\_section
  * Event:
    * Removal of add\_field method (use add\_column instead)
    * Removal of fields attribute (use columns instead)
  * FlexiRecord:
    * Addition of id, section\_id and name attributes (these no longer need to be passed to methods)
    * FlexiRecord::Field renamed to FlexiRecord::Column
    * The following methods are now instance not class methods:
      * get\_fields (also renamed to get\_columns)
      * add\_field (also renamed to add\_column)
      * get\_data
    * The following methods have bceome instance methods of a subclasses:
      * update\_field (moved to column.update)
      * delete\_field (moved to column.delete)
      * update\_data (moved to data.update)
  * Member:
    * Removal of grouping attribute
    * Removal of grouping\_label attribute
    * Addition of myscout\_link method (used to get the link to the member's My.SCOUT page)
  * Section:
    * subscription\_level attribute is now a Fixnum not Symbol
    * Addition of subscription\_level\_name method to get the name of the subscription level for the section
    * flexi\_records attribute now contains an Array of Osm::FlexiRecord
  * "Under the hood" changes:
    * Instead of caching individual items and a list of items the gem now caches a list of IDs. This should reduce the cache size.
    * When updating items requires multiple OSM requests, now only updates what changed
    * Updating of cached data when deleting/updating items from OSM
>>>>>>> dev_v_0.2.0

## Version 0.1.17

  * Add comparison to Evening
  * Passing a Term to the get\_programme method of Evening is now optional

## Version 0.1.16

  * Member's grouping attribute:
    * Renamed to grouping\_label
    * Virtual attribute grouping added (maps to grouping\_label currently) marked as depricated as it will use a Grouping object not a String in the future
  * Fix exception when OSM returns empty string when requesting groupings for a section
  * Fix exception when OSM returns empty string when requesting register structure for a section
  * Fix updating of grouping for Member
  * Fix validation error for Member - a leader's joining\_in\_years is -1
  * Add spaces and spaces? methods to Event

## Version 0.1.15

  * Rename grouping\_name attribute of Member to grouping

## Version 0.1.14

  * Fix grouping\_name attribute of Member not being set when getting data from OSM

## Version 0.1.13

  * Add attendance limit attributes to Event:
    * attendance\_limit - Fixnum, 0 = no limit
    * attendance\_limit\_includes\_leaders Boolean
  * Add limited\_attendance? method to Event
  * Add setting of a section's notepad
  * Add updating of Activity
  * Add grouping\_name attribute to Member

## Version 0.1.12

  * Attribute Section.myscout\_email\_address\_send defaults to an empty String
  * Attribute Section.myscout\_email\_address\_copy defaults to an empty String
  * Attribute Section.myscout\_email\_address\_send renamed to myscout\_email\_address\_from
  * Osm::Event::Column
    * Rename parent\_label attribute to label
    * Add update method to update OSM
    * Add delete method to update OSM
  * Osm::Evening
    * Add delete method to update OSM
    * Changes to create method:
      * Now takes arguments of (api, parameters)
      * Now returns an Osm::Evening on success, nil on failure
      * Will now pass start time, finish time and title to OSM
  * Add activity to programme
      * Evening.add\_activity(api, activity, notes="")
      * Activity.add\_to\_programme(api, section, date, notes="")
  * Osm::Member
    * Add create method to update OSM
    * Add update method to update OSM
  * Osm::FlexiRecord
    * Add add\_field method to add a field to the record in OSM
    * Add update\_field method to rename a field in OSM
    * Add delete\_field method to delete a field from OSM
    * Add update\_data method to update the data in OSM

## Version 0.1.11

  * Fix "can't convert Hash into String" occuring when some section's config is a Hash not a JSON encoded Hash
  * Remove num\_scouts attribute from Section (OSM always sets this to 999)
  * Add My.SCOUT related attributes to Section:
    * gocardless (Boolean) - does the section use gocardless
    * myscout\_events\_expires (Date) - when the subscription to Events in My.SCOUT expires
    * myscout\_badges\_expires (Date) - when the subscription to Badges in My.SCOUT expires
    * myscout\_programme\_expires (Date) - when the subscription to Badges in My.SCOUT expires
    * myscout\_events (Boolean) - whether the section uses the Events part of My.SCOUT
    * myscout\_badges (Boolean) - whether the section uses the Badges part of My.SCOUT
    * myscout\_programme (Boolean) - whether the section uses the Programme part of My.SCOUT
    * myscout\_payments (Boolean) - whether the section uses the Payments part of My.SCOUT
    * myscout\_emails (Hash of Symbol to Boolean) - which email addresses are linked to MyScout for each Member
    * myscout\_email\_address\_send (String, blank OK) - which email address to send My.SCOUT emails as
    * myscout\_email\_address\_copy (String, blank OK) - which email address to send copys of My.SCOUT emails to
    * myscout\_badges\_partial (Boolean) - Whether parents can see partially completed badges
    * myscout\_programme\_summary (Boolean) - Whether parents can see the summary of programme items
    * myscout\_event\_reminder\_count (Integer) - How many event reminders to send to parents who haven't responded
    * myscout\_event\_reminder\_frequency (Integer) - How many days to leave between event reminder emails
    * myscout\_payment\_reminder\_count (Integer) - How many payment reminders to send to parents who haven't paid yet
    * myscout\_payment\_reminder\_frequency (Integer) - How many days to leave between payment reminder emails
  * Add new OSM attributes to Event:
    * notepad - the notepad shown in OSM
    * public\_notepad - the notepad shown on My.SCOUT
    * confirm\_by\_date - the last day that parents can change their child's attendance details
    * allow\_changes - whether parents can change their child's attendance details
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

  * Osm::Model has new class method get\_user\_permission(api, section_id, permission)
  * API may return permissions value as a string not integer

## Version 0.1.3

  * Add get\_badge\_stock(api) to section

## Version 0.1.2

  * Bug fixes

## Version 0.1.1

  * Add get\_options Hash to Model.get\_user\_permissions
  * Bug fixes

## Version 0.1.0

  * Configuration is through Osm::configure not Osm::Api.configure and it takes a different Hash
  * Api.authorize returns a different Hash
  * Removal of Osm::Api methods:
    * get\_*
    * update\_*
    * create\_*
  * EventAttendance is now Event::Attendance
  * Removal of Osm::Role
    * Osm::Section now has two new required attributes group\_id and group\_name
    * long\_name and full\_name methods should be replaced with something similar to "#{section.name} (#{section.group\_name})" in your own code
    * Section has a class method fetch\_user\_permissions(api) which returns a Hash (section\_id to permissions Hash)
  * Activity now has class method get(api, activity\_id)
  * ApiAccess: now has class methods
    * get\_all(api, section)
    * get(api, section, for\_api)
    * get\_ours(api, section) -> actually just calls get(api, section, api)
  * DueBadges now has a class method get(api, section)
  * Evening now has class methods:
    * get\_programme(api, section\_id, term\_id)
    * create(api, parameters)
  * Evening now has instance methods:
    * update(api)
    * get\_badge\_requirements(api, evening)
  * Event now has class methods:
    * get\_for\_section(api, section)
    * get(api, section, event\_id)
    * create(api)
  * Event now has instance methods:
    * update(api)
    * delete(api)
    * get\_attendance(api)
    * add\_field(api, label)
  * Event now has a fields attribute
  * Event::Attendance has instance method update(api, field\_id)
  * FlexiRecord has class methods:
    * get\_fields(api, section, flexi\_record\_id)
    * get\_data(api, section, flexi\_record\_id, term)
  * Grouping now has a class method get\_for\_section(api, section)
  * Member now has a class method to get\_for\_section(api, section\_id, term\_id)
  * Register now has class methods:
    * get\_structure(api, section)
    * get\_attendance(api, section)
    * update\_attendance(data)
  * Section now has class methods:
    * get\_all(api)
    * get(api, section\_id)
  * Section now has instance method get\_notepad(api)
  * Term now has class methods:
    * get\_all(api)
    * get(api, term\_id)
    * get\_for\_section(api, section\_id)
    * get\_current\_term\_for\_section(api, section\_id)
    * create(api, parameters)
  * Term now has instance method update(api)

## Version 0.0.26

  * Register - Update attendance
    * Add api.get\_badge\_requirements\_for\_evening
    * Add api.update\_register
  * Event:
    * Add api.ceate\_event
    * Add api.update\_event
    * Add api.delete\_event
    * Add api.add\_event\_field
  * Event attendance:
    * Add api.get\_event
    * Add api.get\_event\_fields
    * Add api.get\_event\_attendance
    * Add api.update\_event\_attendance
  * Fix "uninitialized constant Osm::Api::HTTParty"

## Version 0.0.25

  * FlexiRecordData, move these attributes to the fields hash:
    * first\_name => 'firstname'
    * last\_name => 'lastname'
    * age => 'age'
    * date\_of\_birth => 'dob'
    * completed => 'completed'
    * total => 'total'

## Version 0.0.24

  * Make Section::FlexiRecord sortable

## Version 0.0.23

  * get\_badge\_stock\_levels now returns a hash whoose values are Fixnum not String

## Version 0.0.22

  * Adjustments so DueBadge is similar enough to badge\_stock data to be useful:
    * by\_member Hash -> Keys are member's name (String), values are the badge key (String)
    * descriptions Hash -> keys are the badge key (String), values are the badge name (String)
    * totals Hash -> keys are the badge key (String), values are the  number required (Fixnum)
    * Badge keys are the same as are used in getting badge stock levels
  * Add ability to get badge stock levels
  * Add ability to Create a term
  * Add ability to Update a term

## Version 0.0.21

  * Fix getting section\_id and grouping\_id for api.get\_members

## Version 0.0.20

  * Deprecation of api\_data option in api methods (raise a warning if used and adjust documentation)
  * Hide sesitive information when printing data sent to OSM in debug mode
  * Add archived attribute to Event
  * Add :include\_archived option to api.get\_events method
  * Add retreival of Flexi Records
  * Make set\_user method of Api public

## Version 0.0.19

  * Fix caching error in api.get\_register\_data

## Version 0.0.18

  * Term's end attribute is now finish
  * Event's end attribute is now finish
  * Evening's evening\_id attribute is now id
  * DueBadge's totals attribute is now a method (totals are calculated each time rather than during initialization)
  * Added exception ArgumentIsInvalid (raised when argument.valid? is false when updating through the API)
  * The following models now use active\_attr:
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

  * -2 is a valid grouping\_id value (corrected in Grouping)

## Version 0.0.15

  * Add :debug option to Api.configure
  * -2 is a valid grouping\_id value
  * Fix check of :section\_id in Member.initalize (apparently 0 is allowd in the API return data)
  * Fix role's section not being set from API data

## Version 0.0.14

  * Fix api.get_register\_data\ returning wrong object
  * Fix check of :num\_scouts in Section.initalize

## Version 0.0.13

  * Fix bug - invalid grouping\_leader in member incorrectly risen for -1

## Version 0.0.12

  * EveningActivity class renamed to Evening::Activity
  * Change of method return types
    * Activity.badges now returns an array of Osm::Activity::Badge objects
    * Activity.files now returns an array of Osm::Activity::File objects
    * Activity.versions now returns an array of Osm::Activity::Version objects
    * Section.flexi_records now returns an array of Osm::Section::FlexiRecord objects
    * api.get\_register\_structure now returns an array of RegisterField objects
  * api.get\_register becomes api.get\_register\_data and now returns an array of RegisterData objects
  * Attribute name changes:
    * Activity::Badge.section becomes section\_type
    * Activity::File.file\_id becomes id
    * Section.extra\_records becomes flexi\_records
    * Member.joined\_in\_years attribute becomes joining\_in\_years
  * from\_api method added to:
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

  * Fix undefined variable in id\_for\_term

## Version 0.0.10

  * Fix handling an empty array being returned from OSM for fields (presumably if not allowed to view)
  * Fix undefined variable in id\_for\_term

## Version 0.0.9

  * Allow passing of Osm::Term objects as well as term IDs
  * Allow passing of Osm::Section objects as well as section IDs
  * Allow configuration of text prepended to keys used in the cache (:cache\_prepend\_to\_key option to configure method)
  * Require setting of cache class to use caching (:cache option to configure method)

## version 0.0.8

  * Fix unknown variable when updating evening

## version 0.0.7

  * Work on documentation:
    * Clarify use of 'mystery' attributes
  * Rename ProgrammeItem to Evening (and move ProgrammeActivity to Evening->EveningActivity)

## Version 0.0.6

  * Usage changes:
    * When calling an api.get\_\* method api_data is now passed as an additional paramter not as part of the options
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
