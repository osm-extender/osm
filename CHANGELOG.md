## Version 0.0.17

  * Fix try method is undefined
  * Since 1/1/1970 is the epoch used by the OSM API, this date will be treated as nil (except member's date of birth)

## Version 0.0.16

  * -2 is a valid grouping\_id value (corrected in Grouping)

## Version 0.0.15

  * Add :debug option to Api.configure
  * -2 is a valid grouping\_id value
  * Fix check of :section\_id in Member.initalize (apparently 0 is allowd in the API return data)
  * Fix role's section not being set from API data

## Version 0.0.14

  * Fix Api.get_register\_data\ returning wrong object
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
    * Api.get\_register\_structure now returns an array of RegisterField objects
  * Api.get\_register becomes Api.get\_register\_data and now returns an array of RegisterData objects
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
