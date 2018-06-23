OpenStudio-ERI
===============

Calculates an Energy Rating Index (ERI) via an OpenStudio/EnergyPlus-based workflow. Building information is provided through an [HPXML file](https://hpxml.nrel.gov/).

The ERI is defined by ANSI/RESNET 301-2014 "Standard for the Calculation and Labeling of the Energy Performance of Low-Rise Residential Buildings using the HERS Index".

**Unit Test Status:** [![CircleCI](https://circleci.com/gh/NREL/OpenStudio-ERI/tree/master.svg?style=svg)](https://circleci.com/gh/NREL/OpenStudio-ERI/tree/master)

**Code Coverage:** [![Coverage Status](https://coveralls.io/repos/github/NREL/OpenStudio-ERI/badge.svg?branch=master)](https://coveralls.io/github/NREL/OpenStudio-ERI?branch=master)

## Setup

1. Download [OpenStudio 2.5.1](https://github.com/NREL/OpenStudio/releases/tag/v2.5.1). At a minimum, install the Command Line Interface and EnergyPlus components.
2. Clone or download this repository's source code. 
3. To obtain all available weather files, navigate to the [workflow](https://github.com/NREL/OpenStudio-ERI/tree/master/workflow) directory and run:
```openstudio.exe energy_rating_index.rb --download-weather``` 

## Running

1. Navigate to the [workflow](https://github.com/NREL/OpenStudio-ERI/tree/master/workflow) directory.
2. Run the ERI calculation on a provided sample HPXML file:  
```openstudio.exe energy_rating_index.rb -x sample_files/valid.xml```  
Note that the Reference Home and Rated Home workflows/simulations will be executed in parallel on the local machine.
3. This will generate output as shown below:
![CLI output](https://user-images.githubusercontent.com/5861765/39766722-27564de2-52a2-11e8-9b14-e49a03514d0f.png)

## Outputs

Upon completion, multiple outputs are currently available:
* ERI_Results.csv and ERI_Worksheet.csv files (that mirror the [HERS Method Test form](http://www.resnet.us/programs/2014_HERS-Method_Results-Form.xlsx))
* Reference & Rated Home HPXML files (transformations of the input HPXML file via the 301 ruleset)
* Summary annual energy consumption by fuel type and/or end use
* EnergyPlus input/output files

See the [sample_results](https://github.com/NREL/OpenStudio-ERI/tree/master/workflow/sample_results) directory for examples of these outputs.

## Tests

Continuous integration tests are automatically run for any change to this repository. The current set of tests include:
- [x] Successful ERI calculations for all sample files
- [x] RESNET HERS Reference Home auto-generation tests
- [x] RESNET HERS method tests (including IAF and proposed tests)
- [x] RESNET Hot water system performance tests (including pre-Addendum A tests)

TODO: Describe how to run the tests locally.

## Software Developers

To use this workflow, software tools must be able to produce a valid HPXML file; see the included [schema](https://github.com/NREL/OpenStudio-ERI/tree/master/hpxml_schemas). The primary section of the HPXML file for describing a building is found at `/HPXML/Building/BuildingDetails`.

HPXML is an flexible and extensible format, where nearly all fields in the schema are optional and custom fields can be included. Because of this, an ERI Use Case for HPXML is under development that specifies the particular HPXML fields required to run this workflow. The [ERI Use Case](https://github.com/NREL/OpenStudio-ERI/blob/master/measures/301EnergyRatingIndexRuleset/resources/301validator.rb) is defined as a set of conditional XPath expressions. Invalid HPXML files produce errors found in, e.g., the `workflow/HERSRatedHome/run.log` and/or `workflow/HERSReferenceHome/run.log` files.

## Status

*	The 301 ruleset and ERI calculation are **works-in-progress**. 
* The format of the ERI HPXML file is still in flux.
*	The workflow has only been tested with the sample files provided in the `workflow/sample_files` directory.
*	Errors/warnings are not yet being handled gracefully.
*	Limited effort has been spent to optimize/speed up the process. 
