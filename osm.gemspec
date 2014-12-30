# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require File.join(File.dirname(__FILE__), 'version')

Gem::Specification.new do |s|
  s.name        = "osm"
  s.license     = 'BSD 3 clause'
  s.version     = Osm::VERSION
  s.authors     = ['Robert Gauld']
  s.email       = ['robert@robertgauld.co.uk']
  s.homepage    = 'https://github.com/robertgauld/osm'
  s.summary     = %q{Use the Online Scout Manager API}
  s.description = %q{Use the Online Scout Manager API (https://www.onlinescoutmanager.co.uk) to retrieve and save data.}

  s.rubyforge_project = "osm"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency 'activesupport', '>= 3.2', '< 5' # Used to parse JSON from OSM
  s.add_runtime_dependency 'httparty', '~> 0.9'             # Used to make web requests to the API
  s.add_runtime_dependency 'active_attr', '~> 0.8'
  s.add_runtime_dependency 'activemodel', '>= 3.2', '< 5'
  s.add_runtime_dependency 'dirty_hashy', '~> 0.2.1'        # Used to track changed data in Badge::Data and FlexiRecord::Data

  s.add_development_dependency 'rake', '~> 10.0'
  s.add_development_dependency 'rspec', '>= 2.14.1', '< 4'
  s.add_development_dependency 'fakeweb', '~> 1.3'
  s.add_development_dependency 'guard-rspec', '~> 4.2', '>= 4.2.5'
  s.add_development_dependency 'rb-inotify', '~> 0.9'
  s.add_development_dependency 'coveralls', '~> 0.7'
  s.add_development_dependency 'simplecov', '~> 0.7'

end
