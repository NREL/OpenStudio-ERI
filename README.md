OpenStudio-ERI
===============

Calculates an Energy Rating Index (ERI) via an OpenStudio/EnergyPlus-based workflow. Building information is provided through an [HPXML file](https://hpxml.nrel.gov/).

The ERI is defined by ANSI/RESNET 301-2014 "Standard for the Calculation and Labeling of the Energy Performance of Low-Rise Residential Buildings using the HERS Index".

**Unit Test Status:** [![CircleCI](https://circleci.com/gh/NREL/OpenStudio-ERI/tree/master.svg?style=svg)](https://circleci.com/gh/NREL/OpenStudio-ERI/tree/master)

**Code Coverage:** [![Coverage Status](https://coveralls.io/repos/github/NREL/OpenStudio-ERI/badge.svg?branch=master)](https://coveralls.io/github/NREL/OpenStudio-ERI?branch=master)

## Setup

1. Download [OpenStudio 2.6.1](https://github.com/NREL/OpenStudio/releases/tag/v2.6.1). At a minimum, install the Command Line Interface and EnergyPlus components.
2. Clone or download this repository's source code. 
3. To obtain all available weather files, navigate to the [workflow](https://github.com/NREL/OpenStudio-ERI/tree/master/workflow) directory and run:  
```openstudio --no-ssl energy_rating_index.rb --download-weather``` 

## Running

1. Navigate to the [workflow](https://github.com/NREL/OpenStudio-ERI/tree/master/workflow) directory.
2. Run the ERI calculation on a provided sample HPXML file:  
```openstudio --no-ssl energy_rating_index.rb -x sample_files/valid.xml```  
Note that the Reference Home, Rated Home and Index Adjustment Home (if applicable) workflows/simulations will be executed in parallel on the local machine.
3. This will generate output as shown below:
![CLI output](https://user-images.githubusercontent.com/5861765/43606063-8f3b6a5c-9657-11e8-8e8d-985a7b6b6f2b.png)

Note that the simulations will run fastest on Linux and Mac by taking advantage of special capabilities on these platforms. Simulations will run significantly slower on Windows, though one possibility is to run the simulations through Windows Subsystem for Linux (WSL).

## Outputs

Upon completion, multiple outputs are currently available:
* ERI_Results.csv and ERI_Worksheet.csv files (that mirror the [HERS Method Test form](http://www.resnet.us/programs/2014_HERS-Method_Results-Form.xlsx))
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
```openstudio tests/energy_rating_index_test.rb --mame=test_resnet_hers_method``` (HERS Method tests only)

At the completion of the test, there will be output that denotes the number of failures/errors like so:  
```Finished in 36.067116s, 0.0277 runs/s, 0.9704 assertions/s.```  
```1 runs, 35 assertions, 0 failures, 0 errors, 0 skips```

## Software Developers

To use this workflow, software tools must be able to produce a valid HPXML file; see the included [schema](https://github.com/NREL/OpenStudio-ERI/tree/master/hpxml_schemas). The primary section of the HPXML file for describing a building is found at `/HPXML/Building/BuildingDetails`.

HPXML is an flexible and extensible format, where nearly all fields in the schema are optional and custom fields can be included. Because of this, an ERI Use Case for HPXML is under development that specifies the particular HPXML fields required to run this workflow. The [ERI Use Case](https://github.com/NREL/OpenStudio-ERI/blob/master/measures/301EnergyRatingIndexRuleset/resources/301validator.rb) is defined as a set of conditional XPath expressions. Invalid HPXML files produce errors found in, e.g., the `workflow/HERSRatedHome/run.log` and/or `workflow/HERSReferenceHome/run.log` files.

## Status

*	The 301 ruleset and ERI calculation are **works-in-progress**. 
* The format of the ERI HPXML file is still in flux.
*	The workflow has only been tested with the sample files provided in the `workflow/sample_files` directory.
*	Errors/warnings are not yet being handled gracefully.
*	Limited effort has been spent to optimize/speed up the process. 
