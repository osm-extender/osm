##Build State
This project uses continuous integration to help ensure that a quality product is delivered.
Travis CI monitors two branches (versions) of the code - Master (which is what gets released)
and Staging (which is what is currently being debugged ready for moving to master).

Master [![Build Status](https://secure.travis-ci.org/robertgauld/osm.png?branch=master)](http://travis-ci.org/robertgauld/osm)

Staging [![Build Status](https://secure.travis-ci.org/robertgauld/osm.png?branch=staging)](http://travis-ci.org/robertgauld/osm)


## OSM

Use the [Online Scout Manager](https://www.onlinescoutmanager.co.uk) API.


## Installation

Add to your Gemfile and run the `bundle` command to install it.

```ruby
gem 'osm'
```

**Requires Ruby 1.9.2 or later.**
