# frozen_string_literal: true

def get_saf(results, program_version, hpxml_obj_or_path)
  if [HPXML::ResidentialTypeSFD, HPXML::ResidentialTypeSFA].include? results[:rated_facility_type] # For condos and apartments in multi-family buildings the SAF shall always equal 1.0.
    if [ES::SFNationalVer3_0, ES::SFPacificVer3_0, DENH::Ver1].include? program_version
      return calc_saf(results, hpxml_obj_or_path)
    end
  end

  return 1.0 # SAF does not apply
end

def calc_saf(results, hpxml_obj_or_path)
  # Calculates the Size Adjustment Factor
  # Calculate the ERI Target for all single-family detached homes, townhomes, rowhomes, duplexes, triplexes, and quadplexes.
  cfa = results[:rated_cfa]
  nbr = results[:rated_nbr]

  if hpxml_obj_or_path.is_a? String
    hpxml_bldg = HPXML.new(hpxml_path: hpxml_obj_or_path).buildings[0]
  elsif hpxml_obj_or_path.is_a? HPXML::Building
    hpxml_bldg = hpxml_obj_or_path
  else
    fail 'Unexpected argument.'
  end

  # Floor area in basements with at least half of the gross surface area of the basement’s exterior walls below grade shall not be counted
  cond_bsmt_floor_area = 0.0
  cond_bsmt_ext_wall_area = 0.0
  cond_bsmt_ext_wall_area_bg = 0.0
  hpxml_bldg.slabs.each do |slab|
    next unless slab.interior_adjacent_to == HPXML::LocationBasementConditioned

    cond_bsmt_floor_area += slab.area
  end
  hpxml_bldg.foundation_walls.each do |fwall|
    next unless fwall.is_exterior
    next unless fwall.interior_adjacent_to == HPXML::LocationBasementConditioned

    cond_bsmt_ext_wall_area += fwall.area
    cond_bsmt_ext_wall_area_bg += (fwall.area * fwall.depth_below_grade / fwall.height)
  end
  hpxml_bldg.walls.each do |wall|
    next unless wall.is_exterior
    next unless wall.interior_adjacent_to == HPXML::LocationBasementConditioned

    cond_bsmt_ext_wall_area += wall.area
  end
  if cond_bsmt_ext_wall_area_bg / cond_bsmt_ext_wall_area > 0.5
    cfa -= cond_bsmt_floor_area
  end

  cfa_benchmark = [600 * nbr + 400, 1000].max
  saf = (cfa_benchmark / cfa)**0.25
  if saf > 1.0 # SAF not to exceed 1.0
    saf = 1.0
  end
  return saf # Size Adjustment Factor
end

def calc_opp_eri_limit(rd_eri, saf, program_version)
  # Calculates the limit, in ERI points, for On-site Power Production per
  # ENERGY STAR and DENH Program Requirements

  if [ES::SFNationalVer3_0, ES::SFPacificVer3_0, DENH::Ver1].include? program_version
    # on-site power generation may only be used to meet the ENERGY STAR and DENH ERI Target for homes
    # that are larger than the Benchmark Home and only for the incremental change in the ENERGY
    # STAR and DENH ERI Target caused by the Size Adjustment Factor
    orig_eri = rd_eri.round(0)
    saf_eri = (rd_eri * saf).round(0)
    return orig_eri - saf_eri
  else
    # on-site power generation may not be used to meet the ENERGY STAR/DENH ERI Target
    return 0.0
  end
end

def calc_renewable_energy_limit(eri_outputs, iecc_version)
  if ['2021'].include? iecc_version
    # For compliance purposes, any reduction in energy use of the rated design associated with
    # on-site renewable energy shall not exceed 5 percent of the total energy use.
    return 0.05 * eri_outputs[CalcType::RatedHome]['Energy Use: Total']
  elsif ['2015', '2018', '2024'].include? iecc_version
    return
  else
    fail 'Unhandled IECC version.'
  end
end
