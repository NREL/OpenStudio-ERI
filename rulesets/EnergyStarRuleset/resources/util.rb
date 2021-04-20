# frozen_string_literal: true

def calc_energystar_saf(results, es_version, hpxml_obj_or_path)
  # Calculates the ENERGY STAR Size Adjustment Factor

  if [ESConstants.SFNationalVer3, ESConstants.SFPacificVer3].include? es_version
    if [HPXML::ResidentialTypeSFD, HPXML::ResidentialTypeSFA].include? results[:rated_facility_type]
      # Calculate the Energy Star ERI Target for all single-family detached homes, townhomes, rowhomes, duplexes, triplexes, and quadplexes.
      cfa = results[:rated_cfa]
      nbr = results[:rated_nbr]

      if hpxml_obj_or_path.is_a? String
        hpxml = HPXML.new(hpxml_path: hpxml_obj_or_path)
      elsif hpxml_obj_or_path.is_a? HPXML
        hpxml = hpxml_obj_or_path
      else
        fail 'Unexpected argument.'
      end

      # Floor area in basements with at least half of the gross surface area of the basement’s exterior walls below grade shall not be counted
      cond_bsmt_floor_area = 0.0
      cond_bsmt_ext_wall_area = 0.0
      cond_bsmt_ext_wall_area_bg = 0.0
      hpxml.slabs.each do |slab|
        next unless slab.interior_adjacent_to == HPXML::LocationBasementConditioned

        cond_bsmt_floor_area += slab.area
      end
      hpxml.foundation_walls.each do |fwall|
        next unless fwall.is_exterior
        next unless fwall.interior_adjacent_to == HPXML::LocationBasementConditioned

        cond_bsmt_ext_wall_area += fwall.area
        cond_bsmt_ext_wall_area_bg += (fwall.area * fwall.depth_below_grade / fwall.height)
      end
      hpxml.walls.each do |wall|
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
    elsif [HPXML::ResidentialTypeApartment].include? results[:rated_facility_type]
      # For condos and apartments in multi-family buildings the SAF shall always equal 1.0.
      return 1.0
    end
  else
    # SAF does not apply
    return 1.0
  end
end

def calc_opp_eri_limit(esrd_eri, saf, es_version)
  # Calculates the limit, in ERI points, for On-site Power Production per
  # ENERGY STAR Program Requirements

  if [ESConstants.SFNationalVer3, ESConstants.SFPacificVer3].include? es_version
    # on-site power generation may only be used to meet the ENERGY STAR ERI Target for homes
    # that are larger than the Benchmark Home and only for the incremental change in the ENERGY
    # STAR ERI Target caused by the Size Adjustment Factor
    orig_eri = esrd_eri.round(0)
    saf_eri = (esrd_eri * saf).round(0)
    return orig_eri - saf_eri
  else
    # on-site power generation may not be used to meet the ENERGY STAR ERI Target
    return 0.0
  end
end
