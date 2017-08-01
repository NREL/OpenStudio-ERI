OpenStudio-ERI
===============

**Unit Test Status:** [![CircleCI](https://circleci.com/gh/NREL/OpenStudio-ERI.svg?style=svg)](https://circleci.com/gh/NREL/OpenStudio-ERI)

**Code Coverage:** [![Coverage Status](https://coveralls.io/repos/github/NREL/OpenStudio-ERI/badge.svg?branch=master)](https://coveralls.io/github/NREL/OpenStudio-ERI?branch=master)

Calculates an Energy Rating Index via an OpenStudio/EnergyPlus-based workflow. Building information is provided through an [HPXML file](https://hpxml.nrel.gov/).

## Setup

Download the latest version of OpenStudio from https://www.openstudio.net/developers. At a minimum, install the "Command Line Interface".

## Running

1. Navigate to the `workflow` directory.
2. Run the ERI calculation on a provided sample HPXML file like so: 
```c:/openstudio-2.2.0/bin/openstudio.exe execute_ruby_script energy_rating_index.rb -x sample_files/valid.xml -e sample_files/denver.epw```
Note that the Reference Home and Rated Home workflows/simulations will be executed in parallel on the local machine.
3. This should generate output like so:
![CLI output](https://user-images.githubusercontent.com/5861765/28829926-9bc71a36-7692-11e7-9cdb-5f8733c55aef.png)
Results files (Reference/Rated HPXML files and output CSVs) will show up in the results/ dir.

## Disclaimers

*	The 301 ruleset and ERI calculation are very much both **works-in-progress**. 
* The format of the RESNET HPXML file is still in flux.
*	The workflow has only been tested with a few sample files, as provided in the `workflow/sample_files` directory.
*	Errors/warnings are not yet being handled gracefully.
*	No effort has been spent to optimize/speed up the process yet. 
