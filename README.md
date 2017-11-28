[![Gem Version](https://badge.fury.io/rb/osm.png)](http://badge.fury.io/rb/osm)
[![Dependency Status](https://gemnasium.com/robertgauld/osm.png)](https://gemnasium.com/robertgauld/osm)

Master branch:
[![Build Status](https://secure.travis-ci.org/robertgauld/osm.png?branch=master)](http://travis-ci.org/robertgauld/osm)
[![Coveralls Status](https://coveralls.io/repos/robertgauld/osm/badge.png?branch=master)](https://coveralls.io/r/robertgauld/osm)
[![Code Climate](https://codeclimate.com/github/robertgauld/osm.png?branch=master)](https://codeclimate.com/github/robertgauld/osm)

Staging branch:
[![Build Status](https://secure.travis-ci.org/robertgauld/osm.png?branch=staging)](http://travis-ci.org/robertgauld/osm)
[![Coveralls Status](https://coveralls.io/repos/robertgauld/osm/badge.png?branch=master)](https://coveralls.io/r/robertgauld/osm)


## Build State
This project uses continuous integration to help ensure that a quality product is delivered.
Travis CI monitors two branches (versions) of the code - Master (which is what gets released)
and Staging (which is what is currently being developed ready for moving to master).


## Ruby Versions
This gem supports the following versions of ruby, it may work on other versions but is not tested against them so don't rely on it.

  * 2.3.0
  * 2.3.1
  * 2.3.2
  * 2.3.3
  * 2.3.4
  * 2.3.5
  * 2.4.0
  * 2.4.1
  * 2.4.2


## OSM

Use the [Online Scout Manager](https://www.onlinescoutmanager.co.uk) API.


## Installation

Add to your Gemfile and run the `bundle` command to install it.

```ruby
gem 'osm', '~> 2.0'
```

Configure the gem to use a cache during the initalization of the app (e.g. if using rails then config/initializers/osm.rb would look like):

```ruby
ActionDispatch::Callbacks.to_prepare do
  OSM::Model.cache = OSMTest::Cache
end
```


## Use

In order to use the OSM API you first need to authorize the api to be used by the user, to do this use the {OSM::Api#authorize} method to get a userid and secret.

```ruby
# Authorise your API to act as the user
api = OSM::Api.new(api_id: id_you_got_from_osm, api_secret: token_you_got_from_osm, name: "A name for your API")
user_credentials = api.authorize(users_email_address, users_osm_password)

# Now login to OSM and give your API some permissions

# Create an api instance with your user credentials
api = api.clone_with_different_user(user_credentials)
```

Once you have done this you should store the userid and secret somewhere, you can then create an {OSM::Api} object to start acting as the user.



## Documentation & Versioning

Documentation can be found on [rubydoc.info](http://rubydoc.info/github/robertgauld/osm/master/frames)

We follow the [Semantic Versioning](http://semver.org/) concept,
however it should be noted that when the OSM API adds a feature it can be difficult to decide Whether to bump the patch or minor version number up. A smaller change (such as adding score into the grouping object) will bump the patch whereas a larger change wil bump the minor version.


## Parts of the OSM API Supported:

### Retrieve
  * Activity
  * API Access
  * API Access for our app
  * Badges (Silver required for activity, Bronze for core, challenge and staged):
    * Which requirements each member has met
    * Details for each badge
    * Requirements for evening
    * Badge stock levels
  * Budgets (Gold required)
  * Due Badges
  * Email delivery reports
  * Evening
  * Event (Silver required)
  * Events (Silver required)
  * Event Columns (Silver required)
  * Event Attendance (Silver required)
  * Flexi Record Data
  * Flexi Record Structure
  * Gift Aid Data
  * Gift Aid Structure
  * Groupings (e.g. Sixes, Patrols)
  * Invoices (Gold required)
  * Members
  * My.SCOUT Templates
  * Notepad
  * Notepads
  * Online Payments:
    * Schedules
    * Payment Statuses
    * Payment Status History
  * Programme
  * Register Data
  * Register Structure
  * Roles
  * Section
  * Sections
  * SMS Delivery Reports
  * Term
  * Terms

### Update
  * Activity
  * Badges (Silver required for activity, Bronze for core, challenge and staged):
    * Which requirements each member has met
  * Budget (Gold required)
  * Evening
  * Event (Silver required)
  * Event Attendance (Silver required)
  * Event Column (Silver required)
  * Flexi Record Column
  * Flexi Record Data
  * Gift Aid Payment
  * Grouping
  * Invoices (Gold required)
  * Member
  * My.SCOUT Templates
  * Online payments - payment status
  * Register Attendance

### Create
  * Budget (Gold required)
  * Evening
  * Event (Silver required)
  * Event Column (Silver required)
  * Flexi Record Column
  * Gift Aid Payment
  * Invoices (Gold required)
  * Member

### Delete
  * Budget (Gold required)
  * Evening
  * Event (Silver required)
  * Event Column (Silver required)
  * Flexi Record Column
  * Invoices (Gold required)

### Actions
  * Authorise an app to use the API on a user's behalf
  * Add activity to programme
  * Send an SMS to member(s)
  * Send an Email to member(s)

## Parts not/never supported
  * Campsite Directory

## Parts of the OSM API currently NOT supported (may not be an exhaustive list):

See the [Roadmap page in the wiki](https://github.com/robertgauld/osm/wiki/Roadmap) for more details.

  * MyScout (Everything)
  * Adult Section Specific Stuff
  * Quartmaster DB
