Residential OpenStudio Measures
===============

**Unit Test Status:** [![CircleCI](https://circleci.com/gh/NREL/OpenStudio-BEopt.svg?style=svg)](https://circleci.com/gh/NREL/OpenStudio-BEopt)

**Code Coverage:** [![Coverage Status](https://coveralls.io/repos/github/NREL/OpenStudio-Beopt/badge.svg?branch=master)](https://coveralls.io/github/NREL/OpenStudio-Beopt?branch=master)

This project includes [OpenStudio measures](http://nrel.github.io/OpenStudio-user-documentation/getting_started/about_measures/) used to model residential buildings via the [EnergyPlus simulation engine](http://energyplus.net/).

This project is a <b>work-in-progress</b>. The models are not fully completed nor tested. These measures will eventually be posted on the [Building Component Library](https://bcl.nrel.gov/).

Progress is tracked in this [spreadsheet](https://docs.google.com/spreadsheets/d/1vIwgJtkB-sCFCV2Tnp1OqnjXgA9vTaxtWXw0gpq_Lc4).

## Table of Contents

* [Development](#development)
* [Running the Measures](#running-the-measures)
* [Workflows](#workflows)
* [Outputs](#outputs)

## Development

See the [wiki page](https://github.com/NREL/OpenStudio-BEopt/wiki/Development) for getting setup as a developer. Also reference the [OpenStudio Measure Writer's Guide](http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/) for in-depth resources on authoring and testing measures.

## Running the Measures

Please read the [Workflows](#workflows) section to understand how the measures are intended to be used, as well as the [Outputs](#outputs) section for a description of the types of outputs that can be produced.

The measures can be run via the standard OpenStudio approaches: the user interfaces ([OpenStudio Application](http://nrel.github.io/OpenStudio-user-documentation/reference/openstudio_application_interface/) and [Parametric Analysis Tool](http://nrel.github.io/OpenStudio-user-documentation/reference/parametric_analysis_tool_2/)), the [Command Line Interface](http://nrel.github.io/OpenStudio-user-documentation/reference/command_line_interface/), or via the [OpenStudio SDK](https://openstudio-sdk-documentation.s3.amazonaws.com/index.html).

If interested in programatically driving the simulations, you will likely find it easiest to use the Command Line Interface approach. The Command Line Interface is a self-contained executable that can run an OpenStudio Workflow file, which defines a series of OpenStudio measures to apply.

An example OpenStudio Workflow [(create-model-example.osw)](https://github.com/NREL/OpenStudio-BEopt/blob/master/workflows/create-model-example.osw) is provided with a pre-populated selection of residential measures and arguments. It can be modified as needed and then run like so:

`openstudio.exe run -w create-model-example.osw`

This will apply the measures to the OpenStudio seed model specified in the .osw, run the EnergyPlus simulation, and produce output. 

### Measure Order

The order in which these measures are called is important. For example, the Window Constructions measure must be called after windows have been added to the building. The table below documents the intended order of using these measures, and was automatically generated from a [JSON file](https://github.com/NREL/OpenStudio-BEopt/blob/master/workflows/measure-info.json).

<nowiki>*</nowiki> Note: Nearly every measure is dependent on having the geometry defined first so this is not included in the table for readability purposes.

<!--- The below table is automated via a rake task -->
<!--- MEASURE_WORKFLOW_START -->
|Group|Measure|Dependencies*|
|:---|:---|:---|
|1. Location|1. Location||
|2. Geometry|1. Geometry - Single-Family Detached (or Single-Family Attached or Multifamily)||
||2. Number of Beds and Baths||
||3. Number of Occupants|Beds/Baths|
||4. Orientation||
||5. Eaves||
||6. Door Area||
||7. Window Areas||
||8. Overhangs|Window Areas|
||9. Neighbors||
|3. Envelope Constructions|1. Ceilings/Roofs - Unfinished Attic (or Finished Roof)||
||2. Ceilings/Roofs - Roof Sheathing||
||3. Ceilings/Roofs - Roofing Material||
||4. Ceilings/Roofs - Radiant Barrier||
||5. Ceilings/Roofs - Ceiling Thermal Mass||
||6. Foundations/Floors - Slab (or Finished Basement, Unfinished Basement, Crawlspace, Pier & Beam)||
||7. Foundations/Floors - Interzonal Floor Construction||
||8. Foundations/Floors - Floor Covering||
||9. Foundations/Floors - Floor Sheathing||
||10. Foundations/Floors - Floor Thermal Mass||
||11. Walls - Wood Stud (or Double Stud, CMU, etc.)||
||12. Walls - Interzonal Construction||
||13. Walls - Wall Sheathing||
||14. Walls - Exterior Finish||
||15. Walls - Exterior Thermal Mass||
||16. Walls - Partition Thermal Mass||
||17. Uninsulated Surfaces||
||18. Window Construction|Window Areas, Location|
||19. Door Construction|Door Area|
||20. Furniture Thermal Mass||
|4. Domestic Hot Water|1. Water Heater - Fuel Tank (or Electric Tank, Fuel Tankless, Heat Pump, etc.)|Beds/Baths|
||2. Hot Water Fixtures|Water Heater|
||3. Hot Water Distribution|Hot Water Fixtures, Location|
|5. HVAC|1. Central Air Source Heat Pump (or AC/Furnace, Boiler, MSHP, etc.)||
||2. Heating Setpoint|HVAC Equipment, Location|
||3. Cooling Setpoint|HVAC Equipment, Location|
||4. Ceiling Fan|Cooling Setpoint, Beds/Baths|
|6. Major Appliances|1. Refrigerator||
||2. Clothes Washer|Water Heater, Location|
||3. Clothes Dryer - Electric (or Fuel)|Beds/Baths, Clothes Washer|
||4. Dishwasher|Water Heater, Location|
||5. Cooking Range - Electric (or Fuel)|Beds/Baths|
|7. Lighting|1. Lighting|Location|
|8. Misc Loads|1. Plug Loads|Beds/Baths|
||2. Extra Refrigerator||
||3. Freezer||
||4. Hot Tub Heater - Electric (or Gas)|Beds/Baths|
||5. Hot Tub Pump|Beds/Baths|
||6. Pool Heater - Electric (or Gas)|Beds/Baths|
||7. Pool Pump|Beds/Baths|
||8. Well Pump|Beds/Baths|
||9. Gas Fireplace|Beds/Baths|
||10. Gas Grill|Beds/Baths|
||11. Gas Lighting|Beds/Baths|
|9. Airflow|1. Airflow|Location, Beds/Baths, HVAC Equipment, Clothes Dryer|
|10. Sizing|1. HVAC Sizing|(lots of measures...)|
<!--- MEASURE_WORKFLOW_END -->

## Workflows

These measures can be used in different workflows:
* [Create Model](#workflow-create-model) - Build up a model from scratch.
* [Modify Model](#workflow-modify-model) - Apply a measure to an existing model.
* [Translate Model From HPXML](#workflow-translate-model-from-hpxml) - Translate a model from a supplyied HPXML file.
* [Create Model from Geometry](#workflow-create-model-from-geometry) - Build up a model on top of an existing geometry.

### Workflow: Create Model

Status: **Available**

![Create Model Diagram](https://cloud.githubusercontent.com/assets/5861765/25557650/fde65e34-2cd2-11e7-8b72-f48745203637.png)

The Create Model workflow allows building up a complete residential building model from an [empty seed](https://github.com/NREL/OpenStudio-BEopt/blob/master/seeds/EmptySeedModel.osm) and calling a series of measures. The measures should be applied according to the specified [measure order](#measure-order).

This workflow includes simple geometry measures to quickly develop 3D building geometry from text-based inputs (floor area, foundation type, number of stories, etc.). These measures are not meant to replace more sophisticated geometry approaches.

### Workflow: Modify Model

Status: **Available**

![Modify Model Workflow Diagram](https://cloud.githubusercontent.com/assets/5861765/25557651/00626b9e-2cd3-11e7-9f56-f380a23a575d.png)

Most of these measures were written to be reusable for existing building retrofits. For example, while the dishwasher measure adds a dishwasher to a model without a dishwasher, the same measure will replace a dishwasher that already exists in an existing building model (rather than adding an additional dishwasher to the model). This could be used to evaluate an EnergyStar dishwasher replacement, for example.

Note that some measures are dependent on others. For example, if the Clothes Washer measure were to be applied to the existing building model, such that the existing clothes washer is replaced, the Clothes Dryer measure would also need to be subsequently applied to the existing building model so that its energy use, as dependent on the clothes washer, is correct.

While some of these measures may work on any user-created OpenStudio model, they have only been tested on, and are primarily intended to operate on, models created via one of the supported [Workflows](#workflows).

### Workflow: Translate Model From HPXML

Status: **Under Development**

![Translate Model From HPXML Diagram](https://cloud.githubusercontent.com/assets/5861765/25557649/fb0fd910-2cd2-11e7-8e23-bd7815ffd982.png)

[HPXML](http://www.hpxmlonline.com/) is an open data standard that supports the exchange of information and data for residential buildings. A number of software tools have capabilities for reading or writing these XML files.

For software that can export a HPXML file, development is underway to easily translate this into an OpenStudio model. If you are a tool developer that is interested to export HPXML files, see the [HPXML Toolbox](https://hpxml.nrel.gov/) for additional resources.

One of the primary reasons for supporting this workflow is to allow the calculation of an [Energy Rating Index](#output-energy-rating-index-eri) using EnergyPlus.

### Workflow: Create Model From Geometry

Status: **Not Yet Available**

![Create Model From Geometry](https://cloud.githubusercontent.com/assets/5861765/25557648/f77be4e2-2cd2-11e7-9837-33840cadd369.png)

Description pending.

## Outputs

These measures allow multiple outputs to be calculated:
* [Simulation Results](#output-simulation-results) - Standard EnergyPlus annual and time series results by end use.
* [Utility Bills](#output-utility-bills) - Simple of complex residential utility bills.
* [Energy Rating Index (ERI)](#output-energy-rating-index-eri) - Calculation for the 301 Standard/HERS Index".

### Output: Simulation Results

Status: **Available**

Description pending.

### Output: Utility Bills

Status: **Under Development**

Description pending.

### Output: Energy Rating Index (ERI)

Status: **Under Development**

Calculations are under development for ANSI/RESNET 301-2014 "Standard for the Calculation and Labeling of the Energy Performance of Low-Rise Residential Buildings using the HERS Index". This metric is also a performance compliance path in the 2015 IECC. Any OpenStudio model created via one of the above [Workflows](#workflows) will be able to obtain an ERI.

Note that because the calculation involves performing multiple simulations (e.g., the Reference Home and Rated Home), a custom workflow will be developed to support this.