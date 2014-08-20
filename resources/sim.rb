
require "#{File.dirname(__FILE__)}/util"

class Construction

	def initialize(path_widths, name=nil, type=nil)
		@name = name
		@type = type
		@path_widths = path_widths
		@path_fracs = []
		path_widths.each do |path_width|
			@path_fracs << path_width / path_widths.inject{ |sum, n| sum + n }
		end		
		@layer_thicknesses = []
		@cond_matrix = []
		@matrix = []
	end
	
	def addlayer(thickness=nil, conductivity_list=nil, material=nil, material_list=nil)
        # Adds layer to the construction using a material name or a thickness and list of conductivities.
		if material
			thickness = material.thick
			conductivity_list = [material.k]
		end		
		begin
			if thickness and thickness > 0
				@layer_thicknesses << thickness

				if @layer_thicknesses.length == 1
					# First layer

					if conductivity_list.length == 1
						# continuous layer
						single_conductivity = conductivity_list[0] #strangely, this is necessary
						(0...@path_fracs.length).to_a.each do |i|
							@cond_matrix << [single_conductivity]
						end						
					else
						# layer has multiple materials
						(0...@path_fracs.length).to_a.each do |i|
							@cond_matrix << [conductivity_list[i]]
						end
					end
				else
					# not first layer
					if conductivity_list.length == 1
						# continuous layer
						(0...@path_fracs.length).to_a.each do |i|
							@cond_matrix[i] << conductivity_list[0]
						end
					else
						# layer has multiple materials
						(0...@path_fracs.length).to_a.each do |i|
							@cond_matrix[i] << conductivity_list[i]
						end
					end
				end
				
			end
		rescue
			runner.registerError("Wrong number of conductivity values specified (#{conductivity_list.length} specified); should be one if a continuous layer, or one per path for non-continuous layers (#{@path_fracs.length} paths).")	
		end
		
	end
		
	def Rvalue_parallel
        # This generic function calculates the total r-value of a wall/roof/floor assembly using parallel paths (R_2D = infinity).
         # layer_thicknesses = [0.5, 5.5, 0.5] # layer thicknesses
         # path_widths = [22.5, 1.5]     # path widths

        # gwb  =  Material(cond=0.17 *0.5779)
        # stud =  Material(cond=0.12 *0.5779)
        # osb  =  Material(cond=0.13 *0.5779)
        # ins  =  Material(cond=0.04 *0.5779)

        # cond_matrix = [[gwb.k, stud.k, osb.k],
                       # [gwb.k, ins.k, osb.k]]
		u_overall = 0
		@path_fracs.each_with_index do |path_frac,path_num|
			# For each parallel path, sum series:
			r_path = 0
			@layer_thicknesses.each_with_index do |layer_thickness,layer_num|
				r_path += layer_thickness / @cond_matrix[path_num][layer_num]
			end
				
			u_overall += 1.0 / r_path * path_frac
		
		end

		return 1.0 / u_overall
		
	end	

end

class Material

	def initialize(name=nil, type=nil, thick=nil, thick_in=nil, width=nil, width_in=nil, mat_base=nil, cond=nil, dens=nil, sh=nil, tAbs=nil, sAbs=nil, vAbs=nil, rvalue=nil, is_pcm=false, pcm_temp=nil, pcm_latent_heat=nil, pcm_melting_range=nil)
		@name = name
		@type = type
		@is_pcm = is_pcm
		@pcm_temp = pcm_temp
		@pcm_latent_heat = pcm_latent_heat
		@pcm_melting_range = pcm_melting_range
		
		if not thick == nil
			@thick = thick
			@thick_in = OpenStudio::convert(@thick,"ft","in").get
		elsif not thick_in == nil
			@thick_in = thick_in
			@thick = OpenStudio::convert(@thick_in,"in","ft").get
		end
		
		if not width == nil
			@width = width
			@width_in = OpenStudio::convert(@width,"ft","in").get
		elsif not width_in == nil
			@width_in = thick_in
			@width = OpenStudio::convert(@width_in,"in","ft").get
		end
		
		if not mat_base == nil
			@k = mat_base.k
			@rho = mat_base.rho
			@cp = mat_base.Cp
		else
			@k = nil
			@rho = nil
			@cp = nil
		end
		# override the material base if both are included
		if not cond == nil
			@k = cond
		end
		if not dens == nil
			@rho = dens
		end
		if not sh == nil
			@cp = sh
		end
		@tAbs = tAbs
		@sAbs = sAbs
		@vAbs = vAbs
		if not rvalue == nil
			@rvalue = rvalue
		elsif not thick == nil and (not cond == nil or not mat_base == nil)
			if @k != 0
				@rvalue = @thick / @k
			end
		end
	end
	
	def thick
		return @thick
  end

  def thick_in
    return @thick_in
  end

  def width
    return @width
  end
	
	def width_in
		return @width_in
	end
	
	def k
		return @k
	end
	
	def rho
		return @rho
	end
	
	def Cp
		return @cp
	end
	
	def Rvalue
		return @rvalue
	end
	
	def TAbs
		return @tAbs
	end
	
	def SAbs
		return @sAbs
	end
	
	def VAbs
		return @vAbs
	end
end

def get_wood_stud_wall_r_assembly(category, prefix, gypsumThickness, gypsumNumLayers, finishThickness, finishConductivty, rigidInsThickness=0, rigidInsRvalue=0, hasOSB=true)

	wallCavityInsFillsCavity = category.send("#{prefix}WallCavityInsFillsCavity")
	wallCavityInsRvalueInstalled = category.send("#{prefix}WallCavityInsRvalueInstalled")
	wallInstallGrade = category.send("#{prefix}WallInstallGrade")
	wallCavityDepth = category.send("#{prefix}WallCavityDepth")
	wallFramingFactor = category.send("#{prefix}WallFramingFactor")

	if not wallCavityInsRvalueInstalled
		wallCavityInsRvalueInstalled = 0
	end
	if not wallFramingFactor
		wallFramingFactor = 0
	end
	
    # For foundation walls, only add OSB if there is wall insulation.
    # This is consistent with the NREMDB costs.
    if wallCavityInsRvalueInstalled == 0 and rigidInsRvalue == 0:
        hasOSB = false
	end
	
	mat_gyp = get_mat_gypsum
	mat_air = get_mat_air
	mat_wood = get_mat_wood
	mat_plywood1_2in = get_mat_plywood1_2in(mat_wood)
  films = Get_films_constant.new
	
	# Add air gap when insulation thickness < cavity depth
	if not wallCavityInsFillsCavity
		wallCavityInsRvalueInstalled += mat_air.R_air_gap
	end

	gapFactor = get_wall_gap_factor(wallInstallGrade, wallFramingFactor)
	
	path_fracs = [wallFramingFactor, 1 - wallFramingFactor - gapFactor, gapFactor]
	wood_stud_wall = Construction.new(path_fracs)
	
	# Interior Film
	wood_stud_wall.addlayer(thickness=OpenStudio::convert(1,"in","ft").get, conductivity_list=[OpenStudio::convert(1,"in","ft").get / films.vertical])
	
	# Interior Finish (GWB) - Currently only include if cavity depth > 0
	if wallCavityDepth > 0
		wood_stud_wall.addlayer(thickness=OpenStudio::convert(gypsumThickness,"in","ft").get * gypsumNumLayers, conductivity_list=[mat_gyp.k])
	end
	
	# Only if cavity depth > 0, indicating a framed wall
	if wallCavityDepth > 0
		# Stud / Cavity Ins / Gap
		ins_k = OpenStudio::convert(wallCavityDepth,"in","ft").get / wallCavityInsRvalueInstalled
		gap_k = OpenStudio::convert(wallCavityDepth,"in","ft").get / mat_air.R_air_gap
		wood_stud_wall.addlayer(thickness=OpenStudio::convert(wallCavityDepth,"in","ft").get, conductivity_list=[mat_wood.k,ins_k,gap_k])		
	end
	
	# OSB sheathing
	if hasOSB
		wood_stud_wall.addlayer(thickness=nil, conductivity_list=nil, material=mat_plywood1_2in, material_list=nil)
	end
	
	# Rigid
	if rigidInsRvalue > 0
		rigid_k = OpenStudio::convert(rigidInsThickness,"in","ft").get / rigidInsRvalue
		wood_stud_wall.addlayer(thickness=OpenStudio::convert(rigidInsThickness,"in","ft").get, conductivity_list=[rigid_k])
	end
	
	# Exterior Finish
	if finishThickness > 0
		wood_stud_wall.addlayer(thickness=OpenStudio::convert(finishThickness,"in","ft").get, conductivity_list=[OpenStudio::convert(finishConductivty,"in","ft").get])
		
		# Exterior Film - Assume below-grade wall if FinishThickness = 0
		wood_stud_wall.addlayer(thickness=OpenStudio::convert(1,"in","ft").get, conductivity_list=[OpenStudio::convert(1,"in","ft").get / films.outside])
	end
	
	# Get overall wall R-value using parallel paths:
	return wood_stud_wall.Rvalue_parallel

end

def get_double_stud_wall_r_assembly(dsw, gypsumThickness, gypsumNumLayers, finishThickness, finishConductivity, rigidInsThickness=0, rigidInsRvalue=0, hasOSB=true)
  # Returns assembly R-value for double stud wall, including air films.

  mat_gyp = get_mat_gypsum
  mat_wood = get_mat_wood
  mat_plywood1_2in = get_mat_plywood1_2in(mat_wood)
  mat_2x4 = get_mat_2x4(mat_wood)
  films = Get_films_constant.new

  dsw.MiscFramingFactor = (dsw.DSWallFramingFactor - mat_2x4.width_in / dsw.DSWallStudSpacing)

  ins_k = OpenStudio::convert(dsw.DSWallCavityDepth,"in","ft").get / dsw.DSWallCavityInsRvalue # = 1/R_per_foot

  if dsw.DSWallIsStaggered
    stud_frac = (2.0 * mat_2x4.width_in) / dsw.DSWallStudSpacing
  else
    stud_frac = (1.0 * mat_2x4.width_in) / dsw.DSWallStudSpacing
  end

  path_fracs = [dsw.MiscFramingFactor, stud_frac, (1.0 - (stud_frac + dsw.MiscFramingFactor))] # frame frac, # stud frac, # Cavity frac
  double_stud_wall = Construction.new(path_fracs)

  # Interior Film
  double_stud_wall.addlayer(thickness=OpenStudio::convert(1.0,"in","ft").get, conductivity_list=[OpenStudio::convert(1.0,"in","ft").get / films.vertical])

  # Interior Finish (GWB)
  double_stud_wall.addlayer(thickness=OpenStudio::convert(gypsumThickness,"in","ft").get * gypsumNumLayers, conductivity_list=[mat_wood.k, mat_wood.k, ins_k])

  # Inner Stud / Cavity Ins
  double_stud_wall.addlayer(thickness=mat_2x4.thick, conductivity_list=[mat_wood.k, mat_wood.k, ins_k])

  # All cavity layer
  double_stud_wall.addlayer(thickness=OpenStudio::convert(dsw.DSWallCavityDepth - (2.0 * mat_2x4.thick_in),"in","ft").get, conductivity_list=[mat_wood.k, ins_k, ins_k])

  # Outer Stud / Cavity Ins
  if dsw.DSWallIsStaggered
    double_stud_wall.addlayer(thickness=mat_2x4.thick, conductivity_list=[mat_wood.k, ins_k, ins_k])
  else
    double_stud_wall.addlayer(thickness=mat_2x4.thick, conductivity_list=[mat_wood.k, mat_wood.k, ins_k])
  end

  # OSB sheathing
  if hasOSB
    double_stud_wall.addlayer(thickness=nil, conductivity_list=nil, material=mat_plywood1_2in, material_list=nil)
  end

  # Rigid
  if rigidInsRvalue > 0
    rigid_k = OpenStudio::convert(rigidInsThickness,"in","ft").get / rigidInsRvalue
    double_stud_wall.addlayer(thickness=OpenStudio::convert(rigidInsThickness,"in","ft").get, conductivity_list=[rigid_k])
  end

  # Exterior Finish
  double_stud_wall.addlayer(thickness=OpenStudio::convert(finishThickness,"in","ft").get, conductivity_list=[OpenStudio::convert(finishConductivity,"in","ft").get])

  # Exterior Film
  double_stud_wall.addlayer(thickness=OpenStudio::convert(1.0,"in","ft").get, conductivity_list=[OpenStudio::convert(1.0,"in","ft").get / films.outside])

  # Get overall wall R-value using parallel paths:
  return dsw, double_stud_wall.Rvalue_parallel

end

def get_interzonal_wall_r_assembly(iw, gypsumThickness, gypsumConductivity=nil)
  # Returns assemblu R-value for Other wall, including air films.

  intWallCavityInsRvalueInstalled = iw.IntWallCavityInsRvalueInstalled

  mat_air = get_mat_air
  mat_wood = get_mat_wood
  films = Get_films_constant.new
  if gypsumConductivity.nil?
    mat_gyp = get_mat_gypsum
    gypsumConductivity = mat_gyp.k
  end

  # Add air gap when insulation thickness < cavity depth
  if iw.IntWallCavityInsFillsCavity == false
    intWallCavityInsRvalueInstalled += mat_air.R_air_gap
  end

  iw.GapFactor = get_wall_gap_factor(iw.IntWallInstallGrade, iw.IntWallFramingFactor)

  path_fracs = [iw.IntWallFramingFactor, 1 - iw.IntWallFramingFactor - iw.GapFactor, iw.GapFactor]

  interzonal_wall = Construction.new(path_fracs)

  # Interior Film
  interzonal_wall.addlayer(thickness=OpenStudio::convert(1.0,"in","ft").get, conductivity_list=[OpenStudio::convert(1.0,"in","ft").get / films.vertical])

  # Interior Finish (GWB)
  interzonal_wall.addlayer(thickness=OpenStudio::convert(gypsumThickness,"in","ft").get, conductivity_list=[gypsumConductivity])

  # Stud / Cavity Ins / Gap
  ins_k = OpenStudio::convert(iw.IntWallCavityDepth,"in","ft").get / intWallCavityInsRvalueInstalled
  gap_k = OpenStudio::convert(iw.IntWallCavityDepth,"in","ft").get / mat_air.R_air_gap
  interzonal_wall.addlayer(thickness=OpenStudio::convert(iw.IntWallCavityDepth,"in","ft").get, conductivity_list=[mat_wood.k, ins_k, gap_k])

  # Rigid
  if iw.IntWallContInsRvalue > 0
    rigid_k = OpenStudio::convert(iw.IntWallContInsThickness,"in","ft").get / iw.IntWallContInsRvalue
    interzonal_wall.addlayer(thickness=OpenStudio::convert(iw.IntWallContInsThickness,"in","ft").get, conductivity_list=[rigid_k])
  end

  # Exterior Film
  interzonal_wall.addlayer(thickness=OpenStudio::convert(1.0,"in","ft").get, conductivity_list=[OpenStudio::convert(1.0,"in","ft").get / films.vertical])

  return interzonal_wall.Rvalue_parallel

end

def get_interzonal_floor_r_assembly(izf, carpetPadRValue, carpetFloorFraction, floor_mass)
  # Returns assembly R-value for interzonal floor, including air films.

  mat_wood = get_mat_wood
  mat_2x6 = get_mat_2x6(mat_wood)
  mat_plywood3_4in = get_mat_plywood3_4in(mat_wood)
  films = Get_films_constant.new

  path_fracs = [izf.IntFloorFramingFactor, 1 - izf.IntFloorFramingFactor]

  izf_const = Construction.new(path_fracs)

  # Interior Film
  izf_const.addlayer(thickness=OpenStudio::convert(1.0,"in","ft").get, conductivity_list=[OpenStudio::convert(1.0,"in","ft").get / films.floor_reduced])

  # Stud/cavity layer
  if izf.IntFloorCavityInsRvalueNominal == 0
    cavity_k = 1000000000
  else
    cavity_k = mat_2x6.thick / izf.IntFloorCavityInsRvalueNominal
  end
  izf_const.addlayer(thickness=mat_2x6.thick, conductivity_list=[mat_wood.k, cavity_k])

  # Floor deck
  izf_const.addlayer(thickness=nil, conductivity_list=nil, material=mat_plywood3_4in, material_list=nil)

  # Floor mass
  if floor_mass.FloorMassThickness > 0
    mat_floor_mass = get_mat_floor_mass(floor_mass)
    izf_const.addlayer(thickness=nil, conductivity_list=nil, material=mat_floor_mass, material_list=nil)
  end

  # Carpet
  if carpetFloorFraction > 0
    carpet_smeared_cond = OpenStudio::convert(0.5,"in","ft").get / (carpetPadRValue * carpetFloorFraction)
    izf_const.addlayer(thickness=OpenStudio::convert(0.5,"in","ft").get, conductivity_list=[carpet_smeared_cond])
  end

  # Exterior Film
  izf_const.addlayer(thickness=OpenStudio::convert(1.0,"in","ft").get, conductivity_list=[OpenStudio::convert(1.0,"in","ft").get / films.floor_reduced])

  return izf_const.Rvalue_parallel

end

def get_mat_gypsum
	return Mat_solid.new(rho=50.0, cp=0.2, k=0.0926)
end

def get_mat_gypsum1_2in(mat_gypsum)
  constants = Constants.new
  return Material.new(name=constants.MaterialGypsumBoard1_2in, type=constants.MaterialTypeProperties, thick=OpenStudio::convert(0.5,"in","ft").get, thick_in=nil, width=nil, width_in=nil, mat_base=mat_gypsum, cond=nil, dens=nil, sh=nil, tAbs=0.9, sAbs=constants.DefaultSolarAbsWall, vAbs=0.1)
end

def get_mat_gypsum_extwall(mat_gypsum)
  constants = Constants.new
	return Material.new(name=constants.MaterialGypsumBoard1_2in, type=constants.MaterialTypeProperties, thick=OpenStudio::convert(0.5,"in","ft").get, thick_in=nil, width=nil, width_in=nil, mat_base=mat_gypsum, cond=nil, dens=nil, sh=nil, tAbs=0.9, sAbs=constants.DefaultSolarAbsWall, vAbs=0.1)
end

def get_mat_gypsum_ceiling(mat_gypsum)
  constants = Constants.new
  return Material.new(name=constants.MaterialGypsumBoard1_2in, type=constants.MaterialTypeProperties, thick=OpenStudio::convert(0.5,"in","ft").get, thick_in=nil, width=nil, width_in=nil, mat_base=mat_gypsum, cond=nil, dens=nil, sh=nil, tAbs=0.9, sAbs=constants.DefaultSolarAbsCeiling, vAbs=0.1)
end

def get_mat_air
	# r_air_gap = 1 # hr*ft*F/Btu (Assume for all air gap configurations since their is no correction for direction of heat flow in the simulation tools)
	# inside_air_sh = 0.24 # Btu/lbm*F	
	return Mat_air.new(r_air_gap=1.0, inside_air_sh=0.24)
end

def get_mat_wood
	return Mat_solid.new(rho=32.0, cp=0.29, k=0.0667)
end

def get_mat_rigid_ins
	return Mat_solid.new(rho=2.0, cp=0.29, k=0.017)
end

def get_mat_plywood1_2in(mat_wood)
  constants = Constants.new
	return Material.new(name=constants.MaterialPlywood1_2in, type=constants.MaterialTypeProperties, thick=OpenStudio::convert(0.5,"in","ft").get, thick_in=nil, width=nil, width_in=nil, mat_base=mat_wood)
end

def get_mat_plywood3_4in(mat_wood)
  constants = Constants.new
	return Material.new(name=constants.MaterialPlywood3_4in, type=constants.MaterialTypeProperties, thick=OpenStudio::convert(0.75,"in","ft").get, thick_in=nil, width=nil, width_in=nil, mat_base=mat_wood)
end

def get_mat_plywood3_2in(mat_wood)
  constants = Constants.new
	return Material.new(name=constants.MaterialPlywood3_2in, type=constants.MaterialTypeProperties, thick=OpenStudio::convert(1.5,"in","ft").get, thick_in=nil, width=nil, width_in=nil, mat_base=mat_wood)
end
	
def get_mat_densepack_generic
	return Mat_solid.new(rho=(get_mat_fiberglass_densepack.rho + get_mat_cellulose_densepack.rho) / 2.0, cp=0.25, k=nil)
end

def get_mat_loosefill_generic
  return Mat_solid.new(rho=(get_mat_fiberglass_loosefill.rho + get_mat_cellulose_loosefill.rho) / 2.0, cp=0.25, k=nil)
end

def get_mat_fiberglass_loosefill
  return Mat_solid.new(rho=0.5, cp=0.25, k=nil)
end

def get_mat_cellulose_loosefill
  return Mat_solid.new(rho=1.5, cp=0.25, k=nil)
end

def get_mat_fiberglass_densepack
	return Mat_solid.new(rho=2.2, cp=0.25, k=nil)
end

def get_mat_cellulose_densepack
	return Mat_solid.new(rho=3.5, cp=0.25, k=nil)
end

def get_mat_soil
	return Mat_solid.new(rho=115.0, cp=0.1, k=1)
end

def get_mat_ceil_pcm(ceiling_mass)
  return Mat_solid.new(rho=ceiling_mass.CeilingMassPCMConcentratedConductivity, cp=ceiling_mass.CeilingMassPCMConcentratedDensity, k=ceiling_mass.CeilingMassPCMConcentratedSpecificHeat)
end

def get_mat_ceil_pcm_conc(mat_ceil_pcm, ceiling_mass)
  constants = Constants.new
  return Material.new(name=constants.MaterialConcPCMCeilWall, type=constants.MaterialTypeProperties, thick=OpenStudio::convert(ceiling_mass.CeilingMassPCMConcentratedThickness,"in","ft").get, thick_in=nil, width=nil, width_in=nil, mat_base=mat_ceil_pcm, cond=nil, dens=nil, sh=nil, tAbs=0.9, sAbs=constants.DefaultSolarAbsCeiling, vAbs=0.1, rvalue=nil, is_pcm=true, pcm_temp=ceiling_mass.CeilingMassPCMTemperature, pcm_latent_heat=ceiling_mass.CeilingMassPCMLatentHeat, pcm_melting_range=ceiling_mass.CeilingMassPCMMeltingRange)
end

def get_mat_part_pcm(partition_wall_mass)
  return Mat_solid.new(rho=partition_wall_mass.PartitionWallMassPCMConcentratedConductivity, cp=partition_wall_mass.PartitionWallMassPCMConcentratedDensity, k=partition_wall_mass.PartitionWallMassPCMConcentratedSpecificHeat)
end

def get_mat_part_pcm_conc(mat_part_pcm, partition_wall_mass)
  constants = Constants.new
  return Material.new(name=constants.MaterialConcPCMPartWall, type=constants.MaterialTypeProperties, thick=OpenStudio::convert(partition_wall_mass.PartitionWallMassPCMConcentratedThickness,"in","ft").get, thick_in=nil, width=nil, width_in=nil, mat_base=mat_part_pcm, cond=nil, dens=nil, sh=nil, tAbs=0.9, sAbs=constants.DefaultSolarAbsWAll, vAbs=0.1, rvalue=nil, is_pcm=true, pcm_temp=partition_wall_mass.PartitionWallMassPCMTemperature, pcm_latent_heat=ceiling_mass.PartitionWallMassPCMLatentHeat, pcm_melting_range=partition_wall_mass.PartitionWallMassPCMMeltingRange)
end

def get_mat_soil12in(mat_soil)
  constants = Constants.new
	return Material.new(name=constants.MaterialSoil12in, type=constants.MaterialTypeProperties, thick=OpenStudio::convert(12,"in","ft").get, thick_in=nil, width=nil, width_in=nil, mat_base=mat_soil)
end

def get_mat_2x(mat_wood, thickness)
  constants = Constants.new
	return Material.new(name=constants.Material2x, type=constants.MaterialTypeProperties, thick=OpenStudio::convert(thickness,"in","ft").get, thick_in=nil, width=OpenStudio::convert(1.5,"in","ft").get, width_in=nil, mat_base=mat_wood)
end

def get_mat_floor_mass(floor_mass)
  constants = Constants.new
	return Material.new(name=constants.MaterialFloorMass, type=constants.MaterialTypeProperties, thick=OpenStudio::convert(floor_mass.FloorMassThickness,"in","ft").get, thick_in=nil, width=nil, width_in=nil, mat_base=nil, cond=OpenStudio::convert(floor_mass.FloorMassConductivity,"in","ft").get, dens=floor_mass.FloorMassDensity, sh=floor_mass.FloorMassSpecificHeat, tAbs=0.9, sAbs=constants.DefaultSolarAbsFloor)
end

def get_mat_partition_wall_mass(partition_wall_mass)
  constants = Constants.new
  return Material.new(name=constants.MaterialPartitionWallMass, type=constants.MaterialTypeProperties, thick=OpenStudio::convert(partition_wall_mass.PartitionWallMassThickness,"in","ft").get, thick_in=nil, width=nil, width_in=nil, mat_base=nil, cond=OpenStudio::convert(partition_wall_mass.PartitionWallMassConductivity,"in","ft").get, dens=partition_wall_mass.PartitionWallMassDensity, sh=partition_wall_mass.PartitionWallMassSpecificHeat, tAbs=0.9, sAbs=constants.DefaultSolarAbsWall, vAbs=0.1)
end

def get_mat_concrete
	return Mat_solid.new(rho=140.0, cp=0.2, k=0.7576)
end

def get_mat_concrete8in(mat_concrete)
  constants = Constants.new
	return Material.new(name=constants.MaterialConcrete8in, type=constants.MaterialTypeProperties, thick=OpenStudio::convert(8,"in","ft").get, thick_in=nil, width=nil, width_in=nil, mat_base=mat_concrete, cond=nil, dens=nil, sh=nil, tAbs=0.9)
end

def get_mat_concrete4in(mat_concrete)
  constants = Constants.new
	return Material.new(name=constants.MaterialConcrete8in, type=constants.MaterialTypeProperties, thick=OpenStudio::convert(4,"in","ft").get, thick_in=nil, width=nil, width_in=nil, mat_base=mat_concrete, cond=nil, dens=nil, sh=nil, tAbs=0.9)
end

def get_mat_carpet_bare(carpet)
  constants = Constants.new
	return Material.new(name=constants.MaterialCarpetBareLayer, type=constants.MaterialTypeProperties, thick=OpenStudio::convert(0.5,"in","ft").get, thick_in=nil, width=nil, width_in=nil, mat_base=nil, cond=OpenStudio::convert(0.5,"in","ft").get / (carpet.CarpetPadRValue * carpet.CarpetFloorFraction), dens=3.4, sh=0.32, tAbs=0.9, sAbs=0.9)
end

def get_mat_stud_and_air(model, mat_wood)
	# Weight specific heat of layer by mass (previously by volume)
	return Mat_solid.new(rho=(get_mat_2x4(mat_wood).width_in / Sim.stud_spacing_default) * mat_wood.rho + (1 - get_mat_2x4(mat_wood).width_in / Sim.stud_spacing_default) * Sim.new(model).inside_air_dens, cp=((get_mat_2x4(mat_wood).width_in / Sim.stud_spacing_default) * mat_wood.Cp * mat_wood.rho + (1 - get_mat_2x4(mat_wood).width_in / Sim.stud_spacing_default) * get_mat_air.inside_air_sh * Sim.new(model).inside_air_dens) / ((get_mat_2x4(mat_wood).width_in / Sim.stud_spacing_default) * mat_wood.rho + (1 - get_mat_2x4(mat_wood).width_in / Sim.stud_spacing_default) * Sim.new(model).inside_air_dens), k=Sim.stud_and_air_thick / Sim.stud_and_air_Rvalue)
end

def get_mat_2x4(mat_wood)
  constants = Constants.new
	return Material.new(name=constants.Material2x4, type=constants.MaterialTypeProperties, thick=OpenStudio::convert(3.5,"in","ft").get, thick_in=nil, width=OpenStudio::convert(1.5,"in","ft").get, width_in=nil, mat_base=mat_wood)
end

def get_mat_2x6(mat_wood)
  constants = Constants.new
  return Material.new(name=constants.Material2x6, type=constants.MaterialTypeProperties, thick=OpenStudio::convert(5.5,"in","ft").get, thick_in=nil, width=OpenStudio::convert(1.5,"in","ft").get, width_in=nil, mat_base=mat_wood)
end

def get_stud_and_air_wall(model, mat_wood)
  constants = Constants.new
	return Material.new(name=constants.MaterialStudandAirWall, type=constants.MaterialTypeProperties, thick=Sim.stud_and_air_thick, thick_in=nil, width=nil, width_in=nil, mat_base=get_mat_stud_and_air(model, mat_wood))
end

def get_mat_roofing_mat(roofing_material)
  constants = Constants.new
  return Material.new(name=constants.MaterialRoofingMaterial, type=constants.MaterialTypeProperties, thick=0.031, thick_in=nil, width=nil, width_in=nil, mat_base=nil, cond=0.094, dens=70, sh=0.35, tAbs=roofing_material.RoofMatEmissivity, sAbs=roofing_material.RoofMatAbsorptivity, vAbs=roofing_material.RoofMatAbsorptivity)
end

def get_mat_radiant_barrier
  constants = Constants.new
  return Material.new(name=constants.MaterialRadiantBarrier, type=constants.MaterialTypeProperties, thick=0.0007, thick_in=nil, width=nil, width_in=nil, mat_base=nil, cond=135.8, dens=168.6, sh=0.22, tAbs=0.05, sAbs=0.05, vAbs=0.05)
end

class Get_films_constant
    def initialize
      @outside = 0.197 # hr-ft-F/Btu
      @vertical = 0.68 # hr-ft-F/Btu (ASHRAE 2005, F25.2, Table 1)
      @flat_enhanced = 0.61 # hr-ft-F/Btu (ASHRAE 2005, F25.2, Table 1)
      @flat_reduced = 0.92 # hr-ft-F/Btu (ASHRAE 2005, F25.2, Table 1)
      # In DOE2, floors between zones use the same film resistance on both
      # sides of the floor so the film coefficient should reflect conditions
      # on both sides.
      # For floors between conditioned spaces where heat does not flow across
      # the floor; heat transfer is only important with regards to the thermal
      @floor_average = (@flat_reduced + @flat_enhanced) / 2.0 # hr-ft-F/Btu
      # For floors above unconditioned basement spaces, where heat will
      # always flow down through the floor.
      @floor_reduced = @flat_reduced # hr-ft-F/Btu
    end

    def outside
      return @outside
    end

    def vertical
      return @vertical
    end

    def flat_enhanced
      return @flat_enhanced
    end

    def flat_reduced
      return @floor_average
    end

    def floor_average
      return @floor_reduced
    end

    def floor_reduced
      return @floor_reduced
    end

    attr_accessor(:slope_enhanced, :slope_reduced, :slope_enhanced_reflective, :slope_reduced_reflective, :roof, :roof_radiant_barrier, :floor_below_unconditioned, :floor_above_unconditioned)
end

def get_wall_gap_factor(installGrade, framingFactor)

	if installGrade == 1
		return 0
	elsif installGrade == 2
		return 0.02 * (1 - framingFactor)
	elsif installGrade == 3
		return 0.05 * (1 - framingFactor)
	else
		return 0
	end

end

class Sim

	def initialize(model)
		@model = model
	end

  def _processInteriorShadingSchedule(ish)
    # Assigns window shade multiplier and shading cooling season for each month.

    constants = Constants.new

    if not ish.IntShadeCoolingMonths.nil?
      cooling_season = ish.IntShadeCoolingMonths.item # TODO: what is this?
    else
      cooling_season = [0.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0]
    end

    window_shade_multiplier = []
    window_shade_cooling_season = cooling_season
    (0..constants.MonthNames.length).to_a.each do |i|
      if cooling_season[i] == 1.0
        window_shade_multiplier << ish.IntShadeCoolingMultiplier
      else
        window_shade_multiplier << ish.IntShadeHeatingMultiplier
      end
    end

    # Interior Shading Schedule

    return window_shade_cooling_season, window_shade_multiplier

  end

	def _processConstructionsExteriorInsulatedWallsWoodStud(wsw, extwallmass, exteriorfinish, wallsh, sc)		
		# Set Furring insulation/air properties	
		if wsw.WSWallCavityInsRvalueInstalled == 0
			cavityInsDens = inside_air_dens # lb/ft^3   Assumes that a cavity with an R-value of 0 is an air cavity tk why would you ever use "self."?
			cavityInsSH = get_mat_air.inside_air_sh
		else
			cavityInsDens = get_mat_densepack_generic.rho
			cavityInsSH = get_mat_densepack_generic.Cp
			cavityInsSH = get_mat_densepack_generic.Cp
		end
		
		wsGapFactor = get_wall_gap_factor(wsw.WSWallInstallGrade, wsw.WSWallFramingFactor)
		
		overall_wall_Rvalue = get_wood_stud_wall_r_assembly(wsw, "WS", extwallmass.ExtWallMassGypsumThickness, extwallmass.ExtWallMassGypsumNumLayers, exteriorfinish.FinishThickness, exteriorfinish.FinishConductivity, wallsh.WallSheathingContInsThickness, wallsh.WallSheathingContInsRvalue, wallsh.WallSheathingHasOSB)
		
		# Create layers for modeling
    films = Get_films_constant.new
		sc.stud_layer_thickness = OpenStudio::convert(wsw.WSWallCavityDepth,"in","ft").get
		sc.stud_layer_conductivity = sc.stud_layer_thickness / (overall_wall_Rvalue - (films.vertical + films.outside + wallsh.WallSheathingContInsRvalue + wallsh.OSBRvalue + exteriorfinish.FinishRvalue + extwallmass.ExtWallMassGypsumRvalue))
		sc.stud_layer_density = wsw.WSWallFramingFactor * get_mat_wood.rho + (1 - wsw.WSWallFramingFactor - wsGapFactor) * cavityInsDens + wsGapFactor * inside_air_dens
		sc.stud_layer_spec_heat = (wsw.WSWallFramingFactor * get_mat_wood.Cp * get_mat_wood.rho + (1 - wsw.WSWallFramingFactor - wsGapFactor) * cavityInsSH * cavityInsDens + wsGapFactor * get_mat_air.inside_air_sh * inside_air_dens) / sc.stud_layer_density

    wallsh = _addInsulatedSheathingMaterial(wallsh)

		return sc, wallsh
		
  end

  def _processConstructionsExteriorInsulatedWallsDoubleStud(dsw, extwallmass, exterior_finish, wallsh, sc, c)
    dsw, overall_wall_Rvalue = get_double_stud_wall_r_assembly(dsw, extwallmass.ExtWallMassGypsumThickness, extwallmass.ExtWallMassGypsumNumLayers, exterior_finish.FinishThickness, exterior_finish.FinishConductivity, wallsh.WallSheathingContInsThickness, wallsh.WallSheathingContInsRvalue, wallsh.WallSheathingHasOSB)

    # R-value of wall if there were no studs, only misc framing (?)
    ins_layer_equiv_Rvalue = 1.0 / ((1.0 - dsw.MiscFramingFactor) / (1.0 / 3.0 * dsw.DSWallCavityInsRvalue) + dsw.MiscFramingFactor / (1.0 / 3.0 * OpenStudio::convert(dsw.DSWallCavityDepth,"in","ft").get / get_mat_wood.k)) # hr*ft^2*F/Btu

    sc.stud_layer_thickness = OpenStudio::convert(dsw.DSWallCavityDepth / 3.0,"in","ft").get # ft
    sc.stud_layer_conductivity = sc.stud_layer_thickness / ((overall_wall_Rvalue - (films.vertical + films.outside + wallsh.WallSheathingContInsRvalue + ins_layer_equiv_Rvalue + wallsh.OSBRvalue + (exterior_finish.FinishThickness / exterior_finish.FinishConductivity) + (OpenStudio::convert(extwallmass.ExtWallMassGypsumThickness,"in","ft").get * extwallmass.ExtWallMassGypsumNumLayers / get_mat_gypsum.k))) / 2.0) # Btu/hr*ft*F
    sc.stud_layer_density = dsw.DSWallFramingFactor * get_mat_wood.rho + (1 - dsw.DSWallFramingFactor) * get_mat_densepack_generic.rho # lbm/ft^3
    sc.stud_layer_spec_heat = (dsw.DSWallFramingFactor * get_mat_wood.Cp * get_mat_wood.rho + (1 - dsw.DSWallFramingFactor) * get_mat_densepack_generic.Cp * get_mat_densepack_generic.rho) / sc.stud_layer_density # Btu/lbm-F

    c.cavity_layer_thickness = OpenStudio::convert(dsw.DSWallCavityDepth / 3.0,"in","ft").get # ft
    c.cavity_layer_conductivity = c.cavity_layer_thickness / ins_layer_equiv_Rvalue # Btu/hr*ft*F
    c.cavity_layer_density = dsw.MiscFramingFactor * get_mat_wood.rho + (1.0 - dsw.MiscFramingFactor) * get_mat_densepack_generic.rho # Btu/hr*ft*F
    c.cavity_layer_spec_heat = (dsw.MiscFramingFactor * get_mat_wood.Cp * get_mat_wood.rho + (1.0 - dsw.MiscFramingFactor) * get_mat_densepack_generic.Cp * get_mat_densepack_generic.rho) / c.cavity_layer_density # Btu/lbm-F

    wallsh = _addInsulatedSheathingMaterial(wallsh)

    return sc, c

  end

  def _processConstructionsInteriorInsulatedWalls(iw, partition_wall_mass, iwi)
    # Calculate R-value of Stud and Cavity Walls between two walls
    # where both interior and exterior spaces are not conditioned.

    # if iw.IntWallCavityDepth is None:
    #   return

    film = Get_films_constant.new

    # Set Furring insulation/air properties
    if iw.IntWallCavityInsRvalueInstalled == 0
      intWallCavityInsDens = inside_air_dens # lbm/ft^3   Assumes that a cavity with an R-value of 0 is an air cavity
      intWallCavityInsSH = get_mat_air.inside_air_sh
    else
      intWallCavityInsDens = get_mat_densepack_generic.rho
      intWallCavityInsSH = get_mat_densepack_generic.Cp
    end

    overall_wall_Rvalue = get_interzonal_wall_r_assembly(iw, partition_wall_mass.PartitionWallMassThickness, OpenStudio::convert(partition_wall_mass.PartitionWallMassConductivity,"in","ft").get)

    iwi.bndry_wall_Rvalue = (overall_wall_Rvalue - (film.vertical * 2.0 + get_mat_partition_wall_mass(partition_wall_mass).Rvalue + iw.IntWallContInsRvalue))

    iwi.bndry_wall_thickness = OpenStudio::convert(iw.IntWallCavityDepth,"in","ft").get # ft
    iwi.bndry_wall_conductivity = iwi.bndry_wall_thickness / iwi.bndry_wall_Rvalue # Btu/hr*ft*F
    iwi.bndry_wall_density = iw.IntWallFramingFactor * get_mat_wood.rho + (1 - iw.IntWallFramingFactor - iw.GapFactor) * intWallCavityInsDens + iw.GapFactor * inside_air_dens # lbm/ft^3
    iwi.bndry_wall_spec_heat = (iw.IntWallFramingFactor * get_mat_wood.Cp * get_mat_wood.rho + (1 - iw.IntWallFramingFactor - iw.GapFactor) * intWallCavityInsSH * intWallCavityInsDens + iw.GapFactor * get_mat_air.inside_air_sh * inside_air_dens) / iwi.bndry_wall_density # Btu/lbm*F

    return iwi

  end
	
	# _processLocationInfo
	def local_pressure
		weather = @model.getWeatherFile
		local_pressure = 2.7128 ** (-0.0000368 * OpenStudio::convert(weather.elevation,"m","ft").get) # atm
		return local_pressure
	end
	
	# _processInfiltration
	def assumed_inside_temp
		assumed_inside_temp = 73.5
		return assumed_inside_temp
	end
	
	# _processMiscMatProps
	def self.stud_spacing_default
		# Nominal Lumber
		return 16 # in
	end

	def self.interior_framing_factor
		return 0.16
  end

  def self.floor_framing_factor
    return 0.13
  end

	def self.ceiling_framing_factor
    return 0.11
  end

	def inside_air_dens
		# Air properties
		mat_air = get_mat_air
		mat_air.inside_air_dens = 2.719 * local_pressure / (get_mat_air.R_air_gap * (assumed_inside_temp + 460)) # lb/ft^3
		# tk OpenStudio::convert(local_pressure,"atm","Btu/ft^3").get doesn't work to get the 2.719
		return mat_air.inside_air_dens
	end
	
	def floor_bare_fraction(carpet)
		return 1 - carpet.CarpetFloorFraction
	end
	
	# Uninsulated stud walls (mostly for partitions)
	def self.u_stud_path
		return Sim.interior_framing_factor / get_mat_2x4(get_mat_wood).Rvalue
	end
	
	def self.u_air_path
		return (1 - Sim.interior_framing_factor) / get_mat_air.R_air_gap
	end
	
	def self.stud_and_air_Rvalue
		return 1 / (Sim.u_stud_path + Sim.u_air_path)
	end	
	
	def self.stud_and_air_thick
		return get_mat_2x4(get_mat_wood).thick
	end
	
	# _processConstructionsGeneral
	def floor_nonstud_layer_Rvalue(floor_mass, carpet)
    films = Get_films_constant.new
		return (2.0 * films.floor_reduced + get_mat_floor_mass(floor_mass).Rvalue + (carpet.CarpetPadRValue * carpet.CarpetFloorFraction) + get_mat_plywood3_4in(get_mat_wood).Rvalue)
	end
	
	def rimjoist_nonstud_layer_Rvalue
    films = Get_films_constant.new
		return (films.vertical + films.outside + get_mat_plywood3_2in(get_mat_wood).Rvalue)
	end
	
	def _processConstructionsSlab(slab, carpet)
		# if not hasSlab(@model) tk
			# return
		# end

    films = Get_films_constant.new

		slab_concrete_Rvalue = OpenStudio::convert(slab.SlabMassThickness,"in","ft").get / slab.SlabMassConductivity
		
		slab = SlabPerimeterConductancesByType(slab)
		
		# Calculate Slab exterior perimeter and slab area
		slab.ext_perimeter = 0 # ft
		slab.area = 0 # ft
		
        # for floor in geometry.floors.floor:
            # if self._getSpace(floor.space_above).finished and \
                # self._getSpace(floor.space_below).spacetype == Constants.SpaceGround:
                # self.slab.ext_perimeter += floor.slab_ext_perimeter
                # self.slab.area += floor.area
		
		# temp tk
		slab.ext_perimeter = 154.0
		slab.area = 1482.0
		#

		slab.slab_carp_ext_perimeter = slab.ext_perimeter * carpet.CarpetFloorFraction
		slab.bare_ext_perimeter = slab.ext_perimeter * floor_bare_fraction(carpet)
		slab.area_perimeter_ratio = slab.area / slab.ext_perimeter
		
        # Calculate R-Values from conductances and geometry
        slab_warning = false
	
        # Define slab variables for DOE-2, which models two floor surfaces.
        if carpet.CarpetFloorFraction > 0
            slab_carpet_area = slab.area * carpet.CarpetFloorFraction

            if slab.slab_carp_ext_perimeter > 0
                effective_carpet_Rvalue = slab_carpet_area / (slab.slab_carp_ext_perimeter * slab.SlabCarpetPerimeterConduction)
            else
                effective_carpet_Rvalue = 1000  # hr*ft^2*F/Btu
			end

            slab.fictitious_carpet_Rvalue = effective_carpet_Rvalue - slab_concrete_Rvalue - films.flat_reduced - get_mat_soil12in(get_mat_soil).Rvalue - carpet.CarpetPadRValue

            if slab.fictitious_carpet_Rvalue <= 0
                slab_warning = true
                slab.carp_slab_factor = effective_carpet_Rvalue / (slab_concrete_Rvalue + films.flat_reduced + get_mat_soil12in(get_mat_soil).Rvalue + carpet.CarpetPadRValue)
            else
                slab.carp_slab_factor = 1.0
			end
		end
		
        if floor_bare_fraction(carpet) > 0
            slab_bare_area = slab.area * floor_bare_fraction(carpet)

            if slab.bare_ext_perimeter > 0
                effective_bare_Rvalue = slab_bare_area / (slab.bare_ext_perimeter * slab.SlabBarePerimeterConduction)
            else
                effective_bare_Rvalue = 1000 # hr*ft^2*F/Btu
			end

            slab.fictitious_bare_Rvalue = effective_bare_Rvalue - slab_concrete_Rvalue - films.flat_reduced - get_mat_soil12in(get_mat_soil).Rvalue # SoilRvalue1ft

            if slab.fictitious_bare_Rvalue <= 0
                slab_warning = true
                slab.bare_slab_factor = effective_bare_Rvalue / (slab_concrete_Rvalue + films.flat_reduced + get_mat_soil12in(get_mat_soil).Rvalue)
            else
                slab.bare_slab_factor = 1.0
			end
		end
		
        # Define slab variables for EPlus, which models one floor surface
        # with an equivalent carpented/bare material (Better alternative
        # to having two floors with twice the total area, compensated by
        # thinning mass thickness.)
        slab_perimeter_conduction = slab.SlabCarpetPerimeterConduction * carpet.CarpetFloorFraction + slab.SlabBarePerimeterConduction * floor_bare_fraction(carpet)

        if slab.ext_perimeter > 0
            effective_slab_Rvalue = slab.area / (slab.ext_perimeter * slab_perimeter_conduction)
        else
            effective_slab_Rvalue = 1000 # hr*ft^2*F/Btu
		end

        slab.fictitious_slab_Rvalue = effective_slab_Rvalue - slab_concrete_Rvalue - films.flat_reduced - get_mat_soil12in(get_mat_soil).Rvalue - (carpet.CarpetPadRValue * carpet.CarpetFloorFraction)

        if slab.fictitious_slab_Rvalue <= 0
            slab_warning = true
            slab.slab_factor = effective_slab_Rvalue / (slab_concrete_Rvalue + films._flat_reduced + get_mat_soil12in(get_mat_soil).Rvalue + carpet.CarpetPadRValue * carpet.CarpetFloorFraction)
        else
            slab.slab_factor = 1.0
		end

        if slab_warning
            runner.registerWarning("The slab foundation thickness will be automatically reduced to avoid simulation errors, but overall R-value will remain the same.")
		end
		
		return slab
		
	end
		
	def _processConstructionsCrawlspace(cs, carpet, floor_mass, wallsh, exterior_finish, cci, cwfr, cwi, cffr, cjc, selected_crawlspace)
		# if not hasSpaceType(@model, Constants::SpaceCrawl) tk
			# return
		# end		

    films = Get_films_constant.new

		# If there is no wall insulation, apply the ceiling insulation R-value to the rim joists
		if cs.CrawlWallContInsRvalueNominal == 0
			cs.CrawlRimJoistInsRvalue = cs.CrawlCeilingCavityInsRvalueNominal
		end
		
		mat_2x = get_mat_2x(get_mat_wood, cs.CrawlCeilingJoistHeight)
		
		# crawlspace = _getSpace(Constants::SpaceCrawl)
		
		# crawlspace_conduction = calc_crawlspace_wall_conductance(cs.CrawlWallContInsRvalueNominal, _getSpace(Constants::SpaceCrawl).height) # tk _getSpace
		# temp tk
		crawlspace_conduction = calc_crawlspace_wall_conductance(cs.CrawlWallContInsRvalueNominal, 4)
		#
		
		cci.crawl_ceiling_Rvalue = get_crawlspace_ceiling_r_assembly(cs, carpet, floor_mass)
		
		crawl_ceiling_studlayer_Rvalue = cci.crawl_ceiling_Rvalue - floor_nonstud_layer_Rvalue(floor_mass, carpet)
		
		if cci.crawl_ceiling_Rvalue > 0
			cci.crawl_ceiling_thickness = mat_2x.thick
			cci.crawl_ceiling_conductivity = cci.crawl_ceiling_thickness / crawl_ceiling_studlayer_Rvalue
			cci.crawl_ceiling_density = cs.CrawlCeilingFramingFactor * get_mat_wood.rho + (1 - cs.CrawlCeilingFramingFactor) * get_mat_densepack_generic.rho # lbm/ft^3
			cci.crawl_ceiling_spec_heat = (cs.CrawlCeilingFramingFactor * get_mat_wood.Cp * get_mat_wood.rho + (1 - cs.CrawlCeilingFramingFactor) * get_mat_densepack_generic.Cp * get_mat_densepack_generic.rho) / cci.crawl_ceiling_density # Btu/lbm*F
		end
		
		if cs.CrawlWallContInsRvalueNominal > 0
			crawlspace_wall_thickness = OpenStudio::convert(cs.CrawlWallContInsRvalueNominal / 5,"in","ft").get # ft
			crawlspace_wall_conductivity = crawlspace_wall_thickness / cs.CrawlWallContInsRvalueNominal # Btu/hr*ft*F
			crawlspace_wall_density = get_mat_rigid_ins.rho # lbm/ft^3
			crawlspace_wall_spec_heat = get_mat_rigid_ins.Cp # Btu/lbm*F
		end
		
		# Calculate Exterior Crawlspace Wall Area and PerimeterSlabInsulation
		crawlspace_wall_area = 0 # ft^2
		cs.ext_perimeter = 0 # ft^2

    # spaces = @model.getSpaces
    # selected_crawlspace.each do |selected_spacetype|
    #   spaces.each do |space|
    #     if selected_spacetype == space.spaceType.get.name.to_s
    #       surfaces = space.surfaces
    #       surfaces.each do |surface|
    #         if surface.surfaceType == "Wall" and surface.outsideBoundaryCondition == "Ground"
    #           vertices = surface.vertices
    #           vertices.each do |vertex|
    #             # tk calculate length of wall here and add to cs.ext_perimeter
    #             # tk calculate area of wall here and add to crawlspace_wall_area
    #           end
    #         end
    #       end
    #     end
    #   end
    # end
		
        # for wall in geometry.walls.wall:
            # space_int = self._getSpace(wall.space_int)
            # space_ext = self._getSpace(wall.space_ext)
            # if space_int.spacetype == Constants.SpaceCrawl and \
               # space_ext.spacetype == Constants.SpaceGround and \
               # wall.foundation_ext_perimeter > 0:
                # crawlspace_wall_area += wall.area  # ft^2
            # if space_int.spacetype == Constants.SpaceCrawl:
                # cs.ext_perimeter += wall.foundation_ext_perimeter
		
		# temp
		crawlspace_wall_area = 624.0
		cs.ext_perimeter = 156.0
		#
		
		if cs.ext_perimeter > 0
			crawlspace_effective_Rvalue = crawlspace_wall_area / (crawlspace_conduction * cs.ext_perimeter) # hr*ft^2*F/Btu
		else
			crawlspace_effective_Rvalue = 1000 # hr*ft^2*F/Btu
		end
		
		crawlspace_US_Rvalue = get_mat_concrete8in(get_mat_concrete).Rvalue + films.vertical + cs.CrawlWallContInsRvalueNominal
		crawlspace_fictitious_Rvalue = crawlspace_effective_Rvalue - get_mat_soil12in(get_mat_soil).Rvalue - crawlspace_US_Rvalue
		
		if cs.CrawlWallContInsRvalueNominal > 0
			cwi.crawlspace_wall_thickness = crawlspace_wall_thickness
			cwi.crawlspace_wall_conductivity = crawlspace_wall_conductivity
			cwi.crawlspace_wall_density = crawlspace_wall_density
			cwi.crawlspace_wall_spec_heat = crawlspace_wall_spec_heat
		end
		
		# Fictitious layer behind unvented crawlspace wall to achieve equivalent R-value. See Winklemann article.
		cwfr.crawlspace_fictitious_Rvalue = crawlspace_fictitious_Rvalue
		
		crawlspace_total_UA = crawlspace_wall_area / crawlspace_effective_Rvalue # Btu/hr*F
		crawlspace_wall_Rvalue = crawlspace_US_Rvalue + get_mat_soil12in(get_mat_soil).Rvalue
		crawlspace_wall_UA = crawlspace_wall_area / crawlspace_wall_Rvalue
		
		if crawlspace_fictitious_Rvalue < 0
			#temp
			area = 1505.0
			#
			crawlspace_floor_Rvalue = area / (crawlspace_total_UA - crawlspace_wall_area / (crawlspace_US_Rvalue + get_mat_soil12in(get_mat_soil).Rvalue)) - get_mat_soil12in(get_mat_soil).Rvalue # hr*ft^2*F/Btu
			 # (assumes crawlspace floor is dirt with no concrete slab)
		else
			crawlspace_floor_Rvalue = 1000 # hr*ft^2*F/Btu
		end

		#crawlspace.WallUA = crawlspace_wall_UA # tk need to make crawlspace object (how is this object used?)
		#crawlspace.FloorUA = crawlspace.area / crawlspace_floor_Rvalue
		#crawlspace.CeilingUA = crawlspace.area / crawl_ceiling_Rvalue
		
		# Fictitious layer below crawlspace floor to achieve equivalent R-value. See Winklemann article.
		cffr.crawlspace_floor_Rvalue = crawlspace_floor_Rvalue
		
		cjc, wallsh = _processConstructionsCrawlspaceRimJoist(cs, wallsh, exterior_finish, cjc)
		
		return cci, cwfr, cwi, cffr, cjc, wallsh

	end
	
	def _processConstructionsCrawlspaceRimJoist(cs, wallsh, exterior_finish, cjc)
	
		rimjoist_framingfactor = 0.6 * cs.CrawlCeilingFramingFactor #0.6 Factor added for due joist orientation
		mat_2x = get_mat_2x(get_mat_wood, cs.CrawlCeilingJoistHeight)
		mat_plywood3_2in = get_mat_plywood3_2in(get_mat_wood)
		wallsh = _addInsulatedSheathingMaterial(wallsh)

		crawl_rimjoist_Rvalue = get_rimjoist_r_assembly(cs, "Crawl", wallsh, 0, 0, rimjoist_framingfactor, exterior_finish.FinishThickness, exterior_finish.FinishConductivity)
		
		crawl_rimjoist_studlayer_Rvalue = crawl_rimjoist_Rvalue - rimjoist_nonstud_layer_Rvalue
		
		crawl_rimjoist_thickness = mat_2x.thick
		crawl_rimjoist_conductivity = crawl_rimjoist_thickness / crawl_rimjoist_studlayer_Rvalue
		
		if cs.CrawlRimJoistInsRvalue > 0
			crawl_rimjoist_density = cs.CrawlCeilingFramingFactor * get_mat_wood.rho + (1 - rimjoist_framingfactor) * get_mat_densepack_generic.rho  # lbm/ft^3
			crawl_rimjoist_spec_heat = (cs.CrawlCeilingFramingFactor * get_mat_wood.Cp * get_mat_wood.rho + (1 - rimjoist_framingfactor) * get_mat_densepack_generic.Cp * get_mat_densepack_generic.rho) / crawl_rimjoist_density # Btu/lbm*F
		else
			crawl_rimjoist_density = rimjoist_framingfactor * get_mat_wood.rho + (1 - rimjoist_framingfactor) * inside_air_dens # lbm/ft^3
			crawl_rimjoist_spec_heat = (rimjoist_framingfactor * get_mat_wood.Cp * get_mat_wood.rho + (1 - rimjoist_framingfactor) * get_mat_air.inside_air_sh * inside_air_dens) / crawl_rimjoist_density # Btu/lbm*F
		end
		
		cjc.crawl_rimjoist_thickness = crawl_rimjoist_thickness
		cjc.crawl_rimjoist_conductivity = crawl_rimjoist_conductivity
		cjc.crawl_rimjoist_density = crawl_rimjoist_density
		cjc.crawl_rimjoist_spec_heat = crawl_rimjoist_spec_heat
   
		return cjc, wallsh
	
	end
	
	def _processConstructionsUnfinishedBasement(ub, carpet, floor_mass, extwallmass, wallsh, exterior_finish, uci, uwi, uwfr, uffr, ujc)
		# if not hasSpaceType(@model, Constants::SpaceUnfinBasement)
			# return
		# end

    films = Get_films_constant.new

		# If there is no wall insulation, apply the ceiling insulation R-value to the rim joists
		if ub.UFBsmtWallContInsRvalue == 0 and ub.UFBsmtWallCavityInsRvalueInstalled == 0
			ub.UFBsmtRimJoistInsRvalue = ub.UFBsmtCeilingCavityInsRvalueNominal
		end

		mat_2x = get_mat_2x(get_mat_wood, ub.UFBsmtCeilingJoistHeight)
		
		# Calculate overall R value of the basement wall, including framed walls with cavity insulation
		overall_wall_Rvalue = get_wood_stud_wall_r_assembly(ub, "UFBsmt", extwallmass.ExtWallMassGypsumThickness, extwallmass.ExtWallMassGypsumNumLayers, 0, nil, ub.UFBsmtWallContInsThickness, ub.UFBsmtWallContInsRvalue)

		ub_conduction_factor = calc_basement_conduction_factor(ub.UFBsmtWallInsHeight, overall_wall_Rvalue)
		
		uci.ub_ceiling_Rvalue = get_unfinished_basement_ceiling_r_assembly(ub, carpet, floor_mass)
		
		ub_ceiling_studlayer_Rvalue = uci.ub_ceiling_Rvalue - floor_nonstud_layer_Rvalue(floor_mass, carpet)
		
		if uci.ub_ceiling_Rvalue > 0
			uci.ub_ceiling_thickness = mat_2x.thick # ft
			uci.ub_ceiling_conductivity = uci.ub_ceiling_thickness / ub_ceiling_studlayer_Rvalue # Btu/hr*ft*F
			uci.ub_ceiling_density = ub.UFBsmtCeilingFramingFactor * get_mat_wood.rho + (1 - ub.UFBsmtCeilingFramingFactor) * get_mat_densepack_generic.rho # lbm/ft^3
			uci.ub_ceiling_spec_heat = (ub.UFBsmtCeilingFramingFactor * get_mat_wood.Cp * get_mat_wood.rho + (1 - ub.UFBsmtCeilingFramingFactor) * get_mat_densepack_generic.Cp * get_mat_densepack_generic.rho) / uci.ub_ceiling_density
		end
		
		# Calculate Exterior Unfinished Basement Wall Area and Perimeter
		ub_wall_area = 0 # ft^2
		ub.ext_perimeter = 0 # ft^2
		
		# temp
		ub_wall_area = 1360
		ub.ext_perimeter = 170
		#
		
        # for wall in geometry.walls.wall:
            # space_int = self._getSpace(wall.space_int)
            # space_ext = self._getSpace(wall.space_ext)
            # if space_int.spacetype == Constants.SpaceUnfinBasement and \
               # space_ext.spacetype == Constants.SpaceGround and \
               # wall.foundation_ext_perimeter > 0:
                # ub_wall_area += wall.area
            # if space_int.spacetype == Constants.SpaceUnfinBasement:
                # ub.ext_perimeter += wall.foundation_ext_perimeter	
				
		if ub.ext_perimeter > 0
			ub_effective_Rvalue = ub_wall_area / (ub_conduction_factor * ub.ext_perimeter)
		else
			ub_effective_Rvalue = 1000 # hr*ft^2*F/Btu
		end
		
        # Insulation of 4ft height inside a 8ft basement is modeled completely in the fictitious layer
        # Insulation of 4ft  inside a 8ft basement is modeled completely in the fictitious layer
		if ub.UFBsmtWallContInsRvalue > 0 and ub.UFBsmtWallInsHeight == 8
			uwi.ub_add_insul_layer = true
		else
			uwi.ub_add_insul_layer = false
		end
		
		if uwi.ub_add_insul_layer
			uwi.ub_wall_Rvalue = ub.UFBsmtWallContInsRvalue # hr*ft^2*F/Btu
			uwi.ub_wall_thickness = uwi.ub_wall_Rvalue * get_mat_rigid_ins.k # ft
			uwi.ub_wall_conductivity = get_mat_rigid_ins.k # Btu/hr*ft*F
			uwi.ub_wall_density = get_mat_rigid_ins.rho # lbm/ft^3
			uwi.ub_spec_heat = get_mat_rigid_ins.Cp
		else
			uwi.ub_wall_Rvalue = 0
		end
		
		ub_US_Rvalue = get_mat_concrete8in(get_mat_concrete).Rvalue + films.vertical + uwi.ub_wall_Rvalue # hr*ft^2*F/Btu
		
		uwfr.ub_fictitious_Rvalue = ub_effective_Rvalue - get_mat_soil12in(get_mat_soil).Rvalue - ub_US_Rvalue # hr*ft^2*F/Btu

        # For some foundations the effective U-value of the wall can be
        # greater than the raw U-value of the wall. If this is the case,
        # then the resistance of the fictitious layer will be negative
        # which DOE-2 will not accept. The code here sets a fictitious
        # R-value for the basement floor which results in the same
        # overall UA value for the crawlspace. Note: The DOE-2 keyword
        # U-EFFECTIVE does not affect DOE-2.2 simulations.
		
		ub_total_UA = ub_wall_area / ub_effective_Rvalue # Btu/hr*F
		ub_wall_Rvalue = ub_US_Rvalue + get_mat_soil12in(get_mat_soil).Rvalue
		ub_wall_UA = ub_wall_area / ub_wall_Rvalue
		
		if uwfr.ub_fictitious_Rvalue < 0 # Not enough cond through walls, need to add in floor conduction
			# To determine basement floor R value, subtract
			# temp
			area = 1505
			#
			ub_basement_floor_Rvalue = area / (ub_total_UA - ub_wall_UA) - get_mat_soil12in(get_mat_soil).Rvalue - get_mat_concrete4in(get_mat_concrete).Rvalue # hr*ft^2*F/Btu # (assumes basement floor is a 4-in concrete slab)
		else
			ub_basement_floor_Rvalue = 1000
		end
		
		# unfinished_basement.WallUA = ub_wallUA
		# unfinished_basement.FloorUA = self._getSpace(Constants.SpaceUnfinBasement).area / ub_basement_floor_Rvalue
		# unfinished_basement.CeilingUA = self._getSpace(Constants.SpaceUnfinBasement).area * 1/ub_ceiling_Rvalue
			
    # Fictitious layer below basement floor to achieve equivalent R-value. See Winklemann article.
    uffr.ub_basement_floor_Rvalue = ub_basement_floor_Rvalue
        
    ujc, wallsh = _processConstructionsUnfinishedBasementRimJoist(ub, wallsh, exterior_finish, ujc)
        
    return uci, uwi, uwfr, uffr, ujc, wallsh
		
	end
	
	def _processConstructionsUnfinishedBasementRimJoist(ub, wallsh, exterior_finish, ujc)
    # if not hasSpaceType(geometry, Constants.SpaceUnfinBasement):
      # return
			
		rimjoist_framingfactor = 0.6 * ub.UFBsmtCeilingFramingFactor #06 Factor added for due joist orientation
		
		mat_2x = get_mat_2x(get_mat_wood, ub.UFBsmtCeilingJoistHeight)
		mat_plywood3_2in = get_mat_plywood3_2in(get_mat_wood)
		wallsh = _addInsulatedSheathingMaterial(wallsh)
		
        ujc.ub_rimjoist_Rvalue = get_rimjoist_r_assembly(ub, "UFBsmt", wallsh, 0, 0, rimjoist_framingfactor, exterior_finish.FinishThickness, exterior_finish.FinishConductivity)
			
        ub_rimjoist_studlayer_Rvalue = ujc.ub_rimjoist_Rvalue - rimjoist_nonstud_layer_Rvalue
        
        ub_rimjoist_thickness = mat_2x.thick
        ub_rimjoist_conductivity = ub_rimjoist_thickness / ub_rimjoist_studlayer_Rvalue			
			
        if ub.UFBsmtRimJoistInsRvalue > 0
            ub_rimjoist_density = rimjoist_framingfactor * get_mat_wood.rho + (1 - rimjoist_framingfactor) * get_mat_densepack_generic.rho # lbm/ft^3
            ub_rimjoist_spec_heat = (rimjoist_framingfactor * get_mat_wood.Cp * get_mat_wood.rho + (1 - rimjoist_framingfactor) * get_mat_densepack_generic.Cp * get_mat_densepack_generic.rho) / ub_rimjoist_density # Btu/lbm*F
		else            
            ub_rimjoist_density = rimjoist_framingfactor * get_mat_wood.rho + (1 - rimjoist_framingfactor) * inside_air_dens # lbm/ft^3
            ub_rimjoist_spec_heat = (rimjoist_framingfactor * get_mat_wood.Cp * get_mat_wood.rho + (1 - rimjoist_framingfactor) * get_mat_air.inside_air_sh * inside_air_dens) / ub_rimjoist_density # Btu/lbm*F
		end
		
		ujc.ub_rimjoist_thickness = ub_rimjoist_thickness
		ujc.ub_rimjoist_conductivity = ub_rimjoist_conductivity
		ujc.ub_rimjoist_density = ub_rimjoist_density
		ujc.ub_rimjoist_spec_heat = ub_rimjoist_spec_heat
		
		return ujc, wallsh			
			
  end

  def _processConstructionsFinishedBasement(fb, carpet, floor_mass, extwallmass, wallsh, exterior_finish, fwi, fwfr, fffr, fjc)
    # if not hasSpaceType(geometry, Constants.SpaceFinBasement):
    #     return

    films = Get_films_constant.new

    # Calculate overall R value of the basement wall, including framed walls with cavity insulation
    overall_wall_Rvalue = get_wood_stud_wall_r_assembly(fb, "FBsmt", extwallmass.ExtWallMassGypsumThickness, extwallmass.ExtWallMassGypsumNumLayers, 0, nil, fb.FBsmtWallContInsThickness, fb.FBsmtWallContInsRvalue)

    fb.conduction_factor = calc_basement_conduction_factor(fb.FBsmtWallInsHeight, overall_wall_Rvalue)

    # Calculate Exterior Finished Basement Wall Area and Perimeter
    # Initialize
    fb.wall_area = 0 # ft^2, FBasementWallArea
    fb.ext_perimeter = 0 # ft, FinishedBasementExtPerimeter

    # temp
    fb.wall_area = 1376
    fb.ext_perimeter = 172
    #

    # for wall in geometry.walls.wall:
    #   space_int = self._getSpace(wall.space_int)
    #   space_ext = self._getSpace(wall.space_ext)
    #   if space_int.spacetype == Constants.SpaceFinBasement and \
    #            space_ext.spacetype == Constants.SpaceGround and \
    #            wall.foundation_ext_perimeter > 0:
    #       self.finished_basement.wall_area += wall.area # ft^2
    #   if space_int.spacetype == Constants.SpaceFinBasement:
    #       self.finished_basement.ext_perimeter += wall.foundation_ext_perimeter
    #
    if fb.ext_perimeter > 0
      fb_effective_Rvalue = fb.wall_area / (fb.conduction_factor * fb.ext_perimeter) # hr*ft^2*F/Btu
    else
      fb_effective_Rvalue = 1000 # hr*ft^2*F/Btu
    end

    # Insulation of 4ft height inside a 8ft basement is modeled completely in the fictitious layer
    if fb.FBsmtWallContInsRvalue > 0 and fb.FBsmtWallInsHeight == 8
      fwi.fb_add_insul_layer = true
    else
      fwi.fb_add_insul_layer = false
    end

    if fwi.fb_add_insul_layer
      fwi.fb_wall_Rvalue = fb.FBsmtWallContInsRvalue # hr*ft^2*F/Btu
      fwi.fb_wall_thickness = fwi.fb_wall_Rvalue * get_mat_rigid_ins.k # ft
      fwi.fb_wall_conductivity = get_mat_rigid_ins.k # Btu/hr*ft*F
      fwi.fb_wall_density = get_mat_rigid_ins.rho # lbm/ft^3
      fwi.fb_wall_specheat = get_mat_rigid_ins.Cp # Btu/lbm*F
    else
      fwi.fb_wall_Rvalue = 0 # hr*ft^2*F/Btu
    end

    fb_US_Rvalue = get_mat_concrete8in(get_mat_concrete).Rvalue + films.vertical + fwi.fb_wall_Rvalue + get_mat_gypsum1_2in(get_mat_gypsum).Rvalue

    fwfr.fb_fictitious_Rvalue = fb_effective_Rvalue - get_mat_soil12in(get_mat_soil).Rvalue - fb_US_Rvalue

      # Fictitious layer behind finished basement wall to achieve
      # equivalent R-value. See Winkelmann article.

    fb_total_ua = fb.wall_area / fb_effective_Rvalue # FBasementTotalUA

    if fwfr.fb_fictitious_Rvalue < 0
      # temp
      area = 1505
      #
      fb_floor_Rvalue = area / (fb_total_ua - fb.wall_area / (fb_US_Rvalue + get_mat_soil12in(get_mat_soil).Rvalue)) - get_mat_soil12in(get_mat_soil).Rvalue - get_mat_concrete4in(get_mat_concrete).Rvalue # hr*ft^2*F/Btu
    else
      fb_floor_Rvalue = 1000 # hr*ft^2*F/Btu
    end

    fffr.fb_floor_Rvalue = fb_floor_Rvalue

    fjc, wallsh = _processConstructionsFinishedBasementRimJoist(fb, wallsh, extwallmass, exterior_finish, fjc)

    return fwi, fwfr, fffr, fjc, wallsh

  end

  def _processConstructionsFinishedBasementRimJoist(fb, wallsh, extwallmass, exterior_finish, fjc)
    # if not hasSpaceType(geometry, Constants.SpaceFinBasement):
    #     return

    rimjoist_framingfactor = 0.6 * fb.FBsmtCeilingFramingFactor #0.6 Factor added for due joist orientation
    mat_2x = get_mat_2x(get_mat_wood, fb.FBsmtCeilingJoistHeight)
    mat_plywood3_2in = get_mat_plywood3_2in(get_mat_wood)

    fjc.fb_rimjoist_Rvalue = get_rimjoist_r_assembly(fb, "FBsmt", wallsh, extwallmass.ExtWallMassGypsumThickness, extwallmass.ExtWallMassGypsumNumLayers, rimjoist_framingfactor, exterior_finish.FinishThickness, exterior_finish.FinishConductivity)

    fb_rimjoist_studlayer_Rvalue = fjc.fb_rimjoist_Rvalue - rimjoist_nonstud_layer_Rvalue

    fb_rimjoist_thickness = mat_2x.thick
    fb_rimjoist_conductivity = fb_rimjoist_thickness / fb_rimjoist_studlayer_Rvalue

    if fb.FBsmtWallContInsRvalue > 0 # insulated rim joist
      fb_rimjoist_density = rimjoist_framingfactor * get_mat_wood.rho + (1 - rimjoist_framingfactor) * get_mat_densepack_generic.rho # lbm/ft^3
      fb_rimjoist_spec_heat = (rimjoist_framingfactor * get_mat_wood.Cp * get_mat_wood.rho + (1 - rimjoist_framingfactor) * get_mat_densepack_generic.Cp * get_mat_densepack_generic.rho) / fb_rimjoist_density # Btu/lbm*F
    else # no insulation
      fb_rimjoist_density = rimjoist_framingfactor * get_mat_wood.rho + (1 - rimjoist_framingfactor) * inside_air_dens # lbm/ft^3
      fb_rimjoist_spec_heat = (rimjoist_framingfactor * get_mat_wood.Cp * get_mat_wood.rho + (1 - rimjoist_framingfactor) * get_mat_air.inside_air_sh * inside_air_dens) / fb_rimjoist_density # Btu/lbm*F
    end

    fjc.fb_rimjoist_thickness = fb_rimjoist_thickness
    fjc.fb_rimjoist_conductivity = fb_rimjoist_conductivity
    fjc.fb_rimjoist_density = fb_rimjoist_density
    fjc.fb_rimjoist_spec_heat = fb_rimjoist_spec_heat

    return fjc, wallsh

  end

  def _processConstructionsInteriorUninsulatedFloors(saf)
    floor_part_U_cavity_path = (1 - Sim.floor_framing_factor) / get_mat_air.R_air_gap # Btu/hr*ft^2*F
    floor_part_U_stud_path = Sim.floor_framing_factor / get_mat_2x6(get_mat_wood).Rvalue # Btu/hr*ft^2*F
    floor_part_Rvalue = 1 / (floor_part_U_cavity_path + floor_part_U_stud_path) # hr*ft^2*F/Btu

    saf.floor_part_thickness = get_mat_2x4(get_mat_wood).thick # ft
    saf.floor_part_conductivity = saf.floor_part_thickness / floor_part_Rvalue # Btu/hr*ft*F
    saf.floor_part_density = Sim.floor_framing_factor * get_mat_wood.rho + (1 - Sim.floor_framing_factor) * inside_air_dens # lbm/ft^3
    saf.floor_part_spec_heat = (Sim.floor_framing_factor * get_mat_wood.Cp * get_mat_wood.rho + (1 - Sim.floor_framing_factor) * get_mat_air.inside_air_sh * inside_air_dens) / saf.floor_part_density # Btu/lbm*F

    return saf
  end

  def _processConstructionsInteriorInsulatedFloors(izf, carpet, floor_mass, ifi)
    # if izf.IntFloorFramingFactor is None:
    #   return

    mat_wood = get_mat_wood
    mat_2x6 = get_mat_2x6(mat_wood)

    overall_floor_Rvalue = get_interzonal_floor_r_assembly(izf, carpet.CarpetPadRValue, carpet.CarpetFloorFraction, floor_mass)

    # Get overall R-value using parallel paths:
    boundaryFloorRvalue = (overall_floor_Rvalue - floor_nonstud_layer_Rvalue(floor_mass, carpet))

    ifi.boundary_floor_thickness = mat_2x6.thick # ft
    ifi.boundary_floor_conductivity = ifi.boundary_floor_thickness / boundaryFloorRvalue # Btu/hr*ft*F
    ifi.boundary_floor_density = izf.IntFloorFramingFactor * mat_wood.rho + (1 - izf.IntFloorFramingFactor) * get_mat_densepack_generic.rho # lbm/ft^3
    ifi.boundary_floor_spec_heat = (izf.IntFloorFramingFactor * mat_wood.Cp * mat_wood.rho + (1 - izf.IntFloorFramingFactor) * get_mat_densepack_generic.Cp * get_mat_densepack_generic.rho) / ifi.boundary_floor_density # Btu/lbm*F

    return ifi

  end

  def _processConstructionsUnfinishedAtticCeiling(uatc, eaves_options, ceiling_mass, uaaci, uatai)
    # if not hasSpaceType(geometry, Constants.SpaceUnfinAttic):
    #     return

    films = Get_films_constant.new

    uatc.UACeilingInsThickness_Rev = get_unfinished_attic_perimeter_insulation_derating(uatc, geometry="temp", eaves_options.EavesDepth)

    # Set properties of ceilings below unfinished attics.

    # If there is ceiling insulation
    if not (uatc.UACeilingInsRvalueNominal == 0 or uatc.UACeilingInsThickness_Rev == 0)

      uA_ceiling_overall_ins_Rvalue = get_unfinished_attic_ceiling_r_assembly(uatc, ceiling_mass.CeilingMassGypsumThickness, ceiling_mass.CeilingMassGypsumNumLayers, uatc.UACeilingInsThickness_Rev)

      # If the ceiling insulation thickness is greater than the joist thickness
      if uatc.UACeilingInsThickness_Rev >= uatc.UACeilingJoistThickness

        # Define a layer equivalent to the thickness of the joists,
        # including both heat flow paths (joist and insulation in parallel).
        uA_ceiling_joist_ins_Rvalue = (uA_ceiling_overall_ins_Rvalue - ceiling_mass.Rvalue - 2.0 * films.floor_average - uatc.UACeilingInsRvalueNominal_Rev + uatc.UACeilingInsRvalueNominal_Rev * uatc.UACeilingJoistThickness / uatc.UACeilingInsThickness_Rev) # Btu/hr*ft^2*F
        uA_ceiling_joist_ins_conductivity = (OpenStudio::convert(uatc.UACeilingJoistThickness,"in","ft").get / uA_ceiling_joist_ins_Rvalue) # Btu/hr*ft*F
        uA_ceiling_joist_ins_density = uatc.UACeilingFramingFactor * get_mat_wood.rho + (1 - uatc.UACeilingFramingFactor) * get_mat_loosefill_generic.rho # lbm/ft^3
        uA_ceiling_joist_ins_spec_heat = (uatc.UACeilingFramingFactor * get_mat_wood.Cp * get_mat_wood.rho + (1 - uatc.UACeilingFramingFactor) * get_mat_loosefill_generic.Cp * get_mat_loosefill_generic.rho) / uA_ceiling_joist_ins_density # lbm/ft^3

        # If there is additional insulation, above the rafter height,
        # these inputs are used for defining an additional layer.
        if uatc.UACeilingInsThickness_Rev > uatc.UACeilingJoistThickness

          uaaci.UA_ceiling_ins_above_density = get_mat_loosefill_generic.rho # lbm/ft^3
          uaaci.UA_ceiling_ins_above_spec_heat = get_mat_loosefill_generic.Cp # Btu/lbm*F

        # Else the joist thickness is greater than the ceiling insulation thickness
        else
          # Define a layer equivalent to the thickness of the joists,
          # including both heat flow paths (joists and insulation in parallel).
          uA_ceiling_joist_ins_conductivity = (OpenStudio::convert(uatc.UACeilingJoistThickness,"in","ft").get / (uA_ceiling_overall_ins_Rvalue - ceiling_mass.Rvalue - 2.0 * films.floor_average)) # Btu/hr*ft*F
          uA_ceiling_joist_ins_density = OpenStudio::convert(uatc.UACeilingJoistThickness,"in","ft").get / uatc.UACeilingJoistThickness * (uatc.UACeilingFramingFactor * get_mat_wood.rho + (1 - uatc.UACeilingFramingFactor) * get_mat_loosefill_generic.rho) + (1 - OpenStudio::convert(uatc.UACeilingJoistThickness,"in","ft").get / uatc.UACeilingJoistThickness) * inside_air_dens # lbm/ft^3
          uA_ceiling_joist_ins_spec_heat = (OpenStudio::convert(uatc.UACeilingJoistThickness,"in","ft").get / uatc.UACeilingJoistThickness * (uatc.UACeilingFramingFactor * get_mat_wood.Cp * get_mat_wood.rho + (1 - uatc.UACeilingFramingFactor) * get_mat_loosefill_generic.Cp * get_mat_loosefill_generic.rho) + (1 - OpenStudio::convert(uatc.UACeilingJoistThickness,"in","ft").get / uatc.UACeilingJoistThickness) * get_mat_air.inside_air_sh * inside_air_dens) / uA_ceiling_joist_ins_density # Btu/lbm*F
        end

      end

    else

      uatc.UACeilingInsRvalueNominal_Rev = 0

    end

    if uatc.UACeilingInsRvalueNominal_Rev != 0 and uatc.UACeilingInsThickness_Rev != 0
      uatai.UA_ceiling_joist_ins_conductivity = uA_ceiling_joist_ins_conductivity
      uatai.UA_ceiling_joist_ins_density = uA_ceiling_joist_ins_density
      uatai.UA_ceiling_joist_ins_spec_heat = uA_ceiling_joist_ins_spec_heat
    end

    return uaaci, uatai

  end

  def _processConstructionsUnfinishedAtticRoof(uatc, radiant_barrier, uarri, uari)
    # if not hasSpaceType(geometry, Constants.SpaceUnfinAttic):
    #     return

    film = _processFilmResistances

    uA_roof_overall_ins_Rvalue, uA_roof_ins_thickness = get_unfinished_attic_roof_r_assembly(uatc, radiant_barrier.HasRadiantBarrier, film.roof)

    if uatc.UARoofContInsThickness > 0
      uA_roof_overall_ins_Rvalue = (uA_roof_overall_ins_Rvalue - film.roof - film.outside - 2.0 * get_mat_plywood3_4in(get_mat_wood).Rvalue - uatc.UARoofContInsRvalue) # hr*ft^2*F/Btu

      uarri.UA_roof_rigid_foam_ins_thickness = OpenStudio::convert(uatc.UARoofContInsThickness,"in","ft").get
      uarri.UA_roof_rigid_foam_ins_conductivity = uarri.UA_roof_rigid_foam_ins_thickness / uatc.UARoofContInsRvalue # Btu/hr*ft*F
      uarri.UA_roof_rigid_foam_ins_density = get_mat_rigid_ins.rho # lbm/ft^3
      uarri.UA_roof_rigid_foam_ins_spec_heat = get_mat_rigid_ins.Cp # Btu/lbm*F

    else

      # uatc.UARoofContInsRvalue = 0

      uA_roof_overall_ins_Rvalue = (uA_roof_overall_ins_Rvalue - film.roof - film.outside - get_mat_plywood3_4in(get_mat_wood).Rvalue) # hr*ft^2*F/Btu

    end

    uA_roof_ins_conductivity = uA_roof_ins_thickness / uA_roof_overall_ins_Rvalue # Btu/hr*ft*F

    if uatc.UARoofInsRvalueNominal == 0
      uA_roof_ins_density = uatc.UARoofFramingFactor * get_mat_wood.rho + (1 - uatc.UARoofFramingFactor) * inside_air_dens # lbm/ft^3
      uA_roof_ins_spec_heat = (uatc.UARoofFramingFactor * get_mat_wood.Cp * get_mat_wood.rho + (1 - uatc.UARoofFramingFactor) * get_mat_air.inside_air_sh * inside_air_dens) / uA_roof_ins_density # Btu/lb*F
    else
      uA_roof_ins_density = uatc.UARoofFramingFactor * get_mat_wood.rho + (1 - uatc.UARoofFramingFactor) * get_mat_densepack_generic.rho # lbm/ft^3
      uA_roof_ins_spec_heat = (uatc.UARoofFramingFactor * get_mat_wood.Cp * get_mat_wood.rho + (1 - uatc.UARoofFramingFactor) * get_mat_densepack_generic.Cp * get_mat_densepack_generic.rho) / uA_roof_ins_density # Btu/lb*F
    end

    uari.UA_roof_ins_thickness = uA_roof_ins_thickness
    uari.UA_roof_ins_conductivity = uA_roof_ins_conductivity
    uari.UA_roof_ins_density = uA_roof_ins_density
    uari.UA_roof_ins_spec_heat = uA_roof_ins_spec_heat

    # Set UA roof film
    if radiant_barrier.HasRadiantBarrier
      uA_roof_film = film.roof_radiant_barrier
    else
      uA_roof_film = film.roof
    end

    return uarri, uari

  end

  def _processConstructionsInsulatedRoof(fr, ceiling_mass, ri, rri)
    # if not self.finished_roof.surface_area > 0
    #   return
    # end

    film = _processFilmResistances

    fr_roof_overall_ins_Rvalue = get_finished_roof_r_assembly(fr, ceiling_mass.CeilingMassGypsumThickness, ceiling_mass.CeilingMassGypsumNumLayers, film.roof)

    if fr.FRRoofContInsThickness > 0
      fr_roof_stud_ins_Rvalue = fr_roof_overall_ins_Rvalue - fr.FRRoofContInsRvalue - 2.0 * get_mat_plywood3_4in(get_mat_wood).Rvalue - ceiling_mass.Rvalue - film.roof - film.outside # hr*ft^2*F/Btu
    else
      fr_roof_stud_ins_Rvalue = fr_roof_overall_ins_Rvalue - get_mat_plywood3_4in(get_mat_wood).Rvalue - ceiling_mass.Rvalue - film.roof - film.outside # hr*ft^2*F/Btu
    end

    # Set roof characteristics for finished roof
    ri.fr_roof_ins_thickness = OpenStudio::convert(fr.FRRoofCavityDepth,"in","ft").get # ft
    ri.fr_roof_ins_conductivity = ri.fr_roof_ins_thickness / fr_roof_stud_ins_Rvalue # Btu/hr*ft*F
    ri.fr_roof_ins_density = fr.FRRoofFramingFactor * get_mat_wood.rho + (1 - fr.FRRoofFramingFactor) * get_mat_densepack_generic.rho # lbm/ft^3
    ri.fr_roof_ins_spec_heat = (fr.FRRoofFramingFactor * get_mat_wood.Cp * get_mat_wood.rho + (1 - fr.FRRoofFramingFactor) * get_mat_densepack_generic.Cp * get_mat_densepack_generic.rho) / ri.fr_roof_ins_density # Btu/lbm*F

    if fr.FRRoofContInsThickness > 0
      rri.fr_roof_rigid_foam_ins_thickness = OpenStudio::convert(fr.FRRoofContInsThickness,"in","ft").get # after() do
      rri.fr_roof_rigid_foam_ins_conductivity = rri.fr_roof_rigid_foam_ins_thickness / fr.FRRoofContInsRvalue # Btu/hr*ft*F
      rri.fr_roof_rigid_foam_ins_density = get_mat_rigid_ins.rho # lbm/ft^3
      rri.fr_roof_rigid_foam_ins_spec_heat = get_mat_rigid_ins.Cp # Btu/lbm*F
    end

    return ri, rri

  end

  def _processConstructionsGarageRoof(gsa)
    # if not hasSpaceType(geometry, Constants.SpaceGarage):
    #     return

    film = _processFilmResistances

    #generic method
    path_fracs = [Sim.ceiling_framing_factor, 1 - Sim.ceiling_framing_factor]
    roof_const = Construction.new(path_fracs)

    # Interior Film
    roof_const.addlayer(thickness=OpenStudio::convert(1.0,"in","ft").get, conductivity_list=[OpenStudio::convert(1.0,"in","ft").get / film.roof])

    # Stud/cavity layer
    roof_const.addlayer(thickness=get_mat_2x4(get_mat_wood).thick, conductivity_list=[get_mat_wood.k, 1000000000.0])

    # Sheathing
    roof_const.addlayer(thickness=nil, conductivity_list=nil, material=get_mat_plywood3_4in(get_mat_wood), material_list=nil)

    # Exterior Film
    roof_const.addlayer(thickness=OpenStudio::convert(1.0,"in","ft").get, conductivity_list=[OpenStudio::convert(1.0,"in","ft").get / film.outside])

    grgRoofStudandAir_Rvalue = roof_const.Rvalue_parallel - film.roof - film.outside - get_mat_plywood3_4in(get_mat_wood).Rvalue # hr*ft^2*F/Btu

    gsa.grg_roof_thickness = get_mat_2x4(get_mat_wood).thick # ft
    gsa.grg_roof_conductivity = gsa.grg_roof_thickness / grgRoofStudandAir_Rvalue # Btu/hr*ft*F
    gsa.grg_roof_density = Sim.ceiling_framing_factor * get_mat_wood.rho + (1 - Sim.ceiling_framing_factor) * inside_air_dens # lbm/ft^3
    gsa.grg_roof_spec_heat = (Sim.ceiling_framing_factor * get_mat_wood.Cp * get_mat_wood.rho + (1 - Sim.ceiling_framing_factor) * get_mat_air.inside_air_sh * inside_air_dens) / gsa.grg_roof_density # Btu/lbm*F

    return gsa

  end  

  def _processConstructionsDoors(d, gd)

    film = _processFilmResistances

    door_Uvalue_air_to_air = 0.2 # Btu/hr*ft^2*F, As per 2010 BA Benchmark
    garage_door_Uvalue_air_to_air = 0.2 # Btu/hr*ft^2*F, R-values typically vary from R5 to R10, from the Home Depot website

    door_Rvalue_air_to_air = 1.0 / door_Uvalue_air_to_air
    garage_door_Rvalue_air_to_air = 1.0 / garage_door_Uvalue_air_to_air

    door_Rvalue = door_Rvalue_air_to_air - film.outside - film.vertical
    garage_door_Rvalue = garage_door_Rvalue_air_to_air - film.outside - film.vertical

    d.mat_door_Uvalue = 1.0 / door_Rvalue
    gd.garage_door_Uvalue = 1.0 / garage_door_Rvalue

    d.door_thickness = 0.208 # ft
    gd.garage_door_thickness = 0.208 # ft

    return d, gd

  end

	def _addInsulatedSheathingMaterial(wallsh)
		if wallsh.WallSheathingContInsThickness == 0
			return wallsh
		end
		
		# Set Rigid Insulation Layer Properties
		wallsh.rigid_ins_layer_thickness = OpenStudio::convert(wallsh.WallSheathingContInsThickness,"in","ft").get # ft
		wallsh.rigid_ins_layer_conductivity = wallsh.rigid_ins_layer_thickness / wallsh.WallSheathingContInsRvalue # Btu/hr*ft*F
		wallsh.rigid_ins_layer_density = get_mat_rigid_ins.rho
		wallsh.rigid_ins_layer_spec_heat = 0.29 # Btu/lbm*F
		
		return wallsh
		
  end

  def _processFilmResistances
    # Film Resistances
    # The following film resistance are used only in sim.py and DOE2

    # cdd = weather.data.CDD65F
    # hdd = weather.data.HDD65F
    # temp
    cdd = 2729.0
    hdd = 1349.0
    #

    # Air Film Resistances
    film = Get_films_constant.new

    # Correlation functions used to interpolate between values provided
    # in ASHRAE 2005, F25.2, Table 1 - which only provides values for
    # 0, 45, and 90 degrees.
    # FilmSlopeXXX values are for non-reflective materials of emissivity = 0.90.
    # film.slope_enhanced = 0.002 * Math::exp(0.0398 * geometry.highest_roof_pitch) + 0.608 # hr-ft-F/Btu (evaluates to FilmFlatEnhanced at 0 degrees, 0.62 at 45 degrees, and FilmVertical at 90 degrees)
    # film.slope_reduced = 0.32 * Math::exp(-0.0154 * geometry.highest_roof_pitch) + 0.6 # hr-ft-F/Btu (evaluates to FilmFlatReduced at 0 degrees, 0.76 at 45 degrees, and FilmVertical at 90 degrees)
    # # FilmSlopeXXXReflective values are for reflective materials of emissivity = 0.05.
    # film.slope_enhanced_reflective = 0.00893 * Math::exp(0.0419 * geometry.hghest_roof_pitch) + 1.311 # hr-ft-F/Btu (evaluates to 1.32 at 0 degrees, 1.37 at 45 degrees, and 1.70 at 90 degrees)
    # film.slope_reduced_reflective = 2.999 * Math::exp(-0.0333 * geometry.highest_roof_pitch) + 1.551 # hr-ft-F/Btu (evaluates to 4.55 at 0 degrees, 2.22 at 45 degrees, and 1.70 at 90 degrees)
    # temp
    hrp = 26.565052
    film.slope_enhanced = 0.002 * Math::exp(0.0398 * hrp) + 0.608 # hr-ft-F/Btu (evaluates to FilmFlatEnhanced at 0 degrees, 0.62 at 45 degrees, and FilmVertical at 90 degrees)
    film.slope_reduced = 0.32 * Math::exp(-0.0154 * hrp) + 0.6 # hr-ft-F/Btu (evaluates to FilmFlatReduced at 0 degrees, 0.76 at 45 degrees, and FilmVertical at 90 degrees)
    # FilmSlopeXXXReflective values are for reflective materials of emissivity = 0.05.
    film.slope_enhanced_reflective = 0.00893 * Math::exp(0.0419 * hrp) + 1.311 # hr-ft-F/Btu (evaluates to 1.32 at 0 degrees, 1.37 at 45 degrees, and 1.70 at 90 degrees)
    film.slope_reduced_reflective = 2.999 * Math::exp(-0.0333 * hrp) + 1.551 # hr-ft-F/Btu (evaluates to 4.55 at 0 degrees, 2.22 at 45 degrees, and 1.70 at 90 degrees)
    #

    # Use weighted average between enhanced and reduced convection based on degree days.
    hdd_frac = hdd / (hdd + cdd)
    cdd_frac = cdd / (hdd + cdd)
    film.roof = film.slope_enhanced * hdd_frac + film.slope_reduced * cdd_frac # hr-ft-F/Btu
    film.roof_radiant_barrier = film.slope_enhanced_reflective * hdd_frac + film.slope_reduced_reflective * cdd_frac # hr-ft-F/Btu

    # For floors above/below unconditioned spaces. Use weighted average between
    # enhanced and reduced convection based on degree days.
    film.floor_below_unconditioned = film.flat_enhanced * hdd_frac + film.flat_reduced * cdd_frac # hr-ft-F/Btu
    film.floor_above_unconditioned = film.flat_reduced * hdd_frac + film.flat_enhanced * cdd_frac

    return film

  end
	
end

def get_rimjoist_r_assembly(category, prefix, wallsh, drywallThickness, drywallNumLayers, rimjoist_framingfactor, finishThickness, finishConductivity)
	# Returns assembly R-value for crawlspace or unfinished/finished basement rimjoist, including air films.
	
	rimJoistInsRvalue = category.send("#{prefix}RimJoistInsRvalue")
	ceilingJoistHeight = category.send("#{prefix}CeilingJoistHeight")
	framingFactor = rimjoist_framingfactor
	
	mat_wood = get_mat_wood
	mat_2x = get_mat_2x(mat_wood, ceilingJoistHeight)
	mat_plywood3_2in = get_mat_plywood3_2in(mat_wood)
	air = get_mat_air
	films = Get_films_constant.new
	
	path_fracs = [framingFactor, 1 - framingFactor]
	
	prefix_rimjoist = Construction.new(path_fracs)
	
	# Interior Film	
	prefix_rimjoist.addlayer(thickness=OpenStudio::convert(1.0,"in","ft").get, conductivity_list=[OpenStudio::convert(1.0,"in","ft").get / films.floor_reduced])

	# Stud/cavity layer
	if rimJoistInsRvalue == 0
		cavity_k = (mat_2x.thick / air.R_air_gap)
	else
		cavity_k = (mat_2x.thick / rimJoistInsRvalue)
	end
		
	prefix_rimjoist.addlayer(thickness=mat_2x.thick, conductivity_list=[mat_wood.k, cavity_k])
	
	# Rim Joist wood layer
	prefix_rimjoist.addlayer(thickness=nil, conductivity_list=nil, material=mat_plywood3_2in, material_list=nil)
	
	# Wall Sheathing
	if wallsh.WallSheathingContInsRvalue > 0
		wallsh_k = (wallsh.WallSheathingContInsThickness / wallsh.WallSheathingContInsRvalue)
		prefix_rimjoist.addlayer(thickness=OpenStudio::convert(wallsh.WallSheathingContInsThickness,"in","ft").get, conductivity_list=[wallsh_k])
	end
	prefix_rimjoist.addlayer(thickness=OpenStudio::convert(finishThickness,"in","ft").get, conductivity_list=[finishConductivity])
	
	# Exterior Film
	prefix_rimjoist.addlayer(thickness=OpenStudio::convert(1.0,"in","ft").get, conductivity_list=[OpenStudio::convert(1,"in","ft").get / films.floor_reduced])
	
	return prefix_rimjoist.Rvalue_parallel

end	

def get_crawlspace_ceiling_r_assembly(cs, carpet, floor_mass)
	# Returns assembly R-value for crawlspace ceiling, including air films.
	
	mat_wood = get_mat_wood
	mat_2x = get_mat_2x(mat_wood, cs.CrawlCeilingJoistHeight)
	mat_plywood3_4in = get_mat_plywood3_4in(mat_wood)
	films = Get_films_constant.new
	
	path_fracs = [cs.CrawlCeilingFramingFactor, 1 - cs.CrawlCeilingFramingFactor]
	
	crawl_ceiling = Construction.new(path_fracs)
	
	# Interior Film
	crawl_ceiling.addlayer(thickness=OpenStudio::convert(1.0,"in","ft").get, conductivity_list=[OpenStudio::convert(1.0,"in","ft").get / films.floor_reduced])
	
	# Stud/cavity layer
	if cs.CrawlCeilingCavityInsRvalueNominal == 0
		cavity_k = 1000000000
	else
		cavity_k = (mat_2x.thick / cs.CrawlCeilingCavityInsRvalueNominal)
	end
	crawl_ceiling.addlayer(thickness=mat_2x.thick, conductivity_list=[mat_wood.k, cavity_k])

	# Floor deck
	crawl_ceiling.addlayer(thickness=nil, conductivity_list=nil, material=mat_plywood3_4in)

	# Floor mass
	if floor_mass.FloorMassThickness > 0
		mat_floor_mass = get_mat_floor_mass(floor_mass)
		crawl_ceiling.addlayer(thickness=nil, conductivity_list=nil, material=mat_floor_mass)
	end

	# Carpet
	if carpet.CarpetFloorFraction > 0
		carpet_smeared_cond = OpenStudio::convert(0.5,"in","ft").get / (carpet.CarpetPadRValue * carpet.CarpetFloorFraction)
		crawl_ceiling.addlayer(thickness=OpenStudio::convert(0.5,"in","ft").get, conductivity_list=[carpet_smeared_cond])	
	end

	# Exterior Film
	crawl_ceiling.addlayer(thickness=OpenStudio::convert(1.0,"in","ft").get, conductivity_list=[OpenStudio::convert(1.0,"in","ft").get / films.floor_reduced])

	return crawl_ceiling.Rvalue_parallel
	
end

def calc_crawlspace_wall_conductance(crawlWallContInsRvalueNominal, crawlWallHeight)
	# Interpolate/extrapolate between 2ft and 4ft conduction factors based on actual space height:
	crawlspace_conduction2 = 1.120 / (0.237 + crawlWallContInsRvalueNominal) ** 0.099
	crawlspace_conduction4 = 1.126 / (0.621 + crawlWallContInsRvalueNominal) ** 0.269
	crawlspace_conduction = crawlspace_conduction2 + (crawlspace_conduction4 - crawlspace_conduction2) * (crawlWallHeight - 2) / (4 - 2)
	return crawlspace_conduction
end

def hasSlab(model)
    # Return true/false whether building has a slab foundation.
    # if geometry.floors is None:
        # return False
    # for floor in geometry.floors.floor:
        # if getSpace(geometry, floor.space_below).spacetype == Constants.SpaceGround and \
           # getSpace(geometry, floor.space_above).spacetype == Constants.SpaceLiving:
            # return True
    # return False
end

def SlabPerimeterConductancesByType(slab)
	slabWidth = 28 # Width (shorter dimension) of slab, feet, to match Winkelmann analysis.
	slabLength = 55 # Longer dimension of slab, feet, to match Winkelmann analysis.
	soilConductivity = 1
	slab.SlabHasWholeInsulation = false
	if slab.SlabPerimeterRvalue > 0
		slab.SlabCarpetPerimeterConduction = PerimeterSlabInsulation(slab.SlabPerimeterRvalue, slab.SlabGapRvalue, slab.SlabPerimeterInsWidth, slabWidth, slabLength, 1, soilConductivity)
		slab.SlabBarePerimeterConduction = PerimeterSlabInsulation(slab.SlabPerimeterRvalue, slab.SlabGapRvalue, slab.SlabPerimeterInsWidth, slabWidth, slabLength, 0, soilConductivity)
	elsif slab.SlabExtRvalue > 0
		slab.SlabCarpetPerimeterConduction = ExteriorSlabInsulation(slab.SlabExtInsDepth, slab.SlabExtRvalue, 1)
		slab.SlabBarePerimeterConduction = ExteriorSlabInsulation(slab.SlabExtInsDepth, slab.SlabExtRvalue, 0)
	elsif slab.SlabWholeInsRvalue > 0
		slab.SlabHasWholeInsulation = true
		if slab.SlabWholeInsRvalue >= 999
			# Super insulated slab option
			slab.SlabCarpetPerimeterConduction = 0.001
			slab.SlabBarePerimeterConduction = 0.001
		else
			slab.SlabCarpetPerimeterConduction = FullSlabInsulation(slab.SlabWholeInsRvalue, slab.SlabGapRvalue, slabWidth, slabLength, 1, soilConductivity)
			slab.SlabBarePerimeterConduction = FullSlabInsulation(slab.SlabWholeInsRvalue, slab.SlabGapRvalue, slabWidth, slabLength, 0, soilConductivity)
		end
	else
		slab.SlabCarpetPerimeterConduction = FullSlabInsulation(0, 0, slabWidth, slabLength, 1, soilConductivity)
		slab.SlabBarePerimeterConduction = FullSlabInsulation(0, 0, slabWidth, slabLength, 0, soilConductivity)
		#The above two values are returned through slab.
	end
	
	return slab
end

def PerimeterSlabInsulation(rperim, rgap, wperim, slabWidth, slabLength, carpet, k)
    # Coded by Dennis Barley, April 2013.
    # This routine calculates the perimeter conductance for a slab with insulation 
    #   under the slab perimeter as well as gap insulation around the edge.
    #   The algorithm is based on a correlation to a set of related, fully insulated
    #   and uninsulated slab (sections), using the FullSlabInsulation function above.
    # Parameters:
    #   Rperim     = R-factor of insulation placed horizontally under the slab perimeter, h*ft2*F/Btu
    #   Rgap       = R-factor of insulation placed vertically between edge of slab & foundation wall, h*ft2*F/Btu
    #   Wperim     = Width of the perimeter insulation, ft.  Must be > 0.
    #   SlabWidth  = width (shorter dimension) of the slab, ft
    #   SlabLength = longer dimension of the slab, ft
    #   Carpet     = 1 if carpeted, 0 if not carpeted
    #   k          = thermal conductivity of the soil, Btu/h*ft*F
    # Constants:
    k2 =  0.329201  # 1st curve fit coefficient
    p = -0.327734  # 2nd curve fit coefficient
    q =  1.158418  # 3rd curve fit coefficient
    r =  0.144171  # 4th curve fit coefficient
    # Related, fully insulated slabs:
    b = FullSlabInsulation(rperim, rgap, 2 * wperim, slabLength, carpet, k)
    c = FullSlabInsulation(0 ,0 , slabWidth, slabLength, carpet, k)
    d = FullSlabInsulation(0, 0, 2 * wperim, slabLength, carpet, k)
    # Trap zeros or small negatives before exponents are applied:
    dB = [d-b, 0.0000001].max
    cD = [c-d, 0.0000001].max
    wp = [wperim, 0.0000001].max
    # Result:
    perimeterConductance = b + c - d + k2 * (2 * wp / slabWidth) ** p * dB ** q * cD ** r 
    return perimeterConductance	
end

def FullSlabInsulation(rbottom, rgap, w, l, carpet, k)
    # Coded by Dennis Barley, March 2013.
    # This routine calculates the perimeter conductance for a slab with insulation 
    #   under the entire slab as well as gap insulation around the edge.
    # Parameters:
    #   Rbottom = R-factor of insulation placed horizontally under the entire slab, h*ft2*F/Btu
    #   Rgap    = R-factor of insulation placed vertically between edge of slab & foundation wall, h*ft2*F/Btu
    #   W       = width (shorter dimension) of the slab, ft.  Set to 28 to match Winkelmann analysis.
    #   L       = longer dimension of the slab, ft.  Set to 55 to match Winkelmann analysis. 
    #   Carpet  = 1 if carpeted, 0 if not carpeted
    #   k       = thermal conductivity of the soil, Btu/h*ft*F.  Set to 1 to match Winkelmann analysis.
    # Constants:
    zf = 0      # Depth of slab bottom, ft
    r0 = 1.47    # Thermal resistance of concrete slab and inside air film, h*ft2*F/Btu
    rca = 0      # R-value of carpet, if absent,  h*ft2*F/Btu
    rcp = 2.0      # R-value of carpet, if present, h*ft2*F/Btu
    rsea = 0.8860  # Effective resistance of slab edge if carpet is absent,  h*ft2*F/Btu
    rsep = 1.5260  # Effective resistance of slab edge if carpet is present, h*ft2*F/Btu
    t  = 4.0 / 12.0  # Thickness of slab: Assumed value if 4 inches; not a variable in the analysis, ft
    # Carpet factors:
    if carpet == 0
        rc  = rca
        rse = rsea
    else
        if carpet == 1
            rc  = rcp
            rse = rsep
        else
            runner.registerError("In FullSlabInsulation, Carpet must be 0 or 1.")
		end
	end
			
    rother = rc + r0 + rbottom   # Thermal resistance other than the soil (from inside air to soil)
    # Ubottom:
    term1 = 2.0 * k / (Math::PI * w)
    term3 = zf / 2.0 + k * rother / Math::PI
    term2 = term3 + w / 2.0
    ubottom = term1 * Math::log(term2 / term3)
    pbottom = ubottom * (l * w) / (2.0 * (l + w))
    # Uedge:
    uedge = 1.0 / (rse + rgap)
    pedge = t * uedge
    # Result:
    perimeterConductance = pbottom + pedge
    return perimeterConductance
end

def ExteriorSlabInsulation(depth, rvalue, carpet)
    # Coded by Dennis Barley, April 2013.
    # This routine calculates the perimeter conductance for a slab with insulation 
    #   placed vertically outside the foundation.
    #   This is a correlation to Winkelmann results.
    # Parameters:
    #   Depth     = Depth to which insulation extends into the ground, ft
    #   Rvalue    = R-factor of insulation, h*ft2*F/Btu
    #   Carpet    = 1 if carpeted, 0 if not carpeted
    # Carpet factors:
    if carpet == 0
        a  = 9.02928
        b  = 8.20902
        e1 = 0.54383
        e2 = 0.74266
    else
        if carpet == 1
            a  =  8.53957
            b  = 11.09168
            e1 =  0.57937
            e2 =  0.80699
        else
            runner.registerError("In ExteriorSlabInsulation, Carpet must be 0 or 1.")
		end
	end
    perimeterConductance = a / (b + rvalue ** e1 * depth ** e2) 
    return perimeterConductance
end

def calc_basement_conduction_factor(bsmtWallInsulationHeight, bsmtWallInsulRvalue)
	if bsmtWallInsulationHeight == 4
		return (1.689 / (0.430 + bsmtWallInsulRvalue) ** 0.164)
	else
		return (2.494 / (1.673 + bsmtWallInsulRvalue) ** 0.488)
	end
end

def get_unfinished_basement_ceiling_r_assembly(ub, carpet, floor_mass)
	# Returns assembly R-value for unfinished basement ceiling, including air films.
	mat_wood = get_mat_wood
	mat_2x = get_mat_2x(get_mat_wood, ub.UFBsmtCeilingJoistHeight)
	mat_plywood3_4in = get_mat_plywood3_4in(mat_wood)
	films = Get_films_constant.new
	
	path_fracs = [ub.UFBsmtCeilingFramingFactor, 1 - ub.UFBsmtCeilingFramingFactor]
	
	ub_ceiling = Construction.new(path_fracs)
	
	# Interior Film
	ub_ceiling.addlayer(thickness=OpenStudio::convert(1,"in","ft").get, conductivity_list=[OpenStudio::convert(1,"in","ft").get / films.floor_reduced])
	
	# Stud/cavity layer
	if ub.UFBsmtCeilingCavityInsRvalueNominal == 0
		cavity_k = 1000000000
	else	
		cavity_k = (mat_2x.thick / ub.UFBsmtCeilingCavityInsRvalueNominal)
	end
	
	ub_ceiling.addlayer(thickness=mat_2x.thick, conductivity_list=[mat_wood.k, cavity_k])
	
	# Floor deck
	ub_ceiling.addlayer(thickness=nil, conductivity_list=nil, material=mat_plywood3_4in, material_list=nil)
	
	# Floor mass
	if floor_mass.FloorMassThickness > 0
		mat_floor_mass = get_mat_floor_mass(floor_mass)
		ub_ceiling.addlayer(thickness=nil, conductivity_list=nil, material=mat_floor_mass, material_list=nil)
	end
	
	# Carpet
	if carpet.CarpetFloorFraction > 0
		carpet_smeared_cond = OpenStudio::convert(0.5,"in","ft").get / (carpet.CarpetPadRValue * carpet.CarpetFloorFraction)
		ub_ceiling.addlayer(thickness=OpenStudio::convert(0.5,"in","ft").get, conductivity_list=[carpet_smeared_cond])
	end
	
	# Exterior Film
	ub_ceiling.addlayer(thickness=OpenStudio::convert(1,"in","ft").get, conductivity_list=[OpenStudio::convert(1,"in","ft").get / films.floor_reduced])
	
	return ub_ceiling.Rvalue_parallel	

end

def get_unfinished_attic_ceiling_r_assembly(uatc, gypsumThickness, gypsumNumLayers, uACeilingInsThickness_Rev=nil)
  # Returns assembly R-value for unfinished attic ceiling, including air films.

  mat_wood = get_mat_wood
  films = Get_films_constant.new
  mat_gyp = get_mat_gypsum

  if uACeilingInsThickness_Rev.nil?
    # No perimeter taper effect:
    uACeilingInsThickness_Rev = uatc.UACeilingInsThickness
  end

  path_fracs = [uatc.UACeilingFramingFactor, 1 - uatc.UACeilingFramingFactor]

  attic_floor = Construction.new(path_fracs)

  # Interior Film
  attic_floor.addlayer(thickness=OpenStudio::convert(1,"in","ft").get, conductivity_list=[OpenStudio::convert(1,"in","ft").get / films.floor_average])

  # Interior Finish (GWB)
  attic_floor.addlayer(thickness=OpenStudio::convert(gypsumThickness,"in","ft").get * gypsumNumLayers, conductivity_list=[mat_gyp.k])

  if uatc.UACeilingInsThickness == 0
    uatc.UACeilingInsRvalueNominal_Rev = uatc.UACeilingInsRvalueNominal
  else
    uatc.UACeilingInsRvalueNominal_Rev = [uatc.UACeilingInsRvalueNominal * uACeilingInsThickness_Rev / uatc.UACeilingInsThickness, 0.0001].max
  end

  # If the ceiling insulation thickness is greater than the joist thickness
  if uACeilingInsThickness_Rev >= uatc.UACeilingJoistThickness

    # Stud / Cavity Ins
    attic_floor.addlayer(thickness=OpenStudio::convert(uatc.UACeilingJoistThickness,"in","ft").get, conductivity_list=[mat_wood.k, OpenStudio::convert(uACeilingInsThickness_Rev,"in","ft").get / uatc.UACeilingInsRvalueNominal_Rev])

    # If there is additional insulation, above the rafter height,
    # these inputs are used for defining an additional layer.after() do

    if uACeilingInsThickness_Rev > uatc.UACeilingJoistThickness

      uA_ceiling_ins_above_thickness = OpenStudio::convert(uACeilingInsThickness_Rev - uatc.UACeilingJoistThickness,"in","ft").get # ft

      attic_floor.addlayer(thickness=uA_ceiling_ins_above_thickness, conductivity_list=[OpenStudio::convert(uACeilingInsThickness_Rev,"in","ft").get / uatc.UACeilingInsRvalueNominal_Rev])

    # Else the joist thickness is greater than the ceiling insulation thickness
    else
      # Stud / Cavity Ins - Insulation layer made thicker and more conductive
      uA_ceiling_joist_ins_thickness = OpenStudio::convert(uatc.UACeilingJoistThickness,"in","ft").get # ft
      if uatc.UACeilingInsRvalueNominal_Rev == 0
        cond_insul = 99999
      else
        cond_insul = uA_ceiling_joist_ins_thickness / uatc.UACeilingInsRvalueNominal_Rev
      end
      attic_floor.addlayer(thickness=uA_ceiling_joist_ins_thickness, conductivity_list=[mat_wood.k, cond_insul])
    end

  end

  # Exterior Film
  attic_floor.addlayer(thickness=OpenStudio::convert(1.0,"in","ft").get, conductivity_list=[OpenStudio::convert(1.0,"in","ft").get / films.floor_average])

  return attic_floor.Rvalue_parallel

end

def get_unfinished_attic_roof_r_assembly(uatc, hasRadiantBarrier, film_roof)
  # Returns assembly R-value for unfinished attic roof, including air films.
  # Also returns roof insulation thickness.

  mat_air = get_mat_air
  mat_wood = get_mat_wood
  mat_plywood3_4in = get_mat_plywood3_4in(mat_wood)
  films = Get_films_constant.new

  path_fracs = [uatc.UARoofFramingFactor, 1 - uatc.UARoofFramingFactor]

  roof_const = Construction.new(path_fracs)

  # Interior Film
  roof_const.addlayer(thickness=OpenStudio::convert(1.0,"in","ft").get, conductivity_list=[OpenStudio::convert(1.0,"in","ft").get / film_roof])

  uA_roof_ins_thickness = OpenStudio::convert([uatc.UARoofInsThickness, uatc.UARoofFramingThickness].max,"in","ft").get

  # Stud/cavity layer
  if uatc.UARoofInsRvalueNominal == 0
    if hasRadiantBarrier
      cavity_k = OpenStudio::convert(uatc.UARoofFramingThickness,"in","ft").get / mat_air.R_air_gap
    else
      cavity_k = 1000000000
    end
  else
    cavity_k = OpenStudio::convert(uatc.UARoofInsThickness,"in","ft").get / uatc.UARoofInsRvalueNominal
    if uatc.UARoofInsThickness < uatc.UARoofFramingThickness
      cavity_k = cavity_k * uatc.UARoofFramingThickness / uatc.UARoofInsThickness
    end
  end

  if uatc.UARoofInsThickness > uatc.UARoofFramingThickness and uatc.UARoofFramingThickness > 0
    wood_k = mat_wood.k * uatc.UARoofInsThickness / uatc.UARoofFramingThickness
  else
    wood_k = mat_wood.k
  end
  roof_const.addlayer(thickness=uA_roof_ins_thickness, conductivity_list=[wood_k, cavity_k])

  # Sheathing
  roof_const.addlayer(thickness=nil, conductivity_list=nil, material=mat_plywood3_4in, material_list=nil)

  # Rigid
  if uatc.UARoofContInsThickness > 0
    roof_const.addlayer(thickness=OpenStudio::convert(uatc.UARoofContInsThickness,"in","ft").get, conductivity_list=[OpenStudio::convert(uatc.UARoofContInsThickness,"in","ft").get / uatc.UARoofContInsRvalue])
    # More sheathing
    roof_const.addlayer(thickness=nil, conductivity_list=nil, material=mat_plywood3_4in, material_list=nil)
  end

  # Exterior Film
  roof_const.addlayer(thickness=OpenStudio::convert(1.0,"in","ft").get, conductivity_list=[OpenStudio::convert(1.0,"in","ft").get / films.outside])

  return roof_const.Rvalue_parallel, uA_roof_ins_thickness

end

def get_unfinished_attic_perimeter_insulation_derating(uatc, geometry, eaves_depth)

  if uatc.UACeilingInsThickness == 0
    return uatc.UACeilingInsThickness
  end

  spaceArea_Rev_UAtc = 0
  windBaffleClearance = 2 # Minimum 2" wind baffle clearance

  if uatc.UARoofFramingThickness < 10
    birdMouthDepth = 0
  else
    birdMouthDepth = 1.5 # inches
  end

  #(2...@model.getBuildingStorys.length + 1).to_a.each do |i|
  # temp
  (2..2).to_a.each do |i|
  #
    spaceArea_UAtc = 0
    rfEdgeW_UAtc = 0
    rfEdgeMinH_UAtc = 0
    rfPerimeter_UAtc = 0
    spaceArea_UAtc_Perim = 0
    # index_num = story_num - 1

    #rfTilt = geometry.roof_pitch.item[index_num]
    # temp
    rfTilt = 26.565052
    #

    # if geometry.roof_structure.item[index_num].nil?
    #   next
    # end

    #geometry.roofs.roof.each do |roof|
    # temp
    (0..1).each do |k|
    #

      # if not (roof.story == story_num and roof.space_below == Constants::SpaceUnfinAttic)
      #   next
      # end

      perimeterUAtc = 0

      # if geometry.roof_structure.item[index_num] == Constants::RoofStructureRafter
      # temp
      roofstructurerafter = "trusscantilever"
      if roofstructurerafter == "rafter"
        rfEdgeMinH_UAtc = OpenStudio::convert([uatc.UACeilingInsThickness, (1 - uatc.UACeilingFramingFactor) * ((uatc.UARoofFramingThickness - windBaffleClearance) / Math::cos(rfTilt / 180 * Math::PI) - birdMouthDepth)].min,"in","ft").get # ft
        rfEdgeW_UAtc = [0, (OpenStudio::convert(uatc.UACeilingInsThickness,"in","ft").get - rfEdgeMinH_UAtc) / Math::tan(rfTilt / 180 * Math::PI)].max # ft
      else
        rfEdgeMinH_UAtc = OpenStudio::convert([uatc.UACeilingInsThickness, OpenStudio::convert(eaves_depth * Math::tan(rfTilt / 180 * Math::PI),"ft","in").get + [0, (1 - uatc.UACeilingFramingFactor) * ((uatc.UARoofFramingThickness - windBaffleClearance) / Math::cos(rfTilt / 180 * Math::PI) - birdMouthDepth)].max].min,"in","ft").get # ft
        rfEdgeW_UAtc = [0, (OpenStudio::convert(uatc.UACeilingInsThickness,"in","ft").get - rfEdgeMinH_UAtc) / Math::tan(rfTilt / 180 * Math::PI)].max # ft
      end

      # min_z = min(roof.vertices.coord.z)
      # roof.vertices.coord[:-1].each_with_index do |vertex,vnum|
      #   vertex_next = roof.vertices.coord[vnum + 1]
      #   if vertex.z < min_z + 0.1 and vertex_next.z < min_z + 0.1
      #     dRoofX = vertex_next.x - vertex.x
      #     dRoofY = vertex_next.y - vertex.y
      #     perimeterUAtc += sqrt(dRoofX ** 2 + dRoofY ** 2) # Calculate unfinished attic Mid edge perimeter
      #   end
      # end
      # temp
      if k == 0
        perimeterUAtc = 40
      elsif k == 1
        perimeterUAtc = 40
      end
      #

      rfPerimeter_UAtc += perimeterUAtc
      #spaceArea_UAtc += roof.area * Math::cos(rfTilt / 180 * Math::PI) # Unfinished attic Area
      # temp
      if k == 0
        spaceArea_UAtc += 670.8204 * Math::cos(rfTilt / 180 * Math::PI) # Unfinished attic Area
      elsif k == 1
        spaceArea_UAtc += 670.8204 * Math::cos(rfTilt / 180 * Math::PI) # Unfinished attic Area
      end
      #
      spaceArea_UAtc_Perim += (perimeterUAtc - 2 * rfEdgeW_UAtc) * rfEdgeW_UAtc

    end

    spaceArea_UAtc_Perim += 4 * rfEdgeW_UAtc ** 2

    if spaceArea_UAtc_Perim != 0 and rfEdgeMinH_UAtc < OpenStudio::convert(uatc.UACeilingInsThickness,"in","ft").get
      spaceArea_UAtc = spaceArea_UAtc - spaceArea_UAtc_Perim + Math::log((rfEdgeW_UAtc * Math::tan(rfTilt / 180 * Math::PI) + rfEdgeMinH_UAtc) / rfEdgeMinH_UAtc) / Math::tan(rfTilt / 180 * Math::PI) * rfPerimeter_UAtc * OpenStudio::convert(uatc.UACeilingInsThicknes,"in","ft").get
    end

    spaceArea_Rev_UAtc += spaceArea_UAtc

  end

  # Return value for uatc.UACeilingInsThickness_Rev
  constants = Constants.new
  area = get_space_area(getSpace(geometry, constants.SpaceUnfinAttic))
  return uatc.UACeilingInsThickness * area / spaceArea_Rev_UAtc

end

def get_finished_roof_r_assembly(fr, gypsumThickness, gypsumNumLayers, film_roof)
  # Returns assembly R-value for finished roof, including air films.

  frRoofCavityInsRvalueInstalled = fr.FRRoofCavityInsRvalueInstalled

  mat_gyp = get_mat_gypsum
  mat_wood = get_mat_wood
  mat_plywood3_4in = get_mat_plywood3_4in(mat_wood)
  mat_air = get_mat_air
  films = Get_films_constant.new

  # Add air film coefficients when insulation thickness < cavity depth
  if not fr.FRRoofCavityInsFillsCavity
    frRoofCavityInsRvalueInstalled += mat_air.R_air_gap
  end

  path_fracs = [fr.FRRoofFramingFactor, 1 - fr.FRRoofFramingFactor]

  roof_const = Construction.new(path_fracs)

  # Interior Film
  roof_const.addlayer(thickness=OpenStudio::convert(1.0,"in","ft").get, conductivity_list=[OpenStudio::convert(1.0,"in","ft").get / film_roof])

  # Interior Finish (GWB)
  (0...gypsumNumLayers).to_a.each do |i|
    roof_const.addlayer(thickness=OpenStudio::convert(gypsumThickness,"in","ft").get, conductivity_list=[mat_gyp.k])
  end

  # Stud/cavity layer
  roof_const.addlayer(thickness=OpenStudio::convert(fr.FRRoofCavityDepth,"in","ft").get, conductivity_list=[mat_wood.k, OpenStudio::convert(fr.FRRoofCavityDepth,"in","ft").get / frRoofCavityInsRvalueInstalled])

  # Sheathing
  roof_const.addlayer(thickness=nil, conductivity_list=nil, material=mat_plywood3_4in, material_list=nil)

  # Rigid
  if fr.FRRoofContInsThickness > 0
    roof_const.addlayer(thickness=OpenStudio::convert(fr.FRRoofContInsThickness,"in","ft").get, conductivity_list=[OpenStudio::convert(fr.FRRoofContInsThickness,"in","ft").get / fr.FRRoofContInsRvalue])
    # More sheathing
    roof_const.addlayer(thickness=nil, conductivity_list=nil, material=mat_plywood3_4in, material_list=nil)
  end

  # Exterior Film
  roof_const.addlayer(thickness=OpenStudio::convert(1.0,"in","ft").get, conductivity_list=[OpenStudio::convert(1.0,"in","ft").get / films.outside])

  return roof_const.Rvalue_parallel

end

def getSpace(geometry, space_in)
  # return space_obj
  return "placeholder"
end

def get_space_area(space)
  # return sum(space.floor_area_level.item) + space.floor_area_foundation
  # temp
    return 1200.0
  #
end

class Process_refrigerator
  #Refrigerator energy use comes from the measure (user specified), schedule is here
  
  #hard coded convective, radiative, latent, and lost fractions for fridges
  Fridge_lat = 0
  Fridge_rad = 0
  Fridge_lost = 0
  Fridge_conv = 1
  
  #Fridge weekday, weekend schedule and monthly multipliers
	
  #Right now hard coded simple schedules
  #TODO: Schedule inputs. Should be 24 or 48 hourly + 12 monthly, is 36-60 inputs too much? how to handle 8760 schedules (from a file?)
  Monthly_mult_fridge = [0.837, 0.835, 1.084, 1.084, 1.084, 1.096, 1.096, 1.096, 1.096, 0.931, 0.925, 0.837]
  Weekday_hourly_fridge = [0.040, 0.039, 0.038, 0.037, 0.036, 0.036, 0.038, 0.040, 0.041, 0.041, 0.040, 0.040, 0.042, 0.042, 0.042, 0.041, 0.044, 0.048, 0.050, 0.048, 0.047, 0.046, 0.044, 0.041]
  Weekend_hourly_fridge = Weekday_hourly_fridge
	
  #if sum != 1, normalize to get correct max val
  sum_fridge_wkdy = 0
  sum_fridge_wknd = 0
  
  Weekday_hourly_fridge.each do |v|
    sum_fridge_wkdy = sum_fridge_wkdy + v
  end
 
  Weekend_hourly_fridge.each do |v|
    sum_fridge_wknd = sum_fridge_wkdy + v
  end
  
  Sum_wkdy = sum_fridge_wkdy
  
  #for v in 0..23
  #Weekday_hourly_fridge[v] = Weekday_hourly_fridge[v]/sum_fridge_wkdy
  #Weekend_hourly_fridge[v] = Weekday_hourly_fridge[v]/sum_fridge_wknd
  #end
  
  #get max schedule value
  
  if Weekday_hourly_fridge.max > Weekend_hourly_fridge.max
	Maxval_fridge = Monthly_mult_fridge.max * Weekday_hourly_fridge.max #/ sum_fridge_wkdy
  else
	Maxval_fridge = Monthly_mult_fridge.max * Weekend_hourly_fridge.max #/ sum_fridge_wknd
  end
end

class Process_range
  #Range energy use comes from the measure (user specified), schedule is here
  
  #hard coded convective, radiative, latent, and lost fractions for fridges
  Range_lat_elec = 0.3
  Range_rad_elec = 0.24
  Range_lost_elec = 0.3
  Range_conv_elec = 0.16
  
  Range_lat_gas = 0.2
  Range_rad_gas = 0.18
  Range_lost_gas = 0.5
  Range_conv_gas = 0.12
  
  #Range weekday, weekend schedule and monthly multipliers
	
  #Right now hard coded simple schedules
  #TODO: Schedule inputs. Should be 24 or 48 hourly + 12 monthly, is 36-60 inputs too much? how to handle 8760 schedules (from a file?)
  Monthly_mult_range = [1.097, 1.097, 0.991, 0.987, 0.991, 0.890, 0.896, 0.896, 0.890, 1.085, 1.085, 1.097]
  Weekday_hourly_range = [0.007, 0.007, 0.004, 0.004, 0.007, 0.011, 0.025, 0.042, 0.046, 0.048, 0.042, 0.050, 0.057, 0.046, 0.057, 0.044, 0.092, 0.150, 0.117, 0.060, 0.035, 0.025, 0.016, 0.011]
  Weekend_hourly_range = Weekday_hourly_range

  
  #get max schedule value
  
  if Weekday_hourly_range.max > Weekend_hourly_range.max
	Maxval_range = Monthly_mult_range.max * Weekday_hourly_range.max
  else
	Maxval_range = Monthly_mult_range.max * Weekend_hourly_range.max
  end
end

class Process_clotheswasher
  #CW energy use comes from the measure (user specified), schedule is here
  
  #hard coded convective, radiative, latent, and lost fractions for fridges
  Clothes_w_lat = 0
  Clothes_w_rad = 0.48
  Clothes_w_lost = 0.2
  Clothes_w_conv = 0.32
  
  #CW weekday, weekend schedule and monthly multipliers
	
  #Right now hard coded simple schedules
  #TODO: Schedule inputs. Should be 24 or 48 hourly + 12 monthly, is 36-60 inputs too much? how to handle 8760 schedules (from a file?)
  Monthly_mult_cw = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0]
  Weekday_hourly_cw = [0.00934, 0.00747, 0.00373, 0.00373,0.00747, 0.01121, 0.02242, 0.04859,0.07289, 0.08598, 0.08411, 0.07476,0.06728, 0.05981, 0.05233, 0.04859,0.05046, 0.04859, 0.04859, 0.04859,0.04859, 0.04672, 0.03177, 0.01682]
  Weekend_hourly_cw = Weekday_hourly_cw
	
  #get max schedule value
  
  if Weekday_hourly_cw.max > Weekend_hourly_cw.max
	Maxval_cw = Monthly_mult_cw.max * Weekday_hourly_cw.max
  else
	Maxval_cw = Monthly_mult_cw.max * Weekend_hourly_cw.max
  end
end

class Process_dishwasher
  #DW energy use comes from the measure (user specified), schedule is here
  
  #hard coded convective, radiative, latent, and lost fractions for fridges
  Dish_w_lat = 0.15
  Dish_w_rad = 0.36
  Dish_w_lost = 0.27
  Dish_w_conv = 0.24
  
  #DW weekday, weekend schedule and monthly multipliers
	
  #Right now hard coded simple schedules
  #TODO: Schedule inputs. Should be 24 or 48 hourly + 12 monthly, is 36-60 inputs too much? how to handle 8760 schedules (from a file?)
  Monthly_mult_dw = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0]
  Weekday_hourly_dw = [0.01535, 0.00682, 0.00511, 0.00341, 0.00341,0.01023, 0.02047, 0.03071, 0.05802, 0.06484,0.05631, 0.04778, 0.04095, 0.04607, 0.03754,0.03583, 0.03754, 0.04948, 0.08703, 0.11092,0.09044, 0.06655, 0.04436, 0.03071]
  Weekend_hourly_dw = Weekday_hourly_dw
	
  #get max schedule value
  
  if Weekday_hourly_dw.max > Weekend_hourly_dw.max
	Maxval_dw = Monthly_mult_dw.max * Weekday_hourly_dw.max
  else
	Maxval_dw = Monthly_mult_dw.max * Weekend_hourly_dw.max
  end
end
