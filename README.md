Residential OpenStudio Measures
===============

Files to support residential measures in OpenStudio

Progress is tracked in this [spreadsheet](https://docs.google.com/spreadsheets/d/1vIwgJtkB-sCFCV2Tnp1OqnjXgA9vTaxtWXw0gpq_Lc4)

## Setup

A number of measures share the same resource files, found in the top-level ```resources``` directory. In order to run the measures, these resources need to be distributed to each measure. This process has been automated via a rake task (a task defined in the rakefile).

To be able to use the rakefile, follow these steps:

1. Run ```gem sources -r https://rubygems.org/```
2. Run ```gem sources -a http://rubygems.org/```
3. Run ```gem install bundler```
4. Download DevKit at http://rubyinstaller.org/downloads/. Choose either the 32-bit or 64-bit version for use with Ruby 2.0 or above, depending on which version of Ruby you installed. Run the installer and extract to a directory (e.g., C:\RubyDevKit). Go to this directory and run ```ruby dk.rb init``` followed by ```ruby dk.rb install```
5. Run ```bundler```

Once setup, you can now run ```rake update_resources``` to update the measures' resource files. You can also run ```rake -T``` to see the list of possible rake tasks.

## Workflow for Users

To build up a complete residential building model from an empty seed model, some measures need to be called before others. For example, the Window Constructions measure must be called after windows have been added to the building. The list below documents the intended workflow for using these measures.

<nowiki>*</nowiki> Note: Nearly every measure is dependent on having the geometry defined first so this is not included in the table for readability purposes.

|Group|Measure|Dependencies*|
|:---|:---|:---|
|1. Location|1. Set Residential Location||
|2. Geometry|1. Create Residential Geometry||
||2. Set Residential Number of Beds, Baths, and Occupants||
||3. Set Residential Orientation||
||4. Set Residential Eaves||
||5. [Windows measure]||
||6. Set Residential Overhangs|Window Area|
||7. Set Residential Door Area||
||8. Set Neighbors||
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
||17. Set Residential Walls - Partition Construction||
||18. Set Residential Walls - Wall Sheathing||
||19. Set Residential Walls - Exterior Finish||
||20. Set Residential Walls - Exterior Thermal Mass||
||21. Set Residential Walls - Partition Thermal Mass||
||22. Set Residential Uninsulated Surfaces||
||23. Set Residential Window Construction|Window Area|
||24. Set Residential Door Construction|Door Area|
||25. Set Residential Furniture Thermal Mass|TODO|
|4. Water Heating|1. Set Residential Water Heater (Electric Tank, Gas Tankless, etc.)|Beds/Baths|
||2. [Hot water distribution; before or after water heater?]||
|5. HVAC|1. TODO||
||2. TODO||
|6. Major Appliances|1. Set Residential Refrigerator||
||2. Set Residential Clothes Washer|Water Heater, Location|
||3. Set Residential Clothes Dryer (Electric or Gas)|Beds/Baths, Clothes Washer|
||4. Set Residential Dishwasher|Water Heater, Location|
||5. Set Residential Cooking Range (Electric or Gas)|Beds/Baths|
|7. Lighting|1. TODO||
||2. TODO||
|8. Plug Loads|1. Set Residential Plug Loads|Beds/Baths|
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
|9. Other|1. TODO||
||2. TODO||

