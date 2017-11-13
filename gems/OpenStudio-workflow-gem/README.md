# OpenStudio::Workflow

[![Circle CI](https://circleci.com/gh/NREL/OpenStudio-workflow-gem/tree/develop.svg?style=svg)](https://circleci.com/gh/NREL/OpenStudio-workflow-gem/tree/develop)
[![Coverage Status](https://coveralls.io/repos/NREL/OpenStudio-workflow-gem/badge.svg?branch=develop&service=github)](https://coveralls.io/github/NREL/OpenStudio-workflow-gem?branch=develop)
[![Dependency Status](https://www.versioneye.com/user/projects/5531fb7b10e714121100102e/badge.svg?style=flat)](https://www.versioneye.com/user/projects/5531fb7b10e714121100102e)

## OpenStudio Workflow Gem

This branch is the development branch for the OpenStudio workflow gem. 
## Installation

The OpenStudio Workflow Gem has the following dependencies:

* Ruby 2.0
* OpenStudio with Ruby 2.0 bindings
* EnergyPlus 8.3 (assuming OpenStudio >= 1.7.2)
* MongoDB if using MongoDB Adapter (or when running rspec)

[OpenStudio](http://developer.nrel.gov/downloads/buildings/openstudio/builds/) needs to be installed
and in your path.  On Mac/Linux it is easiest to add the following to your .bash_profile or /etc/profile.d/<file>.sh to ensure OpenStudio can be loaded.

    export OPENSTUDIO_ROOT=/usr/local
    export RUBYLIB=$OPENSTUDIO_ROOT/lib/ruby/site_ruby/2.0.0

Add this line to your application's Gemfile:

    gem 'OpenStudio-workflow'

And then execute:
    
    Mac/Linux:

        $ bundle
        
    Windows (avoids native extensions):
    
        $ bundle install --without xml profile

Or install it yourself as:
    
    $ gem install OpenStudio-workflow
    
## Usage

Note that the branches of the Workflow Gem depict which version of EnergyPlus is in use. The develop branch at the
moment should not be used.

There are currently two adapters to run OpenStudio workflow. The first is a simple Local adapter
allowing the user to pass in the directory to simulation. The directory must have an
[analysis/problem JSON file](spec/files/local_ex1/analysis_1.json) and a [datapoint JSON file](spec/files/local_ex1/datapoint_1.json).
The workflow manager will use these data (and the measures, seed model, and weather data) to assemble and
execute the standard workflow of (preflight->openstudio measures->energyplus->postprocess).

    r = OpenStudio::Workflow.load 'Local', '/home/user/a_directory', options
    r.run

The workflow manager can also use MongoDB to receive instructions on the workflow to run and the data point values.

## Caveats and Todos

### Todos

* Add a test to ensure that the models being returned contain alterations after apply_measure
* Add unit tests for each util method
* Define and document the complete set of options for the adapter and run classes
* Implement better error handling with custom exception classes

## Testing

The preferred way for testing is to run rspec either natively or via docker.

### Locally

```
rspec spec/
```

### Docker

```
export OPENSTUDIO_VERSION=1.13.0
docker run -v $(pwd):/var/simdata/openstudio \
      nrel/openstudio:$OPENSTUDIO_VERSION \
      /var/simdata/openstudio/test/bin/docker-run.sh
```

## Contributing

1. Fork it ( https://github.com/NREL/OpenStudio-workflow/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
