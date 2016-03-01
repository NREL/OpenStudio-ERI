
require "#{File.dirname(__FILE__)}/util"
require "#{File.dirname(__FILE__)}/weather"
require "#{File.dirname(__FILE__)}/constants"
require "#{File.dirname(__FILE__)}/psychrometrics"
require "#{File.dirname(__FILE__)}/unit_conversions"
        
class Sim

  def initialize(model, runner)
    @weather = WeatherProcess.new(model, runner)
    @model = model
  end
        
  def _processInfiltration(si, living_space, garage, finished_basement, space_unfinished_basement, crawlspace, unfinished_attic, selected_garage, selected_fbsmt, selected_ufbsmt, selected_crawl, selected_unfinattic, wind_speed, neighbors, site, geometry)
    # Infiltration calculations.

    # loop thru all the spaces
    spaces = []
    spaces << living_space
    if not selected_garage.nil?
      spaces << garage
    end
    if not selected_fbsmt.nil?
      spaces << finished_basement
    end
    if not selected_ufbsmt.nil?
      spaces << space_unfinished_basement
    end
    if not selected_crawl.nil?
      spaces << crawlspace
    end
    if not selected_unfinattic.nil?
      spaces << unfinished_attic
    end

    outside_air_density = UnitConversion.atm2Btu_ft3(@weather.header.LocalPressure) / (Gas.Air.R * (@weather.data.AnnualAvgDrybulb + 460.0))
    inf_conv_factor = 776.25 # [ft/min]/[inH2O^(1/2)*ft^(3/2)/lbm^(1/2)]
    delta_pref = 0.016 # inH2O

    # Assume an average inside temperature
    si.assumed_inside_temp = Constants.AssumedInsideTemp # deg F, used other places. Make available.

    spaces.each do |space|
      space.inf_method = nil
      space.SLA = nil
      space.ACH = nil
      space.inf_flow = nil
      space.hor_leak_frac = nil
      space.neutral_level = nil
    end

    if not si.InfiltrationLivingSpaceACH50.nil?
      if living_space.volume == 0
          living_space.SLA = 0
          living_space.ELA = 0
          living_space.ACH = 0
          living_space.inf_flow = 0
      else
          # Living Space Infiltration
          living_space.inf_method = Constants.InfMethodASHRAE

          # Based on "Field Validation of Algebraic Equations for Stack and
          # Wind Driven Air Infiltration Calculations" by Walker and Wilson (1998)

          # Pressure Exponent
          si.n_i = 0.67
          
          # Calculate SLA for above-grade portion of the building
          living_space.SLA = get_infiltration_SLA_from_ACH50(si.InfiltrationLivingSpaceACH50, si.n_i, geometry.above_grade_finished_floor_area, living_space.volume)

          # Effective Leakage Area (ft^2)
          si.A_o = living_space.SLA * geometry.above_grade_finished_floor_area

          # Flow Coefficient (cfm/inH2O^n) (based on ASHRAE HoF)
          si.C_i = si.A_o * (2.0 / outside_air_density) ** 0.5 * delta_pref ** (0.5 - si.n_i) * inf_conv_factor
          has_flue = false

          if has_flue
            # for future use
            flue_diameter = 0.5 # after() do
            si.Y_i = flue_diameter ** 2.0 / 4.0 / si.A_o # Fraction of leakage through the flu
            si.flue_height = geometry.building_height + 2.0 # ft
            si.S_wflue = 1.0 # Flue Shelter Coefficient
          else
            si.Y_i = 0.0 # Fraction of leakage through the flu
            si.flue_height = 0.0 # ft
            si.S_wflue = 0.0 # Flue Shelter Coefficient
          end

          # Leakage distributions per Iain Walker (LBL) recommendations
          if not selected_crawl.nil? and crawlspace.CrawlACH > 0
            # 15% ceiling, 35% walls, 50% floor leakage distribution for vented crawl
            leakage_ceiling = 0.15
            leakage_walls = 0.35
            leakage_floor = 0.50
          else
            # 25% ceiling, 50% walls, 25% floor leakage distribution for slab/basement/unvented crawl
            leakage_ceiling = 0.25
            leakage_walls = 0.50
            leakage_floor = 0.25          
          end
          if leakage_ceiling + leakage_walls + leakage_floor != 1
            runner.registerError("Invalid air leakage distribution specified (#{leakage_ceiling}, #{leakage_walls}, #{leakage_floor}); does not add up to 1.")
            return false
          end
          si.R_i = (leakage_ceiling + leakage_floor)
          si.X_i = (leakage_ceiling - leakage_floor)
          si.R_i = si.R_i * (1 - si.Y_i)
          si.X_i = si.X_i * (1 - si.Y_i)         
          
          living_space.hor_leak_frac = si.R_i
          si.Z_f = si.flue_height / (living_space.height + living_space.coord_z)

          # Calculate Stack Coefficient
          si.M_o = (si.X_i + (2.0 * si.n_i + 1.0) * si.Y_i) ** 2.0 / (2 - si.R_i)

          if si.M_o <= 1.0
            si.M_i = si.M_o # eq. 10
          else
            si.M_i = 1.0 # eq. 11
          end

          if has_flue
            # Eq. 13
            si.X_c = si.R_i + (2.0 * (1.0 - si.R_i - si.Y_i)) / (si.n_i + 1.0) - 2.0 * si.Y_i * (si.Z_f - 1.0) ** si.n_i
            # Additive flue function, Eq. 12
            si.F_i = si.n_i * si.Y_y * (si.Z_f - 1.0) ** ((3.0 * si.n_i - 1.0) / 3.0) * (1.0 - (3.0 * (si.X_c - si.X_i) ** 2.0 * si.R_i ** (1 - si.n_i)) / (2.0 * (si.Z_f + 1.0)))
          else
            # Critical value of ceiling-floor leakage difference where the
            # neutral level is located at the ceiling (eq. 13)
            si.X_c = si.R_i + (2.0 * (1.0 - si.R_i - si.Y_i)) / (si.n_i + 1.0)
            # Additive flue function (eq. 12)
            si.F_i = 0.0
          end

          si.f_s = ((1.0 + si.n_i * si.R_i) / (si.n_i + 1.0)) * (0.5 - 0.5 * si.M_i ** (1.2)) ** (si.n_i + 1.0) + si.F_i

          si.stack_coef = si.f_s * (UnitConversion.lbm_fts22inH2O(outside_air_density * Constants.g * living_space.height) / (si.assumed_inside_temp + 460.0)) ** si.n_i # inH2O^n/R^n

          # Calculate wind coefficient
          if not selected_crawl.nil? and crawlspace.CrawlACH > 0

            if si.X_i > 1.0 - 2.0 * si.Y_i
              # Critical floor to ceiling difference above which f_w does not change (eq. 25)
              si.X_i = 1.0 - 2.0 * si.Y_i
            end

            # Redefined R for wind calculations for houses with crawlspaces (eq. 21)
            si.R_x = 1.0 - si.R_i * (si.n_i / 2.0 + 0.2)
            # Redefined Y for wind calculations for houses with crawlspaces (eq. 22)
            si.Y_x = 1.0 - si.Y_i / 4.0
            # Used to calculate X_x (eq.24)
            si.X_s = (1.0 - si.R_i) / 5.0 - 1.5 * si.Y_i
            # Redefined X for wind calculations for houses with crawlspaces (eq. 23)
            si.X_x = 1.0 - (((si.X_i - si.X_s) / (2.0 - si.R_i)) ** 2.0) ** 0.75
            # Wind factor (eq. 20)
            si.f_w = 0.19 * (2.0 - si.n_i) * si.X_x * si.R_x * si.Y_x

          else

            si.J_i = (si.X_i + si.R_i + 2.0 * si.Y_i) / 2.0
            si.f_w = 0.19 * (2.0 - si.n_i) * (1.0 - ((si.X_i + si.R_i) / 2.0) ** (1.5 - si.Y_i)) - si.Y_i / 4.0 * (si.J_i - 2.0 * si.Y_i * si.J_i ** 4.0)

          end

          si.wind_coef = si.f_w * UnitConversion.lbm_ft32inH2O_mph2(outside_air_density / 2.0) ** si.n_i # inH2O^n/mph^2n

          living_space.ACH = get_infiltration_ACH_from_SLA(living_space.SLA, geometry.stories, @weather)

          # Convert living space ACH to cfm:
          living_space.inf_flow = living_space.ACH / OpenStudio::convert(1.0,"hr","min").get * living_space.volume # cfm
          
      end
          
    elsif not si.InfiltrationLivingSpaceConstantACH.nil?

      # Used for constant ACH
      living_space.inf_method = Constants.InfMethodRes
      # ACH; Air exchange rate of above-grade conditioned spaces, due to natural ventilation
      living_space.ACH = si.InfiltrationLivingSpaceConstantACH

      # Convert living space ACH to cfm
      living_space.inf_flow = living_space.ACH / OpenStudio::convert(1.0,"hr","min").get * living_space.volume # cfm

    end

    unless selected_garage.nil?

      garage.inf_method = Constants.InfMethodSG
      garage.hor_leak_frac = 0.4 # DOE-2 Default
      garage.neutral_level = 0.5 # DOE-2 Default
      garage.SLA = get_infiltration_SLA_from_ACH50(si.InfiltrationGarageACH50, 0.67, garage.area, garage.volume)
      garage.ACH = get_infiltration_ACH_from_SLA(garage.SLA, 1.0, @weather)
      # Convert ACH to cfm:
      garage.inf_flow = garage.ACH / OpenStudio::convert(1.0,"hr","min").get * garage.volume # cfm

    end

    unless selected_fbsmt.nil?

      finished_basement.inf_method = Constants.InfMethodRes # Used for constant ACH
      finished_basement.ACH = finished_basement.FBsmtACH
      # Convert ACH to cfm
      finished_basement.inf_flow = finished_basement.ACH / OpenStudio::convert(1.0,"hr","min").get * finished_basement.volume

    end

    unless selected_ufbsmt.nil?

      space_unfinished_basement.inf_method = Constants.InfMethodRes # Used for constant ACH
      space_unfinished_basement.ACH = space_unfinished_basement.UFBsmtACH
      # Convert ACH to cfm
      space_unfinished_basement.inf_flow = space_unfinished_basement.ACH / OpenStudio::convert(1.0,"hr","min").get * space_unfinished_basement.volume

    end

    unless selected_crawl.nil?

      crawlspace.inf_method = Constants.InfMethodRes

      crawlspace.ACH = crawlspace.CrawlACH
      # Convert ACH to cfm
      crawlspace.inf_flow = crawlspace.ACH / OpenStudio::convert(1.0,"hr","min").get * crawlspace.volume

    end

    unless selected_unfinattic.nil?

      unfinished_attic.inf_method = Constants.InfMethodSG
      unfinished_attic.hor_leak_frac = 0.75 # Same as Energy Gauge USA Attic Model
      unfinished_attic.neutral_level = 0.5 # DOE-2 Default
      unfinished_attic.SLA = unfinished_attic.UASLA

      unfinished_attic.ACH = get_infiltration_ACH_from_SLA(unfinished_attic.SLA, 1.0, @weather)

      # Convert ACH to cfm
      unfinished_attic.inf_flow = unfinished_attic.ACH / OpenStudio::convert(1.0,"hr","min").get * unfinished_attic.volume

    end

    ws = Sim._processWindSpeedCorrection(wind_speed, site, si, neighbors, geometry)

    spaces.each do |space|
    
      if space.volume == 0
        next
      end
      
      space.f_t_SG = ws.site_terrain_multiplier * ((space.height + space.coord_z) / 32.8) ** ws.site_terrain_exponent / (ws.terrain_multiplier * (ws.height / 32.8) ** ws.terrain_exponent)
      space.f_s_SG = nil
      space.f_w_SG = nil
      space.C_s_SG = nil
      space.C_w_SG = nil
      space.ELA = nil

      if space.inf_method == Constants.InfMethodSG

        space.f_s_SG = 2.0 / 3.0 * (1 + space.hor_leak_frac / 2.0) * (2.0 * space.neutral_level * (1.0 - space.neutral_level)) ** 0.5 / (space.neutral_level ** 0.5 + (1.0 - space.neutral_level) ** 0.5)
        space.f_w_SG = ws.shielding_coef * (1.0 - space.hor_leak_frac) ** (1.0 / 3.0) * space.f_t_SG
        space.C_s_SG = space.f_s_SG ** 2.0 * Constants.g * space.height / (si.assumed_inside_temp + 460.0)
        space.C_w_SG = space.f_w_SG ** 2.0
        space.ELA = space.SLA * space.area # ft^2

      elsif space.inf_method == Constants.InfMethodASHRAE

        space.ELA = space.SLA * space.area # ft^2

      else

        space.ELA = 0 # ft^2
        space.hor_leak_frac = 0

      end

    end

    return si, living_space, ws, garage, finished_basement, space_unfinished_basement, crawlspace, unfinished_attic

  end
            
  def self._processWindSpeedCorrection(wind_speed, site, infiltration, neighbors, geometry)
    # Wind speed correction
    wind_speed.height = 32.8 # ft (Standard weather station height)
    
    # Open, Unrestricted at Weather Station
    wind_speed.terrain_multiplier = 1.0 # Used for DOE-2's correlation
    wind_speed.terrain_exponent = 0.15 # Used for DOE-2's correlation
    wind_speed.ashrae_terrain_thickness = 270
    wind_speed.ashrae_terrain_exponent = 0.14
    
    if site.TerrainType == Constants.TerrainOcean
      wind_speed.site_terrain_multiplier = 1.30 # Used for DOE-2's correlation
      wind_speed.site_terrain_exponent = 0.10 # Used for DOE-2's correlation
      wind_speed.ashrae_site_terrain_thickness = 210 # Ocean, Bayou flat country
      wind_speed.ashrae_site_terrain_exponent = 0.10 # Ocean, Bayou flat country
    elsif site.TerrainType == Constants.TerrainPlains
      wind_speed.site_terrain_multiplier = 1.00 # Used for DOE-2's correlation
      wind_speed.site_terrain_exponent = 0.15 # Used for DOE-2's correlation
      wind_speed.ashrae_site_terrain_thickness = 270 # Flat, open country
      wind_speed.ashrae_site_terrain_exponent = 0.14 # Flat, open country
    elsif site.TerrainType == Constants.TerrainRural
      wind_speed.site_terrain_multiplier = 0.85 # Used for DOE-2's correlation
      wind_speed.site_terrain_exponent = 0.20 # Used for DOE-2's correlation
      wind_speed.ashrae_site_terrain_thickness = 270 # Flat, open country
      wind_speed.ashrae_site_terrain_exponent = 0.14 # Flat, open country
    elsif site.TerrainType == Constants.TerrainSuburban
      wind_speed.site_terrain_multiplier = 0.67 # Used for DOE-2's correlation
      wind_speed.site_terrain_exponent = 0.25 # Used for DOE-2's correlation
      wind_speed.ashrae_site_terrain_thickness = 370 # Rough, wooded country, suburbs
      wind_speed.ashrae_site_terrain_exponent = 0.22 # Rough, wooded country, suburbs
    elsif site.TerrainType == Constants.TerrainCity
      wind_speed.site_terrain_multiplier = 0.47 # Used for DOE-2's correlation
      wind_speed.site_terrain_exponent = 0.35 # Used for DOE-2's correlation
      wind_speed.ashrae_site_terrain_thickness = 460 # Towns, city outskirs, center of large cities
      wind_speed.ashrae_site_terrain_exponent = 0.33 # Towns, city outskirs, center of large cities 
    end
    
    # Local Shielding
    if infiltration.InfiltrationShelterCoefficient == Constants.Auto
      if neighbors.min_nonzero_offset == 0
        # Typical shelter for isolated rural house
        wind_speed.S_wo = 0.90
      elsif neighbors.min_nonzero_offset > geometry.building_height
        # Typical shelter caused by other building across the street
        wind_speed.S_wo = 0.70
      else
        # Typical shelter for urban buildings where sheltering obstacles
        # are less than one building height away.
        # Recommended by C.Christensen.
        wind_speed.S_wo = 0.50
      end
    else
      wind_speed.S_wo = infiltration.InfiltrationShelterCoefficient.to_f
    end

    # S-G Shielding Coefficients are roughly 1/3 of AIM2 Shelter Coefficients
    wind_speed.shielding_coef = wind_speed.S_wo / 3.0
    
    return wind_speed

  end

  def _processMechanicalVentilation(infil, vent, ageOfHome, clothes_dryer, geometry, living_space, schedules)
    # Mechanical Ventilation

    # Get ASHRAE 62.2 required ventilation rate (excluding infiltration credit)
    ashrae_mv_without_infil_credit = get_mech_vent_whole_house_cfm(1, geometry.num_bedrooms, geometry.finished_floor_area, vent.MechVentASHRAEStandard) 
    
    # Determine mechanical ventilation infiltration credit (per ASHRAE 62.2);
    # only applies to existing buildings
    infil.rate_credit = 0 # default to no credit
    if vent.MechVentInfilCreditForExistingHomes and ageOfHome > 0

      if vent.MechVentASHRAEStandard == '2010'
        # ASHRAE Standard 62.2 2010
        # 2 cfm per 100ft^2 of occupiable floor area
        infil.default_rate = 2.0 * geometry.finished_floor_area / 100.0 # cfm
        # Half the excess infiltration rate above the default rate is credited toward mech vent:
        infil.rate_credit = [(living_space.inf_flow - default_rate) / 2.0, 0].max
      
      elsif vent.MechVentASHRAEStandard == '2013'
        # ASHRAE Standard 62.2 2013
        # Only applies to single-family homes (Section 8.2.1: "The required mechanical ventilation 
        # rate shall not be reduced as described in Section 4.1.3.").     
        if geometry.num_units == 1
          ela = infil.A_o # Effective leakage area, ft^2
          nl = 1000.0 * ela / living_space.area * (living_space.height / 8.2) ** 0.4 # Normalized leakage, eq. 4.4
          qinf = nl * @weather.header.WSF * living_space.area / 7.3 # Effective annual average infiltration rate, cfm, eq. 4.5a
          infil.rate_credit = [(2.0 / 3.0) * ashrae_mv_without_infil_credit, qinf].min
        end
      
      end

    end

    # Apply infiltration credit (if any)
    vent.ashrae_vent_rate = [ashrae_mv_without_infil_credit - infil.rate_credit, 0.0].max # cfm
    # Apply fraction of ASHRAE value
    vent.whole_house_vent_rate = vent.MechVentFractionOfASHRAE * vent.ashrae_vent_rate # cfm    

    # Spot Ventilation
    vent.MechVentBathroomExhaust = 50.0 # cfm, per HSP
    vent.MechVentRangeHoodExhaust = 100.0 # cfm, per HSP
    vent.MechVentSpotFanPower = 0.3 # W/cfm/fan, per HSP

    vent.bath_exhaust_operation = 60.0 # min/day, per HSP
    vent.range_hood_exhaust_operation = 60.0 # min/day, per HSP
    vent.clothes_dryer_exhaust_operation = 60.0 # min/day, per HSP

    if vent.MechVentType == Constants.VentTypeExhaust
        vent.num_vent_fans = 1 # One fan for unbalanced airflow
    elsif vent.MechVentType == Constants.VentTypeSupply
        vent.num_vent_fans = 1 # One fan for unbalanced airflow
    elsif vent.MechVentType == Constants.VentTypeBalanced
        vent.num_vent_fans = 2 # Two fans for balanced airflow
    else
        vent.num_vent_fans = 1 # Default to one fan
    end

    if vent.MechVentType == Constants.VentTypeExhaust
      vent.percent_fan_heat_to_space = 0.0 # Fan heat does not enter space
    elsif vent.MechVentType == Constants.VentTypeSupply
      vent.percent_fan_heat_to_space = 1.0 # Fan heat does enter space
    elsif vent.MechVentType == Constants.VentTypeBalanced
      vent.percent_fan_heat_to_space = 0.5 # Assumes supply fan heat enters space
    else
      vent.percent_fan_heat_to_space = 0.0
    end

    vent.bathroom_hour_avg_exhaust = vent.MechVentBathroomExhaust * geometry.num_bathrooms * vent.bath_exhaust_operation / 60.0 # cfm
    vent.range_hood_hour_avg_exhaust = vent.MechVentRangeHoodExhaust * vent.range_hood_exhaust_operation / 60.0 # cfm
    vent.clothes_dryer_hour_avg_exhaust = clothes_dryer.DryerExhaust * vent.clothes_dryer_exhaust_operation / 60.0 # cfm

    vent.max_power = [vent.bathroom_hour_avg_exhaust * vent.MechVentSpotFanPower + vent.whole_house_vent_rate * vent.MechVentHouseFanPower * vent.num_vent_fans, vent.range_hood_hour_avg_exhaust * vent.MechVentSpotFanPower + vent.whole_house_vent_rate * vent.MechVentHouseFanPower * vent.num_vent_fans].max / OpenStudio::convert(1.0,"kW","W").get # kW

    # Fan energy schedule (as fraction of maximum power). Bathroom
    # exhaust at 7:00am and range hood exhaust at 6:00pm. Clothes
    # dryer exhaust not included in mech vent power.
    if vent.max_power > 0
      vent.hourly_energy_schedule = Array.new(24, vent.whole_house_vent_rate * vent.MechVentHouseFanPower * vent.num_vent_fans / OpenStudio::convert(1.0,"kW","W").get / vent.max_power)
      vent.hourly_energy_schedule[6] = ((vent.bathroom_hour_avg_exhaust * vent.MechVentSpotFanPower + vent.whole_house_vent_rate * vent.MechVentHouseFanPower * vent.num_vent_fans) / OpenStudio::convert(1.0,"kW","W").get / vent.max_power)
      vent.hourly_energy_schedule[17] = ((vent.range_hood_hour_avg_exhaust * vent.MechVentSpotFanPower + vent.whole_house_vent_rate * vent.MechVentHouseFanPower * vent.num_vent_fans) / OpenStudio::convert(1.0,"kW","W").get / vent.max_power)
      vent.average_vent_fan_eff = ((vent.whole_house_vent_rate * 24.0 * vent.MechVentHouseFanPower * vent.num_vent_fans + (vent.bathroom_hour_avg_exhaust + vent.range_hood_hour_avg_exhaust) * vent.MechVentSpotFanPower) / (vent.whole_house_vent_rate * 24.0 + vent.bathroom_hour_avg_exhaust + vent.range_hood_hour_avg_exhaust))
    else
      vent.hourly_energy_schedule = Array.new(24, 0.0)
    end

    sch_year = "
    Schedule:Year,
      MechanicalVentilationEnergy,                        !- Name
      FRACTION,                                           !- Schedule Type
      MechanicalVentilationEnergyWk,                      !- Week Schedule Name
      1,                                                  !- Start Month
      1,                                                  !- Start Day
      12,                                                 !- End Month
      31;                                                 !- End Day"

    sch_hourly = "
    Schedule:Day:Hourly,
      MechanicalVentilationEnergyDay,                     !- Name
      FRACTION,                                           !- Schedule Type
      "
    vent.hourly_energy_schedule[0..23].each do |hour|
      sch_hourly += "#{hour},\n"
    end
    sch_hourly += "#{vent.hourly_energy_schedule[23]};"

    sch_week = "
    Schedule:Week:Compact,
      MechanicalVentilationEnergyWk,                      !- Name
      For: Weekdays,
      MechanicalVentilationEnergyDay,
      For: CustomDay1,
      MechanicalVentilationEnergyDay,
      For: CustomDay2,
      MechanicalVentilationEnergyDay,
      For: AllOtherDays,
      MechanicalVentilationEnergyDay;"

    schedules.MechanicalVentilationEnergy = [sch_hourly, sch_week, sch_year]

    vent.base_vent_rate = vent.whole_house_vent_rate * (1.0 - vent.MechVentTotalEfficiency)
    vent.max_vent_rate = [vent.bathroom_hour_avg_exhaust, vent.range_hood_hour_avg_exhaust, vent.clothes_dryer_hour_avg_exhaust].max + vent.base_vent_rate

    # Ventilation schedule (as fraction of maximum flow). Assume bathroom
    # exhaust at 7:00am, range hood exhaust at 6:00pm, and clothes dryer
    # exhaust at 11am.
    if vent.max_vent_rate > 0
      vent.hourly_schedule = Array.new(24, vent.base_vent_rate / vent.max_vent_rate)
      vent.hourly_schedule[6] = (vent.bathroom_hour_avg_exhaust + vent.base_vent_rate) / vent.max_vent_rate
      vent.hourly_schedule[10] = (vent.clothes_dryer_hour_avg_exhaust + vent.base_vent_rate) / vent.max_vent_rate
      vent.hourly_schedule[17] = (vent.range_hood_hour_avg_exhaust + vent.base_vent_rate) / vent.max_vent_rate
    else
      vent.hourly_schedule = Array.new(24, 0.0)
    end

    sch_year = "
    Schedule:Year,
      MechanicalVentilation,                              !- Name
      FRACTION,                                           !- Schedule Type
      MechanicalVentilationWk,                            !- Week Schedule Name
      1,                                                  !- Start Month
      1,                                                  !- Start Day
      12,                                                 !- End Month
      31;                                                 !- End Day"

    sch_hourly = "
    Schedule:Day:Hourly,
      MechanicalVentilationDay,                           !- Name
      FRACTION,                                           !- Schedule Type
      "
    vent.hourly_schedule[0..23].each do |hour|
      sch_hourly += "#{hour},\n"
    end
    sch_hourly += "#{vent.hourly_schedule[23]};"

    sch_week = "
    Schedule:Week:Compact,
      MechanicalVentilationWk,                      !- Name
      For: Weekdays,
      MechanicalVentilationDay,
      For: CustomDay1,
      MechanicalVentilationDay,
      For: CustomDay2,
      MechanicalVentilationDay,
      For: AllOtherDays,
      MechanicalVentilationDay;"

    schedules.MechanicalVentilation = [sch_hourly, sch_week, sch_year]

    bath_exhaust_hourly = Array.new(24, 0.0)
    bath_exhaust_hourly[6] = 1.0

    sch_year = "
    Schedule:Year,
      BathExhaust,                                        !- Name
      FRACTION,                                           !- Schedule Type
      BathExhaustWk,                                      !- Week Schedule Name
      1,                                                  !- Start Month
      1,                                                  !- Start Day
      12,                                                 !- End Month
      31;                                                 !- End Day"

    sch_hourly = "
    Schedule:Day:Hourly,
      BathExhaustDay,                                     !- Name
      FRACTION,                                           !- Schedule Type
      "
    bath_exhaust_hourly[0..23].each do |hour|
      sch_hourly += "#{hour}\n,"
    end
    sch_hourly += "#{bath_exhaust_hourly[23]};"

    sch_week = "
    Schedule:Week:Compact,
      BathExhaustWk,                                      !- Name
      For: Weekdays,
      BathExhaustDay,
      For: CustomDay1,
      BathExhaustDay,
      For: CustomDay2,
      BathExhaustDay,
      For: AllOtherDays,
      BathExhaustDay;"

    schedules.BathExhaust = [sch_hourly, sch_week, sch_year]

    clothes_dryer_exhaust_hourly = Array.new(24, 0.0)
    clothes_dryer_exhaust_hourly[10] = 1.0

    sch_year = "
    Schedule:Year,
      ClothesDryerExhaust,                                !- Name
      FRACTION,                                           !- Schedule Type
      ClothesDryerExhaustWk,                              !- Week Schedule Name
      1,                                                  !- Start Month
      1,                                                  !- Start Day
      12,                                                 !- End Month
      31;                                                 !- End Day"

    sch_hourly = "
    Schedule:Day:Hourly,
      ClothesDryerExhaustDay,                             !- Name
      FRACTION,                                           !- Schedule Type
      "
    clothes_dryer_exhaust_hourly[0..23].each do |hour|
      sch_hourly += "#{hour},\n"
    end
    sch_hourly += "#{clothes_dryer_exhaust_hourly[23]};"

    sch_week = "
    Schedule:Week:Compact,
      ClothesDryerExhaustWk,                              !- Name
      For: Weekdays,
      ClothesDryerExhaustDay,
      For: CustomDay1,
      ClothesDryerExhaustDay,
      For: CustomDay2,
      ClothesDryerExhaustDay,
      For: AllOtherDays,
      ClothesDryerExhaustDay;"

    schedules.ClothesDryerExhaust = [sch_hourly, sch_week, sch_year]

    range_hood_hourly = Array.new(24, 0.0)
    range_hood_hourly[17] = 1.0

    sch_year = "
    Schedule:Year,
      RangeHood,                                          !- Name
      FRACTION,                                           !- Schedule Type
      RangeHoodWk,                                        !- Week Schedule Name
      1,                                                  !- Start Month
      1,                                                  !- Start Day
      12,                                                 !- End Month
      31;                                                 !- End Day"

    sch_hourly = "
    Schedule:Day:Hourly,
      RangeHoodDay,                                       !- Name
      FRACTION,                                           !- Schedule Type
      "
    range_hood_hourly[0..23].each do |hour|
      sch_hourly += "#{hour},\n"
    end
    sch_hourly += "#{range_hood_hourly[23]};"

    sch_week = "
    Schedule:Week:Compact,
      RangeHoodWk,                                        !- Name
      For: Weekdays,
      RangeHoodDay,
      For: CustomDay1,
      RangeHoodDay,
      For: CustomDay2,
      RangeHoodDay,
      For: AllOtherDays,
      RangeHoodDay;"

    schedules.RangeHood = [sch_hourly, sch_week, sch_year]

    #--- Calculate HRV/ERV effectiveness values. Calculated here for use in sizing routines.

    vent.MechVentApparentSensibleEffectiveness = 0.0
    vent.MechVentHXCoreSensibleEffectiveness = 0.0
    vent.MechVentLatentEffectiveness = 0.0

    if vent.MechVentType == Constants.VentTypeBalanced and vent.MechVentSensibleEfficiency > 0 and vent.whole_house_vent_rate > 0
      # Must assume an operating condition (HVI seems to use CSA 439)
      t_sup_in = 0
      w_sup_in = 0.0028
      t_exh_in = 22
      w_exh_in = 0.0065
      cp_a = 1006
      p_fan = vent.whole_house_vent_rate * vent.MechVentHouseFanPower                                         # Watts

      m_fan = OpenStudio::convert(vent.whole_house_vent_rate,"cfm","m^3/s").get * 16.02 * Psychrometrics.rhoD_fT_w_P(OpenStudio::convert(t_sup_in,"C","F").get, w_sup_in, 14.7) # kg/s

      # The following is derived from (taken from CSA 439):
      #    E_SHR = (m_sup,fan * Cp * (Tsup,out - Tsup,in) - P_sup,fan) / (m_exh,fan * Cp * (Texh,in - Tsup,in) + P_exh,fan)
      t_sup_out = t_sup_in + (vent.MechVentSensibleEfficiency * (m_fan * cp_a * (t_exh_in - t_sup_in) + p_fan) + p_fan) / (m_fan * cp_a)

      # Calculate the apparent sensible effectiveness
      vent.MechVentApparentSensibleEffectiveness = (t_sup_out - t_sup_in) / (t_exh_in - t_sup_in)

      # Calculate the supply temperature before the fan
      t_sup_out_gross = t_sup_out - p_fan / (m_fan * cp_a)

      # Sensible effectiveness of the HX only
      vent.MechVentHXCoreSensibleEffectiveness = (t_sup_out_gross - t_sup_in) / (t_exh_in - t_sup_in)

      if (vent.MechVentHXCoreSensibleEffectiveness < 0.0) or (vent.MechVentHXCoreSensibleEffectiveness > 1.0)
        return
      end

      # Use summer test condition to determine the latent effectivess since TRE is generally specified under the summer condition
      if vent.MechVentTotalEfficiency > 0

        t_sup_in = 35.0
        w_sup_in = 0.0178
        t_exh_in = 24.0
        w_exh_in = 0.0092

        m_fan = OpenStudio::convert(vent.whole_house_vent_rate,"cfm","m^3/s").get * UnitConversion.lbm_ft32kg_m3(Psychrometrics.rhoD_fT_w_P(OpenStudio::convert(t_sup_in,"C","F").get, w_sup_in, 14.7)) # kg/s

        t_sup_out_gross = t_sup_in - vent.MechVentHXCoreSensibleEffectiveness * (t_sup_in - t_exh_in)
        t_sup_out = t_sup_out_gross + p_fan / (m_fan * cp_a)

        h_sup_in = Psychrometrics.h_fT_w_SI(t_sup_in, w_sup_in)
        h_exh_in = Psychrometrics.h_fT_w_SI(t_exh_in, w_exh_in)
        h_sup_out = h_sup_in - (vent.MechVentTotalEfficiency * (m_fan * (h_sup_in - h_exh_in) + p_fan) + p_fan) / m_fan

        w_sup_out = Psychrometrics.w_fT_h_SI(t_sup_out, h_sup_out)
        vent.MechVentLatentEffectiveness = [0.0, (w_sup_out - w_sup_in) / (w_exh_in - w_sup_in)].max

        if (vent.MechVentLatentEffectiveness < 0.0) or (vent.MechVentLatentEffectiveness > 1.0)
          return
        end

      else
        vent.MechVentLatentEffectiveness = 0.0
      end
    else
      if vent.MechVentTotalEfficiency > 0
        vent.MechVentApparentSensibleEffectiveness = vent.MechVentTotalEfficiency
        vent.MechVentHXCoreSensibleEffectiveness = vent.MechVentTotalEfficiency
        vent.MechVentLatentEffectiveness = vent.MechVentTotalEfficiency
      end
    end

    return vent, schedules

  end

  def _processNaturalVentilation(nv, living_space, wind_speed, infiltration, schedules, geometry, cooling_set_point, heating_set_point)
    # Natural Ventilation

    # Specify an array of hourly lower-temperature-limits for natural ventilation
    nv.htg_ssn_hourly_temp = Array.new
    cooling_set_point.CoolingSetpointWeekday.each do |x|
      nv.htg_ssn_hourly_temp << OpenStudio::convert(x - nv.NatVentHtgSsnSetpointOffset,"F","C").get
    end
    nv.htg_ssn_hourly_weekend_temp = Array.new
    cooling_set_point.CoolingSetpointWeekend.each do |x|
      nv.htg_ssn_hourly_weekend_temp << OpenStudio::convert(x - nv.NatVentHtgSsnSetpointOffset,"F","C").get
    end

    nv.clg_ssn_hourly_temp = Array.new
    heating_set_point.HeatingSetpointWeekday.each do |x|
      nv.clg_ssn_hourly_temp << OpenStudio::convert(x + nv.NatVentClgSsnSetpointOffset,"F","C").get
    end
    nv.clg_ssn_hourly_weekend_temp = Array.new
    heating_set_point.HeatingSetpointWeekend.each do |x|
      nv.clg_ssn_hourly_weekend_temp << OpenStudio::convert(x + nv.NatVentClgSsnSetpointOffset,"F","C").get
    end

    nv.ovlp_ssn_hourly_temp = Array.new(24, OpenStudio::convert([heating_set_point.HeatingSetpointWeekday.max, heating_set_point.HeatingSetpointWeekend.max].max + nv.NatVentOvlpSsnSetpointOffset,"F","C").get)
    nv.ovlp_ssn_hourly_weekend_temp = nv.ovlp_ssn_hourly_temp

    # Natural Ventilation Probability Schedule (DOE2, not E+)
    sch_year = "
    Schedule:Constant,
      NatVentProbability,                                 !- Name
      FRACTION,                                           !- Schedule Type
      1,                                                  !- Hourly Value"

    schedules.NatVentProbability = [sch_year]

    nat_vent_clg_ssn_temp = "
    Schedule:Week:Compact,
      NatVentClgSsnTempWeek,                              !- Name
      For: Weekdays,
      NatVentClgSsnTempWkDay,
      For: CustomDay1,
      NatVentClgSsnTempWkDay,
      For: CustomDay2,
      NatVentClgSsnTempWkEnd,
      For: AllOtherDays,
      NatVentClgSsnTempWkEnd;"

    nat_vent_htg_ssn_temp = "
    Schedule:Week:Compact,
      NatVentHtgSsnTempWeek,                              !- Name
      For: Weekdays,
      NatVentHtgSsnTempWkDay,
      For: CustomDay1,
      NatVentHtgSsnTempWkDay,
      For: CustomDay2,
      NatVentHtgSsnTempWkEnd,
      For: AllOtherDays,
      NatVentHtgSsnTempWkEnd;"

    nat_vent_ovlp_ssn_temp = "
    Schedule:Week:Compact,
      NatVentOvlpSsnTempWeek,                             !- Name
      For: Weekdays,
      NatVentOvlpSsnTempWkDay,
      For: CustomDay1,
      NatVentOvlpSsnTempWkDay,
      For: CustomDay2,
      NatVentOvlpSsnTempWkEnd,
      For: AllOtherDays,
      NatVentOvlpSsnTempWkEnd;"

    natVentHtgSsnTempWkDay_hourly = "
    Schedule:Day:Hourly,
      NatVentHtgSsnTempWkDay,                             !- Name
      TEMPERATURE,                                        !- Schedule Type
      "
    nv.htg_ssn_hourly_temp[0..23].each do |hour|
      natVentHtgSsnTempWkDay_hourly += "#{hour}\n,"
    end
    natVentHtgSsnTempWkDay_hourly += "#{nv.htg_ssn_hourly_temp[23]};"

    natVentHtgSsnTempWkEnd_hourly = "
    Schedule:Day:Hourly,
      NatVentHtgSsnTempWkEnd,                             !- Name
      TEMPERATURE,                                        !- Schedule Type
      "
    nv.htg_ssn_hourly_weekend_temp[0..23].each do |hour|
      natVentHtgSsnTempWkEnd_hourly += "#{hour}\n,"
    end
    natVentHtgSsnTempWkEnd_hourly += "#{nv.htg_ssn_hourly_weekend_temp[23]};"

    natVentClgSsnTempWkDay_hourly = "
    Schedule:Day:Hourly,
      NatVentClgSsnTempWkDay,                             !- Name
      TEMPERATURE,                                        !- Schedule Type
      "
    nv.clg_ssn_hourly_temp[0..23].each do |hour|
      natVentClgSsnTempWkDay_hourly += "#{hour}\n,"
    end
    natVentClgSsnTempWkDay_hourly += "#{nv.clg_ssn_hourly_temp[23]};"

    natVentClgSsnTempWkEnd_hourly = "
    Schedule:Day:Hourly,
      NatVentClgSsnTempWkEnd,                             !- Name
      TEMPERATURE,                                        !- Schedule Type
      "
    nv.clg_ssn_hourly_weekend_temp[0..23].each do |hour|
      natVentClgSsnTempWkEnd_hourly += "#{hour}\n,"
    end
    natVentClgSsnTempWkEnd_hourly += "#{nv.clg_ssn_hourly_weekend_temp[23]};"

    natVentOvlpSsnTempWkDay_hourly = "
    Schedule:Day:Hourly,
      NatVentOvlpSsnTempWkDay,                            !- Name
      TEMPERATURE,                                        !- Schedule Type
      "
    nv.ovlp_ssn_hourly_temp[0..23].each do |hour|
      natVentOvlpSsnTempWkDay_hourly += "#{hour}\n,"
    end
    natVentOvlpSsnTempWkDay_hourly += "#{nv.ovlp_ssn_hourly_temp[23]};"

    natVentOvlpSsnTempWkEnd_hourly = "
    Schedule:Day:Hourly,
      NatVentOvlpSsnTempWkEnd,                            !- Name
      TEMPERATURE,                                        !- Schedule Type
      "
    nv.ovlp_ssn_hourly_weekend_temp[0..23].each do |hour|
      natVentOvlpSsnTempWkEnd_hourly += "#{hour}\n,"
    end
    natVentOvlpSsnTempWkEnd_hourly += "#{nv.ovlp_ssn_hourly_weekend_temp[23]};"

    # Parse the idf for season_type array
    heating_season_names = []
    heating_season = []
    cooling_season_names = []
    cooling_season = []
    sch_args = @model.getObjectsByType("Schedule:Day:Interval".to_IddObjectType)
    (1..12).to_a.each do |i|
      heating_season_names << "HeatingSeasonSchedule%02dd" % i.to_s
      cooling_season_names << "CoolingSeasonSchedule%02dd" % i.to_s
    end

    heating_season_names.each do |sch_name|
      sch_args.each do |sch_arg|
        sch_arg_name = sch_arg.getString(0).to_s # Name
        if sch_arg_name == sch_name
          heating_season << sch_arg.getString(4).get.to_f
        end
      end
    end
    cooling_season_names.each do |sch_name|
      sch_args.each do |sch_arg|
        sch_arg_name = sch_arg.getString(0).to_s # Name
        if sch_arg_name == sch_name
          cooling_season << sch_arg.getString(4).get.to_f
        end
      end
    end

    nv.season_type = []
    (0...12).to_a.each do |month|
      if heating_season[month] == 1.0 and cooling_season[month] == 0.0
        nv.season_type << Constants.SeasonHeating
      elsif heating_season[month] == 0.0 and cooling_season[month] == 1.0
        nv.season_type << Constants.SeasonCooling
      elsif heating_season[month] == 1.0 and cooling_season[month] == 1.0
        nv.season_type << Constants.SeasonOverlap
      else
        nv.season_type << Constants.SeasonNone
      end
    end

    sch_year = "
    Schedule:Year,
      NatVentTemp,                 !- Name
      TEMPERATURE,                 !- Schedule Type"
    nv.season_type.each_with_index do |ssn_type, month|
      if ssn_type == Constants.SeasonHeating
        week_schedule_name = "NatVentHtgSsnTempWeek"
      elsif ssn_type == Constants.SeasonCooling
        week_schedule_name = "NatVentClgSsnTempWeek"
      else
        week_schedule_name = "NatVentOvlpSsnTempWeek"
      end
      if month == 0
        sch_year += "
        #{week_schedule_name},    !- Week Schedule Name
        1,                        !- Start Month
        1,                        !- Start Day
        1,                        !- End Month
        31,                       !- End Day"
      elsif month == 1
        sch_year += "
        #{week_schedule_name},    !- Week Schedule Name
        2,                        !- Start Month
        1,                        !- Start Day
        2,                        !- End Month
        28,                       !- End Day"
      elsif month == 2
        sch_year += "
        #{week_schedule_name},    !- Week Schedule Name
        3,                        !- Start Month
        1,                        !- Start Day
        3,                        !- End Month
        31,                       !- End Day"
      elsif month == 3
        sch_year += "
        #{week_schedule_name},    !- Week Schedule Name
        4,                        !- Start Month
        1,                        !- Start Day
        4,                        !- End Month
        30,                       !- End Day"
      elsif month == 4
        sch_year += "
        #{week_schedule_name},    !- Week Schedule Name
        5,                        !- Start Month
        1,                        !- Start Day
        5,                        !- End Month
        31,                       !- End Day"
      elsif month == 5
        sch_year += "
        #{week_schedule_name},    !- Week Schedule Name
        6,                        !- Start Month
        1,                        !- Start Day
        6,                        !- End Month
        30,                       !- End Day"
      elsif month == 6
        sch_year += "
        #{week_schedule_name},    !- Week Schedule Name
        7,                        !- Start Month
        1,                        !- Start Day
        7,                        !- End Month
        31,                       !- End Day"
      elsif month == 7
        sch_year += "
        #{week_schedule_name},    !- Week Schedule Name
        8,                        !- Start Month
        1,                        !- Start Day
        8,                        !- End Month
        31,                       !- End Day"
      elsif month == 8
        sch_year += "
        #{week_schedule_name},    !- Week Schedule Name
        9,                        !- Start Month
        1,                        !- Start Day
        9,                        !- End Month
        30,                       !- End Day"
      elsif month == 9
        sch_year += "
        #{week_schedule_name},    !- Week Schedule Name
        10,                       !- Start Month
        1,                        !- Start Day
        10,                       !- End Month
        31,                       !- End Day"
      elsif month == 10
        sch_year += "
        #{week_schedule_name},    !- Week Schedule Name
        11,                       !- Start Month
        1,                        !- Start Day
        11,                       !- End Month
        30,                       !- End Day"
      elsif month == 11
        sch_year += "
        #{week_schedule_name},    !- Week Schedule Name
        12,                       !- Start Month
        1,                        !- Start Day
        12,                       !- End Month
        31,                       !- End Day"
      end
    end

    schedules.NatVentTemp = [natVentHtgSsnTempWkDay_hourly, natVentHtgSsnTempWkEnd_hourly, natVentClgSsnTempWkDay_hourly, natVentClgSsnTempWkEnd_hourly, natVentOvlpSsnTempWkDay_hourly, natVentOvlpSsnTempWkEnd_hourly, nat_vent_clg_ssn_temp, nat_vent_htg_ssn_temp, nat_vent_ovlp_ssn_temp, sch_year]

    natventon_day_hourly = Array.new(24, 1)

    on_day = "
    Schedule:Day:Hourly,
      NatVentOn-Day,                                   !- Name
      FRACTION,                                        !- Schedule Type
      "
    natventon_day_hourly[0..23].each do |hour|
      on_day += "#{hour}\n,"
    end
    on_day += "#{natventon_day_hourly[23]};"

    natventoff_day_hourly = Array.new(24, 0)

    off_day = "
    Schedule:Day:Hourly,
      NatVentOff-Day,                                  !- Name
      FRACTION,                                        !- Schedule Type
      "
    natventoff_day_hourly[0..23].each do |hour|
      off_day += "#{hour}\n,"
    end
    off_day += "#{natventoff_day_hourly[23]};"

    off_week = "
    Schedule:Week:Compact,
      NatVentOffSeason-Week,                           !- Name
      For: Weekdays,
      NatVentOff-Day,
      For: CustomDay1,
      NatVentOff-Day,
      For: CustomDay2,
      NatVentOff-Day,
      For: AllOtherDays,
      NatVentOff-Day;"

    on_week = "
    Schedule:Week:Compact,
      NatVent-Week,                                    !- Name
      For: Weekdays,
      NatVentOn-Day,
      For: CustomDay1,
      NatVentOn-Day,
      For: CustomDay2,
      NatVentOn-Day,
      For: AllOtherDays,
      NatVentOff-Day;"

    # # Apply the on schedule to the correct number of days
    # wkday_order = ('monday','wednesday','friday','tuesday','thursday')
    # for dayname,_i in zip(wkday_order,range(1,nv.NatVentNumberWeekdays+1)):
    #   getattr(on_week,'set_%s' % dayname)(on_day)
    #   wkend_order = ('saturday','sunday')
    #   for dayname,_i in zip(wkend_order,range(1,nv.NatVentNumberWeekendDays+1)):
    #     getattr(on_week,'set_%s' % dayname)(on_day)
    #     on_week.set_other_days(off_day)

    sch_year = "
    Schedule:Year,
      NatVent,                  !- Name
      FRACTION,                 !- Schedule Type"
    (0...12).to_a.each do |month|
      if (nv.season_type[month] == Constants.SeasonHeating and nv.NatVentHeatingSeason) or (nv.season_type[month] == Constants.SeasonCooling and nv.NatVentCoolingSeason) or (nv.season_type[month] == Constants.SeasonOverlap and nv.NatVentOverlapSeason)
        week_schedule_name = "NatVent-Week"
      else
        week_schedule_name = "NatVentOffSeason-Week"
      end
      if month == 0
        sch_year += "
        #{week_schedule_name},    !- Week Schedule Name
        1,                        !- Start Month
        1,                        !- Start Day
        1,                        !- End Month
        31,                       !- End Day"
      elsif month == 1
        sch_year += "
        #{week_schedule_name},    !- Week Schedule Name
        2,                        !- Start Month
        1,                        !- Start Day
        2,                        !- End Month
        28,                       !- End Day"
      elsif month == 2
        sch_year += "
        #{week_schedule_name},    !- Week Schedule Name
        3,                        !- Start Month
        1,                        !- Start Day
        3,                        !- End Month
        31,                       !- End Day"
      elsif month == 3
        sch_year += "
        #{week_schedule_name},    !- Week Schedule Name
        4,                        !- Start Month
        1,                        !- Start Day
        4,                        !- End Month
        30,                       !- End Day"
      elsif month == 4
        sch_year += "
        #{week_schedule_name},    !- Week Schedule Name
        5,                        !- Start Month
        1,                        !- Start Day
        5,                        !- End Month
        31,                       !- End Day"
      elsif month == 5
        sch_year += "
        #{week_schedule_name},    !- Week Schedule Name
        6,                        !- Start Month
        1,                        !- Start Day
        6,                        !- End Month
        30,                       !- End Day"
      elsif month == 6
        sch_year += "
        #{week_schedule_name},    !- Week Schedule Name
        7,                        !- Start Month
        1,                        !- Start Day
        7,                        !- End Month
        31,                       !- End Day"
      elsif month == 7
        sch_year += "
        #{week_schedule_name},    !- Week Schedule Name
        8,                        !- Start Month
        1,                        !- Start Day
        8,                        !- End Month
        31,                       !- End Day"
      elsif month == 8
        sch_year += "
        #{week_schedule_name},    !- Week Schedule Name
        9,                        !- Start Month
        1,                        !- Start Day
        9,                        !- End Month
        30,                       !- End Day"
      elsif month == 9
        sch_year += "
        #{week_schedule_name},    !- Week Schedule Name
        10,                       !- Start Month
        1,                        !- Start Day
        10,                       !- End Month
        31,                       !- End Day"
      elsif month == 10
        sch_year += "
        #{week_schedule_name},    !- Week Schedule Name
        11,                       !- Start Month
        1,                        !- Start Day
        11,                       !- End Month
        30,                       !- End Day"
      elsif month == 11
        sch_year += "
        #{week_schedule_name},    !- Week Schedule Name
        12,                       !- Start Month
        1,                        !- Start Day
        12,                       !- End Month
        31,                       !- End Day"
      end
    end

    schedules.NatVentAvailability = [on_day, off_day, off_week, on_week, sch_year]

    # Explanation for FRAC-VENT-AREA equation:
    # From DOE22 Vol2-Dictionary: For VENT-METHOD=S-G, this is 0.6 times
    # the open window area divided by the floor area.
    # According to 2010 BA Benchmark, 33% of the windows on any facade will
    # be open at any given time and can only be opened to 20% of their area.

    nv.area = 0.6 * geometry.window_area * nv.NatVentFractionWindowsOpen * nv.NatVentFractionWindowAreaOpen # ft^2 (For S-G, this is 0.6*(open window area))
    nv.max_rate = 20.0 # Air Changes per hour
    nv.max_flow_rate = nv.max_rate * living_space.volume / OpenStudio::convert(1.0,"hr","min").get
    nv_neutral_level = 0.5
    nv.hor_vent_frac = 0.0
    f_s_nv = 2.0 / 3.0 * (1.0 + nv.hor_vent_frac / 2.0) * (2.0 * nv_neutral_level * (1 - nv_neutral_level)) ** 0.5 / (nv_neutral_level ** 0.5 + (1 - nv_neutral_level) ** 0.5)
    f_w_nv = wind_speed.shielding_coef * (1 - nv.hor_vent_frac) ** (1.0 / 3.0) * living_space.f_t_SG
    nv.C_s = f_s_nv ** 2.0 * Constants.g * living_space.height / (infiltration.assumed_inside_temp + 460.0)
    nv.C_w = f_w_nv ** 2.0

    return nv, schedules

  end
                    
  def _processAirSystem(supply, furnace=nil, air_conditioner=nil, heat_pump=nil, hasFurnace=false, hasCoolingEquipment=false, hasAirConditioner=false, hasHeatPump=false, hasMiniSplitHP=false, hasRoomAirConditioner=false, hasGroundSourceHP=false)
    # Air System

    if air_conditioner.ACCoolingInstalledSEER == 999
      air_conditioner.hasIdealAC = true
    else
      air_conditioner.hasIdealAC = false
    end

    supply.static = UnitConversion.inH2O2Pa(0.5) # Pascal

    # Flow rate through AC units - hardcoded assumption of 400 cfm/ton
    supply.cfm_ton = 400 # cfm / ton

    supply.HPCoolingOversizingFactor = 1 # Default to a value of 1 (currently only used for MSHPs)
    supply.SpaceConditionedMult = 1 # Default used for central equipment

    if hasFurnace

      f = furnace
    
      # Before we allowed systems with no cooling equipment, the system
      # fan was defined by the cooling equipment option. For systems
      # with only a furnace, the system fan is (for the time being) hard
      # coded here.

      if not hasAirConditioner or not hasHeatPump or not hasGroundSourceHP or not hasMiniSplitHP or not hasRoomAirConditioner

        supply.fan_power = f.FurnaceSupplyFanPowerInstalled # Based on 2010 BA Benchmark
        supply.eff = OpenStudio::convert(supply.static / supply.fan_power,"cfm","m^3/s").get # Overall Efficiency of the Supply Fan, Motor and Drive
        # self.supply.delta_t = 0.00055000 / units.Btu2kWh(1.0) / (self.mat.air.inside_air_dens * self.mat.air.inside_air_sh * units.hr2min(1.0))
        supply.min_flow_ratio = 1.00000000
        supply.FAN_EIR_FPLR_SPEC_coefficients = [0.00000000, 1.00000000, 0.00000000, 0.00000000]

      end

      supply.max_temp = f.FurnaceMaxSupplyTemp

      f.hir = get_furnace_hir(f.FurnaceInstalledAFUE)

      # Parasitic Electricity (Source: DOE. (2007). Technical Support Document: Energy Efficiency Program for Consumer Products: "Energy Conservation Standards for Residential Furnaces and Boilers". www.eere.energy.gov/buildings/appliance_standards/residential/furnaces_boilers.html)
      #             FurnaceParasiticElecDict = {Constants.FuelTypeGas     :  76, # W during operation
      #                                         Constants.FuelTypeOil     : 220}
      #             f.aux_elec = FurnaceParasiticElecDict[f.FurnaceFuelType]
      f.aux_elec = 0.0 # set to zero until we figure out a way to distribute to the correct end uses (DOE-2 limitation?)

      return f, air_conditioner, supply

    end

    if hasCoolingEquipment

      ac = air_conditioner
    
      if hasAirConditioner

        # Cooling Coil
        if ac.hasIdealAC
          supply = get_cooling_coefficients(ac.ACNumberSpeeds, true, false, supply)
        else
          supply = get_cooling_coefficients(ac.ACNumberSpeeds, false, false, supply)
        end

        supply.CFM_TON_Rated = calc_cfm_ton_rated(ac.ACRatedAirFlowRate, ac.ACFanspeedRatio, ac.ACCapacityRatio)
        supply = Sim._processAirSystemCoolingCoil(ac.ACNumberSpeeds, ac.ACCoolingEER, ac.ACCoolingInstalledSEER, ac.ACSupplyFanPowerInstalled, ac.ACSupplyFanPowerRated, ac.ACSHRRated, ac.ACCapacityRatio, ac.ACFanspeedRatio, ac.ACCondenserType, ac.ACCrankcase, ac.ACCrankcaseMaxT, ac.ACEERCapacityDerateFactor, air_conditioner, supply, hasHeatPump)

      end

      if hasHeatPump

        hp = heat_pump

        # Cooling Coil
        supply = get_cooling_coefficients(hp.HPNumberSpeeds, false, true, supply)
        supply.CFM_TON_Rated = calc_cfm_ton_rated(hp.HPRatedAirFlowRateCooling, hp.HPFanspeedRatioCooling, hp.HPCapacityRatio)
        supply = Sim._processAirSystemCoolingCoil(hp.HPNumberSpeeds, hp.HPCoolingEER, hp.HPCoolingInstalledSEER, hp.HPSupplyFanPowerInstalled, hp.HPSupplyFanPowerRated, hp.HPSHRRated, hp.HPCapacityRatio, hp.HPFanspeedRatioCooling, hp.HPCondenserType, hp.HPCrankcase, hp.HPCrankcaseMaxT, hp.HPEERCapacityDerateFactor, air_conditioner, supply, hasHeatPump)

        # Heating Coil
        supply = get_heating_coefficients(supply.Number_Speeds, false, supply)
        supply.CFM_TON_Rated_Heat = calc_cfm_ton_rated(hp.HPRatedAirFlowRateHeating, hp.HPFanspeedRatioHeating, hp.HPCapacityRatio)
        supply = Sim._processAirSystemHeatingCoil(hp.HPHeatingCOP, hp.HPHeatingInstalledHSPF, hp.HPSupplyFanPowerRated, hp.HPCapacityRatio, hp.HPFanspeedRatioHeating, hp.HPMinT, hp.HPCOPCapacityDerateFactor, supply)

      end

      if hasMiniSplitHP

      end

      if hasRoomAirConditioner

      end

      if hasGroundSourceHP

      end

      # Determine if the compressor is multi-speed (in our case 2 speed).
      # If the minimum flow ratio is less than 1, then the fan and
      # compressors can operate at lower speeds.
      if supply.min_flow_ratio == 1.0
        supply.compressor_speeds = 1.0
      elsif hasAirConditioner
        supply.compressor_speeds = supply.Number_Speeds
      else
        supply.compressor_speeds = 2.0
      end

      return ac, supply

    else
      supply.compressor_speeds = nil
    end

    if not hasAirConditioner and not hasHeatPump and not hasFurnace and not hasGroundSourceHP and not hasMiniSplitHP and not hasRoomAirConditioner
      # Turn off Fan for no forced air equipment
      supply.fan_power = 0.00000000
      supply.eff = 0.0 # Overall Efficiency of the Supply Fan, Motor and Drive
      # self.supply.delta_t = 0.00000000
      supply.min_flow_ratio = 1.0
      supply.FAN_EIR_FPLR_SPEC_coefficients = Array.new(4, 0.0)
    end

    # Dehumidifier coefficients
    # Generic model coefficients from Winkler, Christensen, and Tomerlin (2011)
    supply.Zone_Water_Remove_Cap_Ft_DB_RH_Coefficients = [-1.162525707, 0.02271469, -0.000113208, 0.021110538, -0.0000693034, 0.000378843]
    supply.Zone_Energy_Factor_Ft_DB_RH_Coefficients = [-1.902154518, 0.063466565, -0.000622839, 0.039540407, -0.000125637, -0.000176722]
    supply.Zone_DXDH_PLF_F_PLR_Coeffcients = [0.90, 0.10, 0.0]

  end

  def self._processAirSystemCoolingCoil(number_Speeds, coolingEER, coolingSEER, supplyFanPower, supplyFanPower_Rated, shr_Rated, capacity_Ratio, fanspeed_Ratio, condenserType, crankcase, crankcase_MaxT, eer_CapacityDerateFactor, air_conditioner, supply, hasHeatPump)

    # if len(Capacity_Ratio) > len(set(Capacity_Ratio)):
    #     SimError("Capacity Ratio values must be unique ({})".format(Capacity_Ratio))

    # Curves are hardcoded for both one and two speed models
    supply.Number_Speeds = number_Speeds

    if air_conditioner.hasIdealAC
      supply = get_cooling_coefficients(supply.Number_Speeds, true, nil, supply)
    end

    supply.CoolingEIR = Array.new
    supply.SHR_Rated = Array.new
    (0...supply.Number_Speeds).to_a.each do |speed|

      if air_conditioner.hasIdealAC
        eir = calc_EIR_from_COP(1.0, supplyFanPower_Rated)
        supply.CoolingEIR << eir

        shr_Rated = 0.8
        supply.SHR_Rated << shr_Rated
        supply.SHR_Rated[speed] = shr_Rated
        supply.FAN_EIR_FPLR_SPEC_coefficients = [1.00000000, 0.00000000, 0.00000000, 0.00000000]

      else
        eir = calc_EIR_from_EER(coolingEER[speed], supplyFanPower_Rated)
        supply.CoolingEIR << eir

        # Convert SHRs from net to gross
        qtot_net_nominal = 12000.0
        qsens_net_nominal = qtot_net_nominal * shr_Rated[speed]
        qtot_gross_nominal = qtot_net_nominal + OpenStudio::convert(supply.CFM_TON_Rated[speed] * supplyFanPower_Rated,"Wh","Btu").get
        qsens_gross_nominal = qsens_net_nominal + OpenStudio::convert(supply.CFM_TON_Rated[speed] * supplyFanPower_Rated,"Wh","Btu").get
        supply.SHR_Rated << (qsens_gross_nominal / qtot_gross_nominal)

        # Make sure SHR's are in valid range based on E+ model limits.
        # The following correlation was devloped by Jon Winkler to test for maximum allowed SHR based on the 300 - 450 cfm/ton limits in E+
        maxSHR = 0.3821066 + 0.001050652 * supply.CFM_TON_Rated[speed] - 0.01
        supply.SHR_Rated[speed] = [supply.SHR_Rated[speed], maxSHR].min
        minSHR = 0.60   # Approximate minimum SHR such that an ADP exists
        supply.SHR_Rated[speed] = [supply.SHR_Rated[speed], minSHR].max
      end
    end

    if supply.Number_Speeds == 1.0
        c_d = calc_Cd_from_SEER_EER_SingleSpeed(coolingSEER, coolingEER[0],supplyFanPower_Rated, hasHeatPump, supply)
    elsif supply.Number_Speeds == 2.0
        c_d = calc_Cd_from_SEER_EER_TwoSpeed(coolingSEER, coolingEER, capacity_Ratio, fanspeed_Ratio, supplyFanPower_Rated, hasHeatPump)
    elsif supply.Number_Speeds == 4.0
        c_d = calc_Cd_from_SEER_EER_FourSpeed(coolingSEER, coolingEER, capacity_Ratio, fanspeed_Ratio, supplyFanPower_Rated, hasHeatPump)

    else
        runner.registerError("AC number of speeds must equal 1, 2, or 4.")
        return false
    end

    if air_conditioner.hasIdealAC
      supply.COOL_CLOSS_FPLR_SPEC_coefficients = [1.0, 0.0, 0.0]
    else
      supply.COOL_CLOSS_FPLR_SPEC_coefficients = [(1.0 - c_d), c_d, 0.0]    # Linear part load model
    end

    supply.Capacity_Ratio_Cooling = capacity_Ratio
    supply.fanspeed_ratio = fanspeed_Ratio
    supply.CondenserType = condenserType
    supply.Crankcase = crankcase
    supply.Crankcase_MaxT = crankcase_MaxT

    # Supply Fan
    supply.fan_power = supplyFanPower
    supply.fan_power_rated = supplyFanPower_Rated
    supply.eff = OpenStudio::convert(supply.static / supply.fan_power,"cfm","m^3/s").get # Overall Efficiency of the Supply Fan, Motor and Drive
    supply.min_flow_ratio = fanspeed_Ratio[0] / fanspeed_Ratio[-1]

    supply.EER_CapacityDerateFactor = eer_CapacityDerateFactor

    return supply

  end

  def self._processAirSystemHeatingCoil(heatingCOP, heatingHSPF, supplyFanPower_Rated, capacity_Ratio, fanspeed_Ratio_Heating, min_T, cop_CapacityDerateFactor, supply)

    # if len(Capacity_Ratio) > len(set(Capacity_Ratio)):
    #     SimError("Capacity Ratio values must be unique ({})".format(Capacity_Ratio))

    supply.HeatingEIR = Array.new
    (0...supply.Number_Speeds).to_a.each do |speed|
      eir = calc_EIR_from_COP(heatingCOP[speed], supplyFanPower_Rated)
      supply.HeatingEIR << eir
    end

    if supply.Number_Speeds == 1.0
      c_d = calc_Cd_from_HSPF_COP_SingleSpeed(heatingHSPF, heatingCOP[0], supplyFanPower_Rated)
    elsif supply.Number_Speeds == 2.0
      c_d = calc_Cd_from_HSPF_COP_TwoSpeed(heatingHSPF, heatingCOP, capacity_Ratio, fanspeed_Ratio_Heating, supplyFanPower_Rated)
    elsif supply.Number_Speeds == 4.0
      c_d = calc_Cd_from_HSPF_COP_FourSpeed(heatingHSPF, heatingCOP, capacity_Ratio, fanspeed_Ratio_Heating, supplyFanPower_Rated)
    else
      runner.registerError("HP number of speeds must equal 1, 2, or 4.")
      return false
    end

    supply.HEAT_CLOSS_FPLR_SPEC_coefficients = [(1 - c_d), c_d, 0] # Linear part load model

    supply.Capacity_Ratio_Heating = capacity_Ratio
    supply.fanspeed_ratio_heating = fanspeed_Ratio_Heating
    supply.max_temp = 105               # Hardcoded due to all heat pumps options having this value. Also effects the sizing so it shouldn't be a user variable
    supply.min_hp_temp = min_T          # Minimum temperature for Heat Pump operation
    supply.max_supp_heating_temp = 40   # Moved from DOE-2. DOE-2 Default
    supply.max_defrost_temp = 40        # Moved from DOE-2. DOE-2 Default

    supply.COP_CapacityDerateFactor = cop_CapacityDerateFactor

    return supply

  end

end

def calc_infiltration_w_factor(weather)
  # Returns a w factor for infiltration calculations; see ticket #852 for derivation.
  hdd65f = weather.data.HDD65F
  ws = weather.data.AnnualAvgWindspeed
  a = 0.36250748
  b = 0.365317169
  c = 0.028902855
  d = 0.050181043
  e = 0.009596674
  f = -0.041567541
  # in ACH
  w = (a + b * hdd65f / 10000.0 + c * (hdd65f / 10000.0) ** 2.0 + d * ws + e * ws ** 2 + f * hdd65f / 10000.0 * ws)
  return w

end

def get_infiltration_ACH_from_SLA(sla, numStories, weather)
  # Returns the infiltration annual average ACH given a SLA.
  w = calc_infiltration_w_factor(weather)

  # Equation from ASHRAE 119-1998 (using numStories for simplification)
  norm_leakage = 1000.0 * sla * numStories ** 0.3

  # Equation from ASHRAE 136-1993
  return norm_leakage * w

end

def get_infiltration_SLA_from_ACH50(ach50, n_i, livingSpaceFloorArea, livingSpaceVolume)
  # Pressure difference between indoors and outdoors, such as during a pressurization test.
  pressure_difference = 50.0 # Pa

  return ((ach50 * 0.2835 * 4.0 ** n_i * livingSpaceVolume) / (livingSpaceFloorArea * OpenStudio::convert(1.0,"ft^2","in^2").get * pressure_difference ** n_i * 60.0))

end

def get_mech_vent_whole_house_cfm(frac622, num_beds, ffa, std)
  # Returns the ASHRAE 62.2 whole house mechanical ventilation rate, excluding any infiltration credit.

  if std == '2013'
    return frac622 * ((num_beds + 1.0) * 7.5 + 0.03 * ffa)
  end
  return frac622 * ((num_beds + 1.0) * 7.5 + 0.01 * ffa)
end

def get_furnace_hir(furnaceInstalledAFUE)
  # Based on DOE2 Volume 5 Compliance Analysis manual.
  # This is not used until we have a better way of disaggregating AFUE
  # if FurnaceInstalledAFUE <= 0.835:
  #     hir = 1 / (0.2907 * FurnaceInstalledAFUE + 0.5787)
  # else:
  #     hir = 1 / (1.1116 * FurnaceInstalledAFUE - 0.098185)

  hir = 1.0 / furnaceInstalledAFUE
  return hir
end

def calc_cfm_ton_rated(rated_airflow_rate, fanspeed_ratios, capacity_ratios)
  array = Array.new
  fanspeed_ratios.each_with_index do |fanspeed_ratio, i|
    capacity_ratio = capacity_ratios[i]
    array << fanspeed_ratio * rated_airflow_rate / capacity_ratio
  end
  return array
end

def get_cooling_coefficients(num_speeds, is_ideal_system, isHeatPump, supply)
  if not [1.0, 2.0, 4.0, Constants.MiniSplitNumSpeeds].include? num_speeds
    runner.registerError("Number_speeds = #{num_speeds} is not supported. Only 1, 2, 4, and 10 cooling equipment can be modeled.")
    return false
  end

  # Hard coded curves
  if is_ideal_system
    if num_speeds == 1.0
      supply.COOL_CAP_FT_SPEC_coefficients = [1, 0, 0, 0, 0, 0]
      supply.COOL_EIR_FT_SPEC_coefficients = [1, 0, 0, 0, 0, 0]
      supply.COOL_CAP_FFLOW_SPEC_coefficients = [1, 0, 0]
      supply.COOL_EIR_FFLOW_SPEC_coefficients = [1, 0, 0]
    elsif num_speeds > 1.0
      supply.COOL_CAP_FT_SPEC_coefficients = [[1, 0, 0, 0, 0, 0]] * num_speeds
      supply.COOL_EIR_FT_SPEC_coefficients = [[1, 0, 0, 0, 0, 0]] * num_speeds
      supply.COOL_CAP_FFLOW_SPEC_coefficients = [[1, 0, 0]] * num_speeds
      supply.COOL_EIR_FFLOW_SPEC_coefficients = [[1, 0, 0]] * num_speeds
    end

  else
    if isHeatPump
      if num_speeds == 1.0
        supply.COOL_CAP_FT_SPEC_coefficients = [3.68637657, -0.098352478, 0.000956357, 0.005838141, -0.0000127, -0.000131702]
        supply.COOL_EIR_FT_SPEC_coefficients = [-3.437356399, 0.136656369, -0.001049231, -0.0079378, 0.000185435, -0.0001441]
        supply.COOL_CAP_FFLOW_SPEC_coefficients = [0.718664047, 0.41797409, -0.136638137]
        supply.COOL_EIR_FFLOW_SPEC_coefficients = [1.143487507, -0.13943972, -0.004047787]
      elsif num_speeds == 2.0
        # one set for low, one set for high
        supply.COOL_CAP_FT_SPEC_coefficients = [[3.998418659, -0.108728222, 0.001056818, 0.007512314, -0.0000139, -0.000164716], [3.466810106, -0.091476056, 0.000901205, 0.004163355, -0.00000919, -0.000110829]]
        supply.COOL_EIR_FT_SPEC_coefficients = [[-4.282911381, 0.181023691, -0.001357391, -0.026310378, 0.000333282, -0.000197405], [-3.557757517, 0.112737397, -0.000731381, 0.013184877, 0.000132645, -0.000338716]]
        supply.COOL_CAP_FFLOW_SPEC_coefficients = [[0.655239515, 0.511655216, -0.166894731], [0.618281092, 0.569060264, -0.187341356]]
        supply.COOL_EIR_FFLOW_SPEC_coefficients = [[1.639108268, -0.998953996, 0.359845728], [1.570774717, -0.914152018, 0.343377302]]
      elsif num_speeds == 4.0
        supply.COOL_CAP_FT_SPEC_coefficients = [[3.63396857, -0.093606786, 0.000918114, 0.011852512, -0.0000318307, -0.000206446],
                                                [1.808745668, -0.041963484, 0.000545263, 0.011346539, -0.000023838, -0.000205162],
                                                [0.112814745, 0.005638646, 0.000203427, 0.011981545, -0.0000207957, -0.000212379],
                                                [1.141506147, -0.023973142, 0.000420763, 0.01038334, -0.0000174633, -0.000197092]]
        supply.COOL_EIR_FT_SPEC_coefficients = [[-1.380674217, 0.083176919, -0.000676029, -0.028120348, 0.000320593, -0.0000616147],
                                                [4.817787321, -0.100122768, 0.000673499, -0.026889359, 0.00029445, -0.0000390331],
                                                [-1.502227232, 0.05896401, -0.000439349, 0.002198465, 0.000148486, -0.000159553],
                                                [-3.443078025, 0.115186164, -0.000852001, 0.004678056, 0.000134319, -0.000171976]]
        supply.COOL_CAP_FFLOW_SPEC_coefficients = [[1, 0, 0], [1, 0, 0], [1, 0, 0], [1, 0, 0]]
        supply.COOL_EIR_FFLOW_SPEC_coefficients = [[1, 0, 0], [1, 0, 0], [1, 0, 0], [1, 0, 0]]
      elsif num_speeds == Constants.MiniSplitNumSpeeds
        # NOTE: These coefficients are in SI UNITS, which differs from the coefficients for 1, 2, and 4 speed units, which are in IP UNITS
        supply.COOL_CAP_FT_SPEC_coefficients = [[1.008993521905866, 0.006512749025457, 0.0, 0.003917565735935, -0.000222646705889, 0.0]] * num_speeds
        supply.COOL_EIR_FT_SPEC_coefficients = [[0.429214441601141, -0.003604841598515, 0.000045783162727, 0.026490875804937, -0.000159212286878, -0.000159062656483]] * num_speeds

        supply.COOL_CAP_FFLOW_SPEC_coefficients = [[1, 0, 0]] * num_speeds
        supply.COOL_EIR_FFLOW_SPEC_coefficients = [[1, 0, 0]] * num_speeds
      end
    else #AC
      if num_speeds == 1.0
        supply.COOL_CAP_FT_SPEC_coefficients = [3.670270705, -0.098652414, 0.000955906, 0.006552414, -0.0000156, -0.000131877]
        supply.COOL_EIR_FT_SPEC_coefficients = [-3.302695861, 0.137871531, -0.001056996, -0.012573945, 0.000214638, -0.000145054]
        supply.COOL_CAP_FFLOW_SPEC_coefficients = [0.718605468, 0.410099989, -0.128705457]
        supply.COOL_EIR_FFLOW_SPEC_coefficients = [1.32299905, -0.477711207, 0.154712157]

      elsif num_speeds == 2.0
        # one set for low, one set for high
        supply.COOL_CAP_FT_SPEC_coefficients = [[3.940185508, -0.104723455, 0.001019298, 0.006471171, -0.00000953, -0.000161658], [3.109456535, -0.085520461, 0.000863238, 0.00863049, -0.0000210, -0.000140186]]
        supply.COOL_EIR_FT_SPEC_coefficients = [[-3.877526888, 0.164566276, -0.001272755, -0.019956043, 0.000256512, -0.000133539], [-1.990708931, 0.093969249, -0.00073335, -0.009062553, 0.000165099, -0.0000997]]
        supply.COOL_CAP_FFLOW_SPEC_coefficients = [[0.65673024, 0.516470835, -0.172887149], [0.690334551, 0.464383753, -0.154507638]]
        supply.COOL_EIR_FFLOW_SPEC_coefficients = [[1.562945114, -0.791859997, 0.230030877], [1.31565404, -0.482467162, 0.166239001]]

      elsif num_speeds == 4.0
        supply.COOL_CAP_FT_SPEC_coefficients = [[3.845135427537, -0.095933272242, 0.000924533273, 0.008939030321, -0.000021025870, -0.000191684744], [1.902445285801, -0.042809294549, 0.000555959865, 0.009928999493, -0.000013373437, -0.000211453245], [-3.176259152730, 0.107498394091, -0.000574951600, 0.005484032413, -0.000011584801, -0.000135528854], [1.216308942608, -0.021962441981, 0.000410292252, 0.007362335339, -0.000000025748, -0.000202117724]]
        supply.COOL_EIR_FT_SPEC_coefficients = [[-1.400822352, 0.075567798, -0.000589362, -0.024655521, 0.00032690848, -0.00010222178], [3.278112067, -0.07106453, 0.000468081, -0.014070845, 0.00022267912, -0.00004950051],                                              [1.183747649, -0.041423179, 0.000390378, 0.021207528, 0.00011181091, -0.00034107189], [-3.97662986, 0.115338094, -0.000841943, 0.015962287, 0.00007757092, -0.00018579409]]
        supply.COOL_CAP_FFLOW_SPEC_coefficients = [[1, 0, 0], [1, 0, 0], [1, 0, 0], [1, 0, 0]]
        supply.COOL_EIR_FFLOW_SPEC_coefficients = [[1, 0, 0], [1, 0, 0], [1, 0, 0], [1, 0, 0]]

      elsif num_speeds == Constants.MiniSplitNumSpeeds
        # NOTE: These coefficients are in SI UNITS, which differs from the coefficients for 1, 2, and 4 speed units, which are in IP UNITS
        supply.COOL_CAP_FT_SPEC_coefficients = [[1.008993521905866, 0.006512749025457, 0.0, 0.003917565735935, -0.000222646705889, 0.0]] * num_speeds
        supply.COOL_EIR_FT_SPEC_coefficients = [[0.429214441601141, -0.003604841598515, 0.000045783162727, 0.026490875804937, -0.000159212286878, -0.000159062656483]] * num_speeds

        supply.COOL_CAP_FFLOW_SPEC_coefficients = [[1, 0, 0]] * num_speeds
        supply.COOL_EIR_FFLOW_SPEC_coefficients = [[1, 0, 0]] * num_speeds
      end
    end
  end

  return supply

end

def get_heating_coefficients(num_speeds, is_ideal_system, supply)
  # Hard coded curves
  if is_ideal_system
    if num_speeds == 1.0
      supply.HEAT_CAP_FT_SPEC_coefficients = [1, 0, 0, 0, 0, 0]
      supply.HEAT_EIR_FT_SPEC_coefficients = [1, 0, 0, 0, 0, 0]
      supply.HEAT_CAP_FFLOW_SPEC_coefficients = [1, 0, 0]
      supply.HEAT_EIR_FFLOW_SPEC_coefficients = [1, 0, 0]
    else
      supply.HEAT_CAP_FT_SPEC_coefficients = [[1, 0, 0, 0, 0, 0]]*num_speeds
      supply.HEAT_EIR_FT_SPEC_coefficients = [[1, 0, 0, 0, 0, 0]]*num_speeds
      supply.HEAT_CAP_FFLOW_SPEC_coefficients = [[1, 0, 0]]*num_speeds
      supply.HEAT_EIR_FFLOW_SPEC_coefficients = [[1, 0, 0]]*num_speeds
    end

  else
    if num_speeds == 1.0
      supply.HEAT_CAP_FT_SPEC_coefficients = [0.566333415, -0.000744164, -0.0000103, 0.009414634, 0.0000506, -0.00000675]
      supply.HEAT_EIR_FT_SPEC_coefficients = [0.718398423, 0.003498178, 0.000142202, -0.005724331, 0.00014085, -0.000215321]
      supply.HEAT_CAP_FFLOW_SPEC_coefficients = [0.694045465, 0.474207981, -0.168253446]
      supply.HEAT_EIR_FFLOW_SPEC_coefficients = [2.185418751, -1.942827919, 0.757409168]
    elsif num_speeds == 2.0
      # one set for low, one set for high
      supply.HEAT_CAP_FT_SPEC_coefficients = [[0.335690634, 0.002405123, -0.0000464, 0.013498735, 0.0000499, -0.00000725], [0.306358843, 0.005376987, -0.0000579, 0.011645092, 0.0000591, -0.0000203]]
      supply.HEAT_EIR_FT_SPEC_coefficients = [[0.36338171, 0.013523725, 0.000258872, -0.009450269, 0.000439519, -0.000653723], [0.981100941, -0.005158493, 0.000243416, -0.005274352, 0.000230742, -0.000336954]]
      supply.HEAT_CAP_FFLOW_SPEC_coefficients = [[0.741466907, 0.378645444, -0.119754733], [0.76634609, 0.32840943, -0.094701495]]
      supply.HEAT_EIR_FFLOW_SPEC_coefficients = [[2.153618211, -1.737190609, 0.584269478], [2.001041353, -1.58869128, 0.587593517]]
    elsif num_speeds == 4.0
      supply.HEAT_CAP_FT_SPEC_coefficients = [[0.304192655, -0.003972566, 0.0000196432, 0.024471251, -0.000000774126, -0.0000841323],
                                              [0.496381324, -0.00144792, 0.0, 0.016020855, 0.0000203447, -0.0000584118],
                                              [0.697171186, -0.006189599, 0.0000337077, 0.014291981, 0.0000105633, -0.0000387956],
                                              [0.555513805, -0.001337363, -0.00000265117, 0.014328826, 0.0000163849, -0.0000480711]]
      supply.HEAT_EIR_FT_SPEC_coefficients = [[0.708311527, 0.020732093, 0.000391479, -0.037640031, 0.000979937, -0.001079042],
                                              [0.025480155, 0.020169585, 0.000121341, -0.004429789, 0.000166472, -0.00036447],
                                              [0.379003189, 0.014195012, 0.0000821046, -0.008894061, 0.000151519, -0.000210299],
                                              [0.690404655, 0.00616619, 0.000137643, -0.009350199, 0.000153427, -0.000213258]]
      supply.HEAT_CAP_FFLOW_SPEC_coefficients = [[1, 0, 0], [1, 0, 0], [1, 0, 0], [1, 0, 0]]
      supply.HEAT_EIR_FFLOW_SPEC_coefficients = [[1, 0, 0], [1, 0, 0], [1, 0, 0], [1, 0, 0]]
    elsif num_speeds == Constants.MiniSplitNumSpeeds
      # NOTE: These coefficients are in SI UNITS, which differs from the coefficients for 1, 2, and 4 speed units, which are in IP UNITS
      supply.HEAT_CAP_FT_SPEC_coefficients = [[1.1527124655908571, -0.010386676170938, 0.0, 0.011263752411403, -0.000392549621117, 0.0]] * num_speeds
      supply.HEAT_EIR_FT_SPEC_coefficients = [[0.966475472847719, 0.005914950101249, 0.000191201688297, -0.012965668198361, 0.000042253229429, -0.000524002558712]] * num_speeds

      supply.HEAT_CAP_FFLOW_SPEC_coefficients = [[1, 0, 0]] * num_speeds
      supply.HEAT_EIR_FFLOW_SPEC_coefficients = [[1, 0, 0]] * num_speeds
    end
  end

  return supply

end

def calc_EIR_from_EER(eer, supplyFanPower_Rated)
  return OpenStudio::convert((1.0 - OpenStudio::convert(supplyFanPower_Rated * 0.03333,"Wh","Btu").get) / eer - supplyFanPower_Rated * 0.03333,"Wh","Btu").get
end

def calc_EIR_from_COP(cop, supplyFanPower_Rated)
  return OpenStudio::convert((OpenStudio::convert(1.0,"Btu","Wh").get + supplyFanPower_Rated * 0.03333) / cop - supplyFanPower_Rated * 0.03333,"Wh","Btu").get
end

def calc_Cd_from_SEER_EER_SingleSpeed(seer, eer_A, supplyFanPower_Rated, isHeatPump, supply)

  # Use hard-coded Cd values
  if seer < 13.0
    return 0.20
  else
    return 0.07
  end


  # eir_A = calc_EIR_from_EER(eer_A, supplyFanPower_Rated)
  #
  # # supply = SuperDict()
  # supply = get_cooling_coefficients(1.0, false, isHeatPump, supply)
  #
  # eir_B = eir_A * MathTools.biquadratic(67, 82, supply.COOL_EIR_FT_SPEC_coefficients) # tk ?
  # eer_B = calc_EER_from_EIR(eir_B, supplyFanPower_Rated)
  #
  # c_d = (seer / eer_B - 1.0) / (-0.5)
  #
  # if c_d < 0.0
  #   c_d = 0.02
  # elsif c_d > 0.25
  #   c_d = 0.25
  # end
  #
  # return c_d
end

def calc_Cd_from_SEER_EER_TwoSpeed(seer, eer_A, capacityRatio, fanSpeedRatio, supplyFanPower_Rated, isHeatPump)

  # Use hard-coded Cd values
  return 0.11


  # c_d = 0.1
  # c_d_1 = c_d
  # c_d_2 = c_d
  #
  # error = seer - calc_SEER_TwoSpeed(eer_A, c_d, capacityRatio, fanSpeedRatio, supplyFanPower_Rated, isHeatPump)
  # error1 = error
  # error2 = error
  #
  # itmax = 50  # maximum iterations
  # cvg = false
  #
  # (1...(itmax+1)).each do |n|
  #
  #   error = eer - calc_SEER_TwoSpeed(eer_A, c_d, capacityRatio, fanSpeedRatio, supplyFanPower_Rated, isHeatPump)
  #
  #   c_d, cvg, c_d_1, error1, c_d_2, error2 = MathTools.Iterate(c_d, error, c_d_1, error1, c_d_2, error2, n, cvg)
  #
  #   if cvg == true
  #     break
  #   end
  #
  # end
  #
  # if cvg == false
  #   c_d = 0.25
  #   runner.registerWarning("Two-speed cooling C_d iteration failed to converge. Setting to maximum value.")
  # end
  #
  # if c_d < 0.0
  #   c_d = 0.02
  # elsif c_d > 0.25
  #   c_d = 0.25
  # end
  #
  # return c_d
end

def calc_Cd_from_SEER_EER_FourSpeed(seer, eer_A, capacityRatio, fanSpeedRatio, supplyFanPower_Rated, isHeatPump)

  # Use hard-coded Cd values
  return 0.25

#   l_EER_A = list(EER_A)
#   l_CapacityRatio = list(CapacityRatio)
#   l_FanSpeedRatio = list(FanSpeedRatio)
#
# # first need to find the nominal capacity
#   if 1 in l_CapacityRatio:
#       nomIndex = l_CapacityRatio.index(1)
#
#   if nomIndex <= 1:
#       SimError('Invalid CapacityRatio array passed to calc_Cd_from_SEER_EER_FourSpeed. Must contain more than 2 elements.')
#   elif nomIndex == 2:
#       del l_EER_A[3]
#   del l_CapacityRatio[3]
#   del l_FanSpeedRatio[3]
#   elif nomIndex == 3:
#       l_EER_A[2] = (l_EER_A[1] + l_EER_A[2]) / 2
#   l_CapacityRatio[2] = (l_CapacityRatio[1] + l_CapacityRatio[2]) / 2
#   l_FanSpeedRatio[2] = (l_FanSpeedRatio[1] + l_FanSpeedRatio[2]) / 2
#   del l_EER_A[1]
#   del l_CapacityRatio[1]
#   del l_FanSpeedRatio[1]
#   else:
#       SimError('Invalid CapacityRatio array passed to calc_Cd_from_SEER_EER_FourSpeed. Must contain value of 1.')
#
#   C_d = 0.25
#   C_d_1 = C_d
#   C_d_2 = C_d
#
# # Note: calc_SEER_VariableSpeed has been modified for MSHPs and should be checked for use with 4 speed units
#   error = SEER - calc_SEER_VariableSpeed(l_EER_A, C_d, l_CapacityRatio, l_FanSpeedRatio, nomIndex,
#                                          SupplyFanPower_Rated, isHeatPump)
#
#   error1 = error
#   error2 = error
#
#   itmax = 50  # maximum iterations
#   cvg = False
#
#   for n in range(1,itmax+1):
#
#     # Note: calc_SEER_VariableSpeed has been modified for MSHPs and should be checked for use with 4 speed units
#     error = SEER - calc_SEER_VariableSpeed(l_EER_A, C_d, l_CapacityRatio, l_FanSpeedRatio, nomIndex,
#                                            SupplyFanPower_Rated, isHeatPump)
#
#     C_d,cvg,C_d_1,error1,C_d_2,error2 = \
#                 MathTools.Iterate(C_d,error,C_d_1,error1,C_d_2,error2,n,cvg)
#
#     if cvg == True: break
#
#     if cvg == False:
#         C_d = 0.25
#     SimWarning('Variable-speed cooling C_d iteration failed to converge. Setting to maximum value.')
#
#     if C_d < 0:
#         C_d = 0.02
#     elif C_d > 0.25:
#         C_d = 0.25
#
#     return C_d
end

def calc_Cd_from_HSPF_COP_SingleSpeed(hspf, cop_47, supplyFanPower_Rated)

  # Use hard-coded Cd values
  if hspf < 7.0
      return 0.20
  else
      return 0.11
  end

  # C_d = 0.1
  # C_d_1 = C_d
  # C_d_2 = C_d
  #
  # error = HSPF - calc_HSPF_SingleSpeed(COP_47, C_d, SupplyFanPower_Rated)
  # error1 = error
  # error2 = error
  #
  # itmax = 50  # maximum iterations
  # cvg = False
  #
  # for n in range(1,itmax+1):
  #
  #   error = HSPF - calc_HSPF_SingleSpeed(COP_47, C_d, SupplyFanPower_Rated)
  #
  #   C_d,cvg,C_d_1,error1,C_d_2,error2 = \
  #               MathTools.Iterate(C_d,error,C_d_1,error1,C_d_2,error2,n,cvg)
  #
  #   if cvg == True: break
  #
  #   if cvg == False:
  #       C_d = 0.25
  #   SimWarning('Single-speed heating C_d iteration failed to converge. Setting to maximum value.')
  #
  #   if C_d < 0:
  #       C_d = 0.02
  #   elif C_d > 0.25:
  #       C_d = 0.25
  #
  #   return C_d

end

def calc_Cd_from_HSPF_COP_TwoSpeed(hspf, cop_47, capacityRatio, fanSpeedRatio, supplyFanPower_Rated)

  # Use hard-coded Cd values
  return 0.11

  # C_d = 0.1
  # C_d_1 = C_d
  # C_d_2 = C_d
  #
  # error = HSPF - calc_HSPF_TwoSpeed(COP_47, C_d, CapacityRatio, FanSpeedRatio,
  #                                   SupplyFanPower_Rated)
  # error1 = error
  # error2 = error
  #
  # itmax = 50  # maximum iterations
  # cvg = False
  #
  # for n in range(1,itmax+1):
  #
  #   error = HSPF - calc_HSPF_TwoSpeed(COP_47, C_d, CapacityRatio, FanSpeedRatio,
  #                                     SupplyFanPower_Rated)
  #
  #   C_d,cvg,C_d_1,error1,C_d_2,error2 = \
  #               MathTools.Iterate(C_d,error,C_d_1,error1,C_d_2,error2,n,cvg)
  #
  #   if cvg == True: break
  #
  #   if cvg == False:
  #       C_d = 0.25
  #   SimWarning('Two-speed heating C_d iteration failed to converge. Setting to maximum value.')
  #
  #   if C_d < 0:
  #       C_d = 0.02
  #   elif C_d > 0.25:
  #       C_d = 0.25
  #
  #   return C_d

end

def calc_Cd_from_HSPF_COP_FourSpeed(hspf, cop_47, capacityRatio, fanSpeedRatio, supplyFanPower_Rated)

  # Use hard-coded Cd values
  return 0.24

  # l_COP_47 = list(COP_47)
  # l_CapacityRatio = list(CapacityRatio)
  # l_FanSpeedRatio = list(FanSpeedRatio)
  #
  # # first need to find the nominal capacity
  # if 1 in l_CapacityRatio:
  #     nomIndex = l_CapacityRatio.index(1)
  #
  # if nomIndex <= 1:
  #     SimError('Invalid CapacityRatio array passed to calc_Cd_from_HSPF_COP_FourSpeed. Must contain more than 2 elements.')
  # elif nomIndex == 2:
  #     del l_COP_47[3]
  # del l_CapacityRatio[3]
  # del l_FanSpeedRatio[3]
  # elif nomIndex == 3:
  #     l_COP_47[2] = (l_COP_47[1] + l_COP_47[2]) / 2
  # l_CapacityRatio[2] = (l_CapacityRatio[1] + l_CapacityRatio[2]) / 2
  # l_FanSpeedRatio[2] = (l_FanSpeedRatio[1] + l_FanSpeedRatio[2]) / 2
  # del l_COP_47[1]
  # del l_CapacityRatio[1]
  # del l_FanSpeedRatio[1]
  # else:
  #     SimError('Invalid CapacityRatio array passed to calc_Cd_from_HSPF_COP_FourSpeed. Must contain value of 1.')
  #
  # C_d = 0.25
  # C_d_1 = C_d
  # C_d_2 = C_d
  #
  # # Note: calc_HSPF_VariableSpeed has been modified for MSHPs and should be checked for use with 4 speed units
  # error = HSPF - calc_HSPF_VariableSpeed(l_COP_47, C_d, l_CapacityRatio,
  #                                        l_FanSpeedRatio, nomIndex,
  #                                        SupplyFanPower_Rated)
  # error1 = error
  # error2 = error
  #
  # itmax = 50  # maximum iterations
  # cvg = False
  #
  # for n in range(1,itmax+1):
  #
  #   # Note: calc_HSPF_VariableSpeed has been modified for MSHPs and should be checked for use with 4 speed units
  #   error = HSPF - calc_HSPF_VariableSpeed(l_COP_47, C_d, l_CapacityRatio,
  #                                          l_FanSpeedRatio, nomIndex,
  #                                          SupplyFanPower_Rated)
  #
  #   C_d,cvg,C_d_1,error1,C_d_2,error2 = \
  #               MathTools.Iterate(C_d,error,C_d_1,error1,C_d_2,error2,n,cvg)
  #
  #   if cvg == True: break
  #
  #   if cvg == False:
  #       C_d = 0.25
  #   SimWarning('Variable-speed heating C_d iteration failed to converge. Setting to maximum value.')
  #
  #   if C_d < 0:
  #       C_d = 0.02
  #   elif C_d > 0.25:
  #       C_d = 0.25
  #
  #   return C_d

end
