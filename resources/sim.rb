
require "#{File.dirname(__FILE__)}/util"
require "#{File.dirname(__FILE__)}/constants"
require "#{File.dirname(__FILE__)}/psychrometrics"
require "#{File.dirname(__FILE__)}/unit_conversions"
        
class Sim

  def initialize(model, runner)
    @model = model
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

def calc_EIR_from_COP(cop, supplyFanPower_Rated)
    return OpenStudio::convert((OpenStudio::convert(1,"Btu","W*h").get + supplyFanPower_Rated * 0.03333) / cop - supplyFanPower_Rated * 0.03333,"W*h","Btu").get
end

def calc_EIR_from_EER(eer, supplyFanPower_Rated)
    return OpenStudio::convert((1 - OpenStudio::convert(supplyFanPower_Rated * 0.03333,"W*h","Btu").get) / eer - supplyFanPower_Rated * 0.03333,"W*h","Btu").get
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
  if not [1.0, 2.0, 4.0, Constants.Num_Speeds_MSHP].include? num_speeds
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
      elsif num_speeds == Constants.Num_Speeds_MSHP
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

      elsif num_speeds == Constants.Num_Speeds_MSHP
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
    elsif num_speeds == Constants.Num_Speeds_MSHP
      # NOTE: These coefficients are in SI UNITS, which differs from the coefficients for 1, 2, and 4 speed units, which are in IP UNITS
      supply.HEAT_CAP_FT_SPEC_coefficients = [[1.1527124655908571, -0.010386676170938, 0.0, 0.011263752411403, -0.000392549621117, 0.0]] * num_speeds
      supply.HEAT_EIR_FT_SPEC_coefficients = [[0.966475472847719, 0.005914950101249, 0.000191201688297, -0.012965668198361, 0.000042253229429, -0.000524002558712]] * num_speeds

      supply.HEAT_CAP_FFLOW_SPEC_coefficients = [[1, 0, 0]] * num_speeds
      supply.HEAT_EIR_FFLOW_SPEC_coefficients = [[1, 0, 0]] * num_speeds
    end
  end

  return supply

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
