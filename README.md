[![Gem Version](https://badge.fury.io/rb/osm.png)](http://badge.fury.io/rb/osm)
[![Dependency Status](https://gemnasium.com/robertgauld/osm.png)](https://gemnasium.com/robertgauld/osm)


##Build State
This project uses continuous integration to help ensure that a quality product is delivered.
Travis CI monitors two branches (versions) of the code - Master (which is what gets released)
and Staging (which is what is currently being developed ready for moving to master).

Master [![Build Status](https://secure.travis-ci.org/robertgauld/osm.png?branch=master)](http://travis-ci.org/robertgauld/osm)

Staging [![Build Status](https://secure.travis-ci.org/robertgauld/osm.png?branch=staging)](http://travis-ci.org/robertgauld/osm)


## Ruby Versions
This gem supports the following versions of ruby, it may work on other versions but is not tested against them so don't rely on it.

  * 1.9.2
  * 1.9.3
  * 2.0.0


## OSM

Use the [Online Scout Manager](https://www.onlinescoutmanager.co.uk) API.


## Installation

**Requires Ruby 1.9.2 or later.**

Add to your Gemfile and run the `bundle` command to install it.

```ruby
gem 'osm', '~> 1.2'
```

Configure the gem during the initalization of the app (e.g. if using rails then config/initializers/osm.rb would look like):

```ruby
ActionDispatch::Callbacks.to_prepare do
  Osm::configure(
    :api => {
      :default_site => :osm, # or :ogm
      :osm => {              # or :ogm (both an :osm and :ogm config are allowed
        :id    => 'YOU WILL BE GIVEN THIS BY ED AT OSM',
        :token => 'YOU WILL BE GIVEN THIS BY ED AT OSM',
        :name  => 'YOU WILL GIVE THIS TO ED AT OSM',
      },
    },
    :cache => {
      :cache => Rails.cache,
    },
  )
end
```


## Use

In order to use the OSM API you first need to authorize the api to be used by the user, to do this use the {Osm::Api#authorize} method to get a userid and secret.

```ruby
Osm::Api.authorize(users_email_address, users_osm_password)
```

Once you have done this you should store the userid and secret somewhere, you can then create an {Osm::Api} object to start acting as the user.

```ruby
api_for_this_user = Osm::Api.new(userid, secret)
```


## Documentation & Versioning

Documentation can be found on [rubydoc.info](http://rubydoc.info/github/robertgauld/osm/master/frames)

We follow the [Semantic Versioning](http://semver.org/) concept,
however it should be noted that when the OSM API adds a feature it can be difficult to decide Whether to bump the patch or minor version number up. A smaller change (such as adding score into the grouping object) will bump the patch whereas a larger change wil bump the minor version.


## Parts of the OSM API Supported:

### Read
  * Activity
  * API Access
  * API Access for our app
  * Badges (Silver required for activity, Bronze for core, challenge and staged):
    * Which requirements each member has met
    * Details for each badge
    * Requirements for evening
    * Badge stock levels
  * Budgets
  * Due Badges
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
  * Members
  * Notepad
  * Notepads
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
  * Budget
  * Evening
  * Event (Silver required)
  * Event Attendance (Silver required)
  * Event Column (Silver required)
  * Flexi Record Column
  * Flexi Record Data
  * Gift Aid Payment
  * Grouping
  * Member
  * Register Attendance

### Create
  * Budget
  * Evening
  * Event (Silver required)
  * Event Column (Silver required)
  * Flexi Record Column
  * Gift Aid Payment
  * Member

### Delete
  * Budget
  * Evening
  * Event (Silver required)
  * Event Column (Silver required)
  * Flexi Record Column

### Actions
  * Authorise an app to use the API on a user's behalf
  * Add activity to programme
  * Send an SMS to member(s)

## Parts not/never supported
  * Campsite Directory

## Parts of the OSM API currently NOT supported (may not be an exhaustive list):

See the [Roadmap page in the wiki](https://github.com/robertgauld/osm/wiki/Roadmap) for more details.

  * Finances (Invoices) (Gold required) [issue 77]
  * MyScout (Everything)
