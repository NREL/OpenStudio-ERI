Capabilities
============

ERI Capabilities
----------------
The following ERI Standards are supported:

- ANSI/RESNET/ICC 301-2014
- ANSI/RESNET/ICC 301-2019
- ANSI/RESNET/ICC 301-2022

The following ENERGY STAR programs/versions are supported:

- Single Family, National, v3.3, v3.2, v3.1, v3.0
- Single Family, Pacific, v3.0
- Single Family, Florida, v3.1
- Single Family, Oregon and Washington, v3.2
- Multifamily, National, v1.3, v1.2, v1.1, v1.0
- Multifamily, Oregon and Washington, v1.2

The following IECC ERI versions are supported:

- 2015
- 2018
- 2021
- 2024

The following DOE DENH (formerly ZERH) versions are supported:

- 1.0
- Single Family, 2.0
- Multifamily, 2.0

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
