<?xml version="1.0" encoding="UTF-8"?>
<sch:schema xmlns:sch='http://purl.oclc.org/dsdl/schematron'>
  <sch:title>HPXML Schematron Validator: Energy Rating Index</sch:title>
  <sch:ns uri='http://hpxmlonline.com/2023/09' prefix='h'/>

  <sch:pattern>
    <sch:title>[Root]</sch:title>
    <sch:rule context='/h:HPXML'>
      <sch:assert role='ERROR' test='count(h:Building) = 1'>Expected 1 element(s) for xpath: Building</sch:assert> <!-- See [Building] -->
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[ERIVersion]</sch:title>
    <sch:rule context='/h:HPXML/h:SoftwareInfo/h:extension/h:ERICalculation/h:Version'>
      <sch:assert role='ERROR' test='text()="latest" or text()="2022CE" or text()="2022C" or text()="2022" or text()="2019ABCD" or text()="2019ABC" or text()="2019AB" or text()="2019A" or text()="2019" or text()="2014AEG" or text()="2014AE" or text()="2014A" or text()="2014"'>Expected SoftwareInfo/extension/ERICalculation/Version to be 'latest' or '2022CE' or '2022C' or '2022' or '2019ABCD' or '2019ABC' or '2019AB' or '2019A' or '2019' or '2014AEG' or '2014AE' or '2014A' or '2014'</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[CO2eVersion]</sch:title>
    <sch:rule context='/h:HPXML/h:SoftwareInfo/h:extension/h:CO2IndexCalculation/h:Version'>
      <sch:assert role='ERROR' test='text()="latest" or text()="2022CE" or text()="2022C" or text()="2022" or text()="2019ABCD"'>Expected SoftwareInfo/extension/CO2IndexCalculation/Version to be 'latest' or '2022CE' or '2022C' or '2022' or '2019ABCD'</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[IECCVersion]</sch:title>
    <sch:rule context='/h:HPXML/h:SoftwareInfo/h:extension/h:IECCERICalculation/h:Version'>
      <sch:assert role='ERROR' test='text()="2024" or text()="2021" or text()="2018" or text()="2015"'>Expected SoftwareInfo/extension/IECCERICalculation/Version to be '2024' or '2021' or '2018' or '2015'</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[ESVersion]</sch:title>
    <sch:rule context='/h:HPXML/h:SoftwareInfo/h:extension/h:EnergyStarCalculation/h:Version'>
      <sch:assert role='ERROR' test='text()="SF_National_3.0" or text()="SF_National_3.1" or text()="SF_National_3.2" or text()="SF_National_3.3" or text()="SF_Pacific_3.0" or text()="SF_Florida_3.1" or text()="SF_OregonWashington_3.2" or text()="MF_National_1.0" or text()="MF_National_1.1" or text()="MF_National_1.2" or text()="MF_National_1.3" or text()="MF_OregonWashington_1.2"'>Expected SoftwareInfo/extension/EnergyStarCalculation/Version to be 'SF_National_3.0' or 'SF_National_3.1' or 'SF_National_3.2' or 'SF_National_3.3' or 'SF_Pacific_3.0' or 'SF_Florida_3.1' or 'SF_OregonWashington_3.2' or 'MF_National_1.0' or 'MF_National_1.1' or 'MF_National_1.2' or 'MF_National_1.3' or 'MF_OregonWashington_1.2'</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[ESVersion=SF]</sch:title>
    <sch:rule context='/h:HPXML/h:SoftwareInfo/h:extension/h:EnergyStarCalculation/h:Version[contains(text(), "SF")]'>
      <sch:assert role='ERROR' test='count(../../../../h:Building/h:BuildingDetails/h:BuildingSummary/h:BuildingConstruction[h:ResidentialFacilityType[text()="single-family detached" or text()="single-family attached"]]) = 1'>Expected 1 element(s) for xpath: ../../../../Building/BuildingDetails/BuildingSummary/BuildingConstruction[ResidentialFacilityType[text()="single-family detached" or text()="single-family attached"]]</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[ESVersion=SFPacific30]</sch:title>
    <sch:rule context='/h:HPXML/h:SoftwareInfo/h:extension/h:EnergyStarCalculation/h:Version[text()="SF_Pacific_3.0"]'>
      <sch:assert role='ERROR' test='count(../../../../h:Building/h:Site/h:Address/h:StateCode[text()="HI" or text()="GU" or text()="MP"]) = 1'>Expected 1 element(s) for xpath: ../../../../Building/Site/Address/StateCode[text()="HI" or text()="GU" or text()="MP"]</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[ESVersion=SFFlorida31]</sch:title>
    <sch:rule context='/h:HPXML/h:SoftwareInfo/h:extension/h:EnergyStarCalculation/h:Version[text()="SF_Florida_3.1"]'>
      <sch:assert role='ERROR' test='count(../../../../h:Building/h:Site/h:Address/h:StateCode[text()="FL"]) = 1'>Expected 1 element(s) for xpath: ../../../../Building/Site/Address/StateCode[text()="FL"]</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[ESVersion=SFOregonWashington32]</sch:title>
    <sch:rule context='/h:HPXML/h:SoftwareInfo/h:extension/h:EnergyStarCalculation/h:Version[text()="SF_OregonWashington_3.2"]'>
      <sch:assert role='ERROR' test='count(../../../../h:Building/h:Site/h:Address/h:StateCode[text()="OR" or text()="WA"]) = 1'>Expected 1 element(s) for xpath: ../../../../Building/Site/Address/StateCode[text()="OR" or text()="WA"]</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[ESVersion=MF]</sch:title>
    <sch:rule context='/h:HPXML/h:SoftwareInfo/h:extension/h:EnergyStarCalculation/h:Version[contains(text(), "MF")]'>
      <sch:assert role='ERROR' test='count(../../../../h:Building/h:BuildingDetails/h:BuildingSummary/h:BuildingConstruction[h:ResidentialFacilityType="apartment unit"]) = 1'>Expected 1 element(s) for xpath: ../../../../Building/BuildingDetails/BuildingSummary/BuildingConstruction[ResidentialFacilityType="apartment unit"]</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[ESVersion=MFOregonWashington12]</sch:title>
    <sch:rule context='/h:HPXML/h:SoftwareInfo/h:extension/h:EnergyStarCalculation/h:Version[text()="MF_OregonWashington_1.2"]'>
      <sch:assert role='ERROR' test='count(../../../../h:Building/h:Site/h:Address/h:StateCode[text()="OR" or text()="WA"]) = 1'>Expected 1 element(s) for xpath: ../../../../Building/Site/Address/StateCode[text()="OR" or text()="WA"]</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[DENHVersion]</sch:title>
    <sch:rule context='/h:HPXML/h:SoftwareInfo/h:extension/h:DENHCalculation/h:Version'>
      <sch:assert role='ERROR' test='text()="1.0" or text()="SF_2.0" or text()="MF_2.0"'>Expected SoftwareInfo/extension/DENHCalculation/Version to be '1.0' or 'SF_2.0' or 'MF_2.0'</sch:assert> <!-- See [DENHVersion=SF_2.0] or [DENHVersion=MF_2.0] -->
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[DENHVersion=SF]</sch:title>
    <sch:rule context='/h:HPXML/h:SoftwareInfo/h:extension/h:DENHCalculation/h:Version[contains(text(), "SF")]'>
      <sch:assert role='ERROR' test='count(../../../../h:Building/h:BuildingDetails/h:BuildingSummary/h:BuildingConstruction[h:ResidentialFacilityType[text()="single-family detached" or text()="single-family attached"]]) = 1'>Expected 1 element(s) for xpath: ../../../../Building/BuildingDetails/BuildingSummary/BuildingConstruction[ResidentialFacilityType[text()="single-family detached" or text()="single-family attached"]]</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[DENHVersion=MF]</sch:title>
    <sch:rule context='/h:HPXML/h:SoftwareInfo/h:extension/h:DENHCalculation/h:Version[contains(text(), "MF")]'>
      <sch:assert role='ERROR' test='count(../../../../h:Building/h:BuildingDetails/h:BuildingSummary/h:BuildingConstruction[h:ResidentialFacilityType[text()="apartment unit"]]) = 1'>Expected 1 element(s) for xpath: ../../../../Building/BuildingDetails/BuildingSummary/BuildingConstruction[ResidentialFacilityType[text()="apartment unit"]]</sch:assert>
    </sch:rule>
  </sch:pattern>

   <sch:pattern>
    <sch:title>[Building]</sch:title>
    <sch:rule context='/h:HPXML/h:Building'>
      <sch:assert role='ERROR' test='count(h:Site) = 1'>Expected 1 element(s) for xpath: Site</sch:assert> <!-- See [BuildingSite] -->
      <sch:assert role='ERROR' test='count(h:BuildingDetails) = 1'>Expected 1 element(s) for xpath: BuildingDetails</sch:assert> <!-- See [BuildingDetails] -->
    </sch:rule>
  </sch:pattern>

 <sch:pattern>
    <sch:title>[BuildingSite]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:Site'>
      <sch:assert role='ERROR' test='count(h:Address/h:StateCode) = 1'>Expected 1 element(s) for xpath: Address/StateCode</sch:assert>
      <sch:assert role='ERROR' test='count(h:Address/h:ZipCode) = 1'>Expected 1 element(s) for xpath: Address/ZipCode</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[BuildingDetails]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails'>
      <sch:assert role='ERROR' test='count(h:BuildingSummary/h:Site) = 1'>Expected 1 element(s) for xpath: BuildingSummary/Site</sch:assert> <!-- See [Site] -->
      <sch:assert role='ERROR' test='count(h:BuildingSummary/h:BuildingConstruction) = 1'>Expected 1 element(s) for xpath: BuildingSummary/BuildingConstruction</sch:assert> <!-- See [BuildingConstruction] -->
      <sch:assert role='ERROR' test='count(h:ClimateandRiskZones/h:ClimateZoneIECC[h:Year="2006"]/h:ClimateZone) = 1'>Expected 1 element(s) for xpath: ClimateandRiskZones/ClimateZoneIECC[Year="2006"]/ClimateZone</sch:assert>
      <sch:assert role='ERROR' test='count(h:ClimateandRiskZones/h:WeatherStation/h:extension/h:EPWFilePath) &lt;= 1'>Expected 0 or 1 element(s) for xpath: ClimateandRiskZones/WeatherStation/extension/EPWFilePath</sch:assert>
      <sch:assert role='ERROR' test='count(h:Enclosure/h:AirInfiltration/h:AirInfiltrationMeasurement[h:BuildingAirLeakage/h:AirLeakage | h:EffectiveLeakageArea]) = 1'>Expected 1 element(s) for xpath: Enclosure/AirInfiltration/AirInfiltrationMeasurement[BuildingAirLeakage/AirLeakage | EffectiveLeakageArea]</sch:assert> <!-- See [AirInfiltrationMeasurement] -->
      <sch:assert role='ERROR' test='count(h:Enclosure/h:Attics/h:Attic) &gt;= 0'>Expected 0 or more element(s) for xpath: Enclosure/Attics/Attic</sch:assert> <!-- See [Attic] -->
      <sch:assert role='ERROR' test='count(h:Enclosure/h:Foundations/h:Foundation) &gt;= 0'>Expected 0 or more element(s) for xpath: Enclosure/Foundations/Foundation</sch:assert> <!-- See [Foundation] -->
      <sch:assert role='ERROR' test='count(h:Enclosure/h:Roofs/h:Roof) &gt;= 0'>Expected 0 or more element(s) for xpath: Enclosure/Roofs/Roof</sch:assert> <!-- See [Roof] -->
      <sch:assert role='ERROR' test='count(h:Enclosure/h:RimJoists/h:RimJoist) &gt;= 0'>Expected 0 or more element(s) for xpath: Enclosure/RimJoists/RimJoist</sch:assert> <!-- See [RimJoist] -->
      <sch:assert role='ERROR' test='count(h:Enclosure/h:Walls/h:Wall) &gt;= 1'>Expected 1 or more element(s) for xpath: Enclosure/Walls/Wall</sch:assert> <!-- See [Wall] -->
      <sch:assert role='ERROR' test='count(h:Enclosure/h:FoundationWalls/h:FoundationWall) &gt;= 0'>Expected 0 or more element(s) for xpath: Enclosure/FoundationWalls/FoundationWall</sch:assert> <!-- See [FoundationWall] -->
      <sch:assert role='ERROR' test='count(h:Enclosure/h:Floors/h:Floor) &gt;= 0'>Expected 0 or more element(s) for xpath: Enclosure/Floors/Floor</sch:assert> <!-- See [Floor] -->
      <sch:assert role='ERROR' test='count(h:Enclosure/h:Slabs/h:Slab) &gt;= 0'>Expected 0 or more element(s) for xpath: Enclosure/Slabs/Slab</sch:assert> <!-- See [Slab] -->
      <sch:assert role='ERROR' test='count(h:Enclosure/h:Windows/h:Window) &gt;= 0'>Expected 0 or more element(s) for xpath: Enclosure/Windows/Window</sch:assert> <!-- See [Window] -->
      <sch:assert role='ERROR' test='count(h:Enclosure/h:Skylights/h:Skylight) &gt;= 0'>Expected 0 or more element(s) for xpath: Enclosure/Skylights/Skylight</sch:assert> <!-- See [Skylight] -->
      <sch:assert role='ERROR' test='count(h:Enclosure/h:Doors/h:Door) &gt;= 0'>Expected 0 or more element(s) for xpath: Enclosure/Doors/Door</sch:assert> <!-- See [Door] -->
      <sch:assert role='ERROR' test='count(h:Systems/h:HVAC/h:HVACPlant/h:HeatingSystem) &gt;= 0'>Expected 0 or more element(s) for xpath: Systems/HVAC/HVACPlant/HeatingSystem</sch:assert> <!-- See [HeatingSystem] -->
      <sch:assert role='ERROR' test='count(h:Systems/h:HVAC/h:HVACPlant/h:CoolingSystem) &gt;= 0'>Expected 0 or more element(s) for xpath: Systems/HVAC/HVACPlant/CoolingSystem</sch:assert> <!-- See [CoolingSystem] -->
      <sch:assert role='ERROR' test='count(h:Systems/h:HVAC/h:HVACPlant/h:HeatPump) &gt;= 0'>Expected 0 or more element(s) for xpath: Systems/HVAC/HVACPlant/HeatPump</sch:assert> <!-- See [HeatPump] -->
      <sch:assert role='ERROR' test='count(h:Systems/h:HVAC/h:HVACControl) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Systems/HVAC/HVACControl</sch:assert> <!-- See [HVACControl] -->
      <sch:assert role='ERROR' test='count(h:Systems/h:HVAC/h:HVACDistribution) &gt;= 0'>Expected 0 or more element(s) for xpath: Systems/HVAC/HVACDistribution</sch:assert> <!-- See [HVACDistribution] -->
      <sch:assert role='ERROR' test='count(h:Systems/h:MechanicalVentilation/h:VentilationFans/h:VentilationFan) &gt;= 0'>Expected 0 or more element(s) for xpath: Systems/MechanicalVentilation/VentilationFans/VentilationFan</sch:assert> <!-- See [VentilationFan] -->
      <sch:assert role='ERROR' test='count(h:Systems/h:WaterHeating/h:WaterHeatingSystem) &gt;= 0'>Expected 0 or more element(s) for xpath: Systems/WaterHeating/WaterHeatingSystem</sch:assert> <!-- See [WaterHeatingSystem] -->
      <sch:assert role='ERROR' test='count(h:Systems/h:WaterHeating/h:HotWaterDistribution) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Systems/WaterHeating/HotWaterDistribution</sch:assert> <!-- See [HotWaterDistribution] -->
      <sch:assert role='ERROR' test='count(h:Systems/h:WaterHeating/h:WaterFixture) &gt;= 0'>Expected 0 or more element(s) for xpath: Systems/WaterHeating/WaterFixture</sch:assert> <!-- See [WaterFixture] -->
      <sch:assert role='ERROR' test='count(h:Systems/h:SolarThermal/h:SolarThermalSystem) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Systems/SolarThermal/SolarThermalSystem</sch:assert> <!-- See [SolarThermalSystem] -->
      <sch:assert role='ERROR' test='count(h:Systems/h:Photovoltaics/h:PVSystem) &gt;= 0'>Expected 0 or more element(s) for xpath: Systems/Photovoltaics/PVSystem</sch:assert> <!-- See [PVSystem] -->
      <sch:assert role='ERROR' test='count(h:Systems/h:Batteries/h:Battery) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Systems/Batteries/Battery</sch:assert> <!-- See [Battery] -->
      <sch:assert role='ERROR' test='count(h:Systems/h:extension/h:Generators/h:Generator) &gt;= 0'>Expected 0 or more element(s) for xpath: Systems/extension/Generators/Generator</sch:assert> <!-- See [Generator] -->
      <sch:assert role='ERROR' test='count(h:Appliances/h:ClothesWasher) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Appliances/ClothesWasher</sch:assert> <!-- See [ClothesWasher] -->
      <sch:assert role='ERROR' test='count(h:Appliances/h:ClothesDryer) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Appliances/ClothesDryer</sch:assert> <!-- See [ClothesDryer] -->
      <sch:assert role='ERROR' test='count(h:Appliances/h:Dishwasher) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Appliances/Dishwasher</sch:assert> <!-- See [Dishwasher] -->
      <sch:assert role='ERROR' test='count(h:Appliances/h:Refrigerator) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Appliances/Refrigerator</sch:assert> <!-- See [Refrigerator] -->
      <sch:assert role='ERROR' test='count(h:Appliances/h:Dehumidifier) &gt;= 0'>Expected 0 or more element(s) for xpath: Appliances/Dehumidifier</sch:assert> <!-- See [Dehumidifier] -->
      <sch:assert role='ERROR' test='count(h:Appliances/h:CookingRange) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Appliances/CookingRange</sch:assert> <!-- See [CookingRange] -->
      <sch:assert role='ERROR' test='count(h:Appliances/h:Oven) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Appliances/Oven</sch:assert> <!-- See [Oven] -->
      <sch:assert role='ERROR' test='count(h:Lighting) = 1'>Expected 1 element(s) for xpath: Lighting</sch:assert> <!-- See [Lighting] -->
      <sch:assert role='ERROR' test='count(h:Lighting/h:CeilingFan) &gt;= 0'>Expected 0 or more element(s) for xpath: Lighting/CeilingFan</sch:assert> <!-- See [CeilingFan] -->
      <!-- Sum Checks -->
      <sch:assert role='ERROR' test='sum(h:Systems/h:HVAC/h:HVACPlant/*/h:FractionHeatLoadServed) + sum(h:Systems/h:HVAC/h:HVACPlant/*/h:IntegratedHeatingSystemFractionHeatLoadServed) &lt;= 1.01'>Expected sum(FractionHeatLoadServed) to be less than or equal to 1</sch:assert>
      <sch:assert role='ERROR' test='sum(h:Systems/h:HVAC/h:HVACPlant/*/h:FractionCoolLoadServed) &lt;= 1.01'>Expected sum(FractionCoolLoadServed) to be less than or equal to 1</sch:assert>
      <sch:assert role='ERROR' test='sum(h:Appliances/h:Dehumidifier/h:FractionDehumidificationLoadServed) &lt;= 1.01'>Expected sum(FractionDehumidificationLoadServed) to be less than or equal to 1</sch:assert>
      <sch:assert role='ERROR' test='(sum(h:Systems/h:WaterHeating/h:WaterHeatingSystem/h:FractionDHWLoadServed) &lt;= 1.01 and sum(h:Systems/h:WaterHeating/h:WaterHeatingSystem/h:FractionDHWLoadServed) &gt;= 0.99) or count(h:Systems/h:WaterHeating/h:WaterHeatingSystem/h:FractionDHWLoadServed) = 0'>Expected sum(FractionDHWLoadServed) to be 1</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Site]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:BuildingSummary/h:Site'>
      <sch:assert role='ERROR' test='count(h:FuelTypesAvailable/h:Fuel) &gt;= 1'>Expected 1 or more element(s) for xpath: FuelTypesAvailable/Fuel</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[BuildingConstruction]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:BuildingSummary/h:BuildingConstruction'>
      <sch:assert role='ERROR' test='count(h:ResidentialFacilityType) = 1'>Expected 1 element(s) for xpath: ResidentialFacilityType</sch:assert> <!-- See [BuildingType=SFAorMF] -->
      <sch:assert role='ERROR' test='h:ResidentialFacilityType[text()="single-family detached" or text()="single-family attached" or text()="apartment unit"] or not(h:ResidentialFacilityType)'>Expected ResidentialFacilityType to be 'single-family detached' or 'single-family attached' or 'apartment unit'</sch:assert>
      <sch:assert role='ERROR' test='count(h:NumberofConditionedFloors) = 1'>Expected 1 element(s) for xpath: NumberofConditionedFloors</sch:assert>
      <sch:assert role='ERROR' test='count(h:NumberofConditionedFloorsAboveGrade) = 1'>Expected 1 element(s) for xpath: NumberofConditionedFloorsAboveGrade</sch:assert>
      <!-- We are more strict than HPXML schema for NumberofConditionedFloorsAboveGrade; see https://github.com/NREL/OpenStudio-HPXML/issues/1755 -->
      <sch:assert role='ERROR' test='number(h:NumberofConditionedFloorsAboveGrade) &gt; 0 or not(h:NumberofConditionedFloorsAboveGrade)'>Expected NumberofConditionedFloorsAboveGrade to be greater than 0</sch:assert>
      <sch:assert role='ERROR' test='number(h:NumberofConditionedFloors) &gt;= number(h:NumberofConditionedFloorsAboveGrade) or not(h:NumberofConditionedFloors) or not(h:NumberofConditionedFloorsAboveGrade)'>Expected NumberofConditionedFloors to be greater than or equal to NumberofConditionedFloorsAboveGrade</sch:assert>
      <sch:assert role='ERROR' test='count(h:NumberofBedrooms) = 1'>Expected 1 element(s) for xpath: NumberofBedrooms</sch:assert>
      <sch:assert role='ERROR' test='number(h:NumberofBedrooms) &gt;= 1 or not(h:NumberofBedrooms)'>Expected NumberofBedrooms to be greater than or equal to 1</sch:assert>
      <sch:assert role='ERROR' test='count(h:ConditionedFloorArea) = 1'>Expected 1 element(s) for xpath: ConditionedFloorArea</sch:assert>
      <sch:assert role='ERROR' test='number(h:ConditionedFloorArea) &gt;= (sum(../../h:Enclosure/h:Slabs/h:Slab[h:InteriorAdjacentTo="conditioned space" or h:InteriorAdjacentTo="basement - conditioned"]/h:Area) + sum(../../h:Enclosure/h:Floors/h:Floor[h:InteriorAdjacentTo="conditioned space" and not(h:ExteriorAdjacentTo="attic - vented" or h:ExteriorAdjacentTo="attic - unvented" or ((h:ExteriorAdjacentTo="other housing unit" or h:ExteriorAdjacentTo="other heated space" or h:ExteriorAdjacentTo="other multifamily buffer space" or h:ExteriorAdjacentTo="other non-freezing space") and h:FloorOrCeiling="ceiling"))]/h:Area) - 1) or not(h:ConditionedFloorArea)'>Expected ConditionedFloorArea to be greater than or equal to the sum of conditioned slab/floor areas.</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[BuildingType=SFAorMF]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:BuildingSummary/h:BuildingConstruction/h:ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]'>
      <sch:assert role='ERROR' test='count(//h:ExteriorAdjacentTo[text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"]) &gt;= 1'>Expected 1 or more element(s) for xpath: //ExteriorAdjacentTo[text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"]</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[AirInfiltrationMeasurement]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:AirInfiltration/h:AirInfiltrationMeasurement[h:BuildingAirLeakage/h:AirLeakage | h:EffectiveLeakageArea]'>
      <sch:assert role='ERROR' test='h:BuildingAirLeakage/h:UnitofMeasure[text()="ACH" or text()="ACHnatural" or text()="CFM" or text()="CFMnatural"] or not(h:BuildingAirLeakage/h:UnitofMeasure)'>Expected BuildingAirLeakage/UnitofMeasure to be 'ACH' or 'ACHnatural' or 'CFM' or 'CFMnatural'</sch:assert>
      <sch:assert role='ERROR' test='count(h:InfiltrationVolume) = 1'>Expected 1 element(s) for xpath: InfiltrationVolume</sch:assert>
      <sch:assert role='ERROR' test='count(h:InfiltrationHeight) &lt;= 1'>Expected 0 or 1 element(s) for xpath: InfiltrationHeight</sch:assert>
      <sch:assert role='ERROR' test='number(h:InfiltrationHeight) &gt; 0 or not(h:InfiltrationHeight)'>Expected InfiltrationHeight to be greater than 0</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[AirInfiltrationMeasurement=ACHorCFM]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:AirInfiltration/h:AirInfiltrationMeasurement[h:BuildingAirLeakage/h:UnitofMeasure[text()="ACH" or text()="CFM"]]'>
      <sch:assert role='ERROR' test='count(h:HousePressure) = 1'>Expected 1 element(s) for xpath: HousePressure</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Attic]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:Attics/h:Attic'>
      <sch:assert role='ERROR' test='count(h:AtticType) = 1'>Expected 1 element(s) for xpath: AtticType</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Foundation]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:Foundations/h:Foundation'>
      <sch:assert role='ERROR' test='count(h:FoundationType) = 1'>Expected 1 element(s) for xpath: FoundationType</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Roof]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:Roofs/h:Roof'>
      <sch:assert role='ERROR' test='count(h:InteriorAdjacentTo) = 1'>Expected 1 element(s) for xpath: InteriorAdjacentTo</sch:assert> <!-- See [RoofType=AdjacentToVentedAttic] or [RoofType=AdjacentToUnventedAttic] -->
      <sch:assert role='ERROR' test='h:InteriorAdjacentTo[text()="attic - vented" or text()="attic - unvented" or text()="conditioned space" or text()="garage"] or not(h:InteriorAdjacentTo)'>Expected InteriorAdjacentTo to be 'attic - vented' or 'attic - unvented' or 'conditioned space' or 'garage'</sch:assert>
      <sch:assert role='ERROR' test='count(h:Area) = 1'>Expected 1 element(s) for xpath: Area</sch:assert>
      <sch:assert role='ERROR' test='count(h:Azimuth) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Azimuth</sch:assert>
      <sch:assert role='ERROR' test='count(h:SolarAbsorptance) = 1'>Expected 1 element(s) for xpath: SolarAbsorptance</sch:assert>
      <sch:assert role='ERROR' test='count(h:Emittance) = 1'>Expected 1 element(s) for xpath: Emittance</sch:assert>
      <sch:assert role='ERROR' test='count(h:Pitch) = 1'>Expected 1 element(s) for xpath: Pitch</sch:assert>
      <sch:assert role='ERROR' test='count(h:RadiantBarrier) &lt;= 1'>Expected 0 or 1 element(s) for xpath: RadiantBarrier</sch:assert> <!-- See [RadiantBarrier] -->
      <sch:assert role='ERROR' test='count(h:Insulation/h:AssemblyEffectiveRValue) = 1'>Expected 1 element(s) for xpath: Insulation/AssemblyEffectiveRValue</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[RoofType=AdjacentToVentedAttic]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:Roofs/h:Roof[h:InteriorAdjacentTo="attic - vented"]'>
      <sch:assert role='ERROR' test='count(../../h:Attics/h:Attic[h:AtticType/h:Attic[h:Vented="true"]]/h:VentilationRate[h:UnitofMeasure="SLA" or h:UnitofMeasure="ACHnatural"]/h:Value) &lt;= 1'>Expected 0 or 1 element(s) for xpath: ../../Attics/Attic[AtticType/Attic[Vented="true"]]/VentilationRate[UnitofMeasure="SLA" or UnitofMeasure="ACHnatural"]/Value</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[RoofType=AdjacentToUnventedAttic]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:Roofs/h:Roof[h:InteriorAdjacentTo="attic - unvented"]'>
      <sch:assert role='ERROR' test='count(../../h:Attics/h:Attic[h:AtticType/h:Attic[h:Vented="false"]]/h:WithinInfiltrationVolume) = count(../../h:Attics/h:Attic[h:AtticType/h:Attic[h:Vented="false"]])'>Expected 1 element(s) for xpath: ../../Attics/Attic[AtticType/Attic[Vented="false"]]/WithinInfiltrationVolume</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[RadiantBarrier]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:Roofs/h:Roof[h:RadiantBarrier="true"]'>
      <sch:assert role='ERROR' test='count(h:RadiantBarrierGrade) = 1'>Expected 1 element(s) for xpath: RadiantBarrierGrade</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[RimJoist]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:RimJoists/h:RimJoist'>
      <sch:assert role='ERROR' test='count(h:ExteriorAdjacentTo) = 1'>Expected 1 element(s) for xpath: ExteriorAdjacentTo</sch:assert>
      <sch:assert role='ERROR' test='h:ExteriorAdjacentTo[text()="outside" or text()="attic - vented" or text()="attic - unvented" or text()="basement - conditioned" or text()="basement - unconditioned" or text()="crawlspace - vented" or text()="crawlspace - unvented" or text()="garage" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"] or not(h:ExteriorAdjacentTo)'>Expected ExteriorAdjacentTo to be 'outside' or 'attic - vented' or 'attic - unvented' or 'basement - conditioned' or 'basement - unconditioned' or 'crawlspace - vented' or 'crawlspace - unvented' or 'garage' or 'other housing unit' or 'other heated space' or 'other multifamily buffer space' or 'other non-freezing space'</sch:assert>
      <sch:assert role='ERROR' test='count(h:InteriorAdjacentTo) = 1'>Expected 1 element(s) for xpath: InteriorAdjacentTo</sch:assert>
      <sch:assert role='ERROR' test='h:InteriorAdjacentTo[text()="conditioned space" or text()="attic - vented" or text()="attic - unvented" or text()="basement - conditioned" or text()="basement - unconditioned" or text()="crawlspace - vented" or text()="crawlspace - unvented" or text()="garage"] or not(h:InteriorAdjacentTo)'>Expected InteriorAdjacentTo to be 'conditioned space' or 'attic - vented' or 'attic - unvented' or 'basement - conditioned' or 'basement - unconditioned' or 'crawlspace - vented' or 'crawlspace - unvented' or 'garage'</sch:assert>
      <sch:assert role='ERROR' test='count(h:Area) = 1'>Expected 1 element(s) for xpath: Area</sch:assert>
      <sch:assert role='ERROR' test='count(h:Azimuth) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Azimuth</sch:assert>
      <sch:assert role='ERROR' test='count(h:Insulation/h:AssemblyEffectiveRValue) = 1'>Expected 1 element(s) for xpath: Insulation/AssemblyEffectiveRValue</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[RimJoist=Exterior]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:RimJoists/h:RimJoist[h:ExteriorAdjacentTo="outside"]'>
      <sch:assert role='ERROR' test='count(h:SolarAbsorptance) = 1'>Expected 1 element(s) for xpath: SolarAbsorptance</sch:assert>
      <sch:assert role='ERROR' test='count(h:Emittance) = 1'>Expected 1 element(s) for xpath: Emittance</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Wall]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:Walls/h:Wall'>
      <sch:assert role='ERROR' test='count(h:ExteriorAdjacentTo) = 1'>Expected 1 element(s) for xpath: ExteriorAdjacentTo</sch:assert>
      <sch:assert role='ERROR' test='h:ExteriorAdjacentTo[text()="outside" or text()="attic - vented" or text()="attic - unvented" or text()="basement - conditioned" or text()="basement - unconditioned" or text()="crawlspace - vented" or text()="crawlspace - unvented" or text()="garage" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"] or not(h:ExteriorAdjacentTo)'>Expected ExteriorAdjacentTo to be 'outside' or 'attic - vented' or 'attic - unvented' or 'basement - conditioned' or 'basement - unconditioned' or 'crawlspace - vented' or 'crawlspace - unvented' or 'garage' or 'other housing unit' or 'other heated space' or 'other multifamily buffer space' or 'other non-freezing space'</sch:assert>
      <sch:assert role='ERROR' test='count(h:InteriorAdjacentTo) = 1'>Expected 1 element(s) for xpath: InteriorAdjacentTo</sch:assert>
      <sch:assert role='ERROR' test='h:InteriorAdjacentTo[text()="conditioned space" or text()="attic - vented" or text()="attic - unvented" or text()="basement - conditioned" or text()="basement - unconditioned" or text()="crawlspace - vented" or text()="crawlspace - unvented" or text()="garage"] or not(h:InteriorAdjacentTo)'>Expected InteriorAdjacentTo to be 'conditioned space' or 'attic - vented' or 'attic - unvented' or 'basement - conditioned' or 'basement - unconditioned' or 'crawlspace - vented' or 'crawlspace - unvented' or 'garage'</sch:assert>
      <sch:assert role='ERROR' test='count(h:WallType[h:WoodStud | h:DoubleWoodStud | h:ConcreteMasonryUnit | h:StructuralInsulatedPanel | h:InsulatedConcreteForms | h:SteelFrame | h:SolidConcrete | h:StructuralBrick | h:StrawBale | h:Stone | h:LogWall | h:Adobe]) = 1'>Expected 1 element(s) for xpath: WallType[WoodStud | DoubleWoodStud | ConcreteMasonryUnit | StructuralInsulatedPanel | InsulatedConcreteForms | SteelFrame | SolidConcrete | StructuralBrick | StrawBale | Stone | LogWall | Adobe]</sch:assert>
      <sch:assert role='ERROR' test='count(h:Area) = 1'>Expected 1 element(s) for xpath: Area</sch:assert>
      <sch:assert role='ERROR' test='count(h:Azimuth) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Azimuth</sch:assert>
      <sch:assert role='ERROR' test='count(h:Insulation/h:AssemblyEffectiveRValue) = 1'>Expected 1 element(s) for xpath: Insulation/AssemblyEffectiveRValue</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Wall]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:Walls/h:Wall[h:ExteriorAdjacentTo="outside"]'>
      <sch:assert role='ERROR' test='count(h:SolarAbsorptance) = 1'>Expected 1 element(s) for xpath: SolarAbsorptance</sch:assert>
      <sch:assert role='ERROR' test='count(h:Emittance) = 1'>Expected 1 element(s) for xpath: Emittance</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[FoundationWall]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:FoundationWalls/h:FoundationWall'>
      <sch:assert role='ERROR' test='count(h:ExteriorAdjacentTo) = 1'>Expected 1 element(s) for xpath: ExteriorAdjacentTo</sch:assert>
      <sch:assert role='ERROR' test='h:ExteriorAdjacentTo[text()="ground" or text()="basement - conditioned" or text()="basement - unconditioned" or text()="crawlspace - vented" or text()="crawlspace - unvented" or text()="garage" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"] or not(h:ExteriorAdjacentTo)'>Expected ExteriorAdjacentTo to be 'ground' or 'basement - conditioned' or 'basement - unconditioned' or 'crawlspace - vented' or 'crawlspace - unvented' or 'garage' or 'other housing unit' or 'other heated space' or 'other multifamily buffer space' or 'other non-freezing space'</sch:assert>
      <sch:assert role='ERROR' test='count(h:InteriorAdjacentTo) = 1'>Expected 1 element(s) for xpath: InteriorAdjacentTo</sch:assert> <!-- See [FoundationWallType=AdjacentToVentedCrawl] or [FoundationWallType=AdjacentToUnventedCrawl] or [FoundationWallType=AdjacentToUncondBasement] or [FoundationWallType=AdjacentToCondBasement] -->
      <sch:assert role='ERROR' test='h:InteriorAdjacentTo[text()="basement - conditioned" or text()="basement - unconditioned" or text()="crawlspace - vented" or text()="crawlspace - unvented" or text()="garage"] or not(h:InteriorAdjacentTo)'>Expected InteriorAdjacentTo to be 'basement - conditioned' or 'basement - unconditioned' or 'crawlspace - vented' or 'crawlspace - unvented' or 'garage'</sch:assert>
      <sch:assert role='ERROR' test='count(h:Type) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Type</sch:assert>
      <sch:assert role='ERROR' test='h:Type[text()="solid concrete" or text()="concrete block" or text()="concrete block foam core" or text()="concrete block vermiculite core" or text()="concrete block perlite core" or text()="concrete block solid core" or text()="double brick" or text()="wood"] or not(h:Type)'>Expected Type to be 'solid concrete' or 'concrete block' or 'concrete block foam core' or 'concrete block vermiculite core' or 'concrete block perlite core' or 'concrete block solid core' or 'double brick' or 'wood'</sch:assert>
      <sch:assert role='ERROR' test='count(h:Height) = 1'>Expected 1 element(s) for xpath: Height</sch:assert>
      <sch:assert role='ERROR' test='count(h:Area) = 1'>Expected 1 element(s) for xpath: Area</sch:assert>
      <sch:assert role='ERROR' test='count(h:Azimuth) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Azimuth</sch:assert>
      <sch:assert role='ERROR' test='count(h:Thickness) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Thickness</sch:assert>
      <sch:assert role='ERROR' test='number(h:Thickness) &gt; 0 or not(h:Thickness)'>Expected Thickness to be greater than 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:DepthBelowGrade) = 1'>Expected 1 element(s) for xpath: DepthBelowGrade</sch:assert>
      <sch:assert role='ERROR' test='number(h:DepthBelowGrade) &lt;= number(h:Height) or not(h:DepthBelowGrade) or not(h:Height)'>Expected DepthBelowGrade to be less than or equal to Height</sch:assert>
      <!-- Insulation: either specify interior and exterior layers OR assembly R-value: -->
      <sch:assert role='ERROR' test='count(h:Insulation/h:Layer[h:InstallationType="continuous - interior"]) + count(h:Insulation/h:AssemblyEffectiveRValue) = 1'>Expected 1 element(s) for xpath: Insulation/Layer[InstallationType="continuous - interior"] | Insulation/AssemblyEffectiveRValue</sch:assert> <!-- See [FoundationWallInsulationLayer] -->
      <sch:assert role='ERROR' test='count(h:Insulation/h:Layer[h:InstallationType="continuous - exterior"]) + count(h:Insulation/h:AssemblyEffectiveRValue) = 1'>Expected 1 element(s) for xpath: Insulation/Layer[InstallationType="continuous - exterior"] | Insulation/AssemblyEffectiveRValue</sch:assert> <!-- See [FoundationWallInsulationLayer] -->
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:Thickness) &lt; 1 and number(h:Thickness) &gt; 0'>Thickness is less than 1 inch; this may indicate incorrect units.</sch:report>
      <sch:report role='WARN' test='number(h:Thickness) &gt; 12'>Thickness is greater than 12 inches; this may indicate incorrect units.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[FoundationWallType=AdjacentToVentedCrawl]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:FoundationWalls/h:FoundationWall[h:InteriorAdjacentTo="crawlspace - vented"]'>
      <sch:assert role='ERROR' test='count(../../h:Foundations/h:Foundation[h:FoundationType/h:Crawlspace[h:Vented="true"]]/h:VentilationRate[h:UnitofMeasure="SLA"]/h:Value) &lt;= 1'>Expected 0 or 1 element(s) for xpath: ../../Foundations/Foundation[FoundationType/Crawlspace[Vented="true"]]/VentilationRate[UnitofMeasure="SLA"]/Value</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[FoundationWallType=AdjacentToUnventedCrawl]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:FoundationWalls/h:FoundationWall[h:InteriorAdjacentTo="crawlspace - unvented"]'>
      <sch:assert role='ERROR' test='count(../../h:Foundations/h:Foundation[h:FoundationType/h:Crawlspace[h:Vented="false"]]/h:WithinInfiltrationVolume) = count(../../h:Foundations/h:Foundation[h:FoundationType/h:Crawlspace[h:Vented="false"]])'>Expected 1 element(s) for xpath: ../../Foundations/Foundation[FoundationType/Crawlspace[Vented="false"]]/WithinInfiltrationVolume</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[FoundationWallType=AdjacentToUncondBasement]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:FoundationWalls/h:FoundationWall[h:InteriorAdjacentTo="basement - unconditioned"]'>
      <sch:assert role='ERROR' test='count(../../h:Foundations/h:Foundation[h:FoundationType/h:Basement[h:Conditioned="false"]]/h:WithinInfiltrationVolume) = count(../../h:Foundations/h:Foundation[h:FoundationType/h:Basement[h:Conditioned="false"]])'>Expected 1 element(s) for xpath: ../../Foundations/Foundation[FoundationType/Basement[Conditioned="false"]]/WithinInfiltrationVolume</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[FoundationWallType=AdjacentToCondBasement]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:FoundationWalls/h:FoundationWall[h:InteriorAdjacentTo="basement - conditioned"]'>
      <sch:assert role='ERROR' test='count(../../h:Foundations/h:Foundation[h:FoundationType/h:Basement[h:Conditioned="true"]]/h:WithinInfiltrationVolume) &lt;= count(../../h:Foundations/h:Foundation[h:FoundationType/h:Basement[h:Conditioned="true"]])'>Expected 0 or 1 element(s) for xpath: ../../Foundations/Foundation[FoundationType/Basement[Conditioned="true"]]/WithinInfiltrationVolume</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[FoundationWallInsulationLayer]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:FoundationWalls/h:FoundationWall/h:Insulation/h:Layer[h:InstallationType="continuous - exterior" or h:InstallationType="continuous - interior"]'>
      <sch:assert role='ERROR' test='count(h:NominalRValue) = 1'>Expected 1 element(s) for xpath: NominalRValue</sch:assert>
      <sch:assert role='ERROR' test='count(h:DistanceToTopOfInsulation) = 1'>Expected 1 element(s) for xpath: DistanceToTopOfInsulation</sch:assert>
      <sch:assert role='ERROR' test='count(h:DistanceToBottomOfInsulation) = 1'>Expected 1 element(s) for xpath: DistanceToBottomOfInsulation</sch:assert>
      <sch:assert role='ERROR' test='number(h:DistanceToBottomOfInsulation) &gt;= number(h:DistanceToTopOfInsulation) or not(h:DistanceToBottomOfInsulation) or not(h:DistanceToTopOfInsulation)'>Expected DistanceToBottomOfInsulation to be greater than or equal to DistanceToTopOfInsulation</sch:assert>
      <sch:assert role='ERROR' test='number(h:DistanceToBottomOfInsulation) &lt;= number(../../h:Height) or not(h:DistanceToBottomOfInsulation) or not(../../h:Height)'>Expected DistanceToBottomOfInsulation to be less than or equal to ../../Height</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Floor]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:Floors/h:Floor'>
      <sch:assert role='ERROR' test='count(h:ExteriorAdjacentTo) = 1'>Expected 1 element(s) for xpath: ExteriorAdjacentTo</sch:assert> <!-- See [FloorType=AdjacentToOther] -->
      <sch:assert role='ERROR' test='h:ExteriorAdjacentTo[text()="outside" or text()="attic - vented" or text()="attic - unvented" or text()="basement - conditioned" or text()="basement - unconditioned" or text()="crawlspace - vented" or text()="crawlspace - unvented" or text()="garage" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"] or not(h:ExteriorAdjacentTo)'>Expected ExteriorAdjacentTo to be 'outside' or 'attic - vented' or 'attic - unvented' or 'basement - conditioned' or 'basement - unconditioned' or 'crawlspace - vented' or 'crawlspace - unvented' or 'garage' or 'other housing unit' or 'other heated space' or 'other multifamily buffer space' or 'other non-freezing space'</sch:assert>
      <sch:assert role='ERROR' test='count(h:InteriorAdjacentTo) = 1'>Expected 1 element(s) for xpath: InteriorAdjacentTo</sch:assert>
      <sch:assert role='ERROR' test='h:InteriorAdjacentTo[text()="conditioned space" or text()="attic - vented" or text()="attic - unvented" or text()="basement - conditioned" or text()="basement - unconditioned" or text()="crawlspace - vented" or text()="crawlspace - unvented" or text()="garage"] or not(h:InteriorAdjacentTo)'>Expected InteriorAdjacentTo to be 'conditioned space' or 'attic - vented' or 'attic - unvented' or 'basement - conditioned' or 'basement - unconditioned' or 'crawlspace - vented' or 'crawlspace - unvented' or 'garage'</sch:assert>
      <sch:assert role='ERROR' test='count(h:FloorType[h:WoodFrame | h:StructuralInsulatedPanel | h:SteelFrame | h:SolidConcrete]) = 1'>Expected 1 element(s) for xpath: FloorType[WoodFrame | StructuralInsulatedPanel | SteelFrame | SolidConcrete]</sch:assert>
      <sch:assert role='ERROR' test='count(h:Area) = 1'>Expected 1 element(s) for xpath: Area</sch:assert>
      <sch:assert role='ERROR' test='count(h:Insulation/h:AssemblyEffectiveRValue) = 1'>Expected 1 element(s) for xpath: Insulation/AssemblyEffectiveRValue</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[FloorType=AdjacentToOther]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:Floors/h:Floor[h:ExteriorAdjacentTo[text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"]]'>
      <sch:assert role='ERROR' test='count(h:FloorOrCeiling[text()="floor" or text()="ceiling"]) = 1'>Expected 1 element(s) for xpath: FloorOrCeiling[text()="floor" or text()="ceiling"]</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Slab]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:Slabs/h:Slab'>
      <sch:assert role='ERROR' test='count(h:InteriorAdjacentTo) = 1'>Expected 1 element(s) for xpath: InteriorAdjacentTo</sch:assert> <!-- See [SlabInteriorAdjacentTo] -->
      <sch:assert role='ERROR' test='h:InteriorAdjacentTo[text()="conditioned space" or text()="basement - conditioned" or text()="basement - unconditioned" or text()="crawlspace - vented" or text()="crawlspace - unvented" or text()="garage"] or not(h:InteriorAdjacentTo)'>Expected InteriorAdjacentTo to be 'conditioned space' or 'basement - conditioned' or 'basement - unconditioned' or 'crawlspace - vented' or 'crawlspace - unvented' or 'garage'</sch:assert>
      <sch:assert role='ERROR' test='count(h:Area) = 1'>Expected 1 element(s) for xpath: Area</sch:assert>
      <sch:assert role='ERROR' test='count(h:Thickness) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Thickness</sch:assert>
      <sch:assert role='ERROR' test='count(h:ExposedPerimeter) = 1'>Expected 1 element(s) for xpath: ExposedPerimeter</sch:assert>
      <sch:assert role='ERROR' test='count(h:DepthBelowGrade) &lt;= 1'>Expected 0 or 1 element(s) for xpath: DepthBelowGrade</sch:assert>
      <sch:assert role='ERROR' test='count(h:PerimeterInsulation/h:Layer/h:NominalRValue) = 1'>Expected 1 element(s) for xpath: PerimeterInsulation/Layer/NominalRValue</sch:assert>
      <sch:assert role='ERROR' test='count(h:PerimeterInsulation/h:Layer/h:InsulationDepth) = 1'>Expected 1 element(s) for xpath: PerimeterInsulation/Layer/InsulationDepth</sch:assert>
      <sch:assert role='ERROR' test='count(h:UnderSlabInsulation/h:Layer/h:NominalRValue) = 1'>Expected 1 element(s) for xpath: UnderSlabInsulation/Layer/NominalRValue</sch:assert>
      <sch:assert role='ERROR' test='count(h:UnderSlabInsulation/h:Layer/h:InsulationWidth) + count(h:UnderSlabInsulation/h:Layer/h:InsulationSpansEntireSlab[text()="true"]) = 1'>Expected 1 element(s) for xpath: UnderSlabInsulation/Layer/InsulationWidth | UnderSlabInsulation/Layer/InsulationSpansEntireSlab[text()="true"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:GapInsulationRValue) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/GapInsulationRValue</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:CarpetFraction) = 1'>Expected 1 element(s) for xpath: extension/CarpetFraction</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:CarpetFraction) &gt;= 0 or not(h:extension/h:CarpetFraction)'>Expected extension/CarpetFraction to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:CarpetFraction) &lt;= 1 or not(h:extension/h:CarpetFraction)'>Expected extension/CarpetFraction to be less than or equal to 1</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:CarpetRValue) = 1'>Expected 1 element(s) for xpath: extension/CarpetRValue</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:ExposedPerimeter) = 0'>Slab has zero exposed perimeter, this may indicate an input error.</sch:report>
      <sch:report role='WARN' test='number(h:Thickness) &lt; 1 and number(h:Thickness) &gt; 0'>Thickness is less than 1 inch; this may indicate incorrect units.</sch:report>
      <sch:report role='WARN' test='number(h:Thickness) &gt; 12'>Thickness is greater than 12 inches; this may indicate incorrect units.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Window]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:Windows/h:Window'>
      <sch:assert role='ERROR' test='count(h:Area) = 1'>Expected 1 element(s) for xpath: Area</sch:assert>
      <sch:assert role='ERROR' test='count(h:Azimuth) = 1'>Expected 1 element(s) for xpath: Azimuth</sch:assert>
      <sch:assert role='ERROR' test='count(h:UFactor) = 1'>Expected 1 element(s) for xpath: UFactor</sch:assert>
      <sch:assert role='ERROR' test='count(h:SHGC) = 1'>Expected 1 element(s) for xpath: SHGC</sch:assert>
      <sch:assert role='ERROR' test='count(h:Overhangs) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Overhangs</sch:assert> <!-- See [WindowOverhangs] -->
      <sch:assert role='ERROR' test='count(h:FractionOperable) = 1'>Expected 1 element(s) for xpath: FractionOperable</sch:assert>
      <sch:assert role='ERROR' test='count(h:PerformanceClass) &lt;= 1'>Expected 0 or 1 element(s) for xpath: PerformanceClass</sch:assert>
      <sch:assert role='ERROR' test='h:PerformanceClass[text()="residential" or text()="architectural"] or not(h:PerformanceClass)'>Expected PerformanceClass to be 'residential' or 'architectural'</sch:assert>
      <sch:assert role='ERROR' test='count(h:AttachedToWall) = 1'>Expected 1 element(s) for xpath: AttachedToWall</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[WindowOverhangs]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:Windows/h:Window/h:Overhangs'>
      <sch:assert role='ERROR' test='count(h:Depth) = 1'>Expected 1 element(s) for xpath: Depth</sch:assert> <!-- See [WindowOverhangs=Present] -->
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:Depth) &gt; 72'>Depth is greater than 72 feet; this may indicate incorrect units.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[WindowOverhangs=Present]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:Windows/h:Window/h:Overhangs[number(h:Depth) > 0]'>
      <sch:assert role='ERROR' test='count(h:DistanceToTopOfWindow) = 1'>Expected 1 element(s) for xpath: DistanceToTopOfWindow</sch:assert>
      <sch:assert role='ERROR' test='count(h:DistanceToBottomOfWindow) = 1'>Expected 1 element(s) for xpath: DistanceToBottomOfWindow</sch:assert>
      <sch:assert role='ERROR' test='number(h:DistanceToBottomOfWindow) &gt; number(h:DistanceToTopOfWindow) or not(h:DistanceToBottomOfWindow) or not(h:DistanceToTopOfWindow)'>Expected DistanceToBottomOfWindow to be greater than DistanceToTopOfWindow</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:DistanceToTopOfWindow) &gt; 12'>DistanceToTopOfWindow is greater than 12 feet; this may indicate incorrect units.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Skylight]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:Skylights/h:Skylight'>
      <sch:assert role='ERROR' test='count(h:Area) = 1'>Expected 1 element(s) for xpath: Area</sch:assert>
      <sch:assert role='ERROR' test='count(h:Azimuth) = 1'>Expected 1 element(s) for xpath: Azimuth</sch:assert>
      <sch:assert role='ERROR' test='count(h:UFactor) = 1'>Expected 1 element(s) for xpath: UFactor</sch:assert>
      <sch:assert role='ERROR' test='count(h:SHGC) = 1'>Expected 1 element(s) for xpath: SHGC</sch:assert>
      <sch:assert role='ERROR' test='count(h:AttachedToRoof) = 1'>Expected 1 element(s) for xpath: AttachedToRoof</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:Curb) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Curb</sch:assert> <!-- See [SkylightCurb] -->
      <sch:assert role='ERROR' test='count(h:extension/h:Shaft) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Shaft</sch:assert> <!-- See [SkylightShaft] -->
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[SkylightCurb]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:Skylights/h:Skylight/h:extension/h:Curb'>
      <sch:assert role='ERROR' test='count(h:Area) = 1'>Expected 1 element(s) for xpath: Area</sch:assert>
      <sch:assert role='ERROR' test='number(h:Area) &gt; 0 or not(h:Area)'>Expected Area to be greater than 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:AssemblyEffectiveRValue) = 1'>Expected 1 element(s) for xpath: AssemblyEffectiveRValue</sch:assert>
      <sch:assert role='ERROR' test='number(h:AssemblyEffectiveRValue) &gt; 0 or not(h:AssemblyEffectiveRValue)'>Expected AssemblyEffectiveRValue to be greater than 0</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[SkylightShaft]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:Skylights/h:Skylight/h:extension/h:Shaft'>
      <sch:assert role='ERROR' test='count(../../h:AttachedToFloor) = 1'>Expected 1 element(s) for xpath: ../../AttachedToFloor</sch:assert>
      <sch:assert role='ERROR' test='count(h:Area) = 1'>Expected 1 element(s) for xpath: Area</sch:assert>
      <sch:assert role='ERROR' test='number(h:Area) &gt; 0 or not(h:Area)'>Expected Area to be greater than 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:AssemblyEffectiveRValue) = 1'>Expected 1 element(s) for xpath: AssemblyEffectiveRValue</sch:assert>
      <sch:assert role='ERROR' test='number(h:AssemblyEffectiveRValue) &gt; 0 or not(h:AssemblyEffectiveRValue)'>Expected AssemblyEffectiveRValue to be greater than 0</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Door]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:Doors/h:Door'>
      <sch:assert role='ERROR' test='count(h:AttachedToWall) = 1'>Expected 1 element(s) for xpath: AttachedToWall</sch:assert>
      <sch:assert role='ERROR' test='count(h:Area) = 1'>Expected 1 element(s) for xpath: Area</sch:assert>
      <sch:assert role='ERROR' test='count(h:Azimuth) = 1'>Expected 1 element(s) for xpath: Azimuth</sch:assert>
      <sch:assert role='ERROR' test='count(h:RValue) = 1'>Expected 1 element(s) for xpath: RValue</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatingSystem]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:HeatingSystem'>
      <sch:assert role='ERROR' test='count(../../h:HVACControl) = 1'>Expected 1 element(s) for xpath: ../../HVACControl</sch:assert> <!-- See [HVACControl] -->
      <sch:assert role='ERROR' test='count(h:HeatingSystemType[h:ElectricResistance | h:Furnace | h:WallFurnace | h:FloorFurnace | h:Boiler | h:Stove | h:SpaceHeater | h:Fireplace]) = 1'>Expected 1 element(s) for xpath: HeatingSystemType[ElectricResistance | Furnace | WallFurnace | FloorFurnace | Boiler | Stove | SpaceHeater | Fireplace]</sch:assert> <!-- See [HeatingSystemType=Resistance] or [HeatingSystemType=Furnace] or [HeatingSystemType=WallFurnace] or [HeatingSystemType=FloorFurnace] or [HeatingSystemType=Boiler] or [HeatingSystemType=Stove] or [HeatingSystemType=SpaceHeater] or [HeatingSystemType=Fireplace] -->
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatingSystemType=Resistance]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:HeatingSystem[h:HeatingSystemType/h:ElectricResistance]'>
      <sch:assert role='ERROR' test='count(h:DistributionSystem) = 0'>Expected 0 element(s) for xpath: DistributionSystem</sch:assert>
      <sch:assert role='ERROR' test='count(h:HeatingSystemFuel) = 1'>Expected 1 element(s) for xpath: HeatingSystemFuel</sch:assert>
      <sch:assert role='ERROR' test='h:HeatingSystemFuel[text()="electricity"] or not(h:HeatingSystemFuel)'>Expected HeatingSystemFuel to be 'electricity'</sch:assert>
      <sch:assert role='ERROR' test='count(h:HeatingCapacity) = 1'>Expected 1 element(s) for xpath: HeatingCapacity</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualHeatingEfficiency[h:Units="Percent"]/h:Value) = 1'>Expected 1 element(s) for xpath: AnnualHeatingEfficiency[Units="Percent"]/Value</sch:assert>
      <sch:assert role='ERROR' test='number(h:AnnualHeatingEfficiency[h:Units="Percent"]/h:Value) &lt;= 1 or not(h:AnnualHeatingEfficiency[h:Units="Percent"]/h:Value)'>Expected AnnualHeatingEfficiency[Units="Percent"]/Value to be less than or equal to 1</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionHeatLoadServed) = 1'>Expected 1 element(s) for xpath: FractionHeatLoadServed</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatingSystemType=Furnace]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:HeatingSystem[h:HeatingSystemType/h:Furnace]'>
      <sch:assert role='ERROR' test='count(../../h:HVACDistribution/h:DistributionSystemType/h:AirDistribution/h:AirDistributionType[text()="regular velocity" or text()="gravity"]) + count(../../h:HVACDistribution/h:DistributionSystemType/h:Other[text()="DSE"]) &gt;= 1'>Expected 1 or more element(s) for xpath: ../../HVACDistribution/DistributionSystemType/AirDistribution/AirDistributionType[text()="regular velocity" or text()="gravity"] | ../../HVACDistribution/DistributionSystemType/Other[text()="DSE"]</sch:assert> <!-- See [HVACDistribution] -->
      <sch:assert role='ERROR' test='count(h:DistributionSystem) = 1'>Expected 1 element(s) for xpath: DistributionSystem</sch:assert>
      <sch:assert role='ERROR' test='count(h:HeatingSystemFuel) = 1'>Expected 1 element(s) for xpath: HeatingSystemFuel</sch:assert>
      <sch:assert role='ERROR' test='h:HeatingSystemFuel[text()="electricity" or text()="natural gas" or text()="fuel oil" or text()="propane" or text()="wood" or text()="wood pellets"] or not(h:HeatingSystemFuel)'>Expected HeatingSystemFuel to be 'electricity' or 'natural gas' or 'fuel oil' or 'propane' or 'wood' or 'wood pellets'</sch:assert>
      <sch:assert role='ERROR' test='count(h:HeatingCapacity) = 1'>Expected 1 element(s) for xpath: HeatingCapacity</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualHeatingEfficiency[h:Units="AFUE"]/h:Value) = 1'>Expected 1 element(s) for xpath: AnnualHeatingEfficiency[Units="AFUE"]/Value</sch:assert>
      <sch:assert role='ERROR' test='number(h:AnnualHeatingEfficiency[h:Units="AFUE"]/h:Value) &lt;= 1 or not(h:AnnualHeatingEfficiency[h:Units="AFUE"]/h:Value)'>Expected AnnualHeatingEfficiency[Units="AFUE"]/Value to be less than or equal to 1</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionHeatLoadServed) = 1'>Expected 1 element(s) for xpath: FractionHeatLoadServed</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:FanPowerWattsPerCFM) = 1'>Expected 1 element(s) for xpath: extension/FanPowerWattsPerCFM</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:FanPowerWattsPerCFM) &gt;= 0 or not(h:extension/h:FanPowerWattsPerCFM)'>Expected extension/FanPowerWattsPerCFM to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:FanMotorType) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/FanMotorType</sch:assert>
      <sch:assert role='ERROR' test='h:extension/h:FanMotorType[text()="PSC" or text()="BPM"] or not(h:extension/h:FanMotorType)'>Expected extension/FanMotorType to be 'PSC' or 'BPM'</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:HeatingDesignAirflowCFM) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/HeatingDesignAirflowCFM</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:HeatingDesignAirflowCFM) &gt;= 0 or not(h:extension/h:HeatingDesignAirflowCFM)'>Expected extension/HeatingDesignAirflowCFM to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:AirflowDefectRatio) = 1'>Expected 1 element(s) for xpath: extension/AirflowDefectRatio</sch:assert> <!-- See [AirflowDefectRatio] -->
      <sch:assert role='ERROR' test='number(h:extension/h:AirflowDefectRatio) &gt;= -0.9 or not(h:extension/h:AirflowDefectRatio)'>Expected extension/AirflowDefectRatio to be greater than or equal to -0.9</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:AirflowDefectRatio) &lt;= 9 or not(h:extension/h:AirflowDefectRatio)'>Expected extension/AirflowDefectRatio to be less than or equal to 9</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatingSystemType=WallFurnace]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:HeatingSystem[h:HeatingSystemType/h:WallFurnace]'>
      <sch:assert role='ERROR' test='count(h:DistributionSystem) = 0'>Expected 0 element(s) for xpath: DistributionSystem</sch:assert>
      <sch:assert role='ERROR' test='count(h:HeatingSystemFuel) = 1'>Expected 1 element(s) for xpath: HeatingSystemFuel</sch:assert>
      <sch:assert role='ERROR' test='h:HeatingSystemFuel[text()="electricity" or text()="natural gas" or text()="fuel oil" or text()="propane" or text()="wood" or text()="wood pellets"] or not(h:HeatingSystemFuel)'>Expected HeatingSystemFuel to be 'electricity' or 'natural gas' or 'fuel oil' or 'propane' or 'wood' or 'wood pellets'</sch:assert>
      <sch:assert role='ERROR' test='count(h:HeatingCapacity) = 1'>Expected 1 element(s) for xpath: HeatingCapacity</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualHeatingEfficiency[h:Units="AFUE"]/h:Value) = 1'>Expected 1 element(s) for xpath: AnnualHeatingEfficiency[Units="AFUE"]/Value</sch:assert>
      <sch:assert role='ERROR' test='number(h:AnnualHeatingEfficiency[h:Units="AFUE"]/h:Value) &lt;= 1 or not(h:AnnualHeatingEfficiency[h:Units="AFUE"]/h:Value)'>Expected AnnualHeatingEfficiency[Units="AFUE"]/Value to be less than or equal to 1</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionHeatLoadServed) = 1'>Expected 1 element(s) for xpath: FractionHeatLoadServed</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:FanPowerWatts) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/FanPowerWatts</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:FanPowerWatts) &gt;= 0 or not(h:extension/h:FanPowerWatts)'>Expected extension/FanPowerWatts to be greater than or equal to 0</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatingSystemType=FloorFurnace]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:HeatingSystem[h:HeatingSystemType/h:FloorFurnace]'>
      <sch:assert role='ERROR' test='count(h:DistributionSystem) = 0'>Expected 0 element(s) for xpath: DistributionSystem</sch:assert>
      <sch:assert role='ERROR' test='count(h:HeatingSystemFuel) = 1'>Expected 1 element(s) for xpath: HeatingSystemFuel</sch:assert>
      <sch:assert role='ERROR' test='h:HeatingSystemFuel[text()="electricity" or text()="natural gas" or text()="fuel oil" or text()="propane" or text()="wood" or text()="wood pellets"] or not(h:HeatingSystemFuel)'>Expected HeatingSystemFuel to be 'electricity' or 'natural gas' or 'fuel oil' or 'propane' or 'wood' or 'wood pellets'</sch:assert>
      <sch:assert role='ERROR' test='count(h:HeatingCapacity) = 1'>Expected 1 element(s) for xpath: HeatingCapacity</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualHeatingEfficiency[h:Units="AFUE"]/h:Value) = 1'>Expected 1 element(s) for xpath: AnnualHeatingEfficiency[Units="AFUE"]/Value</sch:assert>
      <sch:assert role='ERROR' test='number(h:AnnualHeatingEfficiency[h:Units="AFUE"]/h:Value) &lt;= 1 or not(h:AnnualHeatingEfficiency[h:Units="AFUE"]/h:Value)'>Expected AnnualHeatingEfficiency[Units="AFUE"]/Value to be less than or equal to 1</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionHeatLoadServed) = 1'>Expected 1 element(s) for xpath: FractionHeatLoadServed</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:FanPowerWatts) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/FanPowerWatts</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:FanPowerWatts) &gt;= 0 or not(h:extension/h:FanPowerWatts)'>Expected extension/FanPowerWatts to be greater than or equal to 0</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatingSystemType=Boiler]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:HeatingSystem[h:HeatingSystemType/h:Boiler]'>
      <sch:assert role='ERROR' test='count(h:IsSharedSystem) = 1'>Expected 1 element(s) for xpath: IsSharedSystem</sch:assert> <!-- See [HeatingSystemType=InUnitBoiler] or [HeatingSystemType=SharedBoiler] -->
      <sch:assert role='ERROR' test='count(h:DistributionSystem) = 1'>Expected 1 element(s) for xpath: DistributionSystem</sch:assert>
      <sch:assert role='ERROR' test='count(h:HeatingSystemFuel) = 1'>Expected 1 element(s) for xpath: HeatingSystemFuel</sch:assert>
      <sch:assert role='ERROR' test='h:HeatingSystemFuel[text()="electricity" or text()="natural gas" or text()="fuel oil" or text()="propane" or text()="wood" or text()="wood pellets"] or not(h:HeatingSystemFuel)'>Expected HeatingSystemFuel to be 'electricity' or 'natural gas' or 'fuel oil' or 'propane' or 'wood' or 'wood pellets'</sch:assert>
      <sch:assert role='ERROR' test='count(h:HeatingCapacity) = 1'>Expected 1 element(s) for xpath: HeatingCapacity</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualHeatingEfficiency[h:Units="AFUE"]/h:Value) = 1'>Expected 1 element(s) for xpath: AnnualHeatingEfficiency[Units="AFUE"]/Value</sch:assert>
      <sch:assert role='ERROR' test='number(h:AnnualHeatingEfficiency[h:Units="AFUE"]/h:Value) &lt;= 1 or not(h:AnnualHeatingEfficiency[h:Units="AFUE"]/h:Value)'>Expected AnnualHeatingEfficiency[Units="AFUE"]/Value to be less than or equal to 1</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionHeatLoadServed) = 1'>Expected 1 element(s) for xpath: FractionHeatLoadServed</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatingSystemType=InUnitBoiler]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:HeatingSystem[h:HeatingSystemType/h:Boiler and h:IsSharedSystem="false"]'>
      <sch:assert role='ERROR' test='count(../../h:HVACDistribution/h:DistributionSystemType/h:HydronicDistribution/h:HydronicDistributionType[text()="radiator" or text()="baseboard" or text()="radiant floor" or text()="radiant ceiling"]) + count(../../h:HVACDistribution/h:DistributionSystemType/h:Other[text()="DSE"]) &gt;= 1'>Expected 1 or more element(s) for xpath: ../../HVACDistribution/DistributionSystemType/HydronicDistribution/HydronicDistributionType[text()="radiator" or text()="baseboard" or text()="radiant floor" or text()="radiant ceiling"] | ../../HVACDistribution/DistributionSystemType/Other[text()="DSE"]</sch:assert> <!-- See [HVACDistribution] -->
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatingSystemType=SharedBoiler]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:HeatingSystem[h:HeatingSystemType/h:Boiler and h:IsSharedSystem="true"]'>
      <sch:assert role='ERROR' test='count(../../../../h:BuildingSummary/h:BuildingConstruction[h:ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]]) = 1'>Expected 1 element(s) for xpath: ../../../../BuildingSummary/BuildingConstruction[ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]]</sch:assert>
      <sch:assert role='ERROR' test='count(../../h:HVACDistribution/h:DistributionSystemType/h:HydronicDistribution/h:HydronicDistributionType[text()="radiator" or text()="baseboard" or text()="radiant floor" or text()="radiant ceiling" or text()="water loop"]) + count(../../h:HVACDistribution/h:DistributionSystemType/h:AirDistribution/h:AirDistributionType[text()="fan coil"]) &gt;= 1'>Expected 1 or more element(s) for xpath: ../../HVACDistribution/DistributionSystemType/HydronicDistribution/HydronicDistributionType[text()="radiator" or text()="baseboard" or text()="radiant floor" or text()="radiant ceiling" or text()="water loop"] | ../../HVACDistribution/DistributionSystemType/AirDistribution/AirDistributionType[text()="fan coil"]</sch:assert> <!-- See [HVACDistribution] or [HeatingSystemType=SharedBoilerWthFanCoil] or [HeatingSystemType=SharedBoilerWithWLHP] -->
      <sch:assert role='ERROR' test='count(h:NumberofUnitsServed) = 1'>Expected 1 element(s) for xpath: NumberofUnitsServed</sch:assert>
      <sch:assert role='ERROR' test='number(h:NumberofUnitsServed) &gt; 1 or not(h:NumberofUnitsServed)'>Expected NumberofUnitsServed to be greater than 1</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:SharedLoopWatts) = 1'>Expected 1 element(s) for xpath: extension/SharedLoopWatts</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:SharedLoopWatts) &gt;= 0 or not(h:extension/h:SharedLoopWatts)'>Expected extension/SharedLoopWatts to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:SharedLoopMotorEfficiency) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/SharedLoopMotorEfficiency</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:SharedLoopMotorEfficiency) &gt; 0 or not(h:extension/h:SharedLoopMotorEfficiency)'>Expected extension/SharedLoopMotorEfficiency to be greater than 0</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:SharedLoopMotorEfficiency) &lt; 1 or not(h:extension/h:SharedLoopMotorEfficiency)'>Expected extension/SharedLoopMotorEfficiency to be less than 1</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatingSystemType=SharedBoilerWthFanCoil]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:HeatingSystem[h:HeatingSystemType/h:Boiler and h:IsSharedSystem="true" and ../../h:HVACDistribution/h:DistributionSystemType/h:AirDistribution/h:AirDistributionType[text()="fan coil"]]'>
      <sch:assert role='ERROR' test='count(h:extension/h:FanCoilWatts) = 1'>Expected 1 element(s) for xpath: extension/FanCoilWatts</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:FanCoilWatts) &gt;= 0 or not(h:extension/h:FanCoilWatts)'>Expected extension/FanCoilWatts to be greater than or equal to 0</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatingSystemType=SharedBoilerWithWLHP]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:HeatingSystem[h:HeatingSystemType/h:Boiler and h:IsSharedSystem="true" and ../../h:HVACDistribution/h:DistributionSystemType/h:HydronicDistribution/h:HydronicDistributionType[text()="water loop"]]'>
      <sch:assert role='ERROR' test='count(../h:HeatPump[h:HeatPumpType="water-loop-to-air"]/h:HeatingCapacity) = 1'>Expected 1 element(s) for xpath: ../HeatPump[HeatPumpType="water-loop-to-air"]/HeatingCapacity</sch:assert>
      <sch:assert role='ERROR' test='count(../h:HeatPump[h:HeatPumpType="water-loop-to-air"]/h:AnnualHeatingEfficiency[h:Units="COP"]/h:Value) = 1'>Expected 1 element(s) for xpath: ../HeatPump[HeatPumpType="water-loop-to-air"]/AnnualHeatingEfficiency[Units="COP"]/Value</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatingSystemType=Stove]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:HeatingSystem[h:HeatingSystemType/h:Stove]'>
      <sch:assert role='ERROR' test='count(h:DistributionSystem) = 0'>Expected 0 element(s) for xpath: DistributionSystem</sch:assert>
      <sch:assert role='ERROR' test='count(h:HeatingSystemFuel) = 1'>Expected 1 element(s) for xpath: HeatingSystemFuel</sch:assert>
      <sch:assert role='ERROR' test='h:HeatingSystemFuel[text()="electricity" or text()="natural gas" or text()="fuel oil" or text()="propane" or text()="wood" or text()="wood pellets"] or not(h:HeatingSystemFuel)'>Expected HeatingSystemFuel to be 'electricity' or 'natural gas' or 'fuel oil' or 'propane' or 'wood' or 'wood pellets'</sch:assert>
      <sch:assert role='ERROR' test='count(h:HeatingCapacity) = 1'>Expected 1 element(s) for xpath: HeatingCapacity</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualHeatingEfficiency[h:Units="Percent"]/h:Value) = 1'>Expected 1 element(s) for xpath: AnnualHeatingEfficiency[Units="Percent"]/Value</sch:assert>
      <sch:assert role='ERROR' test='number(h:AnnualHeatingEfficiency[h:Units="Percent"]/h:Value) &lt;= 1 or not(h:AnnualHeatingEfficiency[h:Units="Percent"]/h:Value)'>Expected AnnualHeatingEfficiency[Units="Percent"]/Value to be less than or equal to 1</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionHeatLoadServed) = 1'>Expected 1 element(s) for xpath: FractionHeatLoadServed</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:FanPowerWatts) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/FanPowerWatts</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:FanPowerWatts) &gt;= 0 or not(h:extension/h:FanPowerWatts)'>Expected extension/FanPowerWatts to be greater than or equal to 0</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatingSystemType=SpaceHeater]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:HeatingSystem[h:HeatingSystemType/h:SpaceHeater]'>
      <sch:assert role='ERROR' test='count(h:DistributionSystem) = 0'>Expected 0 element(s) for xpath: DistributionSystem</sch:assert>
      <sch:assert role='ERROR' test='count(h:HeatingSystemFuel) = 1'>Expected 1 element(s) for xpath: HeatingSystemFuel</sch:assert>
      <sch:assert role='ERROR' test='h:HeatingSystemFuel[text()="electricity" or text()="natural gas" or text()="fuel oil" or text()="propane" or text()="wood" or text()="wood pellets"] or not(h:HeatingSystemFuel)'>Expected HeatingSystemFuel to be 'electricity' or 'natural gas' or 'fuel oil' or 'propane' or 'wood' or 'wood pellets'</sch:assert>
      <sch:assert role='ERROR' test='count(h:HeatingCapacity) = 1'>Expected 1 element(s) for xpath: HeatingCapacity</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualHeatingEfficiency[h:Units="Percent"]/h:Value) = 1'>Expected 1 element(s) for xpath: AnnualHeatingEfficiency[Units="Percent"]/Value</sch:assert>
      <sch:assert role='ERROR' test='number(h:AnnualHeatingEfficiency[h:Units="Percent"]/h:Value) &lt;= 1 or not(h:AnnualHeatingEfficiency[h:Units="Percent"]/h:Value)'>Expected AnnualHeatingEfficiency[Units="Percent"]/Value to be less than or equal to 1</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionHeatLoadServed) = 1'>Expected 1 element(s) for xpath: FractionHeatLoadServed</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:FanPowerWatts) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/FanPowerWatts</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:FanPowerWatts) &gt;= 0 or not(h:extension/h:FanPowerWatts)'>Expected extension/FanPowerWatts to be greater than or equal to 0</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatingSystemType=Fireplace]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:HeatingSystem[h:HeatingSystemType/h:Fireplace]'>
      <sch:assert role='ERROR' test='count(h:DistributionSystem) = 0'>Expected 0 element(s) for xpath: DistributionSystem</sch:assert>
      <sch:assert role='ERROR' test='count(h:HeatingSystemFuel) = 1'>Expected 1 element(s) for xpath: HeatingSystemFuel</sch:assert>
      <sch:assert role='ERROR' test='h:HeatingSystemFuel[text()="electricity" or text()="natural gas" or text()="fuel oil" or text()="propane" or text()="wood" or text()="wood pellets"] or not(h:HeatingSystemFuel)'>Expected HeatingSystemFuel to be 'electricity' or 'natural gas' or 'fuel oil' or 'propane' or 'wood' or 'wood pellets'</sch:assert>
      <sch:assert role='ERROR' test='count(h:HeatingCapacity) = 1'>Expected 1 element(s) for xpath: HeatingCapacity</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualHeatingEfficiency[h:Units="Percent"]/h:Value) = 1'>Expected 1 element(s) for xpath: AnnualHeatingEfficiency[Units="Percent"]/Value</sch:assert>
      <sch:assert role='ERROR' test='number(h:AnnualHeatingEfficiency[h:Units="Percent"]/h:Value) &lt;= 1 or not(h:AnnualHeatingEfficiency[h:Units="Percent"]/h:Value)'>Expected AnnualHeatingEfficiency[Units="Percent"]/Value to be less than or equal to 1</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionHeatLoadServed) = 1'>Expected 1 element(s) for xpath: FractionHeatLoadServed</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:FanPowerWatts) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/FanPowerWatts</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:FanPowerWatts) &gt;= 0 or not(h:extension/h:FanPowerWatts)'>Expected extension/FanPowerWatts to be greater than or equal to 0</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[CoolingSystem]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:CoolingSystem'>
      <sch:assert role='ERROR' test='count(../../h:HVACControl) = 1'>Expected 1 element(s) for xpath: ../../HVACControl</sch:assert> <!-- See [HVACControl] -->
      <sch:assert role='ERROR' test='count(h:CoolingSystemType) = 1'>Expected 1 element(s) for xpath: CoolingSystemType</sch:assert> <!-- See [CoolingSystemType=CentralAC] or [CoolingSystemType=PTACorRoomAC] or [CoolingSystemType=EvapCooler] or [CoolingSystemType=MiniSplitAC] or [CoolingSystemType=SharedChiller] or [CoolingSystemType=SharedCoolingTowerWLHP] -->
      <sch:assert role='ERROR' test='h:CoolingSystemType[text()="central air conditioner" or text()="room air conditioner" or text()="evaporative cooler" or text()="mini-split" or text()="chiller" or text()="cooling tower" or text()="packaged terminal air conditioner"] or not(h:CoolingSystemType)'>Expected CoolingSystemType to be 'central air conditioner' or 'room air conditioner' or 'evaporative cooler' or 'mini-split' or 'chiller' or 'cooling tower' or 'packaged terminal air conditioner'</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[CoolingSystemType=CentralAC]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:CoolingSystem[h:CoolingSystemType="central air conditioner"]'>
      <sch:assert role='ERROR' test='count(../../h:HVACDistribution/h:DistributionSystemType/h:AirDistribution/h:AirDistributionType[text()="regular velocity"]) + count(../../h:HVACDistribution/h:DistributionSystemType/h:Other[text()="DSE"]) &gt;= 1'>Expected 1 or more element(s) for xpath: ../../HVACDistribution/DistributionSystemType/AirDistribution/AirDistributionType[text()="regular velocity"] | ../../HVACDistribution/DistributionSystemType/Other[text()="DSE"]</sch:assert> <!-- See [HVACDistribution] -->
      <sch:assert role='ERROR' test='count(h:DistributionSystem) = 1'>Expected 1 element(s) for xpath: DistributionSystem</sch:assert>
      <sch:assert role='ERROR' test='count(h:CoolingSystemFuel) = 1'>Expected 1 element(s) for xpath: CoolingSystemFuel</sch:assert>
      <sch:assert role='ERROR' test='h:CoolingSystemFuel[text()="electricity"] or not(h:CoolingSystemFuel)'>Expected CoolingSystemFuel to be 'electricity'</sch:assert>
      <sch:assert role='ERROR' test='count(h:CoolingCapacity) = 1'>Expected 1 element(s) for xpath: CoolingCapacity</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionCoolLoadServed) = 1'>Expected 1 element(s) for xpath: FractionCoolLoadServed</sch:assert>
      <sch:assert role='ERROR' test='count(h:CompressorType) = 1'>Expected 1 element(s) for xpath: CompressorType</sch:assert>
      <sch:assert role='ERROR' test='h:CompressorType[text()="single stage" or text()="two stage" or text()="variable speed"] or not(h:CompressorType)'>Expected CompressorType to be 'single stage' or 'two stage' or 'variable speed'</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualCoolingEfficiency[h:Units="SEER" or h:Units="SEER2"]/h:Value) = 1'>Expected 1 element(s) for xpath: AnnualCoolingEfficiency[Units="SEER" or Units="SEER2"]/Value</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualCoolingEfficiency[h:Units="EER" or h:Units="EER2"]/h:Value) = 1'>Expected 1 element(s) for xpath: AnnualCoolingEfficiency[Units="EER" or Units="EER2"]/Value</sch:assert>
      <sch:assert role='ERROR' test='number(h:AnnualCoolingEfficiency[h:Units="EER"]/h:Value) &lt; number(h:AnnualCoolingEfficiency[h:Units="SEER"]/h:Value) or not(h:AnnualCoolingEfficiency[h:Units="EER"]/h:Value) or not(h:AnnualCoolingEfficiency[h:Units="SEER"]/h:Value)'>Expected EER to be less than SEER.</sch:assert>
      <sch:assert role='ERROR' test='number(h:AnnualCoolingEfficiency[h:Units="EER2"]/h:Value) &lt;= number(h:AnnualCoolingEfficiency[h:Units="SEER2"]/h:Value) or not(h:AnnualCoolingEfficiency[h:Units="EER2"]/h:Value) or not(h:AnnualCoolingEfficiency[h:Units="SEER2"]/h:Value)'>Expected EER2 to be less than or equal to SEER2.</sch:assert>
      <sch:assert role='ERROR' test='count(h:SensibleHeatFraction) = 0'>Expected 0 element(s) for xpath: SensibleHeatFraction</sch:assert>
      <sch:assert role='ERROR' test='count(h:IntegratedHeatingSystemFuel) = 0'>Expected 0 element(s) for xpath: IntegratedHeatingSystemFuel</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:FanPowerWattsPerCFM) = 1'>Expected 1 element(s) for xpath: extension/FanPowerWattsPerCFM</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:FanPowerWattsPerCFM) &gt;= 0 or not(h:extension/h:FanPowerWattsPerCFM)'>Expected extension/FanPowerWattsPerCFM to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:FanMotorType) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/FanMotorType</sch:assert>
      <sch:assert role='ERROR' test='h:extension/h:FanMotorType[text()="PSC" or text()="BPM"] or not(h:extension/h:FanMotorType)'>Expected extension/FanMotorType to be 'PSC' or 'BPM'</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:CoolingDesignAirflowCFM) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/CoolingDesignAirflowCFM</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:CoolingDesignAirflowCFM) &gt;= 0 or not(h:extension/h:CoolingDesignAirflowCFM)'>Expected extension/CoolingDesignAirflowCFM to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:AirflowDefectRatio) = 1'>Expected 1 element(s) for xpath: extension/AirflowDefectRatio</sch:assert> <!-- See [AirflowDefectRatio] -->
      <sch:assert role='ERROR' test='number(h:extension/h:AirflowDefectRatio) &gt;= -0.9 or not(h:extension/h:AirflowDefectRatio)'>Expected extension/AirflowDefectRatio to be greater than or equal to -0.9</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:AirflowDefectRatio) &lt;= 9 or not(h:extension/h:AirflowDefectRatio)'>Expected extension/AirflowDefectRatio to be less than or equal to 9</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:ChargeDefectRatio) = 1'>Expected 1 element(s) for xpath: extension/ChargeDefectRatio</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:ChargeDefectRatio) = 0 or number(h:extension/h:ChargeDefectRatio) = -0.25 or number(h:extension/h:ChargeDefectRatio) = 0.25 or not(h:extension/h:ChargeDefectRatio)'>Expected extension/ChargeDefectRatio to be 0, -0.25, or 0.25</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:EquipmentType) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/EquipmentType</sch:assert>
      <sch:assert role='ERROR' test='h:extension/h:EquipmentType[text()="split system" or text()="packaged system" or text()="small duct high velocity system" or text()="space constrained system"] or not(h:extension/h:EquipmentType)'>Expected extension/EquipmentType to be 'split system', 'packaged system', 'small duct high velocity system', or 'space constrained system'</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[CoolingSystemType=PTACorRoomAC]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:CoolingSystem[h:CoolingSystemType="room air conditioner" or h:CoolingSystemType="packaged terminal air conditioner"]'>
      <sch:assert role='ERROR' test='count(h:DistributionSystem) = 0'>Expected 0 element(s) for xpath: DistributionSystem</sch:assert>
      <sch:assert role='ERROR' test='count(h:CoolingSystemFuel) = 1'>Expected 1 element(s) for xpath: CoolingSystemFuel</sch:assert>
      <sch:assert role='ERROR' test='h:CoolingSystemFuel[text()="electricity"] or not(h:CoolingSystemFuel)'>Expected CoolingSystemFuel to be 'electricity'</sch:assert>
      <sch:assert role='ERROR' test='count(h:CoolingCapacity) = 1'>Expected 1 element(s) for xpath: CoolingCapacity</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionCoolLoadServed) = 1'>Expected 1 element(s) for xpath: FractionCoolLoadServed</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualCoolingEfficiency[h:Units="EER" or h:Units="CEER"]/h:Value) = 1'>Expected 1 element(s) for xpath: AnnualCoolingEfficiency[Units="EER" or Units="CEER"]/Value</sch:assert>
      <sch:assert role='ERROR' test='count(h:SensibleHeatFraction) = 0'>Expected 0 element(s) for xpath: SensibleHeatFraction</sch:assert>
      <sch:assert role='ERROR' test='count(h:IntegratedHeatingSystemFuel) &lt;= 1'>Expected 0 or 1 element(s) for xpath: IntegratedHeatingSystemFuel</sch:assert>
      <sch:assert role='ERROR' test='h:IntegratedHeatingSystemFuel[text()="electricity" or text()="natural gas" or text()="fuel oil" or text()="propane" or text()="wood" or text()="wood pellets"] or not(h:IntegratedHeatingSystemFuel)'>Expected IntegratedHeatingSystemFuel to be 'electricity' or 'natural gas' or 'fuel oil' or 'propane' or 'wood' or 'wood pellets'</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[CoolingSystemType=EvapCooler]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:CoolingSystem[h:CoolingSystemType="evaporative cooler"]'>
      <sch:assert role='ERROR' test='count(../../h:HVACDistribution/h:DistributionSystemType/h:AirDistribution/h:AirDistributionType[text()="regular velocity"]) + count(../../h:HVACDistribution/h:DistributionSystemType/h:Other[text()="DSE"]) &gt;= 0'>Expected 0 or more element(s) for xpath: ../../HVACDistribution/DistributionSystemType/AirDistribution/AirDistributionType[text()="regular velocity"] | ../../HVACDistribution/DistributionSystemType/Other[text()="DSE"]</sch:assert> <!-- See [HVACDistribution] -->
      <sch:assert role='ERROR' test='count(h:DistributionSystem) &lt;= 1'>Expected 0 or 1 element(s) for xpath: DistributionSystem</sch:assert>
      <sch:assert role='ERROR' test='count(h:CoolingSystemFuel) = 1'>Expected 1 element(s) for xpath: CoolingSystemFuel</sch:assert>
      <sch:assert role='ERROR' test='h:CoolingSystemFuel[text()="electricity"] or not(h:CoolingSystemFuel)'>Expected CoolingSystemFuel to be 'electricity'</sch:assert>
      <sch:assert role='ERROR' test='count(h:CoolingCapacity) = 1'>Expected 1 element(s) for xpath: CoolingCapacity</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionCoolLoadServed) = 1'>Expected 1 element(s) for xpath: FractionCoolLoadServed</sch:assert>
      <sch:assert role='ERROR' test='count(h:IntegratedHeatingSystemFuel) = 0'>Expected 0 element(s) for xpath: IntegratedHeatingSystemFuel</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[CoolingSystemType=MiniSplitAC]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:CoolingSystem[h:CoolingSystemType="mini-split"]'>
      <sch:assert role='ERROR' test='count(../../h:HVACDistribution/h:DistributionSystemType/h:AirDistribution/h:AirDistributionType[text()="regular velocity"]) + count(../../h:HVACDistribution/h:DistributionSystemType/h:Other[text()="DSE"]) &gt;= 0'>Expected 0 or more element(s) for xpath: ../../HVACDistribution/DistributionSystemType/AirDistribution/AirDistributionType[text()="regular velocity"] | ../../HVACDistribution/DistributionSystemType/Other[text()="DSE"]</sch:assert> <!-- See [HVACDistribution] -->
      <sch:assert role='ERROR' test='count(h:DistributionSystem) &lt;= 1'>Expected 0 or 1 element(s) for xpath: DistributionSystem</sch:assert>
      <sch:assert role='ERROR' test='count(h:CoolingSystemFuel) = 1'>Expected 1 element(s) for xpath: CoolingSystemFuel</sch:assert>
      <sch:assert role='ERROR' test='h:CoolingSystemFuel[text()="electricity"] or not(h:CoolingSystemFuel)'>Expected CoolingSystemFuel to be 'electricity'</sch:assert>
      <sch:assert role='ERROR' test='count(h:CoolingCapacity) = 1'>Expected 1 element(s) for xpath: CoolingCapacity</sch:assert>
      <sch:assert role='ERROR' test='count(h:CompressorType) = 1'>Expected 1 element(s) for xpath: CompressorType</sch:assert>
      <sch:assert role='ERROR' test='h:CompressorType[text()="variable speed"] or not(h:CompressorType)'>Expected CompressorType to be 'variable speed'</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionCoolLoadServed) = 1'>Expected 1 element(s) for xpath: FractionCoolLoadServed</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualCoolingEfficiency[h:Units="SEER" or h:Units="SEER2"]/h:Value) = 1'>Expected 1 element(s) for xpath: AnnualCoolingEfficiency[Units="SEER" or Units="SEER2"]/Value</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualCoolingEfficiency[h:Units="EER" or h:Units="EER2"]/h:Value) = 1'>Expected 1 element(s) for xpath: AnnualCoolingEfficiency[Units="EER" or Units="EER2"]/Value</sch:assert>
      <sch:assert role='ERROR' test='number(h:AnnualCoolingEfficiency[h:Units="EER"]/h:Value) &lt; number(h:AnnualCoolingEfficiency[h:Units="SEER"]/h:Value) or not(h:AnnualCoolingEfficiency[h:Units="EER"]/h:Value) or not(h:AnnualCoolingEfficiency[h:Units="SEER"]/h:Value)'>Expected EER to be less than SEER.</sch:assert>
      <sch:assert role='ERROR' test='number(h:AnnualCoolingEfficiency[h:Units="EER2"]/h:Value) &lt;= number(h:AnnualCoolingEfficiency[h:Units="SEER2"]/h:Value) or not(h:AnnualCoolingEfficiency[h:Units="EER2"]/h:Value) or not(h:AnnualCoolingEfficiency[h:Units="SEER2"]/h:Value)'>Expected EER2 to be less than or equal to SEER2.</sch:assert>
      <sch:assert role='ERROR' test='count(h:SensibleHeatFraction) = 0'>Expected 0 element(s) for xpath: SensibleHeatFraction</sch:assert>
      <sch:assert role='ERROR' test='count(h:IntegratedHeatingSystemFuel) = 0'>Expected 0 element(s) for xpath: IntegratedHeatingSystemFuel</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:FanPowerWattsPerCFM) = 1'>Expected 1 element(s) for xpath: extension/FanPowerWattsPerCFM</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:FanPowerWattsPerCFM) &gt;= 0 or not(h:extension/h:FanPowerWattsPerCFM)'>Expected extension/FanPowerWattsPerCFM to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:FanMotorType) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/FanMotorType</sch:assert>
      <sch:assert role='ERROR' test='h:extension/h:FanMotorType[text()="PSC" or text()="BPM"] or not(h:extension/h:FanMotorType)'>Expected extension/FanMotorType to be 'PSC' or 'BPM'</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:CoolingDesignAirflowCFM) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/CoolingDesignAirflowCFM</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:CoolingDesignAirflowCFM) &gt;= 0 or not(h:extension/h:CoolingDesignAirflowCFM)'>Expected extension/CoolingDesignAirflowCFM to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:AirflowDefectRatio) = 1'>Expected 1 element(s) for xpath: extension/AirflowDefectRatio</sch:assert> <!-- See [AirflowDefectRatio] -->
      <sch:assert role='ERROR' test='number(h:extension/h:AirflowDefectRatio) &gt;= -0.9 or not(h:extension/h:AirflowDefectRatio)'>Expected extension/AirflowDefectRatio to be greater than or equal to -0.9</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:AirflowDefectRatio) &lt;= 9 or not(h:extension/h:AirflowDefectRatio)'>Expected extension/AirflowDefectRatio to be less than or equal to 9</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:ChargeDefectRatio) = 1'>Expected 1 element(s) for xpath: extension/ChargeDefectRatio</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:ChargeDefectRatio) = 0 or number(h:extension/h:ChargeDefectRatio) = -0.25 or number(h:extension/h:ChargeDefectRatio) = 0.25 or not(h:extension/h:ChargeDefectRatio)'>Expected extension/ChargeDefectRatio to be 0, -0.25, or 0.25</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[CoolingSystemType=SharedChiller]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:CoolingSystem[h:CoolingSystemType="chiller"]'>
      <sch:assert role='ERROR' test='count(../../../../h:BuildingSummary/h:BuildingConstruction[h:ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]]) = 1'>Expected 1 element(s) for xpath: ../../../../BuildingSummary/BuildingConstruction[ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]]</sch:assert>
      <sch:assert role='ERROR' test='count(../../h:HVACDistribution/h:DistributionSystemType/h:HydronicDistribution/h:HydronicDistributionType[text()="radiator" or text()="baseboard" or text()="radiant floor" or text()="radiant ceiling" or text()="water loop"]) + count(../../h:HVACDistribution/h:DistributionSystemType/h:AirDistribution/h:AirDistributionType[text()="fan coil"]) &gt;= 1'>Expected 1 or more element(s) for xpath: ../../HVACDistribution/DistributionSystemType/HydronicDistribution/HydronicDistributionType[text()="radiator" or text()="baseboard" or text()="radiant floor" or text()="radiant ceiling" or text()="water loop"] | ../../HVACDistribution/DistributionSystemType/AirDistribution/AirDistributionType[text()="fan coil"]</sch:assert> <!-- See [HVACDistribution] or [CoolingSystemType=SharedChillerWithFanCoil] or [CoolingSystemType=SharedChillerWithWLHP] -->
      <sch:assert role='ERROR' test='count(h:DistributionSystem) = 1'>Expected 1 element(s) for xpath: DistributionSystem</sch:assert>
      <sch:assert role='ERROR' test='count(h:IsSharedSystem[text()="true"]) = 1'>Expected 1 element(s) for xpath: IsSharedSystem[text()="true"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:NumberofUnitsServed) = 1'>Expected 1 element(s) for xpath: NumberofUnitsServed</sch:assert>
      <sch:assert role='ERROR' test='number(h:NumberofUnitsServed) &gt; 1 or not(h:NumberofUnitsServed)'>Expected NumberofUnitsServed to be greater than 1</sch:assert>
      <sch:assert role='ERROR' test='count(h:CoolingSystemFuel) = 1'>Expected 1 element(s) for xpath: CoolingSystemFuel</sch:assert>
      <sch:assert role='ERROR' test='h:CoolingSystemFuel[text()="electricity"] or not(h:CoolingSystemFuel)'>Expected CoolingSystemFuel to be 'electricity'</sch:assert>
      <sch:assert role='ERROR' test='count(h:CoolingCapacity) = 1'>Expected 1 element(s) for xpath: CoolingCapacity</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionCoolLoadServed) = 1'>Expected 1 element(s) for xpath: FractionCoolLoadServed</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualCoolingEfficiency[h:Units="kW/ton"]/h:Value) = 1'>Expected 1 element(s) for xpath: AnnualCoolingEfficiency[Units="kW/ton"]/Value</sch:assert>
      <sch:assert role='ERROR' test='count(h:IntegratedHeatingSystemFuel) = 0'>Expected 0 element(s) for xpath: IntegratedHeatingSystemFuel</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:SharedLoopWatts) = 1'>Expected 1 element(s) for xpath: extension/SharedLoopWatts</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:SharedLoopWatts) &gt;= 0 or not(h:extension/h:SharedLoopWatts)'>Expected extension/SharedLoopWatts to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:SharedLoopMotorEfficiency) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/SharedLoopMotorEfficiency</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:SharedLoopMotorEfficiency) &gt; 0 or not(h:extension/h:SharedLoopMotorEfficiency)'>Expected extension/SharedLoopMotorEfficiency to be greater than 0</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:SharedLoopMotorEfficiency) &lt; 1 or not(h:extension/h:SharedLoopMotorEfficiency)'>Expected extension/SharedLoopMotorEfficiency to be less than 1</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[CoolingSystemType=SharedChillerWithFanCoil]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:CoolingSystem[h:CoolingSystemType="chiller" and ../../h:HVACDistribution/h:DistributionSystemType/h:AirDistribution/h:AirDistributionType[text()="fan coil"]]'>
      <sch:assert role='ERROR' test='count(h:extension/h:FanCoilWatts) = 1'>Expected 1 element(s) for xpath: extension/FanCoilWatts</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:FanCoilWatts) &gt;= 0 or not(h:extension/h:FanCoilWatts)'>Expected extension/FanCoilWatts to be greater than or equal to 0</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[CoolingSystemType=SharedChillerWithWLHP]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:CoolingSystem[h:CoolingSystemType="chiller" and ../../h:HVACDistribution/h:DistributionSystemType/h:HydronicDistribution/h:HydronicDistributionType[text()="water loop"]]'>
      <sch:assert role='ERROR' test='count(../h:HeatPump[h:HeatPumpType="water-loop-to-air"]/h:CoolingCapacity) = 1'>Expected 1 element(s) for xpath: ../HeatPump[HeatPumpType="water-loop-to-air"]/CoolingCapacity</sch:assert>
      <sch:assert role='ERROR' test='count(../h:HeatPump[h:HeatPumpType="water-loop-to-air"]/h:AnnualCoolingEfficiency[h:Units="EER"]/h:Value) = 1'>Expected 1 element(s) for xpath: ../HeatPump[HeatPumpType="water-loop-to-air"]/AnnualCoolingEfficiency[Units="EER"]/Value</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[CoolingSystemType=SharedCoolingTowerWLHP]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:CoolingSystem[h:CoolingSystemType="cooling tower"]'>
      <sch:assert role='ERROR' test='count(../../../../h:BuildingSummary/h:BuildingConstruction[h:ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]]) = 1'>Expected 1 element(s) for xpath: ../../../../BuildingSummary/BuildingConstruction[ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]]</sch:assert>
      <sch:assert role='ERROR' test='count(../../h:HVACDistribution/h:DistributionSystemType/h:HydronicDistribution/h:HydronicDistributionType[text()="water loop"]) &gt;= 1'>Expected 1 or more element(s) for xpath: ../../HVACDistribution/DistributionSystemType/HydronicDistribution/HydronicDistributionType[text()="water loop"]</sch:assert> <!-- See [HVACDistribution] -->
      <sch:assert role='ERROR' test='count(h:DistributionSystem) = 1'>Expected 1 element(s) for xpath: DistributionSystem</sch:assert>
      <sch:assert role='ERROR' test='count(h:IsSharedSystem[text()="true"]) = 1'>Expected 1 element(s) for xpath: IsSharedSystem[text()="true"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:NumberofUnitsServed) = 1'>Expected 1 element(s) for xpath: NumberofUnitsServed</sch:assert>
      <sch:assert role='ERROR' test='number(h:NumberofUnitsServed) &gt; 1 or not(h:NumberofUnitsServed)'>Expected NumberofUnitsServed to be greater than 1</sch:assert>
      <sch:assert role='ERROR' test='count(h:IntegratedHeatingSystemFuel) = 0'>Expected 0 element(s) for xpath: IntegratedHeatingSystemFuel</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:SharedLoopWatts) = 1'>Expected 1 element(s) for xpath: extension/SharedLoopWatts</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:SharedLoopWatts) &gt;= 0 or not(h:extension/h:SharedLoopWatts)'>Expected extension/SharedLoopWatts to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:SharedLoopMotorEfficiency) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/SharedLoopMotorEfficiency</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:SharedLoopMotorEfficiency) &gt; 0 or not(h:extension/h:SharedLoopMotorEfficiency)'>Expected extension/SharedLoopMotorEfficiency to be greater than 0</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:SharedLoopMotorEfficiency) &lt; 1 or not(h:extension/h:SharedLoopMotorEfficiency)'>Expected extension/SharedLoopMotorEfficiency to be less than 1</sch:assert>
      <sch:assert role='ERROR' test='count(../h:HeatPump[h:HeatPumpType="water-loop-to-air"]/h:CoolingCapacity) = 1'>Expected 1 element(s) for xpath: ../HeatPump[HeatPumpType="water-loop-to-air"]/CoolingCapacity</sch:assert>
      <sch:assert role='ERROR' test='count(../h:HeatPump[h:HeatPumpType="water-loop-to-air"]/h:AnnualCoolingEfficiency[h:Units="EER"]/h:Value) = 1'>Expected 1 element(s) for xpath: ../HeatPump[HeatPumpType="water-loop-to-air"]/AnnualCoolingEfficiency[Units="EER"]/Value</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[CoolingSystem=HasIntegratedHeatingSystem]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:CoolingSystem[h:IntegratedHeatingSystemFuel]'>
      <sch:assert role='ERROR' test='count(h:IntegratedHeatingSystemFractionHeatLoadServed) = 1'>Expected 1 element(s) for xpath: IntegratedHeatingSystemFractionHeatLoadServed</sch:assert>
      <sch:assert role='ERROR' test='count(h:IntegratedHeatingSystemCapacity) = 1'>Expected 1 element(s) for xpath: IntegratedHeatingSystemCapacity</sch:assert>
      <sch:assert role='ERROR' test='count(h:IntegratedHeatingSystemAnnualEfficiency[h:Units="Percent"]) = 1'>Expected 1 element(s) for xpath: IntegratedHeatingSystemAnnualEfficiency[Units="Percent"]</sch:assert>
      <sch:assert role='ERROR' test='number(h:IntegratedHeatingSystemAnnualEfficiency[h:Units="Percent"]/h:Value) &lt;= 1 or not(h:IntegratedHeatingSystemAnnualEfficiency[h:Units="Percent"]/h:Value)'>Expected IntegratedHeatingSystemAnnualEfficiency[Units="Percent"]/Value to be less than or equal to 1</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatPump]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:HeatPump'>
      <sch:assert role='ERROR' test='count(../../h:HVACControl) = 1'>Expected 1 element(s) for xpath: ../../HVACControl</sch:assert> <!-- See [HVACControl] -->
      <sch:assert role='ERROR' test='count(h:HeatPumpType) = 1'>Expected 1 element(s) for xpath: HeatPumpType</sch:assert> <!-- See [HeatPumpType=AirSource] or [HeatPumpType=MiniSplit] or [HeatPumpType=GroundSource] or [HeatPumpType=WaterLoop] or [HeatPumpType=PTHPorRoomACwithReverseCycle] -->
      <sch:assert role='ERROR' test='h:HeatPumpType[text()="air-to-air" or text()="mini-split" or text()="ground-to-air" or text()="water-loop-to-air" or text()="packaged terminal heat pump" or text()="room air conditioner with reverse cycle"] or not(h:HeatPumpType)'>Expected HeatPumpType to be 'air-to-air' or 'mini-split' or 'ground-to-air' or 'water-loop-to-air' or 'packaged terminal heat pump' or 'room air conditioner with reverse cycle'</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatPumpType=AirSource]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:HeatPump[h:HeatPumpType="air-to-air"]'>
      <sch:assert role='ERROR' test='count(../../h:HVACDistribution/h:DistributionSystemType/h:AirDistribution/h:AirDistributionType[text()="regular velocity"]) + count(../../h:HVACDistribution/h:DistributionSystemType/h:Other[text()="DSE"]) &gt;= 1'>Expected 1 or more element(s) for xpath: ../../HVACDistribution/DistributionSystemType/AirDistribution/AirDistributionType[text()="regular velocity"] | ../../HVACDistribution/DistributionSystemType/Other[text()="DSE"]</sch:assert> <!-- See [HVACDistribution] -->
      <sch:assert role='ERROR' test='count(h:DistributionSystem) = 1'>Expected 1 element(s) for xpath: DistributionSystem</sch:assert>
      <sch:assert role='ERROR' test='count(h:HeatPumpFuel) = 1'>Expected 1 element(s) for xpath: HeatPumpFuel</sch:assert>
      <sch:assert role='ERROR' test='h:HeatPumpFuel[text()="electricity"] or not(h:HeatPumpFuel)'>Expected HeatPumpFuel to be 'electricity'</sch:assert>
      <sch:assert role='ERROR' test='count(h:HeatingCapacity) = 1'>Expected 1 element(s) for xpath: HeatingCapacity</sch:assert>
      <sch:assert role='ERROR' test='count(h:HeatingCapacity17F) = 1'>Expected 1 element(s) for xpath: HeatingCapacity17F</sch:assert>
      <sch:assert role='ERROR' test='number(h:HeatingCapacity17F) &lt;= number(h:HeatingCapacity) or not(h:HeatingCapacity17F) or not(h:HeatingCapacity)'>Expected HeatingCapacity17F to be less than or equal to HeatingCapacity</sch:assert>
      <sch:assert role='ERROR' test='count(h:CoolingCapacity) = 1'>Expected 1 element(s) for xpath: CoolingCapacity</sch:assert>
      <sch:assert role='ERROR' test='count(h:CompressorType) = 1'>Expected 1 element(s) for xpath: CompressorType</sch:assert>
      <sch:assert role='ERROR' test='h:CompressorType[text()="single stage" or text()="two stage" or text()="variable speed"] or not(h:CompressorType)'>Expected CompressorType to be 'single stage' or 'two stage' or 'variable speed'</sch:assert>
      <sch:assert role='ERROR' test='count(h:CompressorLockoutTemperature) &lt;= 1'>Expected 0 or 1 element(s) for xpath: CompressorLockoutTemperature</sch:assert>
      <sch:assert role='ERROR' test='count(h:CoolingSensibleHeatFraction) = 0'>Expected 0 element(s) for xpath: CoolingSensibleHeatFraction</sch:assert>
      <sch:assert role='ERROR' test='count(h:BackupType) &lt;= 1'>Expected 0 or 1 element(s) for xpath: BackupType</sch:assert> <!-- See [HeatPumpBackup=Integrated] -->
      <sch:assert role='ERROR' test='h:BackupType[text()="integrated"] or not(h:BackupType)'>Expected BackupType to be 'integrated'</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionHeatLoadServed) = 1'>Expected 1 element(s) for xpath: FractionHeatLoadServed</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionCoolLoadServed) = 1'>Expected 1 element(s) for xpath: FractionCoolLoadServed</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualCoolingEfficiency[h:Units="SEER" or h:Units="SEER2"]/h:Value) = 1'>Expected 1 element(s) for xpath: AnnualCoolingEfficiency[Units="SEER" or Units="SEER2"]/Value</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualCoolingEfficiency[h:Units="EER" or h:Units="EER2"]/h:Value) = 1'>Expected 1 element(s) for xpath: AnnualCoolingEfficiency[Units="EER" or Units="EER2"]/Value</sch:assert>
      <sch:assert role='ERROR' test='number(h:AnnualCoolingEfficiency[h:Units="EER"]/h:Value) &lt; number(h:AnnualCoolingEfficiency[h:Units="SEER"]/h:Value) or not(h:AnnualCoolingEfficiency[h:Units="EER"]/h:Value) or not(h:AnnualCoolingEfficiency[h:Units="SEER"]/h:Value)'>Expected EER to be less than SEER.</sch:assert>
      <sch:assert role='ERROR' test='number(h:AnnualCoolingEfficiency[h:Units="EER2"]/h:Value) &lt;= number(h:AnnualCoolingEfficiency[h:Units="SEER2"]/h:Value) or not(h:AnnualCoolingEfficiency[h:Units="EER2"]/h:Value) or not(h:AnnualCoolingEfficiency[h:Units="SEER2"]/h:Value)'>Expected EER2 to be less than or equal to SEER2.</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualHeatingEfficiency[h:Units="HSPF" or h:Units="HSPF2"]/h:Value) = 1'>Expected 1 element(s) for xpath: AnnualHeatingEfficiency[Units="HSPF" or Units="HSPF2"]/Value</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:FanPowerWattsPerCFM) = 1'>Expected 1 element(s) for xpath: extension/FanPowerWattsPerCFM</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:FanPowerWattsPerCFM) &gt;= 0 or not(h:extension/h:FanPowerWattsPerCFM)'>Expected extension/FanPowerWattsPerCFM to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:FanMotorType) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/FanMotorType</sch:assert>
      <sch:assert role='ERROR' test='h:extension/h:FanMotorType[text()="PSC" or text()="BPM"] or not(h:extension/h:FanMotorType)'>Expected extension/FanMotorType to be 'PSC' or 'BPM'</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:HeatingDesignAirflowCFM) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/HeatingDesignAirflowCFM</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:HeatingDesignAirflowCFM) &gt;= 0 or not(h:extension/h:HeatingDesignAirflowCFM)'>Expected extension/HeatingDesignAirflowCFM to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:CoolingDesignAirflowCFM) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/CoolingDesignAirflowCFM</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:CoolingDesignAirflowCFM) &gt;= 0 or not(h:extension/h:CoolingDesignAirflowCFM)'>Expected extension/CoolingDesignAirflowCFM to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:AirflowDefectRatio) = 1'>Expected 1 element(s) for xpath: extension/AirflowDefectRatio</sch:assert> <!-- See [AirflowDefectRatio] -->
      <sch:assert role='ERROR' test='number(h:extension/h:AirflowDefectRatio) &gt;= -0.9 or not(h:extension/h:AirflowDefectRatio)'>Expected extension/AirflowDefectRatio to be greater than or equal to -0.9</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:AirflowDefectRatio) &lt;= 9 or not(h:extension/h:AirflowDefectRatio)'>Expected extension/AirflowDefectRatio to be less than or equal to 9</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:ChargeDefectRatio) = 1'>Expected 1 element(s) for xpath: extension/ChargeDefectRatio</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:ChargeDefectRatio) = 0 or number(h:extension/h:ChargeDefectRatio) = -0.25 or number(h:extension/h:ChargeDefectRatio) = 0.25 or not(h:extension/h:ChargeDefectRatio)'>Expected extension/ChargeDefectRatio to be 0, -0.25, or 0.25</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:EquipmentType) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/EquipmentType</sch:assert>
      <sch:assert role='ERROR' test='h:extension/h:EquipmentType[text()="split system" or text()="packaged system" or text()="small duct high velocity system" or text()="space constrained system"] or not(h:extension/h:EquipmentType)'>Expected extension/EquipmentType to be 'split system', 'packaged system', 'small duct high velocity system', or 'space constrained system'</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatPumpType=MiniSplit]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:HeatPump[h:HeatPumpType="mini-split"]'>
      <sch:assert role='ERROR' test='count(../../h:HVACDistribution/h:DistributionSystemType/h:AirDistribution/h:AirDistributionType[text()="regular velocity"]) + count(../../h:HVACDistribution/h:DistributionSystemType/h:Other[text()="DSE"]) &gt;= 0'>Expected 0 or more element(s) for xpath: ../../HVACDistribution/DistributionSystemType/AirDistribution/AirDistributionType[text()="regular velocity"] | ../../HVACDistribution/DistributionSystemType/Other[text()="DSE"]</sch:assert> <!-- See [HVACDistribution] -->
      <sch:assert role='ERROR' test='count(h:DistributionSystem) &lt;= 1'>Expected 0 or 1 element(s) for xpath: DistributionSystem</sch:assert>
      <sch:assert role='ERROR' test='count(h:HeatPumpFuel) = 1'>Expected 1 element(s) for xpath: HeatPumpFuel</sch:assert>
      <sch:assert role='ERROR' test='h:HeatPumpFuel[text()="electricity"] or not(h:HeatPumpFuel)'>Expected HeatPumpFuel to be 'electricity'</sch:assert>
      <sch:assert role='ERROR' test='count(h:HeatingCapacity) = 1'>Expected 1 element(s) for xpath: HeatingCapacity</sch:assert>
      <sch:assert role='ERROR' test='count(h:HeatingCapacity17F) = 1'>Expected 1 element(s) for xpath: HeatingCapacity17F</sch:assert>
      <sch:assert role='ERROR' test='number(h:HeatingCapacity17F) &lt;= number(h:HeatingCapacity) or not(h:HeatingCapacity17F) or not(h:HeatingCapacity)'>Expected HeatingCapacity17F to be less than or equal to HeatingCapacity</sch:assert>
      <sch:assert role='ERROR' test='count(h:CoolingCapacity) = 1'>Expected 1 element(s) for xpath: CoolingCapacity</sch:assert>
      <sch:assert role='ERROR' test='count(h:CompressorType) = 1'>Expected 1 element(s) for xpath: CompressorType</sch:assert>
      <sch:assert role='ERROR' test='h:CompressorType[text()="variable speed"] or not(h:CompressorType)'>Expected CompressorType to be 'variable speed'</sch:assert>
      <sch:assert role='ERROR' test='count(h:CompressorLockoutTemperature) &lt;= 1'>Expected 0 or 1 element(s) for xpath: CompressorLockoutTemperature</sch:assert>
      <sch:assert role='ERROR' test='count(h:CoolingSensibleHeatFraction) = 0'>Expected 0 element(s) for xpath: CoolingSensibleHeatFraction</sch:assert>
      <sch:assert role='ERROR' test='count(h:BackupType) &lt;= 1'>Expected 0 or 1 element(s) for xpath: BackupType</sch:assert> <!-- See [HeatPumpBackup=Integrated] -->
      <sch:assert role='ERROR' test='h:BackupType[text()="integrated"] or not(h:BackupType)'>Expected BackupType to be 'integrated'</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionHeatLoadServed) = 1'>Expected 1 element(s) for xpath: FractionHeatLoadServed</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionCoolLoadServed) = 1'>Expected 1 element(s) for xpath: FractionCoolLoadServed</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualCoolingEfficiency[h:Units="SEER" or h:Units="SEER2"]/h:Value) = 1'>Expected 1 element(s) for xpath: AnnualCoolingEfficiency[Units="SEER" or Units="SEER2"]/Value</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualCoolingEfficiency[h:Units="EER" or h:Units="EER2"]/h:Value) = 1'>Expected 1 element(s) for xpath: AnnualCoolingEfficiency[Units="EER" or Units="EER2"]/Value</sch:assert>
      <sch:assert role='ERROR' test='number(h:AnnualCoolingEfficiency[h:Units="EER"]/h:Value) &lt; number(h:AnnualCoolingEfficiency[h:Units="SEER"]/h:Value) or not(h:AnnualCoolingEfficiency[h:Units="EER"]/h:Value) or not(h:AnnualCoolingEfficiency[h:Units="SEER"]/h:Value)'>Expected EER to be less than SEER.</sch:assert>
      <sch:assert role='ERROR' test='number(h:AnnualCoolingEfficiency[h:Units="EER2"]/h:Value) &lt;= number(h:AnnualCoolingEfficiency[h:Units="SEER2"]/h:Value) or not(h:AnnualCoolingEfficiency[h:Units="EER2"]/h:Value) or not(h:AnnualCoolingEfficiency[h:Units="SEER2"]/h:Value)'>Expected EER2 to be less than or equal to SEER2.</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualHeatingEfficiency[h:Units="HSPF" or h:Units="HSPF2"]/h:Value) = 1'>Expected 1 element(s) for xpath: AnnualHeatingEfficiency[Units="HSPF" or Units="HSPF2"]/Value</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:FanPowerWattsPerCFM) = 1'>Expected 1 element(s) for xpath: extension/FanPowerWattsPerCFM</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:FanPowerWattsPerCFM) &gt;= 0 or not(h:extension/h:FanPowerWattsPerCFM)'>Expected extension/FanPowerWattsPerCFM to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:FanMotorType) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/FanMotorType</sch:assert>
      <sch:assert role='ERROR' test='h:extension/h:FanMotorType[text()="PSC" or text()="BPM"] or not(h:extension/h:FanMotorType)'>Expected extension/FanMotorType to be 'PSC' or 'BPM'</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:HeatingDesignAirflowCFM) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/HeatingDesignAirflowCFM</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:HeatingDesignAirflowCFM) &gt;= 0 or not(h:extension/h:HeatingDesignAirflowCFM)'>Expected extension/HeatingDesignAirflowCFM to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:CoolingDesignAirflowCFM) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/CoolingDesignAirflowCFM</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:CoolingDesignAirflowCFM) &gt;= 0 or not(h:extension/h:CoolingDesignAirflowCFM)'>Expected extension/CoolingDesignAirflowCFM to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:AirflowDefectRatio) = 1'>Expected 1 element(s) for xpath: extension/AirflowDefectRatio</sch:assert> <!-- See [AirflowDefectRatio] -->
      <sch:assert role='ERROR' test='number(h:extension/h:AirflowDefectRatio) &gt;= -0.9 or not(h:extension/h:AirflowDefectRatio)'>Expected extension/AirflowDefectRatio to be greater than or equal to -0.9</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:AirflowDefectRatio) &lt;= 9 or not(h:extension/h:AirflowDefectRatio)'>Expected extension/AirflowDefectRatio to be less than or equal to 9</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:ChargeDefectRatio) = 1'>Expected 1 element(s) for xpath: extension/ChargeDefectRatio</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:ChargeDefectRatio) = 0 or number(h:extension/h:ChargeDefectRatio) = -0.25 or number(h:extension/h:ChargeDefectRatio) = 0.25 or not(h:extension/h:ChargeDefectRatio)'>Expected extension/ChargeDefectRatio to be 0, -0.25, or 0.25</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatPumpType=GroundSource]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:HeatPump[h:HeatPumpType="ground-to-air"]'>
      <sch:assert role='ERROR' test='count(../../h:HVACDistribution/h:DistributionSystemType/h:AirDistribution/h:AirDistributionType[text()="regular velocity"]) + count(../../h:HVACDistribution/h:DistributionSystemType/h:Other[text()="DSE"]) &gt;= 1'>Expected 1 or more element(s) for xpath: ../../HVACDistribution/DistributionSystemType/AirDistribution/AirDistributionType[text()="regular velocity"] | ../../HVACDistribution/DistributionSystemType/Other[text()="DSE"]</sch:assert> <!-- See [HVACDistribution] -->
      <sch:assert role='ERROR' test='count(h:IsSharedSystem) = 1'>Expected 1 element(s) for xpath: IsSharedSystem</sch:assert> <!-- See [HeatPumpType=GroundSourceWithSharedLoop] -->
      <sch:assert role='ERROR' test='count(h:DistributionSystem) = 1'>Expected 1 element(s) for xpath: DistributionSystem</sch:assert>
      <sch:assert role='ERROR' test='count(h:HeatPumpFuel) = 1'>Expected 1 element(s) for xpath: HeatPumpFuel</sch:assert>
      <sch:assert role='ERROR' test='h:HeatPumpFuel[text()="electricity"] or not(h:HeatPumpFuel)'>Expected HeatPumpFuel to be 'electricity'</sch:assert>
      <sch:assert role='ERROR' test='count(h:HeatingCapacity) = 1'>Expected 1 element(s) for xpath: HeatingCapacity</sch:assert>
      <sch:assert role='ERROR' test='count(h:CoolingCapacity) = 1'>Expected 1 element(s) for xpath: CoolingCapacity</sch:assert>
      <sch:assert role='ERROR' test='count(h:CoolingSensibleHeatFraction) = 0'>Expected 0 element(s) for xpath: CoolingSensibleHeatFraction</sch:assert>
      <sch:assert role='ERROR' test='count(h:BackupType) &lt;= 1'>Expected 0 or 1 element(s) for xpath: BackupType</sch:assert> <!-- See [HeatPumpBackup=Integrated] -->
      <sch:assert role='ERROR' test='h:BackupType[text()="integrated"] or not(h:BackupType)'>Expected BackupType to be 'integrated'</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionHeatLoadServed) = 1'>Expected 1 element(s) for xpath: FractionHeatLoadServed</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionCoolLoadServed) = 1'>Expected 1 element(s) for xpath: FractionCoolLoadServed</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualCoolingEfficiency[h:Units="EER"]/h:Value) = 1'>Expected 1 element(s) for xpath: AnnualCoolingEfficiency[Units="EER"]/Value</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualHeatingEfficiency[h:Units="COP"]/h:Value) = 1'>Expected 1 element(s) for xpath: AnnualHeatingEfficiency[Units="COP"]/Value</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:PumpPowerWattsPerTon) = 1'>Expected 1 element(s) for xpath: extension/PumpPowerWattsPerTon</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:PumpPowerWattsPerTon) &gt;= 0 or not(h:extension/h:PumpPowerWattsPerTon)'>Expected extension/PumpPowerWattsPerTon to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:FanPowerWattsPerCFM) = 1'>Expected 1 element(s) for xpath: extension/FanPowerWattsPerCFM</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:FanPowerWattsPerCFM) &gt;= 0 or not(h:extension/h:FanPowerWattsPerCFM)'>Expected extension/FanPowerWattsPerCFM to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:FanMotorType) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/FanMotorType</sch:assert>
      <sch:assert role='ERROR' test='h:extension/h:FanMotorType[text()="PSC" or text()="BPM"] or not(h:extension/h:FanMotorType)'>Expected extension/FanMotorType to be 'PSC' or 'BPM'</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:HeatingDesignAirflowCFM) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/HeatingDesignAirflowCFM</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:HeatingDesignAirflowCFM) &gt;= 0 or not(h:extension/h:HeatingDesignAirflowCFM)'>Expected extension/HeatingDesignAirflowCFM to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:CoolingDesignAirflowCFM) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/CoolingDesignAirflowCFM</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:CoolingDesignAirflowCFM) &gt;= 0 or not(h:extension/h:CoolingDesignAirflowCFM)'>Expected extension/CoolingDesignAirflowCFM to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:AirflowDefectRatio) = 1'>Expected 1 element(s) for xpath: extension/AirflowDefectRatio</sch:assert> <!-- See [AirflowDefectRatio] -->
      <sch:assert role='ERROR' test='number(h:extension/h:AirflowDefectRatio) &gt;= -0.9 or not(h:extension/h:AirflowDefectRatio)'>Expected extension/AirflowDefectRatio to be greater than or equal to -0.9</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:AirflowDefectRatio) &lt;= 9 or not(h:extension/h:AirflowDefectRatio)'>Expected extension/AirflowDefectRatio to be less than or equal to 9</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:ChargeDefectRatio) = 1'>Expected 1 element(s) for xpath: extension/ChargeDefectRatio</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:ChargeDefectRatio) = 0 or number(h:extension/h:ChargeDefectRatio) = -0.25 or number(h:extension/h:ChargeDefectRatio) = 0.25 or not(h:extension/h:ChargeDefectRatio)'>Expected extension/ChargeDefectRatio to be 0, -0.25, or 0.25</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatPumpType=GroundSourceWithSharedLoop]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:HeatPump[h:HeatPumpType="ground-to-air" and h:IsSharedSystem="true"]'>
      <sch:assert role='ERROR' test='count(../../../../h:BuildingSummary/h:BuildingConstruction[h:ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]]) = 1'>Expected 1 element(s) for xpath: ../../../../BuildingSummary/BuildingConstruction[ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]]</sch:assert>
      <sch:assert role='ERROR' test='count(h:NumberofUnitsServed) = 1'>Expected 1 element(s) for xpath: NumberofUnitsServed</sch:assert>
      <sch:assert role='ERROR' test='number(h:NumberofUnitsServed) &gt; 1 or not(h:NumberofUnitsServed)'>Expected NumberofUnitsServed to be greater than 1</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:SharedLoopWatts) = 1'>Expected 1 element(s) for xpath: extension/SharedLoopWatts</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:SharedLoopWatts) &gt;= 0 or not(h:extension/h:SharedLoopWatts)'>Expected extension/SharedLoopWatts to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:SharedLoopMotorEfficiency) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/SharedLoopMotorEfficiency</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:SharedLoopMotorEfficiency) &gt; 0 or not(h:extension/h:SharedLoopMotorEfficiency)'>Expected extension/SharedLoopMotorEfficiency to be greater than 0</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:SharedLoopMotorEfficiency) &lt; 1 or not(h:extension/h:SharedLoopMotorEfficiency)'>Expected extension/SharedLoopMotorEfficiency to be less than 1</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatPumpType=WaterLoop]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:HeatPump[h:HeatPumpType="water-loop-to-air"]'>
      <sch:assert role='ERROR' test='count(../../h:HVACDistribution/h:DistributionSystemType/h:AirDistribution/h:AirDistributionType[text()="regular velocity"]) + count(../../h:HVACDistribution/h:DistributionSystemType/h:Other[text()="DSE"]) &gt;= 1'>Expected 1 or more element(s) for xpath: ../../HVACDistribution/DistributionSystemType/AirDistribution/AirDistributionType[text()="regular velocity"] | ../../HVACDistribution/DistributionSystemType/Other[text()="DSE"]</sch:assert> <!-- See [HVACDistribution] -->
      <sch:assert role='ERROR' test='count(../h:HeatingSystem[h:HeatingSystemType/h:Boiler and h:IsSharedSystem="true"]) + count(../h:CoolingSystem[(h:CoolingSystemType="chiller" or h:CoolingSystemType="cooling tower") and h:IsSharedSystem="true"]) &gt;= 1'>Expected 1 or more element(s) for xpath: ../HeatingSystem[HeatingSystemType/Boiler and IsSharedSystem="true"] | ../CoolingSystem[(CoolingSystemType="chiller" or CoolingSystemType="cooling tower") and IsSharedSystem="true"]</sch:assert>
      <sch:assert role='ERROR' test='count(../../h:HVACDistribution/h:DistributionSystemType/h:HydronicDistribution/h:HydronicDistributionType[text()="water loop"]) &gt;= 1'>Expected 1 or more element(s) for xpath: ../../HVACDistribution/DistributionSystemType/HydronicDistribution[HydronicDistributionType="water loop"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:HeatPumpFuel) = 1'>Expected 1 element(s) for xpath: HeatPumpFuel</sch:assert>
      <sch:assert role='ERROR' test='h:HeatPumpFuel[text()="electricity"] or not(h:HeatPumpFuel)'>Expected HeatPumpFuel to be 'electricity'</sch:assert>
      <sch:assert role='ERROR' test='count(h:BackupType) &lt;= 1'>Expected 0 or 1 element(s) for xpath: BackupType</sch:assert> <!-- See [HeatPumpBackup=Integrated] -->
      <sch:assert role='ERROR' test='h:BackupType[text()="integrated"] or not(h:BackupType)'>Expected BackupType to be 'integrated'</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatPumpType=PTHPorRoomACwithReverseCycle]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:HeatPump[h:HeatPumpType="packaged terminal heat pump" or h:HeatPumpType="room air conditioner with reverse cycle"]'>
      <sch:assert role='ERROR' test='count(h:DistributionSystem) = 0'>Expected 0 element(s) for xpath: DistributionSystem</sch:assert>
      <sch:assert role='ERROR' test='count(h:HeatPumpFuel) = 1'>Expected 1 element(s) for xpath: HeatPumpFuel</sch:assert>
      <sch:assert role='ERROR' test='h:HeatPumpFuel[text()="electricity"] or not(h:HeatPumpFuel)'>Expected HeatPumpFuel to be 'electricity'</sch:assert>
      <sch:assert role='ERROR' test='count(h:HeatingCapacity) = 1'>Expected 1 element(s) for xpath: HeatingCapacity</sch:assert>
      <sch:assert role='ERROR' test='count(h:HeatingCapacity17F) &lt;= 1'>Expected 0 or 1 element(s) for xpath: HeatingCapacity17F</sch:assert>
      <sch:assert role='ERROR' test='number(h:HeatingCapacity17F) &lt;= number(h:HeatingCapacity) or not(h:HeatingCapacity17F) or not(h:HeatingCapacity)'>Expected HeatingCapacity17F to be less than or equal to HeatingCapacity</sch:assert>
      <sch:assert role='ERROR' test='count(h:CoolingCapacity) = 1'>Expected 1 element(s) for xpath: CoolingCapacity</sch:assert>
      <sch:assert role='ERROR' test='count(h:CompressorLockoutTemperature) &lt;= 1'>Expected 0 or 1 element(s) for xpath: CompressorLockoutTemperature</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualCoolingEfficiency[h:Units="EER" or h:Units="CEER"]/h:Value) = 1'>Expected 1 element(s) for xpath: AnnualCoolingEfficiency[Units="EER" or Units="CEER"]/Value</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualHeatingEfficiency[h:Units="COP"]/h:Value) = 1'>Expected 1 element(s) for xpath: AnnualHeatingEfficiency[Units="COP"]/Value</sch:assert>
      <sch:assert role='ERROR' test='count(h:CoolingSensibleHeatFraction) = 0'>Expected 0 element(s) for xpath: CoolingSensibleHeatFraction</sch:assert>
      <sch:assert role='ERROR' test='count(h:BackupType) &lt;= 1'>Expected 0 or 1 element(s) for xpath: BackupType</sch:assert> <!-- See [HeatPumpBackup=Integrated] -->
      <sch:assert role='ERROR' test='h:BackupType[text()="integrated"] or not(h:BackupType)'>Expected BackupType to be 'integrated'</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionHeatLoadServed) = 1'>Expected 1 element(s) for xpath: FractionHeatLoadServed</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionCoolLoadServed) = 1'>Expected 1 element(s) for xpath: FractionCoolLoadServed</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatPumpBackup=Integrated]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:HeatPump[h:BackupType="integrated" or h:BackupSystemFuel]'>
      <sch:assert role='ERROR' test='count(h:BackupType[text()="integrated"]) = 1'>Expected 1 element(s) for xpath: BackupType[text()="integrated"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:BackupSystemFuel) = 1'>Expected 1 element(s) for xpath: BackupSystemFuel</sch:assert>
      <sch:assert role='ERROR' test='h:BackupSystemFuel[text()="electricity" or text()="natural gas" or text()="fuel oil" or text()="propane" or text()="wood" or text()="wood pellets"] or not(h:BackupSystemFuel)'>Expected BackupSystemFuel to be 'electricity' or 'natural gas' or 'fuel oil' or 'propane' or 'wood' or 'wood pellets'</sch:assert>
      <sch:assert role='ERROR' test='count(h:BackupAnnualHeatingEfficiency[h:Units="Percent" or h:Units="AFUE"]/h:Value) = 1'>Expected 1 element(s) for xpath: BackupAnnualHeatingEfficiency[Units="Percent" or Units="AFUE"]/Value</sch:assert>
      <sch:assert role='ERROR' test='number(h:BackupAnnualHeatingEfficiency[h:Units="Percent" or h:Units="AFUE"]/h:Value) &lt;= 1 or not(h:BackupAnnualHeatingEfficiency[h:Units="Percent" or h:Units="AFUE"]/h:Value)'>Expected BackupAnnualHeatingEfficiency[Units="Percent" or Units="AFUE"]/Value to be less than or equal to 1</sch:assert>
      <sch:assert role='ERROR' test='count(h:BackupHeatingCapacity) = 1'>Expected 1 element(s) for xpath: BackupHeatingCapacity</sch:assert>
      <sch:assert role='ERROR' test='count(h:BackupHeatingSwitchoverTemperature) = 0'>Expected 0 element(s) for xpath: BackupHeatingSwitchoverTemperature</sch:assert>
      <sch:assert role='ERROR' test='count(h:BackupHeatingLockoutTemperature) = 0'>Expected 0 element(s) for xpath: BackupHeatingLockoutTemperature</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatPumpBackup=FossilFuel]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:HeatPump[not(h:BackupSystemFuel) or h:BackupSystemFuel[text()="natural gas" or text()="fuel oil" or text()="propane" or text()="wood" or text()="wood pellets"]]'>
      <sch:assert role='ERROR' test='count(h:CompressorLockoutTemperature) = 0'>Expected 0 element(s) for xpath: CompressorLockoutTemperature</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[AirflowDefectRatio]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/*[not(h:DistributionSystem)]'>
      <sch:assert role='ERROR' test='number(h:extension/h:AirflowDefectRatio) = 0 or not(h:extension/h:AirflowDefectRatio)'>Expected extension/AirflowDefectRatio to be 0</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HVACControl]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACControl'>
      <sch:assert role='ERROR' test='count(h:ControlType[text()="manual thermostat" or text()="programmable thermostat"]) = 1'>Expected 1 element(s) for xpath: ControlType[text()="manual thermostat" or text()="programmable thermostat"]</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HVACDistribution]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACDistribution'>
      <sch:assert role='ERROR' test='count(h:DistributionSystemType[h:AirDistribution | h:HydronicDistribution | h:Other[text()="DSE"]]) = 1'>Expected 1 element(s) for xpath: DistributionSystemType[AirDistribution | HydronicDistribution | Other[text()="DSE"]]</sch:assert> <!-- See [HVACDistributionType=Air] or [HVACDistributionType=Hydronic] or [HVACDistributionType=DSE] -->
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HVACDistributionType=Air]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACDistribution/h:DistributionSystemType/h:AirDistribution'>
      <sch:assert role='ERROR' test='count(h:AirDistributionType) = 1'>Expected 1 element(s) for xpath: AirDistributionType</sch:assert>
      <sch:assert role='ERROR' test='h:AirDistributionType[text()="regular velocity" or text()="gravity" or text()="fan coil"] or not(h:AirDistributionType)'>Expected AirDistributionType to be 'regular velocity' or 'gravity' or 'fan coil'</sch:assert> <!-- See [AirDistributionType=RegularVelocityOrGravity] or [AirDistributionType=FanCoil] -->
      <sch:assert role='ERROR' test='count(h:Ducts) &gt;= 0'>Expected 0 or more element(s) for xpath: Ducts</sch:assert> <!-- See [HVACDuct] -->
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[AirDistributionType=RegularVelocityOrGravity]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACDistribution/h:DistributionSystemType/h:AirDistribution[h:AirDistributionType[text()="regular velocity" or text()="gravity"]]'>
      <sch:assert role='ERROR' test='count(h:DuctLeakageMeasurement[h:DuctType="supply"]/h:DuctLeakage[(h:Units="CFM25" or h:Units="CFM50") and h:TotalOrToOutside="to outside"]) = 1'>Expected 1 element(s) for xpath: DuctLeakageMeasurement[DuctType="supply"]/DuctLeakage[(Units="CFM25" or Units="CFM50") and TotalOrToOutside="to outside"]</sch:assert> <!-- See [DuctLeakage=CFM] -->
      <sch:assert role='ERROR' test='count(h:DuctLeakageMeasurement[h:DuctType="return"]/h:DuctLeakage[(h:Units="CFM25" or h:Units="CFM50") and h:TotalOrToOutside="to outside"]) = 1'>Expected 1 element(s) for xpath: DuctLeakageMeasurement[DuctType="return"]/DuctLeakage[(Units="CFM25" or Units="CFM50") and TotalOrToOutside="to outside"]</sch:assert> <!-- See [DuctLeakage=CFM] -->
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[AirDistributionType=FanCoil]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACDistribution/h:DistributionSystemType/h:AirDistribution[h:AirDistributionType[text()="fan coil"]]'>
      <sch:assert role='ERROR' test='count(h:DuctLeakageMeasurement[h:DuctType="supply"]/h:DuctLeakage[(h:Units="CFM25" or h:Units="CFM50") and h:TotalOrToOutside="to outside"]) &lt;= 1'>Expected 0 or 1 element(s) for xpath: DuctLeakageMeasurement[DuctType="supply"]/DuctLeakage[(Units="CFM25" or Units="CFM50") and TotalOrToOutside="to outside"]</sch:assert> <!-- See [DuctLeakage=CFM] -->
      <sch:assert role='ERROR' test='count(h:DuctLeakageMeasurement[h:DuctType="return"]/h:DuctLeakage[(h:Units="CFM25" or h:Units="CFM50") and h:TotalOrToOutside="to outside"]) &lt;= 1'>Expected 0 or 1 element(s) for xpath: DuctLeakageMeasurement[DuctType="return"]/DuctLeakage[(Units="CFM25" or Units="CFM50") and TotalOrToOutside="to outside"]</sch:assert> <!-- See [DuctLeakage=CFM] -->
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[DuctLeakage=CFM]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACDistribution/h:DistributionSystemType/h:AirDistribution/h:DuctLeakageMeasurement/h:DuctLeakage[h:Units="CFM25" or h:Units="CFM50"]'>
      <sch:assert role='ERROR' test='count(h:Value) = 1'>Expected 1 element(s) for xpath: Value</sch:assert>
      <sch:assert role='ERROR' test='number(h:Value) &gt;= 0 or not(h:Value)'>Expected Value to be greater than or equal to 0</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HVACDistributionType=Hydronic]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACDistribution/h:DistributionSystemType/h:HydronicDistribution'>
      <sch:assert role='ERROR' test='count(h:HydronicDistributionType) = 1'>Expected 1 element(s) for xpath: HydronicDistributionType</sch:assert>
      <sch:assert role='ERROR' test='h:HydronicDistributionType[text()="radiator" or text()="baseboard" or text()="radiant floor" or text()="radiant ceiling" or text()="water loop"] or not(h:HydronicDistributionType)'>Expected HydronicDistributionType to be 'radiator' or 'baseboard' or 'radiant floor' or 'radiant ceiling' or 'water loop'</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HVACDistributionType=DSE]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACDistribution[h:DistributionSystemType[h:Other[text()="DSE"]]]'>
      <sch:assert role='ERROR' test='count(h:AnnualHeatingDistributionSystemEfficiency) = 1'>Expected 1 element(s) for xpath: AnnualHeatingDistributionSystemEfficiency</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualCoolingDistributionSystemEfficiency) = 1'>Expected 1 element(s) for xpath: AnnualCoolingDistributionSystemEfficiency</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HVACDuct]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACDistribution/h:DistributionSystemType/h:AirDistribution/h:Ducts'>
      <sch:assert role='ERROR' test='count(h:DuctType) = 1'>Expected 1 element(s) for xpath: DuctType</sch:assert>
      <sch:assert role='ERROR' test='h:DuctType[text()="supply" or text()="return"] or not(h:DuctType)'>Expected DuctType to be 'supply' or 'return'</sch:assert>
      <sch:assert role='ERROR' test='count(h:DuctInsulationRValue) = 1'>Expected 1 element(s) for xpath: DuctInsulationRValue</sch:assert>
      <sch:assert role='ERROR' test='count(h:DuctBuriedInsulationLevel) &lt;= 1'>Expected 0 or 1 element(s) for xpath: DuctBuriedInsulationLevel</sch:assert>
      <sch:assert role='ERROR' test='h:DuctBuriedInsulationLevel[text()="not buried" or text()="partially buried" or text()="fully buried" or text()="deeply buried"] or not(h:DuctBuriedInsulationLevel)'>Expected DuctBuriedInsulationLevel to be 'not buried' or 'partially buried' or 'fully buried' or 'deeply buried'</sch:assert>
      <sch:assert role='ERROR' test='count(h:DuctLocation) = 1'>Expected 1 element(s) for xpath: DuctLocation</sch:assert> <!-- See [HVACDuct=WithLocation] or [HVACDuct=WithoutLocation] -->
      <sch:assert role='ERROR' test='h:DuctLocation[text()="conditioned space" or text()="basement - conditioned" or text()="basement - unconditioned" or text()="crawlspace - vented" or text()="crawlspace - unvented" or text()="attic - vented" or text()="attic - unvented" or text()="garage" or text()="exterior wall" or text()="under slab" or text()="roof deck" or text()="outside" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"] or not(h:DuctLocation)'>Expected DuctLocation to be 'conditioned space' or 'basement - conditioned' or 'basement - unconditioned' or 'crawlspace - vented' or 'crawlspace - unvented' or 'attic - vented' or 'attic - unvented' or 'garage' or 'exterior wall' or 'under slab' or 'roof deck' or 'outside' or 'other housing unit' or 'other heated space' or 'other multifamily buffer space' or 'other non-freezing space'</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionDuctArea) + count(h:DuctSurfaceArea) &gt;= 1'>Expected 1 or more element(s) for xpath: FractionDuctArea | DuctSurfaceArea</sch:assert>
      <sch:assert role='ERROR' test='count(../h:NumberofReturnRegisters) = 1'>Expected 1 element(s) for xpath: ../NumberofReturnRegisters</sch:assert>
      <sch:assert role='ERROR' test='count(../../../h:ConditionedFloorAreaServed) = 1'>Expected 1 element(s) for xpath: ../../../ConditionedFloorAreaServed</sch:assert>
      <!-- Sum Checks -->
      <sch:assert role='ERROR' test='(sum(h:Ducts[h:DuctType="supply"]/h:FractionDuctArea) &gt;= 0.99 and sum(h:Ducts[h:DuctType="supply"]/h:FractionDuctArea) &lt;= 1.01) or count(h:Ducts[h:DuctType="supply"]/h:FractionDuctArea) = 0'>Expected sum(Ducts/FractionDuctArea) for DuctType="supply" to be 1</sch:assert>
      <sch:assert role='ERROR' test='(sum(h:Ducts[h:DuctType="return"]/h:FractionDuctArea) &gt;= 0.99 and sum(h:Ducts[h:DuctType="return"]/h:FractionDuctArea) &lt;= 1.01) or count(h:Ducts[h:DuctType="return"]/h:FractionDuctArea) = 0'>Expected sum(Ducts/FractionDuctArea) for DuctType="return" to be 1</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[VentilationFan]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:MechanicalVentilation/h:VentilationFans/h:VentilationFan'>
      <sch:assert role='ERROR' test='count(h:UsedForWholeBuildingVentilation[text()="true"]) + count(h:UsedForLocalVentilation[text()="true"]) + count(h:UsedForSeasonalCoolingLoadReduction[text()="true"]) + count(h:UsedForGarageVentilation[text()="true"]) = 1'>Expected 1 element(s) for xpath: UsedForWholeBuildingVentilation[text()="true"] | UsedForLocalVentilation[text()="true"] | UsedForSeasonalCoolingLoadReduction[text()="true"] | UsedForGarageVentilation[text()="true"]</sch:assert> <!-- See [MechanicalVentilation] or [WholeHouseFan] -->
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[MechanicalVentilation]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:MechanicalVentilation/h:VentilationFans/h:VentilationFan[h:UsedForWholeBuildingVentilation="true"]'>
      <sch:assert role='ERROR' test='count(h:FanType) = 1'>Expected 1 element(s) for xpath: FanType</sch:assert> <!-- See [MechanicalVentilationType=ExhaustOnly] or [MechanicalVentilationType=SupplyOnly] or [MechanicalVentilationType=Balanced] or [MechanicalVentilationType=HRV] or [MechanicalVentilationType=ERV] or [MechanicalVentilationType=CFIS] -->
      <sch:assert role='ERROR' test='h:FanType[text()="energy recovery ventilator" or text()="heat recovery ventilator" or text()="exhaust only" or text()="supply only" or text()="balanced" or text()="central fan integrated supply"] or not(h:FanType)'>Expected FanType to be 'energy recovery ventilator' or 'heat recovery ventilator' or 'exhaust only' or 'supply only' or 'balanced' or 'central fan integrated supply'</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[MechanicalVentilationType=ExhaustOnly]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:MechanicalVentilation/h:VentilationFans/h:VentilationFan[h:UsedForWholeBuildingVentilation="true" and h:FanType="exhaust only"]'>
      <sch:assert role='ERROR' test='count(h:IsSharedSystem) = 1'>Expected 1 element(s) for xpath: IsSharedSystem</sch:assert> <!-- See [MechanicalVentilationType=InUnit] or [MechanicalVentilationType=Shared] -->
      <sch:assert role='ERROR' test='count(h:CFISControls) = 0'>Expected 0 element(s) for xpath: CFISControls</sch:assert>
      <sch:assert role='ERROR' test='count(h:HoursInOperation) + count(../h:VentilationFan[h:UsedForWholeBuildingVentilation="true" and h:FanType="central fan integrated supply"]/h:CFISControls[h:AdditionalRuntimeOperatingMode="supplemental fan"]) &gt;= 1'>Expected 1 or more element(s) for xpath: HoursInOperation || ../VentilationFan[UsedForWholeBuildingVentilation="true" and FanType="central fan integrated supply"]/CFISControls[AdditionalRuntimeOperatingMode="supplemental fan"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:FanPower) + count(h:extension/h:FanPowerDefaulted[text()="true"]) = 1'>Expected 1 element(s) for xpath: FanPower | extension/FanPowerDefaulted[text()="true"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:TotalRecoveryEfficiency) + count(h:AdjustedTotalRecoveryEfficiency) = 0'>Expected 0 element(s) for xpath: TotalRecoveryEfficiency | AdjustedTotalRecoveryEfficiency</sch:assert>
      <sch:assert role='ERROR' test='count(h:SensibleRecoveryEfficiency) + count(h:AdjustedSensibleRecoveryEfficiency) = 0'>Expected 0 element(s) for xpath: SensibleRecoveryEfficiency | AdjustedSensibleRecoveryEfficiency</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[MechanicalVentilationType=SupplyOnly]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:MechanicalVentilation/h:VentilationFans/h:VentilationFan[h:UsedForWholeBuildingVentilation="true" and h:FanType="supply only"]'>
      <sch:assert role='ERROR' test='count(h:IsSharedSystem) = 1'>Expected 1 element(s) for xpath: IsSharedSystem</sch:assert> <!-- See [MechanicalVentilationType=InUnit] or [MechanicalVentilationType=Shared] -->
      <sch:assert role='ERROR' test='count(h:CFISControls) = 0'>Expected 0 element(s) for xpath: CFISControls</sch:assert>
      <sch:assert role='ERROR' test='count(h:HoursInOperation) + count(../h:VentilationFan[h:UsedForWholeBuildingVentilation="true" and h:FanType="central fan integrated supply"]/h:CFISControls[h:AdditionalRuntimeOperatingMode="supplemental fan"]) &gt;= 1'>Expected 1 or more element(s) for xpath: HoursInOperation || ../VentilationFan[UsedForWholeBuildingVentilation="true" and FanType="central fan integrated supply"]/CFISControls[AdditionalRuntimeOperatingMode="supplemental fan"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:FanPower) + count(h:extension/h:FanPowerDefaulted[text()="true"]) = 1'>Expected 1 element(s) for xpath: FanPower | extension/FanPowerDefaulted[text()="true"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:TotalRecoveryEfficiency) + count(h:AdjustedTotalRecoveryEfficiency) = 0'>Expected 0 element(s) for xpath: TotalRecoveryEfficiency | AdjustedTotalRecoveryEfficiency</sch:assert>
      <sch:assert role='ERROR' test='count(h:SensibleRecoveryEfficiency) + count(h:AdjustedSensibleRecoveryEfficiency) = 0'>Expected 0 element(s) for xpath: SensibleRecoveryEfficiency | AdjustedSensibleRecoveryEfficiency</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[MechanicalVentilationType=Balanced]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:MechanicalVentilation/h:VentilationFans/h:VentilationFan[h:UsedForWholeBuildingVentilation="true" and h:FanType="balanced"]'>
      <sch:assert role='ERROR' test='count(h:IsSharedSystem) = 1'>Expected 1 element(s) for xpath: IsSharedSystem</sch:assert> <!-- See [MechanicalVentilationType=InUnit] or [MechanicalVentilationType=Shared] -->
      <sch:assert role='ERROR' test='count(h:CFISControls) = 0'>Expected 0 element(s) for xpath: CFISControls</sch:assert>
      <sch:assert role='ERROR' test='count(h:HoursInOperation) + count(../h:VentilationFan[h:UsedForWholeBuildingVentilation="true" and h:FanType="central fan integrated supply"]/h:CFISControls[h:AdditionalRuntimeOperatingMode="supplemental fan"]) &gt;= 1'>Expected 1 or more element(s) for xpath: HoursInOperation || ../VentilationFan[UsedForWholeBuildingVentilation="true" and FanType="central fan integrated supply"]/CFISControls[AdditionalRuntimeOperatingMode="supplemental fan"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:FanPower) + count(h:extension/h:FanPowerDefaulted[text()="true"]) = 1'>Expected 1 element(s) for xpath: FanPower | extension/FanPowerDefaulted[text()="true"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:TotalRecoveryEfficiency) + count(h:AdjustedTotalRecoveryEfficiency) = 0'>Expected 0 element(s) for xpath: TotalRecoveryEfficiency | AdjustedTotalRecoveryEfficiency</sch:assert>
      <sch:assert role='ERROR' test='count(h:SensibleRecoveryEfficiency) + count(h:AdjustedSensibleRecoveryEfficiency) = 0'>Expected 0 element(s) for xpath: SensibleRecoveryEfficiency | AdjustedSensibleRecoveryEfficiency</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[MechanicalVentilationType=HRV]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:MechanicalVentilation/h:VentilationFans/h:VentilationFan[h:UsedForWholeBuildingVentilation="true" and h:FanType="heat recovery ventilator"]'>
      <sch:assert role='ERROR' test='count(h:IsSharedSystem) = 1'>Expected 1 element(s) for xpath: IsSharedSystem</sch:assert> <!-- See [MechanicalVentilationType=InUnit] or [MechanicalVentilationType=Shared] -->
      <sch:assert role='ERROR' test='count(h:CFISControls) = 0'>Expected 0 element(s) for xpath: CFISControls</sch:assert>
      <sch:assert role='ERROR' test='count(h:HoursInOperation) + count(../h:VentilationFan[h:UsedForWholeBuildingVentilation="true" and h:FanType="central fan integrated supply"]/h:CFISControls[h:AdditionalRuntimeOperatingMode="supplemental fan"]) &gt;= 1'>Expected 1 or more element(s) for xpath: HoursInOperation || ../VentilationFan[UsedForWholeBuildingVentilation="true" and FanType="central fan integrated supply"]/CFISControls[AdditionalRuntimeOperatingMode="supplemental fan"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:FanPower) + count(h:extension/h:FanPowerDefaulted[text()="true"]) = 1'>Expected 1 element(s) for xpath: FanPower | extension/FanPowerDefaulted[text()="true"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:TotalRecoveryEfficiency) + count(h:AdjustedTotalRecoveryEfficiency) = 0'>Expected 0 element(s) for xpath: TotalRecoveryEfficiency | AdjustedTotalRecoveryEfficiency</sch:assert>
      <sch:assert role='ERROR' test='count(h:SensibleRecoveryEfficiency) + count(h:AdjustedSensibleRecoveryEfficiency) = 1'>Expected 1 element(s) for xpath: SensibleRecoveryEfficiency | AdjustedSensibleRecoveryEfficiency</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[MechanicalVentilationType=ERV]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:MechanicalVentilation/h:VentilationFans/h:VentilationFan[h:UsedForWholeBuildingVentilation="true" and h:FanType="energy recovery ventilator"]'>
      <sch:assert role='ERROR' test='count(h:IsSharedSystem) = 1'>Expected 1 element(s) for xpath: IsSharedSystem</sch:assert> <!-- See [MechanicalVentilationType=InUnit] or [MechanicalVentilationType=Shared] -->
      <sch:assert role='ERROR' test='count(h:CFISControls) = 0'>Expected 0 element(s) for xpath: CFISControls</sch:assert>
      <sch:assert role='ERROR' test='count(h:HoursInOperation) + count(../h:VentilationFan[h:UsedForWholeBuildingVentilation="true" and h:FanType="central fan integrated supply"]/h:CFISControls[h:AdditionalRuntimeOperatingMode="supplemental fan"]) &gt;= 1'>Expected 1 or more element(s) for xpath: HoursInOperation || ../VentilationFan[UsedForWholeBuildingVentilation="true" and FanType="central fan integrated supply"]/CFISControls[AdditionalRuntimeOperatingMode="supplemental fan"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:FanPower) + count(h:extension/h:FanPowerDefaulted[text()="true"]) = 1'>Expected 1 element(s) for xpath: FanPower | extension/FanPowerDefaulted[text()="true"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:TotalRecoveryEfficiency) + count(h:AdjustedTotalRecoveryEfficiency) = 1'>Expected 1 element(s) for xpath: TotalRecoveryEfficiency | AdjustedTotalRecoveryEfficiency</sch:assert>
      <sch:assert role='ERROR' test='count(h:SensibleRecoveryEfficiency) + count(h:AdjustedSensibleRecoveryEfficiency) = 1'>Expected 1 element(s) for xpath: SensibleRecoveryEfficiency | AdjustedSensibleRecoveryEfficiency</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[MechanicalVentilationType=CFIS]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:MechanicalVentilation/h:VentilationFans/h:VentilationFan[h:UsedForWholeBuildingVentilation="true" and h:FanType="central fan integrated supply"]'>
      <sch:assert role='ERROR' test='count(h:IsSharedSystem[text()="true"]) = 0'>Expected 0 element(s) for xpath: IsSharedSystem[text()="true"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:HoursInOperation) + count(../h:VentilationFan[h:UsedForWholeBuildingVentilation="true" and h:FanType="central fan integrated supply"]/h:CFISControls[h:AdditionalRuntimeOperatingMode="supplemental fan"]) &gt;= 1'>Expected 1 or more element(s) for xpath: HoursInOperation || ../VentilationFan[UsedForWholeBuildingVentilation="true" and FanType="central fan integrated supply"]/CFISControls[AdditionalRuntimeOperatingMode="supplemental fan"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:FanPower) = 0'>Expected 0 element(s) for xpath: FanPower</sch:assert>
      <sch:assert role='ERROR' test='count(h:TotalRecoveryEfficiency) + count(h:AdjustedTotalRecoveryEfficiency) = 0'>Expected 0 element(s) for xpath: TotalRecoveryEfficiency | AdjustedTotalRecoveryEfficiency</sch:assert>
      <sch:assert role='ERROR' test='count(h:SensibleRecoveryEfficiency) + count(h:AdjustedSensibleRecoveryEfficiency) = 0'>Expected 0 element(s) for xpath: SensibleRecoveryEfficiency | AdjustedSensibleRecoveryEfficiency</sch:assert>
      <sch:assert role='ERROR' test='count(h:CFISControls/h:HasOutdoorAirControl) = 1'>Expected 1 element(s) for xpath: CFISControls/HasOutdoorAirControl</sch:assert>
      <sch:assert role='ERROR' test='count(h:CFISControls/h:AdditionalRuntimeOperatingMode) = 1'>Expected 1 element(s) for xpath: CFISControls/AdditionalRuntimeOperatingMode</sch:assert>
      <sch:assert role='ERROR' test='h:CFISControls/h:AdditionalRuntimeOperatingMode[text()="air handler fan" or text()="supplemental fan" or text()="none"] or not(h:CFISControls/h:AdditionalRuntimeOperatingMode)'>Expected CFISControls/AdditionalRuntimeOperatingMode to be 'air handler fan' or 'supplemental fan' or 'none'</sch:assert> <!-- See [CFISAdditionalRuntimeMode=AirHandlerFan] or [CFISAdditionalRuntimeMode=SupplementalFan] or [CFISAdditionalRuntimeMode=None] -->
      <sch:assert role='ERROR' test='count(h:CFISControls/h:extension/h:ControlType) = 1'>Expected 1 element(s) for xpath: CFISControls/extension/ControlType</sch:assert>
      <sch:assert role='ERROR' test='h:CFISControls/h:extension/h:ControlType[text()="optimized" or text()="timer"] or not(h:CFISControls/h:extension/h:ControlType)'>Expected CFISControls/extension/ControlType to be 'optimized' or 'timer'</sch:assert> <!-- See CFISControlType=Timer -->
      <sch:assert role='ERROR' test='count(h:AttachedToHVACDistributionSystem) = 1'>Expected 1 element(s) for xpath: AttachedToHVACDistributionSystem</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:FanPowerDefaulted) = 0'>Expected 0 element(s) for xpath: extension/FanPowerDefaulted</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:VentilationOnlyModeAirflowFraction) = 0'>Expected 0 element(s) for xpath: extension/VentilationOnlyModeAirflowFraction</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[CFISControlType=Timer]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:MechanicalVentilation/h:VentilationFans/h:VentilationFan[h:UsedForWholeBuildingVentilation="true" and h:FanType="central fan integrated supply" and h:CFISControls/h:extension/h:ControlType="timer"]'>
      <sch:assert role='ERROR' test='h:CFISControls/h:AdditionalRuntimeOperatingMode[text()="air handler fan"]'>Expected CFISControls/AdditionalRuntimeOperatingMode to be 'air handler fan'</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[CFISAdditionalRuntimeMode=AirHandlerFan]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:MechanicalVentilation/h:VentilationFans/h:VentilationFan[h:UsedForWholeBuildingVentilation="true" and h:FanType="central fan integrated supply" and h:CFISControls/h:AdditionalRuntimeOperatingMode="air handler fan"]'>
      <sch:assert role='ERROR' test='count(h:CFISControls/h:SupplementalFan) = 0'>Expected 0 element(s) for xpath: CFISControls/SupplementalFan</sch:assert>
      <sch:assert role='ERROR' test='count(h:CFISControls/h:extension/h:SupplementalFanRunsWithAirHandlerFan) = 0'>Expected 0 element(s) for xpath: CFISControls/extension/SupplementalFanRunsWithAirHandlerFan</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[CFISAdditionalRuntimeMode=SupplementalFan]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:MechanicalVentilation/h:VentilationFans/h:VentilationFan[h:UsedForWholeBuildingVentilation="true" and h:FanType="central fan integrated supply" and h:CFISControls/h:AdditionalRuntimeOperatingMode="supplemental fan"]'>
      <sch:assert role='ERROR' test='count(h:CFISControls/h:SupplementalFan) = 1'>Expected 1 element(s) for xpath: CFISControls/SupplementalFan</sch:assert>
      <sch:assert role='ERROR' test='count(h:CFISControls/h:extension/h:SupplementalFanRunsWithAirHandlerFan) &lt;= 1'>Expected 0 or 1 element(s) for xpath: CFISControls/extension/SupplementalFanRunsWithAirHandlerFan</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[CFISAdditionalRuntimeMode=None]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:MechanicalVentilation/h:VentilationFans/h:VentilationFan[h:UsedForWholeBuildingVentilation="true" and h:FanType="central fan integrated supply" and h:CFISControls/h:AdditionalRuntimeOperatingMode="none"]'>
      <sch:assert role='ERROR' test='count(h:CFISControls/h:SupplementalFan) = 0'>Expected 0 element(s) for xpath: CFISControls/SupplementalFan</sch:assert>
      <sch:assert role='ERROR' test='count(h:CFISControls/h:extension/h:SupplementalFanRunsWithAirHandlerFan) = 0'>Expected 0 element(s) for xpath: CFISControls/extension/SupplementalFanRunsWithAirHandlerFan</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[MechanicalVentilationType=InUnit]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:MechanicalVentilation/h:VentilationFans/h:VentilationFan[h:UsedForWholeBuildingVentilation="true" and h:IsSharedSystem="false"]'>
      <sch:assert role='ERROR' test='count(h:TestedFlowRate) + count(h:extension/h:FlowRateNotTested[text()="true"]) = 1'>Expected 1 element(s) for xpath: TestedFlowRate | extension/FlowRateNotTested[text()="true"]</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[MechanicalVentilationType=Shared]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:MechanicalVentilation/h:VentilationFans/h:VentilationFan[h:UsedForWholeBuildingVentilation="true" and h:IsSharedSystem="true"]'>
      <sch:assert role='ERROR' test='count(h:RatedFlowRate) = 1'>Expected 1 element(s) for xpath: RatedFlowRate</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionRecirculation) = 1'>Expected 1 element(s) for xpath: FractionRecirculation</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:InUnitFlowRate) + count(h:extension/h:FlowRateNotTested[text()="true"]) = 1'>Expected 1 element(s) for xpath: extension/InUnitFlowRate | extension/FlowRateNotTested[text()="true"]</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:InUnitFlowRate) &lt; number(h:TestedFlowRate) or not(h:extension/h:InUnitFlowRate) or not(h:TestedFlowRate)'>Expected extension/InUnitFlowRate to be less than TestedFlowRate</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:InUnitFlowRate) &lt; number(h:RatedFlowRate) or not(h:extension/h:InUnitFlowRate) or not(h:RatedFlowRate)'>Expected extension/InUnitFlowRate to be less than RatedFlowRate</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:PreHeating) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/PreHeating</sch:assert> <!-- See [MechanicalVentilationType=SharedWithPreHeating] -->
      <sch:assert role='ERROR' test='count(h:extension/h:PreCooling) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/PreCooling</sch:assert> <!-- See [MechanicalVentilationType=SharedWithPreCooling] -->
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[MechanicalVentilationType=SharedWithPreHeating]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:MechanicalVentilation/h:VentilationFans/h:VentilationFan[h:UsedForWholeBuildingVentilation="true" and h:IsSharedSystem="true"]/h:extension/h:PreHeating'>
      <sch:assert role='ERROR' test='count(../../h:FanType[text()="exhaust only"]) = 0'>Expected 0 element(s) for xpath: ../../FanType[text()="exhaust only"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:Fuel) = 1'>Expected 1 element(s) for xpath: Fuel</sch:assert>
      <sch:assert role='ERROR' test='h:Fuel[text()="natural gas" or text()="fuel oil" or text()="propane" or text()="electricity" or text()="wood" or text()="wood pellets"] or not(h:Fuel)'>Expected Fuel to be 'natural gas' or 'fuel oil' or 'propane' or 'electricity' or 'wood' or 'wood pellets'</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualHeatingEfficiency[h:Units="COP"]/h:Value) = 1'>Expected 1 element(s) for xpath: AnnualHeatingEfficiency[Units="COP"]/Value</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionVentilationHeatLoadServed) = 1'>Expected 1 element(s) for xpath: FractionVentilationHeatLoadServed</sch:assert>
      <sch:assert role='ERROR' test='number(h:FractionVentilationHeatLoadServed) &gt;= 0 or not(h:FractionVentilationHeatLoadServed)'>Expected FractionVentilationHeatLoadServed to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='number(h:FractionVentilationHeatLoadServed) &lt;= 1 or not(h:FractionVentilationHeatLoadServed)'>Expected FractionVentilationHeatLoadServed to be less than or equal to 1</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[MechanicalVentilationType=SharedWithPreCooling]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:MechanicalVentilation/h:VentilationFans/h:VentilationFan[h:UsedForWholeBuildingVentilation="true" and h:IsSharedSystem="true"]/h:extension/h:PreCooling'>
      <sch:assert role='ERROR' test='count(../../h:FanType[text()="exhaust only"]) = 0'>Expected 0 element(s) for xpath: ../../FanType[text()="exhaust only"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:Fuel) = 1'>Expected 1 element(s) for xpath: Fuel</sch:assert>
      <sch:assert role='ERROR' test='h:Fuel[text()="electricity"] or not(h:Fuel)'>Expected Fuel to be 'electricity'</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualCoolingEfficiency[h:Units="COP"]/h:Value) = 1'>Expected 1 element(s) for xpath: AnnualCoolingEfficiency[Units="COP"]/Value</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionVentilationCoolLoadServed) = 1'>Expected 1 element(s) for xpath: FractionVentilationCoolLoadServed</sch:assert>
      <sch:assert role='ERROR' test='number(h:FractionVentilationCoolLoadServed) &gt;= 0 or not(h:FractionVentilationCoolLoadServed)'>Expected FractionVentilationCoolLoadServed to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='number(h:FractionVentilationCoolLoadServed) &lt;= 1 or not(h:FractionVentilationCoolLoadServed)'>Expected FractionVentilationCoolLoadServed to be less than or equal to 1</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[WholeHouseFan]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:MechanicalVentilation/h:VentilationFans/h:VentilationFan[h:UsedForSeasonalCoolingLoadReduction="true"]'>
      <sch:assert role='ERROR' test='count(h:RatedFlowRate) = 1'>Expected 1 element(s) for xpath: RatedFlowRate</sch:assert>
      <sch:assert role='ERROR' test='count(h:FanPower) = 1'>Expected 1 element(s) for xpath: FanPower</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[WaterHeatingSystem]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:WaterHeating/h:WaterHeatingSystem'>
      <sch:assert role='ERROR' test='count(../h:HotWaterDistribution) = 1'>Expected 1 element(s) for xpath: ../HotWaterDistribution</sch:assert> <!-- See [HotWaterDistribution] -->
      <sch:assert role='ERROR' test='count(../h:WaterFixture) &gt;= 1'>Expected 1 or more element(s) for xpath: ../WaterFixture</sch:assert> <!-- See [WaterFixture] -->
      <sch:assert role='ERROR' test='count(h:WaterHeaterType) = 1'>Expected 1 element(s) for xpath: WaterHeaterType</sch:assert> <!-- See [WaterHeatingSystemType=Tank] or [WaterHeatingSystemType=Tankless] or [WaterHeatingSystemType=HeatPump] or [WaterHeatingSystemType=CombiIndirect] or [WaterHeatingSystemType=CombiTanklessCoil] -->
      <sch:assert role='ERROR' test='h:WaterHeaterType[text()="storage water heater" or text()="instantaneous water heater" or text()="heat pump water heater" or text()="space-heating boiler with storage tank" or text()="space-heating boiler with tankless coil"] or not(h:WaterHeaterType)'>Expected WaterHeaterType to be 'storage water heater' or 'instantaneous water heater' or 'heat pump water heater' or 'space-heating boiler with storage tank' or 'space-heating boiler with tankless coil'</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[WaterHeatingSystemType=Tank]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:WaterHeating/h:WaterHeatingSystem[h:WaterHeaterType="storage water heater"]'>
      <sch:assert role='ERROR' test='count(h:FuelType) = 1'>Expected 1 element(s) for xpath: FuelType</sch:assert>
      <sch:assert role='ERROR' test='h:FuelType[text()="natural gas" or text()="fuel oil" or text()="propane" or text()="electricity" or text()="wood" or text()="wood pellets"] or not(h:FuelType)'>Expected FuelType to be 'natural gas' or 'fuel oil' or 'propane' or 'electricity' or 'wood' or 'wood pellets'</sch:assert>
      <sch:assert role='ERROR' test='count(h:Location) = 1'>Expected 1 element(s) for xpath: Location</sch:assert>
      <sch:assert role='ERROR' test='h:Location[text()="conditioned space" or text()="basement - unconditioned" or text()="basement - conditioned" or text()="attic - unvented" or text()="attic - vented" or text()="garage" or text()="crawlspace - unvented" or text()="crawlspace - vented" or text()="other exterior" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"] or not(h:Location)'>Expected Location to be 'conditioned space' or 'basement - unconditioned' or 'basement - conditioned' or 'attic - unvented' or 'attic - vented' or 'garage' or 'crawlspace - unvented' or 'crawlspace - vented' or 'other exterior' or 'other housing unit' or 'other heated space' or 'other multifamily buffer space' or 'other non-freezing space'</sch:assert>
      <sch:assert role='ERROR' test='count(h:IsSharedSystem) = 1'>Expected 1 element(s) for xpath: IsSharedSystem</sch:assert> <!-- See [WaterHeatingSystemType=Shared] -->
      <sch:assert role='ERROR' test='count(h:TankVolume) = 1'>Expected 1 element(s) for xpath: TankVolume</sch:assert>
      <sch:assert role='ERROR' test='count(h:HeatingCapacity) &lt;= 1'>Expected 0 or 1 element(s) for xpath: HeatingCapacity</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionDHWLoadServed) = 1'>Expected 1 element(s) for xpath: FractionDHWLoadServed</sch:assert>
      <sch:assert role='ERROR' test='count(h:UniformEnergyFactor) + count(h:EnergyFactor) = 1'>Expected 1 element(s) for xpath: UniformEnergyFactor | EnergyFactor</sch:assert>
      <sch:assert role='ERROR' test='count(h:FirstHourRating) + count(h:EnergyFactor) &gt;= 1'>Expected 1 or more element(s) for xpath: FirstHourRating | EnergyFactor</sch:assert>
      <sch:assert role='ERROR' test='number(h:UniformEnergyFactor) &lt; 1 or not(h:UniformEnergyFactor)'>Expected UniformEnergyFactor to be less than 1</sch:assert>
      <sch:assert role='ERROR' test='number(h:EnergyFactor) &lt; 1 or not(h:EnergyFactor)'>Expected EnergyFactor to be less than 1</sch:assert>
      <sch:assert role='ERROR' test='count(h:WaterHeaterInsulation/h:Jacket/h:JacketRValue) &lt;= 1'>Expected 0 or 1 element(s) for xpath: WaterHeaterInsulation/Jacket/JacketRValue</sch:assert>
      <sch:assert role='ERROR' test='count(h:UsesDesuperheater) &lt;= 1'>Expected 0 or 1 element(s) for xpath: UsesDesuperheater</sch:assert> <!-- See [Desuperheater] -->
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[WaterHeatingSystemType=FuelTank]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:WaterHeating/h:WaterHeatingSystem[h:WaterHeaterType="storage water heater" and h:FuelType!="electricity"]'>
      <sch:assert role='ERROR' test='count(h:RecoveryEfficiency) &lt;= 1'>Expected 0 or 1 element(s) for xpath: RecoveryEfficiency</sch:assert>
      <sch:assert role='ERROR' test='number(h:RecoveryEfficiency) &gt; number(h:EnergyFactor) or not(h:RecoveryEfficiency) or not (h:EnergyFactor)'>Expected RecoveryEfficiency to be greater than EnergyFactor</sch:assert>
      <sch:assert role='ERROR' test='number(h:RecoveryEfficiency) &gt; number(h:UniformEnergyFactor) or not(h:RecoveryEfficiency) or not (h:UniformEnergyFactor)'>Expected RecoveryEfficiency to be greater than UniformEnergyFactor</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[WaterHeatingSystemType=Tankless]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:WaterHeating/h:WaterHeatingSystem[h:WaterHeaterType="instantaneous water heater"]'>
      <sch:assert role='ERROR' test='count(h:FuelType) = 1'>Expected 1 element(s) for xpath: FuelType</sch:assert>
      <sch:assert role='ERROR' test='h:FuelType[text()="natural gas" or text()="fuel oil" or text()="propane" or text()="electricity" or text()="wood" or text()="wood pellets"] or not(h:FuelType)'>Expected FuelType to be 'natural gas' or 'fuel oil' or 'propane' or 'electricity' or 'wood' or 'wood pellets'</sch:assert>
      <sch:assert role='ERROR' test='count(h:Location) = 1'>Expected 1 element(s) for xpath: Location</sch:assert>
      <sch:assert role='ERROR' test='h:Location[text()="conditioned space" or text()="basement - unconditioned" or text()="basement - conditioned" or text()="attic - unvented" or text()="attic - vented" or text()="garage" or text()="crawlspace - unvented" or text()="crawlspace - vented" or text()="other exterior" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"] or not(h:Location)'>Expected Location to be 'conditioned space' or 'basement - unconditioned' or 'basement - conditioned' or 'attic - unvented' or 'attic - vented' or 'garage' or 'crawlspace - unvented' or 'crawlspace - vented' or 'other exterior' or 'other housing unit' or 'other heated space' or 'other multifamily buffer space' or 'other non-freezing space'</sch:assert>
      <sch:assert role='ERROR' test='count(h:IsSharedSystem) = 1'>Expected 1 element(s) for xpath: IsSharedSystem</sch:assert> <!-- See [WaterHeatingSystemType=Shared] -->
      <sch:assert role='ERROR' test='count(h:FractionDHWLoadServed) = 1'>Expected 1 element(s) for xpath: FractionDHWLoadServed</sch:assert>
      <sch:assert role='ERROR' test='count(h:UniformEnergyFactor) + count(h:EnergyFactor) = 1'>Expected 1 element(s) for xpath: UniformEnergyFactor | EnergyFactor</sch:assert>
      <sch:assert role='ERROR' test='number(h:UniformEnergyFactor) &lt; 1 or not(h:UniformEnergyFactor)'>Expected UniformEnergyFactor to be less than 1</sch:assert>
      <sch:assert role='ERROR' test='number(h:EnergyFactor) &lt; 1 or not(h:EnergyFactor)'>Expected EnergyFactor to be less than 1</sch:assert>
      <sch:assert role='ERROR' test='count(h:UsesDesuperheater) &lt;= 1'>Expected 0 or 1 element(s) for xpath: UsesDesuperheater</sch:assert> <!-- See [Desuperheater] -->
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[WaterHeatingSystemType=HeatPump]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:WaterHeating/h:WaterHeatingSystem[h:WaterHeaterType="heat pump water heater"]'>
      <sch:assert role='ERROR' test='count(h:FuelType[text()="electricity"]) = 1'>Expected 1 element(s) for xpath: FuelType[text()="electricity"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:Location) = 1'>Expected 1 element(s) for xpath: Location</sch:assert>
      <sch:assert role='ERROR' test='h:Location[text()="conditioned space" or text()="basement - unconditioned" or text()="basement - conditioned" or text()="attic - unvented" or text()="attic - vented" or text()="garage" or text()="crawlspace - unvented" or text()="crawlspace - vented" or text()="other exterior" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"] or not(h:Location)'>Expected Location to be 'conditioned space' or 'basement - unconditioned' or 'basement - conditioned' or 'attic - unvented' or 'attic - vented' or 'garage' or 'crawlspace - unvented' or 'crawlspace - vented' or 'other exterior' or 'other housing unit' or 'other heated space' or 'other multifamily buffer space' or 'other non-freezing space'</sch:assert>
      <sch:assert role='ERROR' test='count(h:IsSharedSystem) = 1'>Expected 1 element(s) for xpath: IsSharedSystem</sch:assert> <!-- See [WaterHeatingSystemType=Shared] -->
      <sch:assert role='ERROR' test='count(h:TankVolume) = 1'>Expected 1 element(s) for xpath: TankVolume</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionDHWLoadServed) = 1'>Expected 1 element(s) for xpath: FractionDHWLoadServed</sch:assert>
      <sch:assert role='ERROR' test='count(h:UniformEnergyFactor) + count(h:EnergyFactor) = 1'>Expected 1 element(s) for xpath: UniformEnergyFactor | EnergyFactor</sch:assert>
      <sch:assert role='ERROR' test='count(h:FirstHourRating) + count(h:EnergyFactor) &gt;= 1'>Expected 1 or more element(s) for xpath: FirstHourRating | EnergyFactor</sch:assert>
      <sch:assert role='ERROR' test='number(h:UniformEnergyFactor) &gt; 1 or not(h:UniformEnergyFactor)'>Expected UniformEnergyFactor to be greater than 1</sch:assert>
      <sch:assert role='ERROR' test='number(h:EnergyFactor) &gt; 1 or not(h:EnergyFactor)'>Expected EnergyFactor to be greater than 1</sch:assert>
      <sch:assert role='ERROR' test='count(h:WaterHeaterInsulation/h:Jacket/h:JacketRValue) &lt;= 1'>Expected 0 or 1 element(s) for xpath: WaterHeaterInsulation/Jacket/JacketRValue</sch:assert>
      <sch:assert role='ERROR' test='count(h:UsesDesuperheater) &lt;= 1'>Expected 0 or 1 element(s) for xpath: UsesDesuperheater</sch:assert> <!-- See [Desuperheater] -->
      <sch:assert role='ERROR' test='count(h:extension/h:HPWHInConfinedSpaceWithoutMitigation) = 1'>Expected 1 element(s) for xpath: extension/HPWHInConfinedSpaceWithoutMitigation</sch:assert> <!-- See [HPWHInConfinedSpaceWithoutMitigation] -->
      <sch:assert role='ERROR' test='h:extension/h:HPWHInConfinedSpaceWithoutMitigation[text()="true" or text()="false"] or not(h:extension/h:HPWHInConfinedSpaceWithoutMitigation)'>Expected extension/HPWHInConfinedSpaceWithoutMitigation to be 'true' or 'false'</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HPWHInConfinedSpaceWithoutMitigation]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:WaterHeating/h:WaterHeatingSystem/h:extension[h:HPWHInConfinedSpaceWithoutMitigation="true"]'>
      <sch:assert role='ERROR' test='count(h:HPWHContainmentVolume) = 1'>Expected 1 element(s) for xpath: HPWHContainmentVolume</sch:assert>
      <sch:assert role='ERROR' test='number(h:HPWHContainmentVolume) &gt; 0 or not(h:HPWHContainmentVolume)'>Expected HPWHContainmentVolume to be greater than 0</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[WaterHeatingSystemType=CombiIndirect]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:WaterHeating/h:WaterHeatingSystem[h:WaterHeaterType="space-heating boiler with storage tank"]'>
      <sch:assert role='ERROR' test='count(h:Location) = 1'>Expected 1 element(s) for xpath: Location</sch:assert>
      <sch:assert role='ERROR' test='h:Location[text()="conditioned space" or text()="basement - unconditioned" or text()="basement - conditioned" or text()="attic - unvented" or text()="attic - vented" or text()="garage" or text()="crawlspace - unvented" or text()="crawlspace - vented" or text()="other exterior" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"] or not(h:Location)'>Expected Location to be 'conditioned space' or 'basement - unconditioned' or 'basement - conditioned' or 'attic - unvented' or 'attic - vented' or 'garage' or 'crawlspace - unvented' or 'crawlspace - vented' or 'other exterior' or 'other housing unit' or 'other heated space' or 'other multifamily buffer space' or 'other non-freezing space'</sch:assert>
      <sch:assert role='ERROR' test='count(h:IsSharedSystem) = 1'>Expected 1 element(s) for xpath: IsSharedSystem</sch:assert> <!-- See [WaterHeatingSystemType=Shared] -->
      <sch:assert role='ERROR' test='count(h:TankVolume) = 1'>Expected 1 element(s) for xpath: TankVolume</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionDHWLoadServed) = 1'>Expected 1 element(s) for xpath: FractionDHWLoadServed</sch:assert>
      <sch:assert role='ERROR' test='count(h:WaterHeaterInsulation/h:Jacket/h:JacketRValue) &lt;= 1'>Expected 0 or 1 element(s) for xpath: WaterHeaterInsulation/Jacket/JacketRValue</sch:assert>
      <sch:assert role='ERROR' test='count(h:StandbyLoss[h:Units="F/hr"]/h:Value) &lt;= 1'>Expected 0 or 1 element(s) for xpath: StandbyLoss[Units="F/hr"]/Value</sch:assert>
      <sch:assert role='ERROR' test='count(h:RelatedHVACSystem) = 1'>Expected 1 element(s) for xpath: RelatedHVACSystem</sch:assert> <!-- See [HeatingSystem] (boiler) -->
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[WaterHeatingSystemType=CombiTanklessCoil]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:WaterHeating/h:WaterHeatingSystem[h:WaterHeaterType="space-heating boiler with tankless coil"]'>
      <sch:assert role='ERROR' test='count(h:Location) = 1'>Expected 1 element(s) for xpath: Location</sch:assert>
      <sch:assert role='ERROR' test='h:Location[text()="conditioned space" or text()="basement - unconditioned" or text()="basement - conditioned" or text()="attic - unvented" or text()="attic - vented" or text()="garage" or text()="crawlspace - unvented" or text()="crawlspace - vented" or text()="other exterior" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"] or not(h:Location)'>Expected Location to be 'conditioned space' or 'basement - unconditioned' or 'basement - conditioned' or 'attic - unvented' or 'attic - vented' or 'garage' or 'crawlspace - unvented' or 'crawlspace - vented' or 'other exterior' or 'other housing unit' or 'other heated space' or 'other multifamily buffer space' or 'other non-freezing space'</sch:assert>
      <sch:assert role='ERROR' test='count(h:IsSharedSystem) = 1'>Expected 1 element(s) for xpath: IsSharedSystem</sch:assert> <!-- See [WaterHeatingSystemType=Shared] -->
      <sch:assert role='ERROR' test='count(h:FractionDHWLoadServed) = 1'>Expected 1 element(s) for xpath: FractionDHWLoadServed</sch:assert>
      <sch:assert role='ERROR' test='count(h:RelatedHVACSystem) = 1'>Expected 1 element(s) for xpath: RelatedHVACSystem</sch:assert> <!-- See [HeatingSystem] (boiler) -->
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[WaterHeatingSystem=Shared]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:WaterHeating/h:WaterHeatingSystem[h:IsSharedSystem="true"]'>
      <sch:assert role='ERROR' test='count(../../../h:BuildingSummary/h:BuildingConstruction[h:ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]]) = 1'>Expected 1 element(s) for xpath: ../../../BuildingSummary/BuildingConstruction[ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]]</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:NumberofBedroomsServed) = 1'>Expected 1 element(s) for xpath: extension/NumberofBedroomsServed</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:NumberofBedroomsServed) &gt; number(../../../h:BuildingSummary/h:BuildingConstruction/h:NumberofBedrooms) or not(h:extension/h:NumberofBedroomsServed) or not(../../../h:BuildingSummary/h:BuildingConstruction/h:NumberofBedrooms)'>Expected extension/NumberofBedroomsServed to be greater than ../../../BuildingSummary/BuildingConstruction/NumberofBedrooms</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Desuperheater]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:WaterHeating/h:WaterHeatingSystem[h:UsesDesuperheater="true"]'>
      <sch:assert role='ERROR' test='count(h:RelatedHVACSystem) = 1'>Expected 1 element(s) for xpath: RelatedHVACSystem</sch:assert> <!-- See [HeatPump] or [CoolingSystem] -->
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HotWaterDistribution]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:WaterHeating/h:HotWaterDistribution'>
      <sch:assert role='ERROR' test='count(h:SystemType/h:Standard) + count(h:SystemType/h:Recirculation) = 1'>Expected 1 element(s) for xpath: SystemType/Standard | SystemType/Recirculation</sch:assert> <!-- See [HotWaterDistributionType=Standard] or [HotWaterDistributionType=Recirculation] -->
      <sch:assert role='ERROR' test='count(h:PipeInsulation/h:PipeRValue) = 1'>Expected 1 element(s) for xpath: PipeInsulation/PipeRValue</sch:assert>
      <sch:assert role='ERROR' test='count(h:DrainWaterHeatRecovery) &lt;= 1'>Expected 0 or 1 element(s) for xpath: DrainWaterHeatRecovery</sch:assert> <!-- See [DrainWaterHeatRecovery] -->
      <sch:assert role='ERROR' test='count(h:extension/h:SharedRecirculation) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/SharedRecirculation</sch:assert> <!-- See [HotWaterDistributionType=SharedRecirculation] -->
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HotWaterDistributionType=Standard]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:WaterHeating/h:HotWaterDistribution/h:SystemType/h:Standard'>
      <sch:assert role='ERROR' test='count(h:PipingLength) = 1'>Expected 1 element(s) for xpath: PipingLength</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HotWaterDistributionType=Recirculation]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:WaterHeating/h:HotWaterDistribution/h:SystemType/h:Recirculation'>
      <sch:assert role='ERROR' test='count(h:ControlType) = 1'>Expected 1 element(s) for xpath: ControlType</sch:assert>
      <sch:assert role='ERROR' test='h:ControlType[text()="manual demand control" or text()="presence sensor demand control" or text()="temperature" or text()="timer" or text()="no control"] or not(h:ControlType)'>Expected ControlType to be 'manual demand control' or 'presence sensor demand control' or 'temperature' or 'timer' or 'no control'</sch:assert>
      <sch:assert role='ERROR' test='count(h:RecirculationPipingLoopLength) = 1'>Expected 1 element(s) for xpath: RecirculationPipingLoopLength</sch:assert>
      <sch:assert role='ERROR' test='count(h:BranchPipingLength) = 1'>Expected 1 element(s) for xpath: BranchPipingLength</sch:assert>
      <sch:assert role='ERROR' test='count(h:PumpPower) = 1'>Expected 1 element(s) for xpath: PumpPower</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HotWaterDistributionType=SharedRecirculation]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:WaterHeating/h:HotWaterDistribution/h:extension/h:SharedRecirculation'>
      <sch:assert role='ERROR' test='count(../../../../../h:BuildingSummary/h:BuildingConstruction[h:ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]]) = 1'>Expected 1 element(s) for xpath: ../../../../../BuildingSummary/BuildingConstruction[ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]]</sch:assert>
      <sch:assert role='ERROR' test='count(../../h:SystemType/h:Standard) = 1'>Expected 1 element(s) for xpath: ../../SystemType/Standard</sch:assert>
      <sch:assert role='ERROR' test='count(h:NumberofBedroomsServed) = 1'>Expected 1 element(s) for xpath: NumberofBedroomsServed</sch:assert>
      <sch:assert role='ERROR' test='number(h:NumberofBedroomsServed) &gt; number(../../../../../h:BuildingSummary/h:BuildingConstruction/h:NumberofBedrooms) or not(h:NumberofBedroomsServed) or not(../../../../../h:BuildingSummary/h:BuildingConstruction/h:NumberofBedrooms)'>Expected NumberofBedroomsServed to be greater than ../../../../../BuildingSummary/BuildingConstruction/NumberofBedrooms</sch:assert>
      <sch:assert role='ERROR' test='count(h:PumpPower) = 1'>Expected 1 element(s) for xpath: PumpPower</sch:assert>
      <sch:assert role='ERROR' test='count(h:MotorEfficiency) &lt;= 1'>Expected 0 or 1 element(s) for xpath: MotorEfficiency</sch:assert>
      <sch:assert role='ERROR' test='number(h:MotorEfficiency) &gt; 0 or not(h:MotorEfficiency)'>Expected MotorEfficiency to be greater than 0</sch:assert>
      <sch:assert role='ERROR' test='number(h:MotorEfficiency) &lt; 1 or not(h:MotorEfficiency)'>Expected MotorEfficiency to be less than 1</sch:assert>
      <sch:assert role='ERROR' test='count(h:ControlType) = 1'>Expected 1 element(s) for xpath: ControlType</sch:assert>
      <sch:assert role='ERROR' test='h:ControlType[text()="manual demand control" or text()="presence sensor demand control" or text()="temperature" or text()="timer" or text()="no control"] or not(h:ControlType)'>Expected ControlType to be 'manual demand control' or 'presence sensor demand control' or 'temperature' or 'timer' or 'no control'</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[DrainWaterHeatRecovery]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:WaterHeating/h:HotWaterDistribution/h:DrainWaterHeatRecovery'>
      <sch:assert role='ERROR' test='count(h:FacilitiesConnected) = 1'>Expected 1 element(s) for xpath: FacilitiesConnected</sch:assert>
      <sch:assert role='ERROR' test='count(h:EqualFlow) = 1'>Expected 1 element(s) for xpath: EqualFlow</sch:assert>
      <sch:assert role='ERROR' test='count(h:Efficiency) = 1'>Expected 1 element(s) for xpath: Efficiency</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[WaterFixture]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:WaterHeating/h:WaterFixture'>
      <sch:assert role='ERROR' test='count(../h:HotWaterDistribution) = 1'>Expected 1 element(s) for xpath: ../HotWaterDistribution</sch:assert> <!-- See [HotWaterDistribution] -->
      <sch:assert role='ERROR' test='count(h:WaterFixtureType) = 1'>Expected 1 element(s) for xpath: WaterFixtureType</sch:assert>
      <sch:assert role='ERROR' test='h:WaterFixtureType[text()="shower head" or text()="faucet"] or not(h:WaterFixtureType)'>Expected WaterFixtureType to be 'shower head' or 'faucet'</sch:assert>
      <sch:assert role='ERROR' test='count(h:LowFlow) = 1'>Expected 1 element(s) for xpath: LowFlow</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[SolarThermalSystem]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:SolarThermal/h:SolarThermalSystem'>
      <sch:assert role='ERROR' test='count(h:CollectorArea) + count(h:SolarFraction) = 1'>Expected 1 element(s) for xpath: CollectorArea | SolarFraction</sch:assert> <!-- See [SolarThermalSystemType=Detailed] or [SolarThermalSystemType=Simple] -->
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[SolarThermalSystemType=Detailed]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:SolarThermal/h:SolarThermalSystem[h:CollectorArea]'>
      <sch:assert role='ERROR' test='count(h:SystemType) = 1'>Expected 1 element(s) for xpath: SystemType</sch:assert>
      <sch:assert role='ERROR' test='h:SystemType[text()="hot water"] or not(h:SystemType)'>Expected SystemType to be 'hot water'</sch:assert>
      <sch:assert role='ERROR' test='count(h:CollectorLoopType) = 1'>Expected 1 element(s) for xpath: CollectorLoopType</sch:assert>
      <sch:assert role='ERROR' test='h:CollectorLoopType[text()="liquid indirect" or text()="liquid direct" or text()="passive thermosyphon"] or not(h:CollectorLoopType)'>Expected CollectorLoopType to be 'liquid indirect' or 'liquid direct' or 'passive thermosyphon'</sch:assert>
      <sch:assert role='ERROR' test='count(h:CollectorType) = 1'>Expected 1 element(s) for xpath: CollectorType</sch:assert>
      <sch:assert role='ERROR' test='h:CollectorType[text()="single glazing black" or text()="double glazing black" or text()="evacuated tube" or text()="integrated collector storage"] or not(h:CollectorType)'>Expected CollectorType to be 'single glazing black' or 'double glazing black' or 'evacuated tube' or 'integrated collector storage'</sch:assert>
      <sch:assert role='ERROR' test='count(h:CollectorAzimuth) = 1'>Expected 1 element(s) for xpath: CollectorAzimuth</sch:assert>
      <sch:assert role='ERROR' test='count(h:CollectorTilt) = 1'>Expected 1 element(s) for xpath: CollectorTilt</sch:assert>
      <sch:assert role='ERROR' test='count(h:CollectorRatedOpticalEfficiency) = 1'>Expected 1 element(s) for xpath: CollectorRatedOpticalEfficiency</sch:assert>
      <sch:assert role='ERROR' test='count(h:CollectorRatedThermalLosses) = 1'>Expected 1 element(s) for xpath: CollectorRatedThermalLosses</sch:assert>
      <sch:assert role='ERROR' test='count(h:StorageVolume) = 1'>Expected 1 element(s) for xpath: StorageVolume</sch:assert>
      <sch:assert role='ERROR' test='count(h:ConnectedTo) = 1'>Expected 1 element(s) for xpath: ConnectedTo</sch:assert> <!-- See [WaterHeatingSystem] (any type but space-heating boiler) -->
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[SolarThermalSystemType=Simple]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:SolarThermal/h:SolarThermalSystem[h:SolarFraction]'>
      <sch:assert role='ERROR' test='count(h:SystemType) = 1'>Expected 1 element(s) for xpath: SystemType</sch:assert>
      <sch:assert role='ERROR' test='h:SystemType[text()="hot water"] or not(h:SystemType)'>Expected SystemType to be 'hot water'</sch:assert>
      <sch:assert role='ERROR' test='number(h:SolarFraction) &lt;= 0.99 or not(h:SolarFraction)'>Expected SolarFraction to be less than or equal to 0.99</sch:assert>
      <sch:assert role='ERROR' test='count(h:ConnectedTo) &lt;= 1'>Expected 0 or 1 element(s) for xpath: ConnectedTo</sch:assert> <!-- See [WaterHeatingSystem] (any type) -->
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[PVSystem]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:Photovoltaics/h:PVSystem'>
      <sch:assert role='ERROR' test='count(h:IsSharedSystem) = 1'>Expected 1 element(s) for xpath: IsSharedSystem</sch:assert> <!-- See [PVSystemType=Shared] -->
      <sch:assert role='ERROR' test='count(h:Location) = 1'>Expected 1 element(s) for xpath: Location</sch:assert>
      <sch:assert role='ERROR' test='h:Location[text()="ground" or text()="roof"] or not(h:Location)'>Expected Location to be 'ground' or 'roof'</sch:assert>
      <sch:assert role='ERROR' test='count(h:ModuleType) = 1'>Expected 1 element(s) for xpath: ModuleType</sch:assert>
      <sch:assert role='ERROR' test='h:ModuleType[text()="standard" or text()="premium" or text()="thin film"] or not(h:ModuleType)'>Expected ModuleType to be 'standard' or 'premium' or 'thin film'</sch:assert>
      <sch:assert role='ERROR' test='count(h:Tracking) = 1'>Expected 1 element(s) for xpath: Tracking</sch:assert>
      <sch:assert role='ERROR' test='h:Tracking[text()="fixed" or text()="1-axis" or text()="1-axis backtracked" or text()="2-axis"] or not(h:Tracking)'>Expected Tracking to be 'fixed' or '1-axis' or '1-axis backtracked' or '2-axis'</sch:assert>
      <sch:assert role='ERROR' test='count(h:ArrayAzimuth) = 1'>Expected 1 element(s) for xpath: ArrayAzimuth</sch:assert>
      <sch:assert role='ERROR' test='count(h:ArrayTilt) = 1'>Expected 1 element(s) for xpath: ArrayTilt</sch:assert>
      <sch:assert role='ERROR' test='count(h:MaxPowerOutput) = 1'>Expected 1 element(s) for xpath: MaxPowerOutput</sch:assert>
      <sch:assert role='ERROR' test='count(h:SystemLossesFraction) = 1'>Expected 1 element(s) for xpath: SystemLossesFraction</sch:assert>
      <sch:assert role='ERROR' test='count(h:AttachedToInverter) = 1'>Expected 1 element(s) for xpath: AttachedToInverter</sch:assert> <!-- See [Inverter] -->
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[PVSystemType=Shared]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:Photovoltaics/h:PVSystem[h:IsSharedSystem="true"]'>
      <sch:assert role='ERROR' test='count(../../../h:BuildingSummary/h:BuildingConstruction[h:ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]]) = 1'>Expected 1 element(s) for xpath: ../../../BuildingSummary/BuildingConstruction[ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]]</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:NumberofBedroomsServed) = 1'>Expected 1 element(s) for xpath: extension/NumberofBedroomsServed</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:NumberofBedroomsServed) &gt; number(../../../h:BuildingSummary/h:BuildingConstruction/h:NumberofBedrooms) or not(h:extension/h:NumberofBedroomsServed) or not(../../../h:BuildingSummary/h:BuildingConstruction/h:NumberofBedrooms)'>Expected extension/NumberofBedroomsServed to be greater than ../../../BuildingSummary/BuildingConstruction/NumberofBedrooms</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Inverter]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:Photovoltaics/h:Inverter'>
      <sch:assert role='ERROR' test='count(h:InverterEfficiency) = 1'>Expected 1 element(s) for xpath: InverterEfficiency</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Battery]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:Batteries/h:Battery'>
      <sch:assert role='ERROR' test='count(h:IsSharedSystem) = 1'>Expected 1 element(s) for xpath: IsSharedSystem</sch:assert> <!-- See [BatteryType=Shared] -->
      <sch:assert role='ERROR' test='count(h:BatteryType[text()="Li-ion"]) = 1'>Expected 1 element(s) for xpath: BatteryType[text()="Li-ion"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:Location) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Location</sch:assert>
      <sch:assert role='ERROR' test='h:Location[text()="conditioned space" or text()="basement - conditioned" or text()="basement - unconditioned" or text()="crawlspace - vented" or text()="crawlspace - unvented" or text()="attic - vented" or text()="attic - unvented" or text()="garage" or text()="outside"] or not(h:Location)'>Expected Location to be 'conditioned space' or 'basement - conditioned' or 'basement - unconditioned' or 'crawlspace - vented' or 'crawlspace - unvented' or 'attic - vented' or 'attic - unvented' or 'garage' or 'outside'</sch:assert>
      <sch:assert role='ERROR' test='count(h:NominalCapacity[h:Units="kWh"]/h:Value) = 1'>Expected 1 element(s) for xpath: NominalCapacity[Units="kWh"]/Value</sch:assert>
      <sch:assert role='ERROR' test='count(h:UsableCapacity[h:Units="kWh"]/h:Value) = 1'>Expected 1 element(s) for xpath: UsableCapacity[Units="kWh"]/Value</sch:assert>
      <sch:assert role='ERROR' test='number(h:UsableCapacity[h:Units="kWh"]/h:Value) &lt; number(h:NominalCapacity[h:Units="kWh"]/h:Value) or not(h:UsableCapacity[h:Units="kWh"]/h:Value) or not(h:NominalCapacity[h:Units="kWh"]/h:Value)'>Expected UsableCapacity to be less than NominalCapacity</sch:assert>
      <sch:assert role='ERROR' test='count(h:RatedPowerOutput) = 1'>Expected 1 element(s) for xpath: RatedPowerOutput</sch:assert>
      <sch:assert role='ERROR' test='count(h:RoundTripEfficiency) = 1'>Expected 1 element(s) for xpath: RoundTripEfficiency</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:RatedPowerOutput) &lt;= 1000 and number(h:RatedPowerOutput) &gt; 0'>Rated power output should typically be greater than or equal to 1000 W.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[BatteryType=Shared]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:Batteries/h:Battery[h:IsSharedSystem="true"]'>
      <sch:assert role='ERROR' test='count(../../../h:BuildingSummary/h:BuildingConstruction[h:ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]]) = 1'>Expected 1 element(s) for xpath: ../../../BuildingSummary/BuildingConstruction[ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]]</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:NumberofBedroomsServed) = 1'>Expected 1 element(s) for xpath: extension/NumberofBedroomsServed</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:NumberofBedroomsServed) &gt; number(../../../h:BuildingSummary/h:BuildingConstruction/h:NumberofBedrooms) or not(h:extension/h:NumberofBedroomsServed) or not(../../../h:BuildingSummary/h:BuildingConstruction/h:NumberofBedrooms)'>Expected extension/NumberofBedroomsServed to be greater than ../../../BuildingSummary/BuildingConstruction/NumberofBedrooms</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Generator]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:extension/h:Generators/h:Generator'>
      <sch:assert role='ERROR' test='count(h:IsSharedSystem) = 1'>Expected 1 element(s) for xpath: IsSharedSystem</sch:assert> <!-- See [GeneratorType=Shared] -->
      <sch:assert role='ERROR' test='count(h:FuelType) = 1'>Expected 1 element(s) for xpath: FuelType</sch:assert>
      <sch:assert role='ERROR' test='h:FuelType[text()="natural gas" or text()="fuel oil" or text()="propane" or text()="wood" or text()="wood pellets"] or not(h:FuelType)'>Expected FuelType to be 'natural gas' or 'fuel oil' or 'propane' or 'wood' or 'wood pellets'</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualConsumptionkBtu) = 1'>Expected 1 element(s) for xpath: AnnualConsumptionkBtu</sch:assert>
      <sch:assert role='ERROR' test='number(h:AnnualConsumptionkBtu) &gt; 0 or not(h:AnnualConsumptionkBtu)'>Expected AnnualConsumptionkBtu to be greater than 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualOutputkWh) = 1'>Expected 1 element(s) for xpath: AnnualOutputkWh</sch:assert>
      <sch:assert role='ERROR' test='number(h:AnnualOutputkWh) &gt; 0 or not(h:AnnualOutputkWh)'>Expected AnnualOutputkWh to be greater than 0</sch:assert>
      <sch:assert role='ERROR' test='number(h:AnnualConsumptionkBtu) &gt; (number(h:AnnualOutputkWh) * 3.412) or not(h:AnnualConsumptionkBtu) or not(h:AnnualOutputkWh)'>Expected AnnualConsumptionkBtu to be greater than AnnualOutputkWh*3412</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[GeneratorType=Shared]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:extension/h:Generators/h:Generator[h:IsSharedSystem="true"]'>
      <sch:assert role='ERROR' test='count(../../../../h:BuildingSummary/h:BuildingConstruction[h:ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]]) = 1'>Expected 1 element(s) for xpath: ../../../BuildingSummary/BuildingConstruction[ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]]</sch:assert>
      <sch:assert role='ERROR' test='count(h:NumberofBedroomsServed) = 1'>Expected 1 element(s) for xpath: NumberofBedroomsServed</sch:assert>
      <sch:assert role='ERROR' test='number(h:NumberofBedroomsServed) &gt; number(../../../../h:BuildingSummary/h:BuildingConstruction/h:NumberofBedrooms) or not(h:NumberofBedroomsServed) or not(../../../../h:BuildingSummary/h:BuildingConstruction/h:NumberofBedrooms)'>Expected NumberofBedroomsServed to be greater than ../../../../BuildingSummary/BuildingConstruction/NumberofBedrooms</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[ClothesWasher]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Appliances/h:ClothesWasher'>
      <sch:assert role='ERROR' test='count(h:IsSharedAppliance) = 1'>Expected 1 element(s) for xpath: IsSharedAppliance</sch:assert> <!-- See [ClothesWasherType=Shared] -->
      <sch:assert role='ERROR' test='count(h:Location) = 1'>Expected 1 element(s) for xpath: Location</sch:assert>
      <sch:assert role='ERROR' test='h:Location[text()="conditioned space" or text()="basement - unconditioned" or text()="basement - conditioned" or text()="attic - unvented" or text()="attic - vented" or text()="garage" or text()="crawlspace - unvented" or text()="crawlspace - vented" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"] or not(h:Location)'>Expected Location to be 'conditioned space' or 'basement - unconditioned' or 'basement - conditioned' or 'attic - unvented' or 'attic - vented' or 'garage' or 'crawlspace - unvented' or 'crawlspace - vented' or 'other housing unit' or 'other heated space' or 'other multifamily buffer space' or 'other non-freezing space'</sch:assert>
      <sch:assert role='ERROR' test='count(h:IntegratedModifiedEnergyFactor) + count(h:ModifiedEnergyFactor) = 1'>Expected 1 element(s) for xpath: IntegratedModifiedEnergyFactor | ModifiedEnergyFactor</sch:assert>
      <sch:assert role='ERROR' test='count(h:RatedAnnualkWh) = 1'>Expected 1 element(s) for xpath: RatedAnnualkWh</sch:assert>
      <sch:assert role='ERROR' test='count(h:LabelElectricRate) = 1'>Expected 1 element(s) for xpath: LabelElectricRate</sch:assert>
      <sch:assert role='ERROR' test='count(h:LabelGasRate) = 1'>Expected 1 element(s) for xpath: LabelGasRate</sch:assert>
      <sch:assert role='ERROR' test='count(h:LabelAnnualGasCost) = 1'>Expected 1 element(s) for xpath: LabelAnnualGasCost</sch:assert>
      <sch:assert role='ERROR' test='count(h:LabelUsage) = 1'>Expected 1 element(s) for xpath: LabelUsage</sch:assert>
      <sch:assert role='ERROR' test='count(h:Capacity) = 1'>Expected 1 element(s) for xpath: Capacity</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[ClothesWasherType=Shared]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Appliances/h:ClothesWasher[h:IsSharedAppliance="true"]'>
      <sch:assert role='ERROR' test='count(../../h:BuildingSummary/h:BuildingConstruction[h:ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]]) = 1'>Expected 1 element(s) for xpath: ../../BuildingSummary/BuildingConstruction[ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]]</sch:assert>
      <sch:assert role='ERROR' test='count(h:AttachedToWaterHeatingSystem) + count(h:AttachedToHotWaterDistribution) = 1'>Expected 1 element(s) for xpath: AttachedToWaterHeatingSystem | AttachedToHotWaterDistribution</sch:assert>
      <sch:assert role='ERROR' test='count(h:Count) = 1'>Expected 1 element(s) for xpath: Count</sch:assert>
      <sch:assert role='ERROR' test='count(h:NumberofUnitsServed) = 1'>Expected 1 element(s) for xpath: NumberofUnitsServed</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[ClothesDryer]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Appliances/h:ClothesDryer'>
      <sch:assert role='ERROR' test='count(h:IsSharedAppliance) = 1'>Expected 1 element(s) for xpath: IsSharedAppliance</sch:assert> <!-- See [ClothesDryerType=Shared] -->
      <sch:assert role='ERROR' test='count(h:Location) = 1'>Expected 1 element(s) for xpath: Location</sch:assert>
      <sch:assert role='ERROR' test='h:Location[text()="conditioned space" or text()="basement - unconditioned" or text()="basement - conditioned" or text()="attic - unvented" or text()="attic - vented" or text()="garage" or text()="crawlspace - unvented" or text()="crawlspace - vented" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"] or not(h:Location)'>Expected Location to be 'conditioned space' or 'basement - unconditioned' or 'basement - conditioned' or 'attic - unvented' or 'attic - vented' or 'garage' or 'crawlspace - unvented' or 'crawlspace - vented' or 'other housing unit' or 'other heated space' or 'other multifamily buffer space' or 'other non-freezing space'</sch:assert>
      <sch:assert role='ERROR' test='count(h:FuelType) = 1'>Expected 1 element(s) for xpath: FuelType</sch:assert>
      <sch:assert role='ERROR' test='h:FuelType[text()="natural gas" or text()="fuel oil" or text()="propane" or text()="electricity" or text()="wood" or text()="wood pellets"] or not(h:FuelType)'>Expected FuelType to be 'natural gas' or 'fuel oil' or 'propane' or 'electricity' or 'wood' or 'wood pellets'</sch:assert>
      <sch:assert role='ERROR' test='count(h:CombinedEnergyFactor) + count(h:EnergyFactor) = 1'>Expected 1 element(s) for xpath: CombinedEnergyFactor | EnergyFactor</sch:assert>
      <sch:assert role='ERROR' test='count(h:ControlType[text()="timer" or text()="moisture"]) + count(../../../../h:SoftwareInfo/h:extension[not(h:ERICalculation) or h:ERICalculation/h:Version[not(text()="2019" or contains(text(), "2014"))]]) &gt;= 1'>Expected 1 or more element(s) for xpath: ControlType | ../../../../SoftwareInfo/extension/ERICalculation/Version[text() &lt; 2019A]</sch:assert>
      <sch:assert role='ERROR' test='count(h:Vented) = 1'>Expected 1 element(s) for xpath: Vented</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[ClothesDryerType=Shared]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Appliances/h:ClothesDryer[h:IsSharedAppliance="true"]'>
      <sch:assert role='ERROR' test='count(../../h:BuildingSummary/h:BuildingConstruction[h:ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]]) = 1'>Expected 1 element(s) for xpath: ../../BuildingSummary/BuildingConstruction[ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]]</sch:assert>
      <sch:assert role='ERROR' test='count(h:Count) = 1'>Expected 1 element(s) for xpath: Count</sch:assert>
      <sch:assert role='ERROR' test='count(h:NumberofUnitsServed) = 1'>Expected 1 element(s) for xpath: NumberofUnitsServed</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Dishwasher]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Appliances/h:Dishwasher'>
      <sch:assert role='ERROR' test='count(h:IsSharedAppliance) = 1'>Expected 1 element(s) for xpath: IsSharedAppliance</sch:assert> <!-- See [DishwasherType=Shared] -->
      <sch:assert role='ERROR' test='count(h:Location) = 1'>Expected 1 element(s) for xpath: Location</sch:assert>
      <sch:assert role='ERROR' test='h:Location[text()="conditioned space" or text()="basement - unconditioned" or text()="basement - conditioned" or text()="attic - unvented" or text()="attic - vented" or text()="garage" or text()="crawlspace - unvented" or text()="crawlspace - vented" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"] or not(h:Location)'>Expected Location to be 'conditioned space' or 'basement - unconditioned' or 'basement - conditioned' or 'attic - unvented' or 'attic - vented' or 'garage' or 'crawlspace - unvented' or 'crawlspace - vented' or 'other housing unit' or 'other heated space' or 'other multifamily buffer space' or 'other non-freezing space'</sch:assert>
      <sch:assert role='ERROR' test='count(h:RatedAnnualkWh) + count(h:EnergyFactor) = 1'>Expected 1 element(s) for xpath: RatedAnnualkWh | EnergyFactor</sch:assert>
      <sch:assert role='ERROR' test='count(h:LabelElectricRate) = 1'>Expected 1 element(s) for xpath: LabelElectricRate</sch:assert>
      <sch:assert role='ERROR' test='count(h:LabelGasRate) = 1'>Expected 1 element(s) for xpath: LabelGasRate</sch:assert>
      <sch:assert role='ERROR' test='count(h:LabelAnnualGasCost) = 1'>Expected 1 element(s) for xpath: LabelAnnualGasCost</sch:assert>
      <sch:assert role='ERROR' test='count(h:LabelUsage) = 1'>Expected 1 element(s) for xpath: LabelUsage</sch:assert>
      <sch:assert role='ERROR' test='count(h:PlaceSettingCapacity) = 1'>Expected 1 element(s) for xpath: PlaceSettingCapacity</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[DishwasherType=Shared]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Appliances/h:Dishwasher[h:IsSharedAppliance="true"]'>
      <sch:assert role='ERROR' test='count(../../h:BuildingSummary/h:BuildingConstruction[h:ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]]) = 1'>Expected 1 element(s) for xpath: ../../BuildingSummary/BuildingConstruction[ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]]</sch:assert>
      <sch:assert role='ERROR' test='count(h:AttachedToWaterHeatingSystem) + count(h:AttachedToHotWaterDistribution) = 1'>Expected 1 element(s) for xpath: AttachedToWaterHeatingSystem | AttachedToHotWaterDistribution</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Refrigerator]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Appliances/h:Refrigerator'>
      <sch:assert role='ERROR' test='count(h:Location) = 1'>Expected 1 element(s) for xpath: Location</sch:assert>
      <sch:assert role='ERROR' test='h:Location[text()="conditioned space" or text()="basement - unconditioned" or text()="basement - conditioned" or text()="attic - unvented" or text()="attic - vented" or text()="garage" or text()="crawlspace - unvented" or text()="crawlspace - vented" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"] or not(h:Location)'>Expected Location to be 'conditioned space' or 'basement - unconditioned' or 'basement - conditioned' or 'attic - unvented' or 'attic - vented' or 'garage' or 'crawlspace - unvented' or 'crawlspace - vented' or 'other housing unit' or 'other heated space' or 'other multifamily buffer space' or 'other non-freezing space'</sch:assert>
      <sch:assert role='ERROR' test='count(h:RatedAnnualkWh) = 1'>Expected 1 element(s) for xpath: RatedAnnualkWh</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Dehumidifier]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Appliances/h:Dehumidifier'>
      <sch:assert role='ERROR' test='count(h:Type) = 1'>Expected 1 element(s) for xpath: Type</sch:assert>
      <sch:assert role='ERROR' test='h:Type[text()="portable" or text()="whole-home"] or not(h:Type)'>Expected Type to be 'portable' or 'whole-home'</sch:assert>
      <sch:assert role='ERROR' test='count(h:Location) = 1'>Expected 1 element(s) for xpath: Location</sch:assert>
      <sch:assert role='ERROR' test='h:Location[text()="conditioned space"] or not(h:Location)'>Expected Location to be 'conditioned space'</sch:assert>
      <sch:assert role='ERROR' test='count(h:Capacity) = 1'>Expected 1 element(s) for xpath: Capacity</sch:assert>
      <sch:assert role='ERROR' test='count(h:IntegratedEnergyFactor) + count(h:EnergyFactor) = 1'>Expected 1 element(s) for xpath: IntegratedEnergyFactor | EnergyFactor</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionDehumidificationLoadServed) = 1'>Expected 1 element(s) for xpath: FractionDehumidificationLoadServed</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[CookingRange]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Appliances/h:CookingRange'>
      <sch:assert role='ERROR' test='count(../h:Oven) = 1'>Expected 1 element(s) for xpath: ../Oven</sch:assert> <!-- See [Oven] -->
      <sch:assert role='ERROR' test='count(h:Location) = 1'>Expected 1 element(s) for xpath: Location</sch:assert>
      <sch:assert role='ERROR' test='h:Location[text()="conditioned space" or text()="basement - unconditioned" or text()="basement - conditioned" or text()="attic - unvented" or text()="attic - vented" or text()="garage" or text()="crawlspace - unvented" or text()="crawlspace - vented" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"] or not(h:Location)'>Expected Location to be 'conditioned space' or 'basement - unconditioned' or 'basement - conditioned' or 'attic - unvented' or 'attic - vented' or 'garage' or 'crawlspace - unvented' or 'crawlspace - vented' or 'other housing unit' or 'other heated space' or 'other multifamily buffer space' or 'other non-freezing space'</sch:assert>
      <sch:assert role='ERROR' test='count(h:FuelType) = 1'>Expected 1 element(s) for xpath: FuelType</sch:assert>
      <sch:assert role='ERROR' test='h:FuelType[text()="natural gas" or text()="fuel oil" or text()="propane" or text()="electricity" or text()="wood" or text()="wood pellets"] or not(h:FuelType)'>Expected FuelType to be 'natural gas' or 'fuel oil' or 'propane' or 'electricity' or 'wood' or 'wood pellets'</sch:assert>
      <sch:assert role='ERROR' test='count(h:IsInduction) = 1'>Expected 1 element(s) for xpath: IsInduction</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Oven]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Appliances/h:Oven'>
      <sch:assert role='ERROR' test='count(../h:CookingRange) = 1'>Expected 1 element(s) for xpath: ../CookingRange</sch:assert> <!-- See [CookingRange] -->
      <sch:assert role='ERROR' test='count(h:IsConvection) = 1'>Expected 1 element(s) for xpath: IsConvection</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Lighting]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Lighting'>
      <sch:assert role='ERROR' test='count(h:LightingGroup[h:LightingType[h:LightEmittingDiode] and h:Location[text()="interior"]]) = 1'>Expected 1 element(s) for xpath: LightingGroup[LightingType[LightEmittingDiode] and Location[text()="interior"]]</sch:assert> <!-- See [LightingGroup] -->
      <sch:assert role='ERROR' test='count(h:LightingGroup[h:LightingType[h:LightEmittingDiode] and h:Location[text()="exterior"]]) = 1'>Expected 1 element(s) for xpath: LightingGroup[LightingType[LightEmittingDiode] and Location[text()="exterior"]]</sch:assert> <!-- See [LightingGroup] -->
      <sch:assert role='ERROR' test='count(h:LightingGroup[h:LightingType[h:LightEmittingDiode] and h:Location[text()="garage"]]) = 1 or not (../h:Enclosure/h:Walls/h:Wall[h:InteriorAdjacentTo="garage" or h:ExteriorAdjacentTo="garage"])'>Expected 1 element(s) for xpath: LightingGroup[LightingType[LightEmittingDiode] and Location[text()="garage"]]</sch:assert> <!-- See [LightingGroup] -->
      <sch:assert role='ERROR' test='count(h:LightingGroup[h:LightingType[h:CompactFluorescent] and h:Location[text()="interior"]]) = 1'>Expected 1 element(s) for xpath: LightingGroup[LightingType[CompactFluorescent] and Location[text()="interior"]]</sch:assert> <!-- See [LightingGroup] -->
      <sch:assert role='ERROR' test='count(h:LightingGroup[h:LightingType[h:CompactFluorescent] and h:Location[text()="exterior"]]) = 1'>Expected 1 element(s) for xpath: LightingGroup[LightingType[CompactFluorescent] and Location[text()="exterior"]]</sch:assert> <!-- See [LightingGroup] -->
      <sch:assert role='ERROR' test='count(h:LightingGroup[h:LightingType[h:CompactFluorescent] and h:Location[text()="garage"]]) = 1 or not (../h:Enclosure/h:Walls/h:Wall[h:InteriorAdjacentTo="garage" or h:ExteriorAdjacentTo="garage"])'>Expected 1 element(s) for xpath: LightingGroup[LightingType[CompactFluorescent] and Location[text()="garage"]]</sch:assert> <!-- See [LightingGroup] -->
      <sch:assert role='ERROR' test='count(h:LightingGroup[h:LightingType[h:FluorescentTube] and h:Location[text()="interior"]]) = 1'>Expected 1 element(s) for xpath: LightingGroup[LightingType[FluorescentTube] and Location[text()="interior"]]</sch:assert> <!-- See [LightingGroup] -->
      <sch:assert role='ERROR' test='count(h:LightingGroup[h:LightingType[h:FluorescentTube] and h:Location[text()="exterior"]]) = 1'>Expected 1 element(s) for xpath: LightingGroup[LightingType[FluorescentTube] and Location[text()="exterior"]]</sch:assert> <!-- See [LightingGroup] -->
      <sch:assert role='ERROR' test='count(h:LightingGroup[h:LightingType[h:FluorescentTube] and h:Location[text()="garage"]]) = 1 or not (../h:Enclosure/h:Walls/h:Wall[h:InteriorAdjacentTo="garage" or h:ExteriorAdjacentTo="garage"])'>Expected 1 element(s) for xpath: LightingGroup[LightingType[FluorescentTube] and Location[text()="garage"]]</sch:assert> <!-- See [LightingGroup] -->
      <!-- Sum Checks -->
      <sch:assert role='ERROR' test='sum(h:LightingGroup[h:Location="interior"]/h:FractionofUnitsInLocation) &lt;= 1.01'>Expected sum(LightingGroup/FractionofUnitsInLocation) for Location="interior" to be less than or equal to 1</sch:assert>
      <sch:assert role='ERROR' test='sum(h:LightingGroup[h:Location="exterior"]/h:FractionofUnitsInLocation) &lt;= 1.01'>Expected sum(LightingGroup/FractionofUnitsInLocation) for Location="exterior" to be less than or equal to 1</sch:assert>
      <sch:assert role='ERROR' test='sum(h:LightingGroup[h:Location="garage"]/h:FractionofUnitsInLocation) &lt;= 1.01'>Expected sum(LightingGroup/FractionofUnitsInLocation) for Location="garage" to be less than or equal to 1</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[LightingGroup]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Lighting/h:LightingGroup[h:LightingType[h:LightEmittingDiode | h:CompactFluorescent | h:FluorescentTube] and h:Location[text()="interior" or text()="exterior" or text()="garage"]]'>
      <sch:assert role='ERROR' test='count(h:FractionofUnitsInLocation) = 1'>Expected 1 element(s) for xpath: FractionofUnitsInLocation</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[CeilingFan]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Lighting/h:CeilingFan'>
      <sch:assert role='ERROR' test='count(h:Airflow[h:FanSpeed="medium"]/h:Efficiency) + count(h:LabelEnergyUse) &gt;= 1'>Expected 1 or more element(s) for xpath: Airflow[FanSpeed="medium"]/Efficiency or LabelEnergyUse</sch:assert>
      <sch:assert role='ERROR' test='count(h:Count) = 1'>Expected 1 element(s) for xpath: Count</sch:assert>
    </sch:rule>
  </sch:pattern>

  <!-- Rules below check that the different space types are appropriately enclosed by surfaces -->

  <sch:pattern>
    <sch:title>[AdjacentSurfaces=ConditionedSpace]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure[*/*[h:InteriorAdjacentTo="conditioned space"]]'>
      <sch:assert role='ERROR' test='count(h:Roofs/h:Roof[h:InteriorAdjacentTo="conditioned space"]) + count(h:Floors/h:Floor[h:InteriorAdjacentTo="conditioned space" and (h:ExteriorAdjacentTo="attic - vented" or h:ExteriorAdjacentTo="attic - unvented" or ((h:ExteriorAdjacentTo="other housing unit" or h:ExteriorAdjacentTo="other heated space" or h:ExteriorAdjacentTo="other multifamily buffer space" or h:ExteriorAdjacentTo="other non-freezing space") and h:FloorOrCeiling="ceiling"))]) &gt;= 1'>There must be at least one ceiling or roof adjacent to conditioned space.</sch:assert>
      <sch:assert role='ERROR' test='count(h:Walls/h:Wall[h:InteriorAdjacentTo="conditioned space" and h:ExteriorAdjacentTo="outside"]) &gt;= 1'>There must be at least one exterior wall adjacent to conditioned space.</sch:assert>
      <sch:assert role='ERROR' test='count(h:Slabs/h:Slab[h:InteriorAdjacentTo="conditioned space" or contains(h:InteriorAdjacentTo, "conditioned")]) + count(h:Floors/h:Floor[h:InteriorAdjacentTo="conditioned space" and not(h:ExteriorAdjacentTo="attic - vented" or h:ExteriorAdjacentTo="attic - unvented" or ((h:ExteriorAdjacentTo="other housing unit" or h:ExteriorAdjacentTo="other heated space" or h:ExteriorAdjacentTo="other multifamily buffer space" or h:ExteriorAdjacentTo="other non-freezing space") and h:FloorOrCeiling="ceiling"))]) &gt;= 1'>There must be at least one floor or slab adjacent to conditioned space.</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[AdjacentSurfaces=ConditionedBasement]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure[*/*[h:InteriorAdjacentTo="basement - conditioned" or h:ExteriorAdjacentTo="basement - conditioned"]]'>
      <sch:assert role='ERROR' test='count(h:FoundationWalls/h:FoundationWall[h:InteriorAdjacentTo="basement - conditioned" and h:ExteriorAdjacentTo="ground"]) + count(h:Walls/h:Wall[h:InteriorAdjacentTo="basement - conditioned" and h:ExteriorAdjacentTo="outside"]) &gt;= 1'>There must be at least one exterior wall or foundation wall adjacent to "basement - conditioned".</sch:assert>
      <sch:assert role='ERROR' test='count(h:Slabs/h:Slab[h:InteriorAdjacentTo="basement - conditioned"]) &gt;= 1'>There must be at least one slab adjacent to "basement - conditioned".</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[AdjacentSurfaces=UnconditionedBasement]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure[*/*[h:InteriorAdjacentTo="basement - unconditioned" or h:ExteriorAdjacentTo="basement - unconditioned"]]'>
      <sch:assert role='ERROR' test='count(h:Floors/h:Floor[h:InteriorAdjacentTo="conditioned space" and h:ExteriorAdjacentTo="basement - unconditioned"]) &gt;= 1'>There must be at least one ceiling adjacent to "basement - unconditioned".</sch:assert>
      <sch:assert role='ERROR' test='count(h:FoundationWalls/h:FoundationWall[h:InteriorAdjacentTo="basement - unconditioned" and h:ExteriorAdjacentTo="ground"]) + count(h:Walls/h:Wall[h:InteriorAdjacentTo="basement - unconditioned" and h:ExteriorAdjacentTo="outside"]) &gt;= 1'>There must be at least one exterior wall or foundation wall adjacent to "basement - unconditioned".</sch:assert>
      <sch:assert role='ERROR' test='count(h:Slabs/h:Slab[h:InteriorAdjacentTo="basement - unconditioned"]) &gt;= 1'>There must be at least one slab adjacent to "basement - unconditioned".</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[AdjacentSurfaces=VentedCrawlspace]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure[*/*[h:InteriorAdjacentTo="crawlspace - vented" or h:ExteriorAdjacentTo="crawlspace - vented"]]'>
      <sch:assert role='ERROR' test='count(h:Floors/h:Floor[h:InteriorAdjacentTo="conditioned space" and h:ExteriorAdjacentTo="crawlspace - vented"]) &gt;= 1'>There must be at least one ceiling adjacent to "crawlspace - vented".</sch:assert>
      <sch:assert role='ERROR' test='count(h:FoundationWalls/h:FoundationWall[h:InteriorAdjacentTo="crawlspace - vented" and h:ExteriorAdjacentTo="ground"]) + count(h:Walls/h:Wall[h:InteriorAdjacentTo="crawlspace - vented" and h:ExteriorAdjacentTo="outside"]) &gt;= 1'>There must be at least one exterior wall or foundation wall adjacent to "crawlspace - vented".</sch:assert>
      <sch:assert role='ERROR' test='count(h:Slabs/h:Slab[h:InteriorAdjacentTo="crawlspace - vented"]) &gt;= 1'>There must be at least one slab adjacent to "crawlspace - vented".</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[AdjacentSurfaces=UnventedCrawlspace]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure[*/*[h:InteriorAdjacentTo="crawlspace - unvented" or h:ExteriorAdjacentTo="crawlspace - unvented"]]'>
      <sch:assert role='ERROR' test='count(h:Floors/h:Floor[h:InteriorAdjacentTo="conditioned space" and h:ExteriorAdjacentTo="crawlspace - unvented"]) &gt;= 1'>There must be at least one ceiling adjacent to "crawlspace - unvented".</sch:assert>
      <sch:assert role='ERROR' test='count(h:FoundationWalls/h:FoundationWall[h:InteriorAdjacentTo="crawlspace - unvented" and h:ExteriorAdjacentTo="ground"]) + count(h:Walls/h:Wall[h:InteriorAdjacentTo="crawlspace - unvented" and h:ExteriorAdjacentTo="outside"]) &gt;= 1'>There must be at least one exterior wall or foundation wall adjacent to "crawlspace - unvented".</sch:assert>
      <sch:assert role='ERROR' test='count(h:Slabs/h:Slab[h:InteriorAdjacentTo="crawlspace - unvented"]) &gt;= 1'>There must be at least one slab adjacent to "crawlspace - unvented".</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[AdjacentSurfaces=Garage]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure[*/*[h:InteriorAdjacentTo="garage" or h:ExteriorAdjacentTo="garage"]]'>
      <sch:assert role='ERROR' test='count(h:Roofs/h:Roof[h:InteriorAdjacentTo="garage"]) + count(h:Floors/h:Floor[h:InteriorAdjacentTo="garage" or h:ExteriorAdjacentTo="garage"]) &gt;= 1'>There must be at least one roof or ceiling adjacent to "garage".</sch:assert>
      <sch:assert role='ERROR' test='count(h:Walls/h:Wall[h:InteriorAdjacentTo="garage" and h:ExteriorAdjacentTo="outside"]) + count(h:FoundationWalls/h:FoundationWall[h:InteriorAdjacentTo="garage" and h:ExteriorAdjacentTo="ground"]) &gt;= 1'>There must be at least one exterior wall or foundation wall adjacent to "garage".</sch:assert>
      <sch:assert role='ERROR' test='count(h:Slabs/h:Slab[h:InteriorAdjacentTo="garage"]) &gt;= 1'>There must be at least one slab adjacent to "garage".</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[AdjacentSurfaces=VentedAttic]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure[*/*[h:InteriorAdjacentTo="attic - vented" or h:ExteriorAdjacentTo="attic - vented"]]'>
      <sch:assert role='ERROR' test='count(h:Roofs/h:Roof[h:InteriorAdjacentTo="attic - vented"]) &gt;= 1'>There must be at least one roof adjacent to "attic - vented".</sch:assert>
      <sch:assert role='ERROR' test='count(h:Floors/h:Floor[h:InteriorAdjacentTo="attic - vented" or h:ExteriorAdjacentTo="attic - vented"]) &gt;= 1'>There must be at least one floor adjacent to "attic - vented".</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[AdjacentSurfaces=UnventedAttic]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure[*/*[h:InteriorAdjacentTo="attic - unvented" or h:ExteriorAdjacentTo="attic - unvented"]]'>
      <sch:assert role='ERROR' test='count(h:Roofs/h:Roof[h:InteriorAdjacentTo="attic - unvented"]) &gt;= 1'>There must be at least one roof adjacent to "attic - unvented".</sch:assert>
      <sch:assert role='ERROR' test='count(h:Floors/h:Floor[h:InteriorAdjacentTo="attic - unvented" or h:ExteriorAdjacentTo="attic - unvented"]) &gt;= 1'>There must be at least one floor adjacent to "attic - unvented".</sch:assert>
    </sch:rule>
  </sch:pattern>

  <!-- Rules below check that the specified appliance, water heater, or duct location exists in the building -->

  <sch:pattern>
    <sch:title>[LocationCheck=ConditionedBasement]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails[h:Appliances/*[h:Location="basement - conditioned"] | h:Systems/*/*[h:Location="basement - conditioned"] | h:Systems/*/*/*/*/*[h:DuctLocation="basement - conditioned"]]'>
      <sch:assert role='ERROR' test='count(h:Enclosure/*/*[h:InteriorAdjacentTo="basement - conditioned" or h:ExteriorAdjacentTo="basement - conditioned"]) &gt;= 1'>A location is specified as "basement - conditioned" but no surfaces were found adjacent to this space type.</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[LocationCheck=UnconditionedBasement]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails[h:Appliances/*[h:Location="basement - unconditioned"] | h:Systems/*/*[h:Location="basement - unconditioned"] | h:Systems/*/*/*/*/*[h:DuctLocation="basement - unconditioned"]]'>
      <sch:assert role='ERROR' test='count(h:Enclosure/*/*[h:InteriorAdjacentTo="basement - unconditioned" or h:ExteriorAdjacentTo="basement - unconditioned"]) &gt;= 1'>A location is specified as "basement - unconditioned" but no surfaces were found adjacent to this space type.</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[LocationCheck=VentedCrawlspace]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails[h:Appliances/*[h:Location="crawlspace - vented"] | h:Systems/*/*[h:Location="crawlspace - vented"] | h:Systems/*/*/*/*/*[h:DuctLocation="crawlspace - vented"]]'>
      <sch:assert role='ERROR' test='count(h:Enclosure/*/*[h:InteriorAdjacentTo="crawlspace - vented" or h:ExteriorAdjacentTo="crawlspace - vented"]) &gt;= 1'>A location is specified as "crawlspace - vented" but no surfaces were found adjacent to this space type.</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[LocationCheck=UnventedCrawlspace]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails[h:Appliances/*[h:Location="crawlspace - unvented"] | h:Systems/*/*[h:Location="crawlspace - unvented"] | h:Systems/*/*/*/*/*[h:DuctLocation="crawlspace - unvented"]]'>
      <sch:assert role='ERROR' test='count(h:Enclosure/*/*[h:InteriorAdjacentTo="crawlspace - unvented" or h:ExteriorAdjacentTo="crawlspace - unvented"]) &gt;= 1'>A location is specified as "crawlspace - unvented" but no surfaces were found adjacent to this space type.</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[LocationCheck=Garage]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails[h:Appliances/*[h:Location="garage"] | h:Systems/*/*[h:Location="garage"] | h:Systems/*/*/*/*/*[h:DuctLocation="garage"]]'>
      <sch:assert role='ERROR' test='count(h:Enclosure/*/*[h:InteriorAdjacentTo="garage" or h:ExteriorAdjacentTo="garage"]) &gt;= 1'>A location is specified as "garage" but no surfaces were found adjacent to this space type.</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[LocationCheck=VentedAttic]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails[h:Appliances/*[h:Location="attic - vented"] | h:Systems/*/*[h:Location="attic - vented"] | h:Systems/*/*/*/*/*[h:DuctLocation="attic - vented"]]'>
      <sch:assert role='ERROR' test='count(h:Enclosure/*/*[h:InteriorAdjacentTo="attic - vented" or h:ExteriorAdjacentTo="attic - vented"]) &gt;= 1'>A location is specified as "attic - vented" but no surfaces were found adjacent to this space type.</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[LocationCheck=UnventedAttic]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails[h:Appliances/*[h:Location="attic - unvented"] | h:Systems/*/*[h:Location="attic - unvented"] | h:Systems/*/*/*/*/*[h:DuctLocation="attic - unvented"]]'>
      <sch:assert role='ERROR' test='count(h:Enclosure/*/*[h:InteriorAdjacentTo="attic - unvented" or h:ExteriorAdjacentTo="attic - unvented"]) &gt;= 1'>A location is specified as "attic - unvented" but no surfaces were found adjacent to this space type.</sch:assert>
    </sch:rule>
  </sch:pattern>

  <!-- Rules below check for the appropriate building type when there are objects referencing SFA/MF locations -->

  <sch:pattern>
    <sch:title>[BuildingTypeCheck=OtherHousingUnit]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails[h:Appliances/*[h:Location="other housing unit"] | h:Systems/*/*[h:Location="other housing unit"] | h:Systems/*/*/*/*/*[h:DuctLocation="other housing unit"] | h:Enclosure[*/*[h:InteriorAdjacentTo="other housing unit" or h:ExteriorAdjacentTo="other housing unit"]]]'>
      <sch:assert role='ERROR' test='h:BuildingSummary/h:BuildingConstruction/h:ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"] or not(h:BuildingSummary/h:BuildingConstruction/h:ResidentialFacilityType)'>There are references to "other housing unit" but ResidentialFacilityType is not "single-family attached" or "apartment unit".</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[BuildingTypeCheck=OtherHeatedSpace]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails[h:Appliances/*[h:Location="other heated space"] | h:Systems/*/*[h:Location="other heated space"] | h:Systems/*/*/*/*/*[h:DuctLocation="other heated space"] | h:Enclosure[*/*[h:InteriorAdjacentTo="other heated space" or h:ExteriorAdjacentTo="other heated space"]]]'>
      <sch:assert role='ERROR' test='h:BuildingSummary/h:BuildingConstruction/h:ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"] or not(h:BuildingSummary/h:BuildingConstruction/h:ResidentialFacilityType)'>There are references to "other heated space" but ResidentialFacilityType is not "single-family attached" or "apartment unit".</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[BuildingTypeCheck=OtherMultifamilyBufferSpace]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails[h:Appliances/*[h:Location="other multifamily buffer space"] | h:Systems/*/*[h:Location="other multifamily buffer space"] | h:Systems/*/*/*/*/*[h:DuctLocation="other multifamily buffer space"] | h:Enclosure[*/*[h:InteriorAdjacentTo="other multifamily buffer space" or h:ExteriorAdjacentTo="other multifamily buffer space"]]]'>
      <sch:assert role='ERROR' test='h:BuildingSummary/h:BuildingConstruction/h:ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"] or not(h:BuildingSummary/h:BuildingConstruction/h:ResidentialFacilityType)'>There are references to "other multifamily buffer space" but ResidentialFacilityType is not "single-family attached" or "apartment unit".</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[BuildingTypeCheck=OtherNonFreezingSpace]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails[h:Appliances/*[h:Location="other non-freezing space"] | h:Systems/*/*[h:Location="other non-freezing space"] | h:Systems/*/*/*/*/*[h:DuctLocation="other non-freezing space"] | h:Enclosure[*/*[h:InteriorAdjacentTo="other non-freezing space" or h:ExteriorAdjacentTo="other non-freezing space"]]]'>
      <sch:assert role='ERROR' test='h:BuildingSummary/h:BuildingConstruction/h:ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"] or not(h:BuildingSummary/h:BuildingConstruction/h:ResidentialFacilityType)'>There are references to "other non-freezing space" but ResidentialFacilityType is not "single-family attached" or "apartment unit".</sch:assert>
    </sch:rule>
  </sch:pattern>

</sch:schema>