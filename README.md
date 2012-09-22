##Build State
This project uses continuous integration to help ensure that a quality product is delivered.
Travis CI monitors two branches (versions) of the code - Master (which is what gets released)
and Staging (which is what is currently being debugged ready for moving to master).

Master [![Build Status](https://secure.travis-ci.org/robertgauld/osm.png?branch=master)](http://travis-ci.org/robertgauld/osm)

Staging [![Build Status](https://secure.travis-ci.org/robertgauld/osm.png?branch=staging)](http://travis-ci.org/robertgauld/osm)

This project also uses gemnasium to help ensure that the current version of libraries are being used.

Master [![Dependency Status](https://gemnasium.com/robertgauld/osm.png)](https://gemnasium.com/robertgauld/osm)


## OSM

Use the [Online Scout Manager](https://www.onlinescoutmanager.co.uk) API.


## Installation

**Requires Ruby 1.9.2 or later.**

Add to your Gemfile and run the `bundle` command to install it.

```ruby
gem 'osm'
```

Configure the gem during the initalization of the app (e.g. if using rails then config/initializers/osm.rb would look like):

```ruby
ActionDispatch::Callbacks.to_prepare do
Osm::Api.configure(
  :api_id     => 'YOU WILL BE GIVEN THIS BY ED AT OSM',
  :api_token  => 'YOU WILL BE GIVEN THIS BY ED AT OSM',
  :api_name   => 'YOU WILL GIVE THIS TO ED AT OSM',
  :api_site   => :scout,
  :cache      => Rails.cache
)
end
```


## Use

In order to use the OSM API you first need to authorize the api to be used by the user, to do this use the {Osm::Api#authorize} method to get a userid and secret.

```ruby
Osm::Api.new.authorize(users_email_address, users_osm_password)
```

Once you have done this you should store the userid and secret somewhere, you can then create an {Osm::Api} object to start acting as the user.

```ruby
api_for_this_user = Osm::Api.new(userid, secret)
```


## Documentation & Versioning

Documentation can be found on [rubydoc.info](http://rubydoc.info/github/robertgauld/osm/master/frames)

We follow the [Semantic Versioning](http://semver.org/) concept,
however it should be noted that when the OSM API adds a feature it can be difficult to decide wether to bump the patch or minor version number up. A smaller change (such as adding score into the grouping object) will bump the patch whereas a larger change wil bump the minor version.


## Parts of the OSM API Supported:

### Read
  * Activity
  * API Access
  * API Access for our app
  * Due Badges
  * Events
  * Groupings (e.g. Sixes, Patrols)
  * Members
  * Notepad
  * Notepads
  * Programme
  * Register
  * Register Structure
  * Roles
  * Section
  * Sections
  * Term
  * Terms

### Update
  * Evening

### Create
  * Evening

### Actions
  * Authorise an app to use the API on a user's behalf


## Parts of the OSM API currently NOT supported:

  * Flexi record fields and data
  * Retreival of leader access
  * Terms:
    * Create
    * Update
  * Register - Update attendance
  * Events:
    * Attendance (everything)
    * Create
    * Update
  * Member:
    * Update
    * Add
  * Badges:
    * Which requirements each member has met:
      * Retreive
      * Update
    * Retrieve details for each badge (stock, short column names etc.)
  * Update Activity
  * Gift aid (everything)
  * Finances (Everything)
  * SMS:
    * Retreival of devlery reports
    * Sending a message
