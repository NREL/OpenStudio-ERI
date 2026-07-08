# frozen_string_literal: true

OpenStudio::Logger.instance.standardOutLogger.setLogLevel(OpenStudio::Fatal)

Dir["#{File.dirname(__FILE__)}/hpxml-measures/HPXMLtoOpenStudio/resources/*.rb"].each do |resource_file|
  next if resource_file.include? 'minitest_helper.rb'

  require resource_file
end

def copy_test_hpxmls
  # Copy ASHRAE 140 files
  FileUtils.rm_f(Dir.glob('workflow/tests/RESNET_Tests/4.1_Standard_140/*.xml'))
  FileUtils.cp(Dir.glob('hpxml-measures/workflow/tests/ASHRAE_Standard_140/*.xml'), 'workflow/tests/RESNET_Tests/4.1_Standard_140')

  # Copy HERS HVAC files
  FileUtils.rm_f(Dir.glob('workflow/tests/RESNET_Tests/4.4_HVAC/*.xml'))
  FileUtils.cp(Dir.glob('hpxml-measures/workflow/tests/HERS_HVAC/*.xml'), 'workflow/tests/RESNET_Tests/4.4_HVAC')

  # Copy HERS DSE files
  FileUtils.rm_f(Dir.glob('workflow/tests/RESNET_Tests/4.5_DSE/*.xml'))
  FileUtils.cp(Dir.glob('hpxml-measures/workflow/tests/HERS_DSE/*.xml'), 'workflow/tests/RESNET_Tests/4.5_DSE')

  # Copy HERS Hot Water files
  FileUtils.rm_f(Dir.glob('workflow/tests/RESNET_Tests/4.6_Hot_Water/*.xml'))
  FileUtils.cp(Dir.glob('hpxml-measures/workflow/tests/HERS_Hot_Water/*.xml'), 'workflow/tests/RESNET_Tests/4.6_Hot_Water')
end

def create_sample_hpxmls
  # Copy sample files from hpxml-measures subtree
  puts 'Copying sample files from OS-HPXML...'
  FileUtils.rm_f(Dir.glob('workflow/sample_files/*.xml'))

  # Copy files we're interested in
  include_list = ['base.xml',
                  'base-appliances-dehumidifier.xml',
                  'base-appliances-dehumidifier-ef-portable.xml',
                  'base-appliances-dehumidifier-ef-whole-home.xml',
                  'base-appliances-dehumidifier-multiple.xml',
                  'base-appliances-gas.xml',
                  'base-appliances-modified.xml',
                  'base-appliances-none.xml',
                  'base-appliances-oil.xml',
                  'base-appliances-propane.xml',
                  'base-appliances-wood.xml',
                  'base-atticroof-cathedral.xml',
                  'base-atticroof-conditioned.xml',
                  'base-atticroof-flat.xml',
                  'base-atticroof-radiant-barrier.xml',
                  'base-atticroof-unvented-insulated-roof.xml',
                  'base-atticroof-vented.xml',
                  'base-battery.xml',
                  'base-bldgtype-mf-unit.xml',
                  'base-bldgtype-mf-unit-adjacent-to-multiple.xml',
                  'base-bldgtype-mf-unit-shared-boiler-only-baseboard.xml',
                  'base-bldgtype-mf-unit-shared-boiler-only-fan-coil.xml',
                  'base-bldgtype-mf-unit-shared-boiler-only-fan-coil-ducted.xml',
                  'base-bldgtype-mf-unit-shared-boiler-only-water-loop-heat-pump.xml',
                  'base-bldgtype-mf-unit-shared-chiller-only-baseboard.xml',
                  'base-bldgtype-mf-unit-shared-chiller-only-fan-coil.xml',
                  'base-bldgtype-mf-unit-shared-chiller-only-fan-coil-ducted.xml',
                  'base-bldgtype-mf-unit-shared-chiller-only-water-loop-heat-pump.xml',
                  'base-bldgtype-mf-unit-shared-cooling-tower-only-water-loop-heat-pump.xml',
                  'base-bldgtype-mf-unit-shared-generator.xml',
                  'base-bldgtype-mf-unit-shared-ground-loop-ground-to-air-heat-pump.xml',
                  'base-bldgtype-mf-unit-shared-laundry-room.xml',
                  'base-bldgtype-mf-unit-shared-laundry-room-multiple-water-heaters.xml',
                  'base-bldgtype-mf-unit-shared-mechvent.xml',
                  'base-bldgtype-mf-unit-shared-mechvent-preconditioning.xml',
                  'base-bldgtype-mf-unit-shared-pv.xml',
                  'base-bldgtype-mf-unit-shared-pv-battery.xml',
                  'base-bldgtype-mf-unit-shared-water-heater.xml',
                  'base-bldgtype-mf-unit-shared-water-heater-heat-pump.xml',
                  'base-bldgtype-mf-unit-shared-water-heater-recirc.xml',
                  'base-bldgtype-sfa-unit.xml',
                  'base-dhw-combi-tankless.xml',
                  'base-dhw-desuperheater.xml',
                  'base-dhw-dwhr.xml',
                  'base-dhw-indirect-standbyloss.xml',
                  'base-dhw-jacket-gas.xml',
                  'base-dhw-jacket-hpwh.xml',
                  'base-dhw-jacket-indirect.xml',
                  'base-dhw-low-flow-fixtures.xml',
                  'base-dhw-multiple.xml',
                  'base-dhw-none.xml',
                  'base-dhw-recirc-demand.xml',
                  'base-dhw-solar-fraction.xml',
                  'base-dhw-solar-indirect-flat-plate.xml',
                  'base-dhw-tank-elec-ef.xml',
                  'base-dhw-tank-gas-ef.xml',
                  'base-dhw-tank-heat-pump-ef.xml',
                  'base-dhw-tank-heat-pump-confined-space.xml',
                  'base-dhw-tankless-electric-ef.xml',
                  'base-dhw-tankless-gas-ef.xml',
                  'base-dhw-tankless-propane.xml',
                  'base-dhw-tank-oil.xml',
                  'base-dhw-tank-wood.xml',
                  'base-enclosure-2stories.xml',
                  'base-enclosure-2stories-garage.xml',
                  'base-enclosure-beds-1.xml',
                  'base-enclosure-beds-2.xml',
                  'base-enclosure-beds-4.xml',
                  'base-enclosure-beds-5.xml',
                  'base-enclosure-ceilingtypes.xml',
                  'base-enclosure-floortypes.xml',
                  'base-enclosure-garage.xml',
                  'base-enclosure-infil-ach-house-pressure.xml',
                  'base-enclosure-infil-cfm50.xml',
                  'base-enclosure-infil-cfm-house-pressure.xml',
                  'base-enclosure-infil-ela.xml',
                  'base-enclosure-infil-natural-ach.xml',
                  'base-enclosure-infil-natural-cfm.xml',
                  'base-enclosure-overhangs.xml',
                  'base-enclosure-skylights.xml',
                  'base-enclosure-skylights-cathedral.xml',
                  'base-enclosure-walltypes.xml',
                  'base-foundation-ambient.xml',
                  'base-foundation-basement-garage.xml',
                  'base-foundation-conditioned-basement-slab-insulation.xml',
                  'base-foundation-conditioned-basement-wall-insulation.xml',
                  'base-foundation-multiple.xml',
                  'base-foundation-slab.xml',
                  'base-foundation-unconditioned-basement.xml',
                  'base-foundation-unconditioned-basement-assembly-r.xml',
                  'base-foundation-unconditioned-basement-wall-insulation.xml',
                  'base-foundation-unvented-crawlspace.xml',
                  'base-foundation-vented-crawlspace.xml',
                  'base-foundation-vented-crawlspace-above-grade.xml',
                  'base-foundation-walkout-basement.xml',
                  'base-hvac-air-to-air-heat-pump-1-speed.xml',
                  'base-hvac-air-to-air-heat-pump-1-speed-cooling-only.xml',
                  'base-hvac-air-to-air-heat-pump-1-speed-heating-only.xml',
                  'base-hvac-air-to-air-heat-pump-1-speed-lockout-temperatures.xml',
                  'base-hvac-air-to-air-heat-pump-1-speed-seer-hspf.xml',
                  'base-hvac-air-to-air-heat-pump-2-speed.xml',
                  'base-hvac-air-to-air-heat-pump-var-speed.xml',
                  'base-hvac-boiler-elec-only.xml',
                  'base-hvac-boiler-gas-only.xml',
                  'base-hvac-boiler-oil-only.xml',
                  'base-hvac-boiler-propane-only.xml',
                  'base-hvac-central-ac-only-1-speed.xml',
                  'base-hvac-central-ac-only-1-speed-seer.xml',
                  'base-hvac-central-ac-only-2-speed.xml',
                  'base-hvac-central-ac-only-var-speed.xml',
                  'base-hvac-central-ac-plus-air-to-air-heat-pump-heating.xml',
                  'base-hvac-dse.xml',
                  'base-hvac-ducts-areas.xml',
                  'base-hvac-ducts-leakage-cfm50.xml',
                  'base-hvac-ducts-buried.xml',
                  'base-hvac-dual-fuel-air-to-air-heat-pump-1-speed.xml',
                  'base-hvac-elec-resistance-only.xml',
                  'base-hvac-evap-cooler-only.xml',
                  'base-hvac-evap-cooler-only-ducted.xml',
                  'base-hvac-fan-motor-type.xml',
                  'base-hvac-fireplace-wood-only.xml',
                  'base-hvac-floor-furnace-propane-only.xml',
                  'base-hvac-furnace-elec-only.xml',
                  'base-hvac-furnace-gas-only.xml',
                  'base-hvac-furnace-gas-plus-air-to-air-heat-pump-cooling.xml',
                  'base-hvac-ground-to-air-heat-pump-1-speed.xml', # FUTURE: Add 2/var-speed files when OS-HPXML modeling reflects it
                  'base-hvac-ground-to-air-heat-pump-cooling-only.xml',
                  'base-hvac-ground-to-air-heat-pump-heating-only.xml',
                  'base-hvac-install-quality-air-to-air-heat-pump-1-speed.xml',
                  'base-hvac-install-quality-furnace-gas-central-ac-1-speed.xml',
                  'base-hvac-install-quality-ground-to-air-heat-pump-1-speed.xml',
                  'base-hvac-install-quality-mini-split-air-conditioner-only-ducted.xml',
                  'base-hvac-install-quality-mini-split-heat-pump-ducted.xml',
                  'base-hvac-mini-split-air-conditioner-only-ducted.xml',
                  'base-hvac-mini-split-air-conditioner-only-ductless.xml',
                  'base-hvac-mini-split-heat-pump-ducted.xml',
                  'base-hvac-mini-split-heat-pump-ducted-cooling-only.xml',
                  'base-hvac-mini-split-heat-pump-ducted-heating-only.xml',
                  'base-hvac-mini-split-heat-pump-ductless.xml',
                  'base-hvac-multiple.xml',
                  'base-hvac-none.xml',
                  'base-hvac-space-heater-gas-only.xml',
                  'base-hvac-ptac.xml',
                  'base-hvac-ptac-with-heating-electricity.xml',
                  'base-hvac-ptac-with-heating-natural-gas.xml',
                  'base-hvac-pthp.xml',
                  'base-hvac-room-ac-only.xml',
                  'base-hvac-room-ac-only-eer.xml',
                  'base-hvac-room-ac-with-heating.xml',
                  'base-hvac-room-ac-with-reverse-cycle.xml',
                  'base-hvac-stove-wood-pellets-only.xml',
                  'base-hvac-undersized.xml',
                  'base-hvac-wall-furnace-elec-only.xml',
                  'base-lighting-ceiling-fans.xml',
                  'base-lighting-ceiling-fans-label-energy-use.xml',
                  'base-location-baltimore-md.xml',
                  'base-location-capetown-zaf.xml',
                  'base-location-dallas-tx.xml',
                  'base-location-duluth-mn.xml',
                  'base-location-helena-mt.xml',
                  'base-location-honolulu-hi.xml',
                  'base-location-miami-fl.xml',
                  'base-location-phoenix-az.xml',
                  'base-location-portland-or.xml',
                  'base-mechvent-balanced.xml',
                  'base-mechvent-cfis.xml',
                  'base-mechvent-cfis-control-type-timer.xml',
                  'base-mechvent-cfis-no-additional-runtime.xml',
                  'base-mechvent-cfis-no-outdoor-air-control.xml',
                  'base-mechvent-cfis-supplemental-fan-exhaust.xml',
                  'base-mechvent-cfis-supplemental-fan-exhaust-synchronized.xml',
                  'base-mechvent-erv.xml',
                  'base-mechvent-erv-atre-asre.xml',
                  'base-mechvent-exhaust.xml',
                  'base-mechvent-hrv.xml',
                  'base-mechvent-hrv-asre.xml',
                  'base-mechvent-multiple.xml',
                  'base-mechvent-supply.xml',
                  'base-mechvent-whole-house-fan.xml',
                  'base-misc-bills.xml',
                  'base-misc-bills-detailed-only.xml',
                  'base-misc-bills-pv.xml',
                  'base-misc-bills-pv-detailed-only.xml',
                  'base-misc-bills-pv-mixed.xml',
                  'base-misc-generators.xml',
                  'base-pv.xml',
                  'base-pv-battery.xml']
  include_list.each do |include_file|
    if File.exist? "hpxml-measures/workflow/sample_files/#{include_file}"
      FileUtils.cp("hpxml-measures/workflow/sample_files/#{include_file}", "workflow/sample_files/#{include_file}")
    else
      puts "Warning: Included file hpxml-measures/workflow/sample_files/#{include_file} not found."
    end
  end

  # Update HPXMLs as needed
  puts 'Updating HPXML inputs for OS-ERI...'
  Dir['workflow/sample_files/*.xml'].each do |hpxml_path|
    next unless File.file? hpxml_path

    hpxml = HPXML.new(hpxml_path: hpxml_path)
    hpxml_bldg = hpxml.buildings[0]

    # Handle different inputs for ERI

    hpxml.header.eri_calculation_versions = ['latest']
    hpxml.header.co2index_calculation_versions = ['latest']
    hpxml.header.iecc_eri_calculation_versions = [IECC::AllVersions[-1]]
    hpxml.header.utility_bill_scenarios.clear unless hpxml_path.include? 'misc-bills'
    hpxml.header.utility_bill_scenarios.each do |bill_scenario|
      next if bill_scenario.elec_tariff_filepath.nil?

      bill_scenario.elec_tariff_filepath = File.join('..', '..', 'hpxml-measures', 'ReportUtilityBills', 'resources', 'detailed_rates', File.basename(bill_scenario.elec_tariff_filepath))
    end
    hpxml.header.timestep = nil
    hpxml_bldg.site.site_type = nil
    hpxml_bldg.site.surroundings = nil
    hpxml_bldg.site.vertical_surroundings = nil
    hpxml_bldg.site.shielding_of_home = nil
    hpxml_bldg.site.orientation_of_front_of_home = nil
    hpxml_bldg.site.azimuth_of_front_of_home = nil
    hpxml_bldg.site.ground_conductivity = nil
    hpxml_bldg.building_construction.number_of_units_in_building = nil
    hpxml_bldg.building_construction.number_of_bathrooms = nil
    hpxml_bldg.air_infiltration_measurements.each do |measurement|
      measurement.infiltration_type = nil
      if measurement.infiltration_volume.nil?
        measurement.infiltration_volume = hpxml_bldg.building_construction.conditioned_building_volume
      end
    end
    hpxml_bldg.building_construction.conditioned_building_volume = nil
    hpxml_bldg.building_construction.average_ceiling_height = nil
    hpxml_bldg.building_construction.unit_height_above_grade = nil
    hpxml_bldg.attics.each do |attic|
      if attic.attic_type == HPXML::AtticTypeVented
        attic.vented_attic_sla = 0.003 if attic.vented_attic_sla.nil?
      end
      if [HPXML::AtticTypeVented,
          HPXML::AtticTypeUnvented].include? attic.attic_type
        attic.within_infiltration_volume = false if attic.within_infiltration_volume.nil?
      end
    end
    hpxml_bldg.foundations.each do |foundation|
      if foundation.foundation_type == HPXML::FoundationTypeCrawlspaceVented
        foundation.vented_crawlspace_sla = 0.00667 if foundation.vented_crawlspace_sla.nil?
      end
      next unless [HPXML::FoundationTypeBasementUnconditioned,
                   HPXML::FoundationTypeCrawlspaceUnvented,
                   HPXML::FoundationTypeCrawlspaceVented].include? foundation.foundation_type

      foundation.within_infiltration_volume = false if foundation.within_infiltration_volume.nil?
    end
    hpxml_bldg.roofs.each do |roof|
      roof.roof_type = nil
      roof.interior_finish_type = nil
      roof.interior_finish_thickness = nil
      if roof.radiant_barrier && roof.radiant_barrier_grade.nil?
        roof.radiant_barrier_grade = 2
      end
      roof.roof_color = nil
      roof.solar_absorptance = 0.7
      roof.emittance = 0.92
    end
    (hpxml_bldg.rim_joists + hpxml_bldg.walls).each do |wall_or_rim_joist|
      wall_or_rim_joist.siding = nil
      wall_or_rim_joist.color = nil
      if wall_or_rim_joist.is_exterior
        wall_or_rim_joist.solar_absorptance = 0.7 if wall_or_rim_joist.solar_absorptance.nil?
        wall_or_rim_joist.emittance = 0.92 if wall_or_rim_joist.emittance.nil?
      else
        wall_or_rim_joist.solar_absorptance = nil
        wall_or_rim_joist.emittance = nil
      end
      next unless wall_or_rim_joist.is_a? HPXML::Wall

      wall_or_rim_joist.attic_wall_type = nil
      wall_or_rim_joist.interior_finish_type = nil
      wall_or_rim_joist.interior_finish_thickness = nil
    end
    hpxml_bldg.floors.each do |floor|
      floor.interior_finish_type = nil
      floor.interior_finish_thickness = nil
      next if [HPXML::LocationOtherHousingUnit,
               HPXML::LocationOtherHeatedSpace,
               HPXML::LocationOtherMultifamilyBufferSpace,
               HPXML::LocationOtherNonFreezingSpace].include? floor.exterior_adjacent_to

      floor.floor_or_ceiling = nil
    end
    hpxml_bldg.foundation_walls.each do |fwall|
      fwall.interior_finish_type = nil
      fwall.interior_finish_thickness = nil
      fwall.insulation_interior_distance_to_top = 0 if fwall.insulation_interior_distance_to_top.nil?
      if fwall.insulation_interior_distance_to_bottom.nil?
        if fwall.insulation_interior_r_value.to_f > 0
          fwall.insulation_interior_distance_to_bottom = fwall.height
        else
          fwall.insulation_interior_distance_to_bottom = 0
        end
      end
      fwall.insulation_exterior_distance_to_top = 0 if fwall.insulation_exterior_distance_to_top.nil?
      if fwall.insulation_exterior_distance_to_bottom.nil?
        if fwall.insulation_exterior_r_value.to_f > 0
          fwall.insulation_exterior_distance_to_bottom = fwall.height
        else
          fwall.insulation_exterior_distance_to_bottom = 0
        end
      end
    end
    hpxml_bldg.slabs.each do |slab|
      if slab.carpet_fraction.nil?
        slab.carpet_fraction = 0.0
      end
      if slab.carpet_r_value.nil?
        slab.carpet_r_value = 0.0
      end
    end
    hpxml_bldg.windows.each do |window|
      window.interior_shading_factor_winter = nil
      window.interior_shading_factor_summer = nil
      window.interior_shading_type = nil
    end
    hpxml_bldg.cooling_systems.each do |cooling_system|
      cooling_system.primary_system = nil
    end
    hpxml_bldg.heating_systems.each do |heating_system|
      heating_system.primary_system = nil
      heating_system.pilot_light = nil
      next unless heating_system.heating_system_type == HPXML::HVACTypeBoiler
      next unless heating_system.is_shared_system.nil?

      heating_system.is_shared_system = false
    end
    hpxml_bldg.heat_pumps.each do |heat_pump|
      heat_pump.primary_heating_system = nil
      heat_pump.primary_cooling_system = nil
      next unless heat_pump.heat_pump_type == HPXML::HVACTypeHeatPumpGroundToAir

      heat_pump.compressor_type = nil # FUTURE: Eventually remove this when OS-HPXML modeling reflects it

      next unless heat_pump.is_shared_system.nil?

      heat_pump.is_shared_system = false
    end
    hpxml_bldg.water_heating_systems.each do |water_heating_system|
      water_heating_system.temperature = nil
      water_heating_system.is_shared_system = false if water_heating_system.is_shared_system.nil?
      if water_heating_system.water_heater_type == HPXML::WaterHeaterTypeHeatPump
        water_heating_system.hpwh_confined_space_without_mitigation = false if water_heating_system.hpwh_confined_space_without_mitigation.nil?
      end
    end
    hpxml_bldg.water_fixtures.each do |water_fixture|
      water_fixture.count = nil
      next unless water_fixture.low_flow.nil?

      water_fixture.low_flow = (water_fixture.flow_rate <= 2)
      water_fixture.flow_rate = nil
    end
    shared_water_heaters = hpxml_bldg.water_heating_systems.select { |wh| wh.is_shared_system }
    if not hpxml_bldg.clothes_washers.empty?
      if hpxml_bldg.clothes_washers[0].is_shared_appliance
        hpxml_bldg.clothes_washers[0].number_of_units_served = shared_water_heaters[0].number_of_bedrooms_served / hpxml_bldg.building_construction.number_of_bedrooms
        hpxml_bldg.clothes_washers[0].count = 2
      else
        hpxml_bldg.clothes_washers[0].is_shared_appliance = false
      end
    end
    if not hpxml_bldg.clothes_dryers.empty?
      if hpxml_bldg.clothes_dryers[0].is_vented.nil?
        hpxml_bldg.clothes_dryers[0].is_vented = (![HPXML::DryingMethodCondensing, HPXML::DryingMethodHeatPump].include? hpxml_bldg.clothes_dryers[0].drying_method)
        hpxml_bldg.clothes_dryers[0].drying_method = nil
      end
      if hpxml_bldg.clothes_dryers[0].is_shared_appliance
        hpxml_bldg.clothes_dryers[0].number_of_units_served = shared_water_heaters[0].number_of_bedrooms_served / hpxml_bldg.building_construction.number_of_bedrooms
        hpxml_bldg.clothes_dryers[0].count = 2
      else
        hpxml_bldg.clothes_dryers[0].is_shared_appliance = false
      end
    end
    if not hpxml_bldg.dishwashers.empty?
      if not hpxml_bldg.dishwashers[0].is_shared_appliance
        hpxml_bldg.dishwashers[0].is_shared_appliance = false
      end
    end
    hpxml_bldg.ventilation_fans.each do |ventilation_fan|
      ventilation_fan.count = nil
      next unless ventilation_fan.used_for_whole_building_ventilation

      ventilation_fan.is_shared_system = false if ventilation_fan.is_shared_system.nil?

      if ventilation_fan.is_shared_system
        ventilation_fan.rated_flow_rate = ventilation_fan.rated_flow_rate.to_f + ventilation_fan.delivered_ventilation.to_f if ventilation_fan.tested_flow_rate.nil?
        ventilation_fan.tested_flow_rate = nil
        ventilation_fan.delivered_ventilation = nil
      else
        ventilation_fan.tested_flow_rate = ventilation_fan.rated_flow_rate.to_f + ventilation_fan.delivered_ventilation.to_f if ventilation_fan.tested_flow_rate.nil?
        ventilation_fan.rated_flow_rate = nil
        ventilation_fan.delivered_ventilation = nil
      end
      ventilation_fan.cfis_vent_mode_airflow_fraction = nil
      if ventilation_fan.fan_type == HPXML::MechVentTypeCFIS
        ventilation_fan.fan_power = nil
        if ventilation_fan.cfis_has_outdoor_air_control.nil?
          ventilation_fan.cfis_has_outdoor_air_control = true
        end
        if ventilation_fan.cfis_control_type.nil?
          ventilation_fan.cfis_control_type = HPXML::CFISControlTypeOptimized
        end
      end
      next if ventilation_fan.is_cfis_supplemental_fan

      if ventilation_fan.hours_in_operation.nil?
        if ventilation_fan.fan_type == HPXML::MechVentTypeCFIS
          ventilation_fan.hours_in_operation = 8.0
        else
          ventilation_fan.hours_in_operation = 24.0
        end
      end
    end
    hpxml_bldg.ventilation_fans.reverse_each do |ventilation_fan|
      next if ventilation_fan.used_for_whole_building_ventilation
      next if ventilation_fan.used_for_seasonal_cooling_load_reduction

      ventilation_fan.delete
    end
    hpxml_bldg.plug_loads.clear
    hpxml_bldg.fuel_loads.clear
    hpxml_bldg.heating_systems.each do |heating_system|
      heating_system.electric_auxiliary_energy = nil
      next unless [HPXML::HVACTypeFurnace].include? heating_system.heating_system_type

      if heating_system.fan_watts_per_cfm.nil?
        heating_system.fan_watts_per_cfm = 0.58
      end
      if heating_system.airflow_defect_ratio.nil?
        heating_system.airflow_defect_ratio = -0.25
      end
    end
    hpxml_bldg.cooling_systems.each do |cooling_system|
      next unless [HPXML::HVACTypeCentralAirConditioner,
                   HPXML::HVACTypeMiniSplitAirConditioner].include? cooling_system.cooling_system_type

      if cooling_system.fan_watts_per_cfm.nil?
        cooling_system.fan_watts_per_cfm = 0.58
      end
      if cooling_system.airflow_defect_ratio.nil?
        if not cooling_system.distribution_system_idref.nil?
          cooling_system.airflow_defect_ratio = -0.25
        else
          cooling_system.airflow_defect_ratio = 0.0
        end
      end
      if cooling_system.charge_defect_ratio.nil?
        cooling_system.charge_defect_ratio = -0.25
      end
    end
    hpxml_bldg.heat_pumps.each do |heat_pump|
      heat_pump.backup_heating_lockout_temp = nil
      heat_pump.backup_heating_switchover_temp = nil

      if hpxml_path.include? 'base-hvac-air-to-air-heat-pump-1-speed-lockout-temperatures.xml'
        heat_pump.compressor_lockout_temp = 10.0 # Change from the OS-ERI default of 5F
      end

      if heat_pump.heating_capacity_17F.nil?
        if [HPXML::HVACTypeHeatPumpAirToAir,
            HPXML::HVACTypeHeatPumpMiniSplit,
            HPXML::HVACTypeHeatPumpPTHP,
            HPXML::HVACTypeHeatPumpRoom].include? heat_pump.heat_pump_type
          if not heat_pump.heating_capacity_fraction_17F.nil?
            heat_pump.heating_capacity_17F = (heat_pump.heating_capacity * heat_pump.heating_capacity_fraction_17F).round
          else
            heat_pump.heating_capacity_17F = (heat_pump.heating_capacity * 0.6).round
          end
          heat_pump.heating_capacity_fraction_17F = nil
        end
      end

      next unless [HPXML::HVACTypeHeatPumpAirToAir,
                   HPXML::HVACTypeHeatPumpGroundToAir,
                   HPXML::HVACTypeHeatPumpMiniSplit].include? heat_pump.heat_pump_type

      if heat_pump.fan_watts_per_cfm.nil?
        heat_pump.fan_watts_per_cfm = 0.58
      end
      if heat_pump.airflow_defect_ratio.nil?
        if not heat_pump.distribution_system_idref.nil?
          heat_pump.airflow_defect_ratio = -0.25
        else
          heat_pump.airflow_defect_ratio = 0.0
        end
      end
      if heat_pump.charge_defect_ratio.nil?
        heat_pump.charge_defect_ratio = -0.25
      end
    end
    hpxml_bldg.heating_systems.each do |heating_system|
      next unless heating_system.heating_system_type == HPXML::HVACTypeBoiler
      next unless heating_system.is_shared_system
      next unless heating_system.heating_capacity.nil?

      heating_system.heating_capacity = 300000
    end
    (hpxml_bldg.cooling_systems + hpxml_bldg.heat_pumps).each do |hvac_system|
      next unless hvac_system.cooling_efficiency_eer.nil? && hvac_system.cooling_efficiency_eer2.nil?
      next if hvac_system.cooling_efficiency_seer.nil? && hvac_system.cooling_efficiency_seer2.nil?

      orig_equipment_type = hvac_system.equipment_type
      hvac_system.equipment_type = HPXML::HVACEquipmentTypeSplit
      hvac_system.cooling_efficiency_eer2 = Defaults.get_hvac_eer2(hvac_system)
      if not hvac_system.cooling_efficiency_seer.nil? # Specify EER instead of EER2
        hvac_system.cooling_efficiency_eer = HVAC.calc_eer_from_eer2(hvac_system).round(1)
        hvac_system.cooling_efficiency_eer2 = nil
      else
        hvac_system.cooling_efficiency_eer2 = hvac_system.cooling_efficiency_eer2.round(1)
      end
      hvac_system.equipment_type = orig_equipment_type
    end
    hpxml_bldg.pv_systems.each do |pv_system|
      pv_system.is_shared_system = false if pv_system.is_shared_system.nil?
      pv_system.location = HPXML::LocationRoof if pv_system.location.nil?
      pv_system.module_type = HPXML::PVModuleTypeStandard if pv_system.module_type.nil?
      pv_system.tracking = HPXML::PVTrackingTypeFixed if pv_system.tracking.nil?
      pv_system.system_losses_fraction = 0.14 if pv_system.system_losses_fraction.nil?
      if pv_system.inverter.nil?
        if hpxml_bldg.inverters.empty?
          hpxml_bldg.inverters.add(id: 'Inverter1')
        end
        pv_system.inverter_idref = hpxml_bldg.inverters[0].id
      end
      pv_system.inverter.inverter_efficiency = 0.96 if pv_system.inverter.inverter_efficiency.nil?
    end
    hpxml_bldg.generators.each do |generator|
      generator.is_shared_system = false if generator.is_shared_system.nil?
    end
    hpxml_bldg.batteries.each do |battery|
      battery.is_shared_system = false if battery.is_shared_system.nil?
      battery.location = nil
      battery.round_trip_efficiency = 0.925
      battery.nominal_capacity_kwh = nil
    end
    n_htg_systems = (hpxml_bldg.heating_systems + hpxml_bldg.heat_pumps).select { |h| h.fraction_heat_load_served.to_f > 0 }.size
    n_clg_systems = (hpxml_bldg.cooling_systems + hpxml_bldg.heat_pumps).select { |h| h.fraction_cool_load_served.to_f > 0 }.size
    hpxml_bldg.hvac_distributions.each do |hvac_distribution|
      next unless hvac_distribution.conditioned_floor_area_served.nil?
      next unless hvac_distribution.distribution_system_type == HPXML::HVACDistributionTypeAir
      next unless hvac_distribution.ducts.size > 0

      n_hvac_systems = [n_htg_systems, n_clg_systems].max
      hvac_distribution.conditioned_floor_area_served = hpxml_bldg.building_construction.conditioned_floor_area / n_hvac_systems
    end

    hpxml_bldg.hvac_distributions.each do |hvac_distribution|
      next unless hvac_distribution.number_of_return_registers.nil?
      next unless hvac_distribution.distribution_system_type == HPXML::HVACDistributionTypeAir

      if hvac_distribution.ducts.select { |d| d.duct_type == HPXML::DuctTypeReturn }.size > 0
        hvac_distribution.number_of_return_registers = hpxml_bldg.building_construction.number_of_conditioned_floors.ceil
      elsif hvac_distribution.air_type != HPXML::AirTypeFanCoil
        hvac_distribution.number_of_return_registers = 0
      end
    end
    hpxml_bldg.water_heating_systems.each do |dhw_system|
      next unless dhw_system.tank_volume.nil?

      if dhw_system.water_heater_type == HPXML::WaterHeaterTypeStorage
        if dhw_system.fuel_type == HPXML::FuelTypeElectricity
          dhw_system.tank_volume = 40
        else
          dhw_system.tank_volume = 30
        end
      elsif dhw_system.water_heater_type == HPXML::WaterHeaterTypeHeatPump
        dhw_system.tank_volume = 80
      elsif dhw_system.water_heater_type == HPXML::WaterHeaterTypeCombiStorage
        dhw_system.tank_volume = 50
      end
    end
    # TODO: Allow UsageBin in 301validator and remove code below
    hpxml_bldg.water_heating_systems.each do |dhw_system|
      next if dhw_system.uniform_energy_factor.nil?
      next unless [HPXML::WaterHeaterTypeStorage, HPXML::WaterHeaterTypeHeatPump].include? dhw_system.water_heater_type
      next unless dhw_system.first_hour_rating.nil?

      dhw_system.first_hour_rating = 56.0
    end
    hpxml_bldg.hot_water_distributions.each do |hot_water_distribution|
      if hot_water_distribution.system_type == HPXML::DHWDistTypeStandard
        hot_water_distribution.standard_piping_length = 50.0 if hot_water_distribution.standard_piping_length.nil?
      elsif hot_water_distribution.system_type == HPXML::DHWDistTypeRecirc
        hot_water_distribution.recirculation_piping_loop_length = 50.0 if hot_water_distribution.recirculation_piping_loop_length.nil?
        hot_water_distribution.recirculation_branch_piping_length = 50.0 if hot_water_distribution.recirculation_branch_piping_length.nil?
        hot_water_distribution.recirculation_pump_power = 50.0 if hot_water_distribution.recirculation_pump_power.nil?
      end
    end
    hpxml_bldg.cooking_ranges.each do |cooking_range|
      next unless cooking_range.is_induction.nil?

      cooking_range.is_induction = false
    end
    (hpxml_bldg.clothes_washers +
     hpxml_bldg.clothes_dryers +
     hpxml_bldg.dishwashers +
     hpxml_bldg.refrigerators +
     hpxml_bldg.cooking_ranges).each do |appliance|
      next unless appliance.location.nil?

      appliance.location = HPXML::LocationConditionedSpace
    end
    zip_map = { 'USA_CO_Denver.Intl.AP.725650_TMY3.epw' => '80019',
                'USA_OR_Portland.Intl.AP.726980_TMY3.epw' => '97214',
                'US_CO_Boulder_AMY_2012.epw' => '80305-3447',
                'USA_MD_Baltimore-Washington.Intl.AP.724060_TMY3.epw' => '21221',
                'USA_TX_Dallas-Fort.Worth.Intl.AP.722590_TMY3.epw' => '75014',
                'USA_MN_Duluth.Intl.AP.727450_TMY3.epw' => '55807',
                'USA_MT_Helena.Rgnl.AP.727720_TMY3.epw' => '59602',
                'USA_HI_Honolulu.Intl.AP.911820_TMY3.epw' => '96817',
                'USA_FL_Miami.Intl.AP.722020_TMY3.epw' => '33134',
                'USA_AZ_Phoenix-Sky.Harbor.Intl.AP.722780_TMY3.epw' => '85001',
                'ZAF_Cape.Town.688160_IWEC.epw' => '00000' }
    hpxml_bldg.zip_code = zip_map[hpxml_bldg.climate_and_risk_zones.weather_station_epw_filepath]
    if hpxml_bldg.zip_code.nil?
      fail "#{hpxml_path}: EPW location (#{hpxml_bldg.climate_and_risk_zones.weather_station_epw_filepath}) not handled. Need to update zip_map."
    end

    if hpxml_bldg.climate_and_risk_zones.weather_station_epw_filepath.include? 'TMY3'
      # Test zipcode -> TMY3 lookup
      hpxml_bldg.climate_and_risk_zones.weather_station_id = nil
      hpxml_bldg.climate_and_risk_zones.weather_station_name = nil
      hpxml_bldg.climate_and_risk_zones.weather_station_epw_filepath = nil
    end

    if hpxml_path.include? 'base-location-capetown-zaf'
      if hpxml_bldg.state_code.nil?
        hpxml_bldg.state_code = 'NA'
      end
      hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs.add(year: 2006,
                                                               zone: '3A')
    end

    # Handle different inputs for ENERGY STAR/DENH

    if hpxml_path.include? 'base-bldgtype-mf-unit'
      hpxml.header.denh_calculation_versions = [DENH::MFVersions.select { |v| v.include?('MF') }.max_by { |v| v.scan(/\d+\.\d+/).first.to_f }]
    else
      hpxml.header.denh_calculation_versions = [DENH::SFVersions.select { |v| v.include?('SF') }.max_by { |v| v.scan(/\d+\.\d+/).first.to_f }]
    end
    if hpxml_path.include? 'base-bldgtype-mf-unit'
      hpxml.header.energystar_calculation_versions = [ES::MFVersions.select { |v| v.include?('MF_National') }.max_by { |v| v.scan(/\d+\.\d+/).first.to_f }]
    elsif hpxml_bldg.state_code == 'FL'
      hpxml.header.energystar_calculation_versions = [ES::SFVersions.select { |v| v.include?('SF_Florida') }.max_by { |v| v.scan(/\d+\.\d+/).first.to_f }]
    elsif hpxml_bldg.state_code == 'HI'
      hpxml.header.energystar_calculation_versions = [ES::SFVersions.select { |v| v.include?('SF_Pacific') }.max_by { |v| v.scan(/\d+\.\d+/).first.to_f }]
    elsif hpxml_bldg.state_code == 'OR'
      hpxml.header.energystar_calculation_versions = [ES::SFVersions.select { |v| v.include?('SF_OregonWashington') }.max_by { |v| v.scan(/\d+\.\d+/).first.to_f }]
    else
      hpxml.header.energystar_calculation_versions = [ES::SFVersions.select { |v| v.include?('SF_National') }.max_by { |v| v.scan(/\d+\.\d+/).first.to_f }]
    end
    hpxml_bldg.hvac_systems.each do |hvac_system|
      next if hvac_system.shared_loop_watts.nil?

      hvac_system.shared_loop_motor_efficiency = 0.9
    end
    hpxml_bldg.hot_water_distributions.each do |dhw_dist|
      next if dhw_dist.shared_recirculation_pump_power.nil?

      dhw_dist.shared_recirculation_motor_efficiency = 0.9
    end

    # Drop all thermostat setpoint info
    if not hpxml_bldg.hvac_controls.empty?
      control_type = hpxml_bldg.hvac_controls[0].control_type
      control_type = HPXML::HVACControlTypeManual if control_type.nil?
      control_id = hpxml_bldg.hvac_controls[0].id
      hpxml_bldg.hvac_controls[0].delete
      hpxml_bldg.hvac_controls.add(id: control_id,
                                   control_type: control_type)
    end

    XMLHelper.write_file(hpxml.to_doc, hpxml_path)
  end

  # Create additional files
  puts 'Creating additional HPXML files for OS-ERI...'

  # base-hvac-programmable-thermostat.xml
  hpxml = HPXML.new(hpxml_path: 'workflow/sample_files/base.xml')
  hpxml_bldg = hpxml.buildings[0]
  hpxml_bldg.hvac_controls[0].control_type = HPXML::HVACControlTypeProgrammable
  XMLHelper.write_file(hpxml.to_doc, 'workflow/sample_files/base-hvac-programmable-thermostat.xml')

  major_eri_versions = Constants::ERIVersions.select { |v| "#{v.to_i}" == v }
  latest_major_eri_versions = major_eri_versions.map { |mv| Constants::ERIVersions.select { |v| v.include?(mv) }.last }

  # All versions, single-family
  hpxml = HPXML.new(hpxml_path: 'workflow/sample_files/base.xml')
  hpxml_bldg = hpxml.buildings[0]
  hpxml.header.eri_calculation_versions = latest_major_eri_versions
  hpxml.header.co2index_calculation_versions = latest_major_eri_versions.select { |v| Constants::ERIVersions.index(v) >= Constants::ERIVersions.index('2019ABCD') }
  hpxml.header.iecc_eri_calculation_versions = IECC::AllVersions
  hpxml.header.energystar_calculation_versions = ES::SFVersions.select { |v| ES::NationalVersions.include?(v) }
  hpxml.header.denh_calculation_versions = DENH::SFVersions
  hpxml_bldg.clothes_dryers[0].control_type = HPXML::ClothesDryerControlTypeTimer # Need old input for clothes dryers
  XMLHelper.write_file(hpxml.to_doc, 'workflow/sample_files/base-versions-multiple-sf.xml')

  # All versions, multi-family
  hpxml = HPXML.new(hpxml_path: 'workflow/sample_files/base-bldgtype-mf-unit.xml')
  hpxml_bldg = hpxml.buildings[0]
  hpxml.header.eri_calculation_versions = latest_major_eri_versions
  hpxml.header.co2index_calculation_versions = latest_major_eri_versions.select { |v| Constants::ERIVersions.index(v) >= Constants::ERIVersions.index('2019ABCD') }
  hpxml.header.iecc_eri_calculation_versions = IECC::AllVersions
  hpxml.header.energystar_calculation_versions = ES::MFVersions.select { |v| ES::NationalVersions.include?(v) }
  hpxml.header.denh_calculation_versions = DENH::MFVersions
  hpxml_bldg.clothes_dryers[0].control_type = HPXML::ClothesDryerControlTypeTimer # Need old input for clothes dryers
  XMLHelper.write_file(hpxml.to_doc, 'workflow/sample_files/base-versions-multiple-mf.xml')

  # Additional ENERGY STAR files
  hpxml = HPXML.new(hpxml_path: 'workflow/sample_files/base-bldgtype-mf-unit.xml')
  hpxml_bldg = hpxml.buildings[0]
  hpxml.header.energystar_calculation_versions = [ES::MFVersions.select { |v| v.include?('MF_OregonWashington') }.max_by { |v| v.scan(/\d+\.\d+/).first.to_f }]
  hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs[0].zone = '4C'
  hpxml_bldg.state_code = 'OR'
  hpxml_bldg.zip_code = '97214'
  XMLHelper.write_file(hpxml.to_doc, 'workflow/sample_files/base-bldgtype-mf-unit-location-portland-or.xml')

  # Reformat real_homes HPXMLs
  puts 'Reformatting real_homes HPXMLs...'
  Dir['workflow/real_homes/*.xml'].each do |hpxml_path|
    hpxml = HPXML.new(hpxml_path: hpxml_path)
    hpxml.header.eri_calculation_versions = ['latest']
    hpxml.header.co2index_calculation_versions = ['latest']
    hpxml.header.iecc_eri_calculation_versions = [IECC::AllVersions[-1]]
    hpxml_bldg = hpxml.buildings[0]
    if hpxml_bldg.building_construction.residential_facility_type == HPXML::ResidentialTypeApartment
      hpxml.header.denh_calculation_versions = [DENH::MFVersions.select { |v| v.include?('MF') }.max_by { |v| v.scan(/\d+\.\d+/).first.to_f }]
      hpxml.header.energystar_calculation_versions = [ES::MFVersions.select { |v| v.include?('MF_National') }.max_by { |v| v.scan(/\d+\.\d+/).first.to_f }]
    else
      hpxml.header.denh_calculation_versions = [DENH::SFVersions.select { |v| v.include?('SF') }.max_by { |v| v.scan(/\d+\.\d+/).first.to_f }]
      hpxml.header.energystar_calculation_versions = [ES::SFVersions.select { |v| v.include?('SF_National') }.max_by { |v| v.scan(/\d+\.\d+/).first.to_f }]
    end
    XMLHelper.write_file(hpxml.to_doc, hpxml_path)
  end

  # Reformat test HPXMLS
  puts 'Reformatting test HPXMLs...'
  (Dir['workflow/tests/EPA_Tests/**/*.xml'] + Dir['workflow/tests/RESNET_Tests/**/*.xml']).each do |hpxml_path|
    hpxml = HPXML.new(hpxml_path: hpxml_path)
    XMLHelper.write_file(hpxml.to_doc, hpxml_path)
  end
end

command_list = [
  :update_measures,
  :update_hpxmls,
  :ruleset_tests,
  :sample_files_tests1,
  :sample_files_tests2,
  :real_home_tests,
  :other_tests,
  :create_release_zip
]

def display_usage(command_list)
  puts "Usage: openstudio #{File.basename(__FILE__)} [COMMAND]\nCommands:\n  " + command_list.join("\n  ")
end

if ARGV.size == 0
  puts 'ERROR: Missing command.'
  display_usage(command_list)
  exit!
elsif ARGV.size > 1
  puts 'ERROR: Too many commands.'
  display_usage(command_list)
  exit!
elsif not command_list.include? ARGV[0].to_sym
  puts "ERROR: Invalid command '#{ARGV[0]}'."
  display_usage(command_list)
  exit!
end

if ARGV[0].to_sym == :update_measures
  # Apply rubocop (uses .rubocop.yml)
  commands = ["\"require 'rubocop/rake_task'\"",
              "\"require 'stringio' \"",
              "\"RuboCop::RakeTask.new(:rubocop) do |t| t.options = ['--autocorrect', '--format', 'simple'] end\"",
              '"Rake.application[:rubocop].invoke"']
  command = "\"#{OpenStudio.getOpenStudioCLI}\" -e #{commands.join(' -e ')}"
  puts 'Applying rubocop auto-correct to measures...'
  system(command)

  puts 'Done.'
end

if ARGV[0].to_sym == :update_hpxmls
  require 'oga'
  require_relative 'rulesets/resources/constants'

  t = Time.now
  copy_test_hpxmls
  create_sample_hpxmls
  puts "Completed in #{(Time.now - t).round(1)}s"
end

if [:ruleset_tests, :sample_files_tests1, :sample_files_tests2, :real_home_tests, :other_tests].include? ARGV[0].to_sym
  case ARGV[0].to_sym
  when :ruleset_tests
    tests_rbs = Dir['rulesets/tests/*.rb']
  when :sample_files_tests1
    tests_rbs = Dir['workflow/tests/sample_files1_test.rb']
  when :sample_files_tests2
    tests_rbs = Dir['workflow/tests/sample_files2_test.rb']
  when :real_home_tests
    tests_rbs = Dir['workflow/tests/real_homes_test.rb']
  when :other_tests
    tests_rbs = Dir['workflow/tests/*test.rb'] - Dir['workflow/tests/real_homes_test.rb'] - Dir['workflow/tests/sample_files*test.rb']
  end

  # Run tests in random order; we don't want them to only
  # work when run in a specific order
  tests_rbs.shuffle!

  # Ensure we run all tests even if there are failures
  failed_tests = []
  tests_rbs.each do |test_rb|
    success = system("\"#{OpenStudio.getOpenStudioCLI}\" #{test_rb}")
    failed_tests << test_rb unless success
  end

  puts
  puts

  if not failed_tests.empty?
    puts 'The following tests FAILED:'
    failed_tests.each do |failed_test|
      puts "- #{failed_test}"
    end
    exit! 1
  end

  puts 'All tests passed.'
end

if ARGV[0].to_sym == :create_release_zip
  require_relative 'workflow/version'

  if ENV['CI']
    # CI doesn't have git, so default to everything
    git_files = Dir['**/*.*']
    git_files -= Dir['workflow/tests/run*/*.*']
    git_files -= Dir['workflow/tests/test_results/*.*']
    git_files -= Dir['workflow/tests/test_files/**/*.*']
  else
    # Only include files under git version control
    command = 'git ls-files'
    begin
      git_files = `#{command}`
    rescue
      puts "Command failed: '#{command}'. Perhaps git needs to be installed?"
      exit!
    end
  end
  files = ['Changelog.md',
           'LICENSE.md',
           'hpxml-measures/HPXMLtoOpenStudio/measure.*',
           'hpxml-measures/HPXMLtoOpenStudio/resources/**/*.*',
           'hpxml-measures/ReportSimulationOutput/measure.*',
           'hpxml-measures/ReportSimulationOutput/resources/**/*.*',
           'hpxml-measures/ReportUtilityBills/measure.*',
           'hpxml-measures/ReportUtilityBills/resources/**/*.*',
           'hpxml-measures/workflow/tests/util.rb',
           'rulesets/**/*.*',
           'weather/*.*',
           'workflow/*.*',
           'workflow/real_homes/*.*',
           'workflow/sample_files/*.*',
           'workflow/tests/*.rb',
           'workflow/tests/**/*.csv',
           'workflow/tests/**/*.xml']

  # Create zip files
  require 'zip'
  zip_path = File.join(File.dirname(__FILE__), "OpenStudio-ERI-v#{Version::OS_ERI_Version}.zip")
  File.delete(zip_path) if File.exist? zip_path
  puts "Creating #{zip_path}..."
  Zip::File.open(zip_path, create: true) do |zipfile|
    files.each do |f|
      Dir[f].each do |file|
        if not git_files.include? file
          next
        end

        zipfile.add(File.join('OpenStudio-ERI', file), file)
      end
    end
  end
  puts "Wrote file at #{zip_path}."
  puts 'Done.'
end
