Capabilities
============

ERI Capabilities
----------------
The following ERI Standards and Addenda are currently available:

- ANSI/RESNET/ICC 301-2014© "Standard for the Calculation and Labeling of the Energy Performance of Low-Rise Residential Buildings using an Energy Rating Index".
- ANSI/RESNET/ICC 301-2014 Addendum A-2015, Domestic Hot Water Systems, January 15, 2016
- ANSI/RESNET/ICC 301-2014 Addendum E-2018, House Size Index Adjustment Factors, February 1, 2018
- ANSI/RESNET/ICC 301-2014 Addendum G-2018, Solid State Lighting, February 2, 2018

Modeling Capabilities
---------------------
The following building features/technologies are available for modeling:

- Enclosure

  - Attics
  
    - Vented
    - Unvented
    - Conditioned
    - Radiant Barriers
    
  - Foundations
  
    - Slab
    - Unconditioned Basement
    - Conditioned Basement
    - Vented Crawlspace
    - Unvented Crawlspace
    - Ambient
    
  - Garages
  - Windows & Overhangs
  - Skylights
  - Doors
  
- HVAC

  - Heating Systems
  
    - Electric Resistance
    - Furnaces
    - Wall Furnaces & Stoves
    - Boilers
    
  - Cooling Systems
  
    - Central Air Conditioners
    - Room Air Conditioners
    
  - Heat Pumps
  
    - Air Source Heat Pumps
    - Mini Split Heat Pumps
    - Ground Source Heat Pumps
    
  - Thermostat Type
  - Ducts
  
- Water Heating

  - Water Heaters
  
    - Storage Tank
    - Instantaneous Tankless
    - Heat Pump Water Heater
    - Indirect Water Heater (Combination Boiler)
    - Tankless Coil (Combination Boiler)
    
  - Hot Water Distribution
  
    - Recirculation
    
  - Drain Water Heat Recovery
  - Low-Flow Fixtures
  
- Mechanical Ventilation

  - Exhaust Only
  - Supply Only
  - Balanced
  - Energy Recovery Ventilator
  - Heat Recovery Ventilator
  - Central Fan Integrated Supply
  
- Photovoltaics
- Appliances

  - Clothes Washer
  - Clothes Dryer
  - Dishwasher
  - Refrigerator
  - Cooking Range/Oven
  
- Lighting
- Ceiling Fans

Accuracy vs Speed
-----------------

The EnergyPlus simulation engine is like a Swiss army knife.
There are often multiple models available for the same building technology with varying tradeoffs between accuracy and speed.
This workflow standardizes the use of EnergyPlus (e.g., the choice of models appropriate for residential buildings) to provide a fast and easy to use solution.

The workflow is continuously being evaluated for ways to reduce runtime without significant impact on accuracy.
A number of such enhancements have been made to date.

There are additional ways that software developers using this workflow can reduce runtime:

- Run on Linux/Mac platform, which is significantly faster by taking advantage of the POSIX fork call.
- Use the --no-ssl flag to prevent SSL initialization in OpenStudio.
- Use the -s flag to skip HPXML validation.
- Run on computing environments with 1) fast CPUs, 2) sufficient memory, and 3) enough processors to allow all simulations to run in parallel.
