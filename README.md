Residential OpenStudio Measures
===============

**Unit Test Status:** [![CircleCI](https://circleci.com/gh/NREL/OpenStudio-BEopt.svg?style=svg)](https://circleci.com/gh/NREL/OpenStudio-BEopt)

**Code Coverage:** [![Coverage Status](https://coveralls.io/repos/github/NREL/OpenStudio-Beopt/badge.svg?branch=master)](https://coveralls.io/github/NREL/OpenStudio-Beopt?branch=master)

This project includes OpenStudio measures used to model residential buildings.

This project is a <b>work-in-progress</b>. The models are not fully completed nor tested. These measures will eventually be posted on the [Building Component Library](https://bcl.nrel.gov/)

Progress is tracked in this [spreadsheet](https://docs.google.com/spreadsheets/d/1vIwgJtkB-sCFCV2Tnp1OqnjXgA9vTaxtWXw0gpq_Lc4).

## Setup

To get started, go through the [OpenStudio Installation Instructions](http://nrel.github.io/OpenStudio-user-documentation/getting_started/getting_started/#installation-instructions), including the "Optional - Install Ruby" section. The "Optional - Setup a Building Component Library (BCL) Account" section is recommended but not required.

A number of measures in this GitHub repository share the same resource files, found in the top-level ```resources``` directory. In order to run the measures, these resources need to be distributed to each measure. This process has been automated via a rake task (a task defined in the rakefile).

To be able to use the rakefile, follow these steps:

1. Run ```gem install bundler```. (If you get an error, you may have to issue the following: ```gem sources -r https://rubygems.org/``` followed by ```gem sources -a http://rubygems.org/```.)
2. Download DevKit at http://rubyinstaller.org/downloads/. Choose either the 32-bit or 64-bit version for use with Ruby 2.0 or above, depending on which version of Ruby you installed. Run the installer and extract to a directory (e.g., C:\RubyDevKit). Go to this directory and run ```ruby dk.rb init``` followed by ```ruby dk.rb install```
3. Run ```bundler```

Once setup, you can now run ```rake update_resources``` to update the measures' resource files. You will want to perform this task anytime you do a clone or pull of the repository.

You can run ```rake -T``` to see the list of possible rake tasks.

## New Construction Workflow for Users

The New Construction workflow illustrates how to build up a complete residential building model from an [empty seed model](https://github.com/NREL/OpenStudio-BEopt/tree/master/geometries/EmptySeedModel.osm). Note that some measures need to be called before others. For example, the Window Constructions measure must be called after windows have been added to the building. The list below documents the intended workflow for using these measures.

<nowiki>*</nowiki> Note: Nearly every measure is dependent on having the geometry defined first so this is not included in the table for readability purposes.

|Group|Measure|Dependencies*|
|:---|:---|:---|
|1. Location|1. Set Residential Location||
|2. Geometry|1. Create Residential Geometry||
||2. Set Residential Number of Beds and Baths||
||3. Set Residential Number of Occupants|Beds/Baths|
||4. Set Residential Orientation||
||5. Set Residential Eaves||
||6. Set Residential Overhangs|Window Area|
||7. Set Residential Door Area||
||8. Set Residential Window Areas||
||9. Set Neighbors||
|3. Envelope Constructions|1. Set Residential Ceilings/Roofs - Unfinished Attic Constructions||
||2. Set Residential Ceilings/Roofs - Finished Roof Construction||
||3. Set Residential Ceilings/Roofs - Roof Sheathing||
||4. Set Residential Ceilings/Roofs - Roofing Material||
||5. Set Residential Ceilings/Roofs - Radiant Barrier||
||6. Set Residential Ceilings/Roofs - Ceiling Thermal Mass||
||7. Set Residential Foundations/Floors - Finished Basement Constructions||
||8. Set Residential Foundations/Floors - Unfinished Basement Constructions||
||9. Set Residential Foundations/Floors - Crawlspace Constructions||
||10. Set Residential Foundations/Floors - Slab Construction||
||11. Set Residential Foundations/Floors - Interzonal Floor Construction||
||12. Set Residential Foundations/Floors - Floor Covering||
||13. Set Residential Foundations/Floors - Floor Sheathing||
||14. Set Residential Foundations/Floors - Floor Thermal Mass||
||15. Set Residential Walls - Wood Stud Construction (or Double Stud, CMU, etc.)||
||16. Set Residential Walls - Interzonal Construction||
||17. Set Residential Walls - Wall Sheathing||
||18. Set Residential Walls - Exterior Finish||
||19. Set Residential Walls - Exterior Thermal Mass||
||20. Set Residential Walls - Partition Thermal Mass||
||21. Set Residential Uninsulated Surfaces||
||22. Set Residential Window Construction|Window Area|
||23. Set Residential Door Construction|Door Area|
||24. Set Residential Furniture Thermal Mass||
|4. Domestic Hot Water|1. Set Residential Water Heater (Electric Tank, Gas Tankless, etc.)|Beds/Baths|
||2. Set Residential Hot Water Fixtures|Water Heater|
||3. Set Residential Hot Water Distribution|Hot Water Fixtures, Location|
|5. HVAC|1. Set Residential Central Air Conditioner and Furnace (or ASHP, Boiler, MSHP, etc.)||
||2. Set Residential Heating Setpoints and Schedules|HVAC Equipment|
||3. Set Residential Cooling Setpoints and Schedules|HVAC Equipment|
|6. Major Appliances|1. Set Residential Refrigerator||
||2. Set Residential Clothes Washer|Water Heater, Location|
||3. Set Residential Clothes Dryer (Electric or Gas)|Beds/Baths, Clothes Washer|
||4. Set Residential Dishwasher|Water Heater, Location|
||5. Set Residential Cooking Range (Electric or Gas)|Beds/Baths|
|7. Lighting|1. Set Residential Lighting|Location|
|8. Misc Loads|1. Set Residential Plug Loads|Beds/Baths|
||2. Set Residential Extra Refrigerator||
||3. Set Residential Freezer||
||4. Set Residential Hot Tub Heater (Electric or Gas)|Beds/Baths|
||5. Set Residential Hot Tub Pump|Beds/Baths|
||6. Set Residential Pool Heater (Electric or Gas)|Beds/Baths|
||7. Set Residential Pool Pump|Beds/Baths|
||8. Set Residential Well Pump|Beds/Baths|
||9. Set Residential Gas Fireplace|Beds/Baths|
||10. Set Residential Gas Grill|Beds/Baths|
||11. Set Residential Gas Lighting|Beds/Baths|
|9. EnergyPlus Measures|1. Set Residential Airflow|HVAC Equipment, Clothes Dryer|

## Retrofit Workflow for Users

Most of these measures were written to be reusable for existing building retrofits. The intended workflow is to create the existing building from an empty seed model in the same way as the [New Construction Workflow](#new-construction-workflow-for-users). Once the existing building model has been created, the same measures can now be used to replace/modify building components as appropriate. 

For example, while the dishwasher measure added a dishwasher to the model when applied to an empty seed model, the same measure, when applied to the existing building model, will replace the existing dishwasher with the newly specified dishwasher (rather than add an additional dishwasher to the model). This example could be used to evaluate an EnergyStar dishwasher replacement, for example. Alternatively, if the existing building was never assigned a dishwasher, then the measure would indeed add a dishwasher to the model.

Note that some measures are dependent on others. For example, if the Clothes Washer measure were to be applied to the existing building model, such that the existing clothes washer is replaced, the Clothes Dryer measure would also need to be subsequently applied to the existing building model so that its energy use, as dependent on the clothes washer, is correct.
