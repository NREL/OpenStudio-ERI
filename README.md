Residential OpenStudio Measures
===============

Files to support residential measures in OpenStudio

Progress is tracked in this [spreadsheet](https://docs.google.com/spreadsheets/d/1vIwgJtkB-sCFCV2Tnp1OqnjXgA9vTaxtWXw0gpq_Lc4/edit#gid=0)

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

1. Location:
  1. Set Residential Location
2. Gometry:
  1. Create Residential Geometry
  2. Set Residential Orientation
  3. Set Residential Eaves
  4. <Windows measure>
  5. Set Residential Overhangs
  6. Set Neighbors
3. Envelope Constructions:
  1. Ceilings/Roofs:
    1. Set Residential Ceilings/Roofs - Unfinished Attic Constructions
    2. Set Residential Ceilings/Roofs - Finished Roof Construction
    3. Set Residential Ceilings/Roofs - Roof Sheathing
    4. Set Residential Ceilings/Roofs - Roofing Material
    5. Set Residential Ceilings/Roofs - Radiant Barrier
  2. Foundations/Floors:
    1. TODO
    2. TODO
  3. Walls:
    1. TODO
    2. TODO
  4. Other:
4. Water Heating:
  1. TODO
  2. TODO
5. HVAC:
  1. TODO
  2. TODO
6. Major Appliances:
  1. TODO
  2. TODO
7. Lighting:
  1. TODO
  2. TODO
8. Plug Loads:
  1. TODO
  2. TODO
9. Other:
  1. TODO
  2. TODO
