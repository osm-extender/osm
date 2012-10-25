## Version 0.1.4

  * Osm::Model has new class method get\_user\_permission(api, section_id, permission)

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
