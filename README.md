Puppet standalone installer builder
===================================

Overview
--------

Helps you to build standalone installers for puppet.

Usage
-----

Just add this in your module Gemfile:

```
gem 'puppet_standalone_installer_builder', :github => 'camptocamp/puppet_standalone_installer_builder', :branch => 'master', :require => false
```

And this in your Rakefile

```
require 'puppet_standalone_installer_builder/rake_tasks'
```

Then run

```
bundle update
bundle exec rake build_standalone_installer
```

This will produce a tarball a the module and all dependencies.

Workflow for reproductible build
--------------------------------

* Branch your module for a specific release version
* Explicitely set dependencies version in .fixtures.yml
* Explicitely set gem version in Gemfile
* Call `bundle update` and `bundle exec rake build_standalone_installer`
