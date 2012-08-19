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
