OpenStudio-ERI
===============

Calculates an Energy Rating Index (ERI) via an OpenStudio/EnergyPlus-based workflow. Building information is provided through an [HPXML file](https://hpxml.nrel.gov/).

The ERI is defined by [ANSI/RESNET/ICC 301-2014 "Standard for the Calculation and Labeling of the Energy Performance of Low-Rise Residential Buildings using an Energy Rating Index"](http://www.resnet.us/blog/ansiresneticc-standard-301-2014-january-15-2016/).

**Unit Test Status:** [![CircleCI](https://circleci.com/gh/NREL/OpenStudio-ERI/tree/master.svg?style=svg)](https://circleci.com/gh/NREL/OpenStudio-ERI/tree/master)

**Code Coverage:** [![codecov](https://codecov.io/gh/NREL/OpenStudio-ERI/branch/master/graph/badge.svg?token=HpCKohTsLI)](https://codecov.io/gh/NREL/OpenStudio-ERI)

## Setup

1. Download [OpenStudio 2.7.0](https://github.com/NREL/OpenStudio/releases/tag/v2.7.0). At a minimum, install the Command Line Interface and EnergyPlus components.
2. Clone or download this repository's source code. 
3. To obtain all available weather files, navigate to the [workflow](https://github.com/NREL/OpenStudio-ERI/tree/master/workflow) directory and run:  
```openstudio --no-ssl energy_rating_index.rb --download-weather``` 

## Running

1. Navigate to the [workflow](https://github.com/NREL/OpenStudio-ERI/tree/master/workflow) directory.
2. Run the ERI calculation on a provided sample HPXML file:  
```openstudio --no-ssl energy_rating_index.rb -s -x sample_files/valid.xml```  
Note that the Reference Home, Rated Home and Index Adjustment Home (if applicable) simulations will be executed in parallel on the local machine.
3. This will generate output as shown below:
![CLI output](https://user-images.githubusercontent.com/5861765/46991458-4e8f1480-d0c3-11e8-8234-22ed4bb4f383.png)

Run `openstudio energy_rating_index.rb -h` to see all available commands/arguments.

## Speed

The workflow is continuously being evaluated for ways to reduce runtime. A number of enhancements have been made to date.

There are additional ways that software developers using this workflow can reduce runtime:
* Run on Linux/Mac platform, which is significantly faster by taking advantage of the [POSIX fork](https://en.wikipedia.org/wiki/Fork_(system_call)) call.
* Use the `--no-ssl` flag to prevent SSL initialization in OpenStudio.
* Use the `-s` flag to skip HPXML validation.

## Outputs

Upon completion, multiple outputs are currently available:
* ERI_Results.csv and ERI_Worksheet.csv files (that mirror the [RESNET HERS Method Test form](http://www.resnet.us/programs/2014_HERS-Method_Results-Form.xlsx))
* Reference/Rated/IndexAdjustment Home HPXML files (transformations of the input HPXML file via the 301 ruleset)
* Summary annual energy consumption by fuel type and/or end use
* EnergyPlus input/output files

See the [sample_results](https://github.com/NREL/OpenStudio-ERI/tree/master/workflow/sample_results) directory for examples of these outputs.

## Tests

Continuous integration tests are automatically run for any change to this repository. The current set of tests include:
- [x] Successful ERI calculations for all sample files
- [x] RESNET HERS Reference Home auto-generation tests
- [x] RESNET HERS method tests (including IAF and 2016-proposed tests)
- [x] RESNET Hot water system performance tests (including pre-Addendum A tests)

Tests can be run locally as follows. Individual tests (any method in `energy_rating_index_test.rb` that begins with "test_") can also be run. For example:  
```openstudio tests/energy_rating_index_test.rb``` (all tests)  
```openstudio tests/energy_rating_index_test.rb --name=test_resnet_hers_method``` (RESNET HERS Method tests only)

At the completion of the test, there will be output that denotes the number of failures/errors like so:  
```Finished in 36.067116s, 0.0277 runs/s, 0.9704 assertions/s.```  
```1 runs, 35 assertions, 0 failures, 0 errors, 0 skips```

## Software Developers

To use this workflow, software tools must produce a valid HPXML file. HPXML is an flexible and extensible format, where nearly all fields in the schema are optional and custom fields can be included. Because of this, an ERI Use Case for HPXML is available that specifies the specific HPXML fields required to run this workflow. The [HPXML ERI Use Case](https://github.com/NREL/OpenStudio-ERI/blob/master/measures/301EnergyRatingIndexRuleset/resources/301validator.rb) is defined as a set of conditional XPath expressions. Invalid HPXML files produce errors found in, e.g., the `workflow/HERSRatedHome/run.log` and/or `workflow/HERSReferenceHome/run.log` files.

## Status

*	The 301 ruleset and ERI calculation are **works-in-progress**. 
* The format of the ERI HPXML file is still in flux.
*	The workflow has only been tested with the sample files provided in the `workflow/sample_files` directory.
*	Errors/warnings are not yet being handled gracefully.

