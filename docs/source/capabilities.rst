Capabilities
============

ERI Capabilities
----------------
The following ERI Standards and Addenda are currently available:

- ANSI/RESNET/ICC 301-2014© Standard for the Calculation and Labeling of the Energy Performance of Low-Rise Residential Buildings using an Energy Rating Index
- ANSI/RESNET/ICC 301-2014 Addendum A-2015, Domestic Hot Water Systems
- ANSI/RESNET/ICC 301-2014 Addendum D-2017, Duct Leakage to Outside Test Exception
- ANSI/RESNET/ICC 301-2014 Addendum E-2018, House Size Index Adjustment Factors
- ANSI/RESNET/ICC 301-2014 Addendum G-2018, Solid State Lighting
- ANSI/RESNET/ICC 301-2014 Addendum L-2018, Duct Leakage to Outside Test Exception
- ANSI/RESNET/ICC 301-2019 Standard for the Calculation and Labeling of the Energy Performance of Dwelling and Sleeping Units using an Energy Rating Index
- ANSI/RESNET/ICC 301-2019 Addendum A-2019, Clothes Washers and Dryers and Dishwashers
- ANSI/RESNET/ICC 301-2019 Addendum B-2020, Clarifications, HVAC Quality Installation Grading, and Dehumidification

The following ENERGY STAR programs/versions are supported:

- Single Family, National, v3.1
- Single Family, National, v3
- Single Family, Pacific, v3
- Single Family, Florida, v3.1
- Single Family, Oregon and Washington, v3.2
- Multifamily, National, v1.1
- Multifamily, National, v1
- Multifamily, Oregon and Washington, v1.2

Accuracy vs Speed
-----------------

The EnergyPlus simulation engine is like a Swiss army knife.
There are often multiple models available for the same building technology with varying trade-offs between accuracy and speed.
This workflow standardizes the use of EnergyPlus (e.g., the choice of models appropriate for residential buildings) to provide a fast and easy to use solution.

The workflow is continuously being evaluated for ways to reduce runtime without significant impact on accuracy.
A number of such enhancements have been made to date.

There are additional ways that software developers using this workflow can reduce runtime:

- Run on Linux/Mac platform, which is significantly faster by taking advantage of the POSIX fork call.
- Do not use the ``--hourly`` flag unless hourly output is required. If required, limit requests to hourly variables of interest.
- Run on computing environments with 1) fast CPUs, 2) sufficient memory, and 3) enough processors to allow all simulations to run in parallel.
- Avoid using the ``--add-component-loads`` argument if heating/cooling component loads are not of interest.
