## Version 0.0.26

  * Event attendance:
    * Add api.get\_event
    * Add api.get\_event\_fields
    * Add api.get\_event\_attendance
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
