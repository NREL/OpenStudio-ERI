OpenStudio®-ERI
==============

[![GitHub release (latest by date including pre-releases)](https://img.shields.io/github/v/release/NREL/OpenStudio-ERI?include_prereleases)](https://github.com/NREL/OpenStudio-ERI/releases)
[![ci](https://github.com/NREL/OpenStudio-ERI/actions/workflows/config.yml/badge.svg?branch=master)](https://github.com/NREL/OpenStudio-ERI/actions/workflows/config.yml)
[![Documentation Status](https://readthedocs.org/projects/openstudio-eri/badge/?version=latest)](https://openstudio-eri.readthedocs.io/en/latest/?badge=latest)


The OpenStudio-ERI project allows calculating an Energy Rating Index (ERI) using the Department of Energy's [EnergyPlus™](https://energyplus.net/) simulation platform.
The building description is provided in an [HPXML file](https://hpxml.nrel.gov/) format.
OpenStudio-ERI is intended to be used by user interfaces or other automated software workflows that automatically produce the HPXML file.

The project supports:
- ANSI/RESNET/ICC 301© Standard for the Calculation and Labeling of the Energy Performance of Dwelling and Sleeping Units using an Energy Rating Index
- ENERGY STAR Certification System for Homes and Apartments Using an ERI Compliance Path
- IECC ERI Compliance Alternative (Section R406)
- DOE Efficient New Homes (formerly Zero Energy Ready Homes) Certification Using an ERI Compliance Path

For more information on running simulations, generating HPXML files, etc., please visit the [documentation](https://openstudio-eri.readthedocs.io/en/latest).

OpenStudio-ERI uses [OpenStudio-HPXML](https://github.com/NREL/OpenStudio-HPXML) to run the individual EnergyPlus simulations.
A high-level workflow diagram is shown below:

![Image](https://github.com/user-attachments/assets/9212f9ff-a1a3-4c9b-8b2e-09296a1d1b0b)

## Users

OpenStudio-ERI is used by a number of software products or organizations, including:

- [APEX](https://pivotalenergysolutions.com)
- [Clarity Common Engine](https://psdconsulting.com/solutions/)
- [HouseRater](https://www.houserater.com)
- [REM/Rate™](https://www.remrate.com)

Are you using OpenStudio-ERI and want to be mentioned here? [Email us](mailto:scott.horowitz@nrel.gov) or [open a Pull Request](https://github.com/NREL/OpenStudio-ERI/edit/master/README.md).

## License

This workflow is available under a BSD-3-like license, which is a free, open-source, and permissive license.
For more information, check out the [license file](https://github.com/NREL/OpenStudio-ERI/blob/master/LICENSE.md).

## Disclaimer

Downloading and using this software from this website does not constitute accreditation of the final software product by RESNET.
If you are seeking to develop RESNET Accredited Rating Software, you will need to submit your final software product to RESNET for accreditation.

Any reference herein to RESNET, its activities, products, or services, or any linkages from this website to RESNET's website, does not constitute or imply the endorsement, recommendation, or favoring of the U.S. Government, the Alliance for Energy Innovation, or any of their employees or contractors acting on their behalf.

