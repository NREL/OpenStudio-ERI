
require "#{File.dirname(__FILE__)}/util"
require "#{File.dirname(__FILE__)}/weather"

class Furniture
  def initialize(type=nil, density=nil, conductivity=nil, spec_heat=nil, area_frac=nil, total_mass=nil, solar_abs=nil)
    @type = type
    @density = density
    @conductivity = conductivity
    @spec_heat = spec_heat
    @area_frac = area_frac
    @total_mass = total_mass
    @solar_abs = solar_abs
  end

  def area_frac
    return @area_frac
  end

  def total_mass
    return @total_mass
  end

  def density
    return @density
  end

  def conductivity
    return @conductivity
  end

  def spec_heat
    return @spec_heat
  end

  def solar_abs
    return @solar_abs
  end

  attr_accessor(:thickness)
end

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
			return false
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
    if prefix != "WS" and wallCavityInsRvalueInstalled == 0 and rigidInsRvalue == 0
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
	wood_stud_wall.addlayer(thickness=OpenStudio::convert(1.0,"in","ft").get, conductivity_list=[OpenStudio::convert(1.0,"in","ft").get / films.vertical])
	
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
		wood_stud_wall.addlayer(thickness=OpenStudio::convert(1.0,"in","ft").get, conductivity_list=[OpenStudio::convert(1.0,"in","ft").get / films.outside])
	end
	
	# Get overall wall R-value using parallel paths:
	return wood_stud_wall.Rvalue_parallel

end

def get_double_stud_wall_r_assembly(dsw, gypsumThickness, gypsumNumLayers, finishThickness, finishConductivity, rigidInsThickness=0, rigidInsRvalue=0, hasOSB=true)
  # Returns assembly R-value for double stud wall, including air films.

  mat_gyp = get_mat_gypsum
  mat_wood = get_mat_wood
  mat_plywood1_2in = get_mat_plywood1_2in(mat_wood)
  mat_2x = get_mat_2x(mat_wood, dsw.DSWallStudDepth)
  mat_air = get_mat_air
  films = Get_films_constant.new

  gapFactor = get_wall_gap_factor(dsw.DSWallInstallGrade, dsw.DSWallFramingFactor)
  
  cavityDepth = 2.0 * dsw.DSWallStudDepth + dsw.DSWallGapDepth
  
  dsw.MiscFramingFactor = (dsw.DSWallFramingFactor - mat_2x.width_in / dsw.DSWallStudSpacing)

  ins_k = OpenStudio::convert(cavityDepth,"in","ft").get / dsw.DSWallCavityInsRvalue # = 1/R_per_foot
  gap_k = OpenStudio::convert(cavityDepth,"in","ft").get / mat_air.R_air_gap

  if dsw.DSWallIsStaggered
    stud_frac = (2.0 * mat_2x.width_in) / dsw.DSWallStudSpacing
  else
    stud_frac = (1.0 * mat_2x.width_in) / dsw.DSWallStudSpacing
  end

  path_fracs = [dsw.MiscFramingFactor, stud_frac, gapFactor, (1.0 - (stud_frac + dsw.MiscFramingFactor - gapFactor))] # frame frac, # stud frac, # Cavity frac
  double_stud_wall = Construction.new(path_fracs)

  # Interior Film
  double_stud_wall.addlayer(thickness=OpenStudio::convert(1.0,"in","ft").get, conductivity_list=[OpenStudio::convert(1.0,"in","ft").get / films.vertical])

  # Interior Finish (GWB)
  double_stud_wall.addlayer(thickness=OpenStudio::convert(gypsumThickness,"in","ft").get * gypsumNumLayers, conductivity_list=[mat_gyp.k])

  # Inner Stud / Cavity Ins
  double_stud_wall.addlayer(thickness=mat_2x.thick, conductivity_list=[mat_wood.k, mat_wood.k, gap_k, ins_k])

  # All cavity layer
  if dsw.DSWallGapDepth > 0
	double_stud_wall.addlayer(thickness=OpenStudio::convert(dsw.DSWallGapDepth,"in","ft").get, conductivity_list=[mat_wood.k, ins_k, gap_k, ins_k])
  end

  # Outer Stud / Cavity Ins
  if dsw.DSWallIsStaggered
    double_stud_wall.addlayer(thickness=mat_2x.thick, conductivity_list=[mat_wood.k, ins_k, gap_k, ins_k])
  else
    double_stud_wall.addlayer(thickness=mat_2x.thick, conductivity_list=[mat_wood.k, mat_wood.k, gap_k, ins_k])
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

def get_steel_stud_wall_r_assembly(ss, gypsumThickness, gypsumNumLayers, finishThickness, finishConductivity, rigidInsThickness=0, rigidInsRvalue=0, hasOSB=true)
    # Returns assembly R-value for steel stud wall, including air films.
    
    # Uses Equation 4-1 from 2015 IECC, which includes a correction factor, as an alternative
    # calculation to the parallel path approach.

	mat_gyp = get_mat_gypsum
    mat_air = get_mat_air
    mat_wood = get_mat_wood
    mat_plywood1_2in = get_mat_plywood1_2in(mat_wood)
    films = Get_films_constant.new
	
    # Add air gap when insulation thickness < cavity depth
	ssWallCavityInsRvalueInstalled = ss.SSWallCavityInsRvalueInstalled
    if not ss.SSWallCavityInsFillsCavity
		ssWallCavityInsRvalueInstalled += mat_air.R_air_gap
	end
    
    gapFactor = get_wall_gap_factor(ss.SSWallInstallGrade, ss.SSWallFramingFactor)

    # The cumulative R-value of the wall components along the path of heat transfer,
    # excluding the cavity insulation and steel studs
    r = films.vertical # Interior film
    r += (OpenStudio::convert(gypsumThickness,"in","ft").get * gypsumNumLayers / mat_gyp.k) # Interior Finish (GWB)
    if hasOSB
        r += mat_plywood1_2in.Rvalue # OSB sheathing
	end
    r += rigidInsRvalue
    r += (OpenStudio::convert(finishThickness,"in","ft").get / OpenStudio::convert(finishConductivity,"in","ft").get) # Exterior Finish
    r += films.outside # Exterior film
    
    # The effective R-value of the cavity insulation with steel studs
    eR = ssWallCavityInsRvalueInstalled * ss.SSWallCorrectionFactor
    
    return r + 1/((1-gapFactor)/eR + gapFactor/mat_air.R_air_gap)
	
end

def get_cmu_wall_r_assembly(cmu, gypsumThickness, gypsumNumLayers, finishThickness, finishConductivity, rigidInsThickness=0, rigidInsRvalue=0, hasOSB=true)
    # Returns assembly R-value for CMU wall, including air films.
    # Also returns furring layer equivalent R-value.
	
	mat_gyp = get_mat_gypsum
    mat_wood = get_mat_wood
    mat_plywood1_2in = get_mat_plywood1_2in(mat_wood)
    mat_2x4 = get_mat_2x4(mat_wood)
    films = Get_films_constant.new
    mat_air = get_mat_air	
	
	# Set paths
	cmuFurringInsRvalue = cmu.CMUFurringInsRvalue
	if cmu.CMUFurringCavityDepth != 0
		# Add air film coefficients when no insulation
		if cmuFurringInsRvalue.nil? or cmuFurringInsRvalue == 0
			cmuFurringInsRvalue = mat_air.R_air_gap
		end
		
		stud_frac = mat_2x4.width_in / cmu.CMUFurringStudSpacing
		cavity_frac = 1.0 - (stud_frac + cmu.CMUFramingFactor)
		path_fracs = [cmu.CMUFramingFactor, stud_frac, cavity_frac]
		furring_layer_equiv_Rvalue = 1.0 / (cavity_frac / cmuFurringInsRvalue + (1.0 - cavity_frac) / (OpenStudio.convert(cmu.CMUFurringCavityDepth,"in","ft").get / mat_wood.k)) # hr*ft^2*F/Btu
	else # No furring:
		path_fracs = [cmu.CMUFramingFactor, 1.0 - cmu.CMUFramingFactor]
		furring_layer_equiv_Rvalue = 0.0
	end
	
	cmu_wall = Construction.new(path_fracs)
	
	# Interior Film
	cmu_wall.addlayer(thickness=OpenStudio.convert(1.0,"in","ft").get, conductivity_list=[OpenStudio.convert(1.0,"in","ft").get / films.vertical])
	
	# Interior Finish (GWB)
	cmu_wall.addlayer(thickness=OpenStudio.convert(gypsumThickness,"in","ft").get, conductivity_list=[mat_gyp.k])

	# Furring/Cavity layer
	cmu_layer_conductivity = OpenStudio.convert(cmu.CMUConductivity,"in","ft").get # Btu/hr-ft-F
	
	if cmu.CMUFurringCavityDepth != 0
		cavity_ins_k = OpenStudio.convert(cmu.CMUFurringCavityDepth,"in","ft").get / cmuFurringInsRvalue
		cmu_wall.addlayer(thickness=OpenStudio.convert(cmu.CMUFurringCavityDepth,"in","ft").get, conductivity_list=[mat_wood.k, mat_wood.k, cavity_ins_k])
		# CMU layer
		cmu_wall.addlayer(thickness=OpenStudio.convert(cmu.CMUThickness,"in","ft").get, conductivity_list=[mat_wood.k, cmu_layer_conductivity, cmu_layer_conductivity])
	else
		cmu_wall.addlayer(thickness=OpenStudio.convert(cmu.CMUThickness,"in","ft").get, conductivity_list=[mat_wood.k, cmu_layer_conductivity])		
	end
	
	# OSB sheathing
	if hasOSB
		cmu_wall.addlayer(thickness=nil, conductivity_list=nil, material=mat_plywood1_2in, material_list=nil)
	end
	
	if rigidInsRvalue > 0
		rigid_k = OpenStudio.convert(rigidInsThickness,"in","ft").get / rigidInsRvalue
		cmu_wall.addlayer(thickness=OpenStudio.convert(rigidInsThickness,"in","ft").get, conductivity_list=[rigid_k])
	end
	
	# Exterior Finish
	cmu_wall.addlayer(thickness=OpenStudio.convert(finishThickness,"in","ft").get, conductivity_list=[OpenStudio.convert(finishConductivity,"in","ft").get])
	
	# Exterior Film
	cmu_wall.addlayer(thickness=OpenStudio.convert(1.0,"in","ft").get, conductivity_list=[OpenStudio.convert(1.0,"in","ft").get / films.outside])
	
	return cmu_wall.Rvalue_parallel, furring_layer_equiv_Rvalue
	
end

def get_sip_sheathing_type(sheathingType)
	constants = Constants.new
    mat_wood = get_mat_wood
    mat_gyp = get_mat_gypsum
    mat_gypcrete = get_mat_gypcrete
    if sheathingType == constants.MaterialOSB
        sheathing = mat_wood
    elsif sheathingType == constants.MaterialGypsum
        sheathing = mat_gyp
    elsif sheathingType == constants.MaterialGypcrete
        sheathing = mat_gypcrete
    else
        runner.registerError("Unknown sheathing type for SIP wall: #{sheathingType}")
		return false
	end
    return sheathing
end

def get_sip_wall_r_assembly(sip, int_sheathing, gypsumThickness, gypsumNumLayers, finishThickness, finishConductivity, rigidInsThickness=0, rigidInsRvalue=0, hasOSB=true)
    # Returns assembly R-value for SIP wall, including air films.
    # Also returns spline layer thickness, insulation layer thickness, and cavity fraction.
                                    
    mat_wood = get_mat_wood
	mat_gyp = get_mat_gypsum
    mat_plywood1_2in = get_mat_plywood1_2in(mat_wood)
    films = Get_films_constant.new

    spline_layer_thickness = OpenStudio.convert(0.5,"in","ft").get
    spline_frac = 4.0 / 48.0 # One 4" spline for every 48" wide panel
    cavity_frac = 1.0 - (spline_frac + sip.SIPFramingFactor)
    path_fracs = [sip.SIPFramingFactor, # frame frac
                  spline_frac, # spline_frac
                  cavity_frac]                              # Cavity frac

    sip_wall = Construction.new(path_fracs)

    cavity_ins_k = OpenStudio.convert(sip.SIPInsThickness,"in","ft").get / sip.SIPInsRvalue

    # Interior Film
    sip_wall.addlayer(thickness=OpenStudio.convert(1.0,"in","ft").get, conductivity_list=[OpenStudio.convert(1.0,"in","ft").get / films.vertical])

    # Interior Finish (GWB)
    sip_wall.addlayer(thickness=OpenStudio.convert(gypsumThickness,"in","ft").get, conductivity_list=[mat_gyp.k])

    # Int sheathing
    sip_wall.addlayer(thickness=OpenStudio.convert(sip.SIPIntSheathingThick,"in","ft").get, conductivity_list=[int_sheathing.k])

    # Spline layer
    sip_wall.addlayer(thickness=spline_layer_thickness, conductivity_list=[mat_wood.k, mat_wood.k, cavity_ins_k])

    # Ins layer
    ins_layer_thickness = OpenStudio.convert(sip.SIPInsThickness,"in","ft").get - (2.0 * spline_layer_thickness) # ft
    sip_wall.addlayer(thickness=ins_layer_thickness, conductivity_list=[mat_wood.k, cavity_ins_k, cavity_ins_k])

    # Spline layer
    sip_wall.addlayer(thickness=spline_layer_thickness, conductivity_list=[mat_wood.k, mat_wood.k, cavity_ins_k])

    # OSB sheathing
    if hasOSB
        sip_wall.addlayer(thickness=nil, conductivity_list=nil, material=mat_plywood1_2in, material_list=nil)
	end

    # Rigid
    if rigidInsRvalue > 0
        rigid_k = OpenStudio.convert(rigidInsThickness,"in","ft").get / rigidInsRvalue
        sip_wall.addlayer(thickness=OpenStudio.convert(rigidInsThickness,"in","ft").get, conductivity_list=[rigid_k])
	end
						  
    # Exterior Finish
    sip_wall.addlayer(thickness=OpenStudio.convert(finishThickness,"in","ft").get, conductivity_list=[OpenStudio.convert(finishConductivity,"in","ft").get])

    # Exterior Film
    sip_wall.addlayer(thickness=OpenStudio.convert(1.0,"in","ft").get, conductivity_list=[OpenStudio.convert(1.0,"in","ft").get / films.outside])

    return sip_wall.Rvalue_parallel, spline_layer_thickness, ins_layer_thickness, cavity_frac
	
end
	
def get_icf_wall_r_assembly(icf, gypsumThickness, gypsumNumLayers, finishThickness, finishConductivity, rigidInsThickness=0, rigidInsRvalue=0, hasOSB=false)
	# Returns assembly R-value for ICF wall, including air films.
	
	mat_wood = get_mat_wood
	mat_gyp = get_mat_gypsum
    mat_plywood1_2in = get_mat_plywood1_2in(mat_wood)
    mat_concrete = get_mat_concrete
    films = films = Get_films_constant.new
	
	path_fracs = [icf.ICFFramingFactor, 1.0 - icf.ICFFramingFactor]
	
    icf_wall = Construction.new(path_fracs)

    # Interior Film
    icf_wall.addlayer(thickness=OpenStudio.convert(1.0,"in","ft").get, conductivity_list=[OpenStudio.convert(1.0,"in","ft").get / films.vertical])

    # Interior Finish (GWB)
    icf_wall.addlayer(thickness=OpenStudio.convert(gypsumThickness,"in","ft").get, conductivity_list=[mat_gyp.k])

    # Framing / Rigid Ins
    ins_k = OpenStudio.convert(icf.ICFInsThickness,"in","ft").get / icf.ICFInsRvalue
    icf_wall.addlayer(thickness=OpenStudio.convert(icf.ICFInsThickness,"in","ft").get, conductivity_list=[mat_wood.k, ins_k])

    # Concrete
    icf_wall.addlayer(thickness=OpenStudio.convert(icf.ICFConcreteThickness,"in","ft").get, conductivity_list=[mat_wood.k, mat_concrete.k])

    # Framing / Rigid Ins
    ins_k = OpenStudio.convert(icf.ICFInsThickness,"in","ft").get / icf.ICFInsRvalue
    icf_wall.addlayer(thickness=OpenStudio.convert(icf.ICFInsThickness,"in","ft").get, conductivity_list=[mat_wood.k, ins_k])

    # OSB sheathing
    if hasOSB
        icf_wall.addlayer(thickness=nil, conductivity_list=nil, material=mat_plywood1_2in, material_list=nil)
	end

    # Rigid
    if rigidInsRvalue > 0
        rigid_k = OpenStudio.convert(rigidInsThickness,"in","ft").get / rigidInsRvalue
        icf_wall.addlayer(thickness=OpenStudio.convert(rigidInsThickness,"in","ft").get, conductivity_list=[rigid_k])
	end

    # Exterior Finish
    icf_wall.addlayer(thickness=OpenStudio.convert(finishThickness,"in","ft").get, conductivity_list=[OpenStudio.convert(finishConductivity,"in","ft").get])

    # Exterior Film
    icf_wall.addlayer(thickness=OpenStudio.convert(1.0,"in","ft").get, conductivity_list=[OpenStudio.convert(1.0,"in","ft").get / films.outside])

    return icf_wall.Rvalue_parallel	
	
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

  gapFactor = get_wall_gap_factor(izf.IntFloorInstallGrade, izf.IntFloorFramingFactor)
  
  path_fracs = [izf.IntFloorFramingFactor, 1 - izf.IntFloorFramingFactor - gapFactor, gapFactor]

  izf_const = Construction.new(path_fracs)

  # Interior Film
  izf_const.addlayer(thickness=OpenStudio::convert(1.0,"in","ft").get, conductivity_list=[OpenStudio::convert(1.0,"in","ft").get / films.floor_reduced])

  # Stud/cavity layer
  if izf.IntFloorCavityInsRvalueNominal == 0
    cavity_k = 1000000000
  else
    cavity_k = mat_2x6.thick / izf.IntFloorCavityInsRvalueNominal
  end
  gap_k = mat_2x6.thick / get_mat_air.R_air_gap
  
  izf_const.addlayer(thickness=mat_2x6.thick, conductivity_list=[mat_wood.k, cavity_k, gap_k])

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

def get_mat_gypcrete
	# http://www.maxxon.com/gyp-crete/data
	return Mat_solid.new(rho=100.0, cp=0.223, k=0.3952)
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

def get_mat_stud_and_air(model, runner, mat_wood)
	# Weight specific heat of layer by mass (previously by volume)
	return Mat_solid.new(rho=(get_mat_2x4(mat_wood).width_in / Sim.stud_spacing_default) * mat_wood.rho + (1 - get_mat_2x4(mat_wood).width_in / Sim.stud_spacing_default) * Sim.new(model, runner).inside_air_dens, cp=((get_mat_2x4(mat_wood).width_in / Sim.stud_spacing_default) * mat_wood.Cp * mat_wood.rho + (1 - get_mat_2x4(mat_wood).width_in / Sim.stud_spacing_default) * get_mat_air.inside_air_sh * Sim.new(model, runner).inside_air_dens) / ((get_mat_2x4(mat_wood).width_in / Sim.stud_spacing_default) * mat_wood.rho + (1 - get_mat_2x4(mat_wood).width_in / Sim.stud_spacing_default) * Sim.new(model, runner).inside_air_dens), k=Sim.stud_and_air_thick / Sim.stud_and_air_Rvalue)
end

def get_mat_2x4(mat_wood)
  constants = Constants.new
	return Material.new(name=constants.Material2x4, type=constants.MaterialTypeProperties, thick=OpenStudio::convert(3.5,"in","ft").get, thick_in=nil, width=OpenStudio::convert(1.5,"in","ft").get, width_in=nil, mat_base=mat_wood)
end

def get_mat_2x6(mat_wood)
  constants = Constants.new
  return Material.new(name=constants.Material2x6, type=constants.MaterialTypeProperties, thick=OpenStudio::convert(5.5,"in","ft").get, thick_in=nil, width=OpenStudio::convert(1.5,"in","ft").get, width_in=nil, mat_base=mat_wood)
end

def get_stud_and_air_wall(model, runner, mat_wood)
  constants = Constants.new
	return Material.new(name=constants.MaterialStudandAirWall, type=constants.MaterialTypeProperties, thick=Sim.stud_and_air_thick, thick_in=nil, width=nil, width_in=nil, mat_base=get_mat_stud_and_air(model, runner, mat_wood))
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
      return @flat_reduced
    end

    def floor_average
      return @floor_average
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

	def initialize(model=nil, runner=nil)
	  @model = nil
	  @weather = nil
	  unless model.nil?
		@model = model
	  end
	  unless runner.nil?
		begin # Spreadsheet
		  #former_workflow_arguments = runner.former_workflow_arguments
		  #weather_file_name = former_workflow_arguments["setdrweatherfile"]["weather_file_name"]
		  #weather_file_dir = former_workflow_arguments["setdrweatherfile"]["weather_directory_name"]
		  weather_file_name = "USA_AZ_Phoenix-Sky.Harbor.Intl.AP.722780_TMY3.epw"
		  weather_file_dir = "weather"
		  epw_path = File.absolute_path(File.join(__FILE__.gsub('sim.rb', ''), '../../..', weather_file_dir, weather_file_name))
		  @weather = WeatherProcess.new(epw_path, runner)
		rescue Exception => e# PAT
		  runner.registerInfo("Did not set EPW weather path to #{epw_path}: #{e.message}")
		  if runner.lastEpwFilePath.is_initialized
			test = runner.lastEpwFilePath.get.to_s
			if File.exist?(test)
			  epw_path = test
			  @weather = WeatherProcess.new(epw_path, runner)
			end
		  end
		end
	  end
	  unless @weather.nil?
		runner.registerInfo("EPW weather path set to #{epw_path}")
	  else
		runner.registerInfo("EPW weather path NOT set to: #{epw_path}")
	  end
	end

  def _getGroundTemperatures
    # Return monthly ground temperatures.

    # This correlation is the same that is used in DOE-2's src\WTH.f file, subroutine GTEMP.
    monthly_temps = @weather.data.MonthlyAvgDrybulbs
    annual_temp = @weather.data.AnnualAvgDrybulb

    amon = [15.0, 46.0, 74.0, 95.0, 135.0, 166.0, 196.0, 227.0, 258.0, 288.0, 319.0, 349.0]
    po = 0.6
    dif = 0.025
    p = OpenStudio::convert(1.0,"yr","hr").get

    beta = Math::sqrt(Math::PI / (p * dif)) * 10.0
    x = Math::exp(-beta)
    x2 = x * x
    s = Math::sin(beta)
    c = Math::cos(beta)
    y = (x2 - 2.0 * x * c + 1.0) / (2.0 * beta ** 2.0)
    gm = Math::sqrt(y)
    z = (1.0 - x * (c + s)) / (1.0 - x * (c - s))
    phi = Math::atan(z)
    bo = (monthly_temps.max - monthly_temps.min) * 0.5

    ground_temps = []
    (0...12).to_a.each do |i|
      theta = amon[i] * 24.0
      ground_temps << OpenStudio::convert(annual_temp - bo * Math::cos(2.0 * Math::PI / p * theta - po - phi) * gm + 460.0,"R","F").get
    end

    return ground_temps, annual_temp

  end

	
  def _processHeatingCoolingSeasons(misc, schedules)
    # Assigns monthly heating and cooling seasons.

    constants = Constants.new

    monthly_temps = @weather.data.MonthlyAvgDrybulbs
    heat_design_db = @weather.design.HeatingDrybulb

    # create basis lists with zero for every month
    cooling_season_temp_basis = Array.new(monthly_temps.length, 0.0)
    heating_season_temp_basis = Array.new(monthly_temps.length, 0.0)

    monthly_temps.each_with_index do |temp, i|
      if temp < 66.0
        heating_season_temp_basis[i] = 1.0
      elsif temp >= 66.0
        cooling_season_temp_basis[i] = 1.0
      end

      if (i == 0 or i == 11) and heat_design_db < 59.0
        heating_season_temp_basis[i] = 1.0
      elsif i == 6 or i == 7
        cooling_season_temp_basis[i] = 1.0
      end
    end

    cooling_season = Array.new(monthly_temps.length, 0.0)
    heating_season = Array.new(monthly_temps.length, 0.0)

    monthly_temps.each_with_index do |temp, i|
      # Heating overlaps with cooling at beginning of summer
      if i == 0 # January
        prevmonth = 11 # December
      else
        prevmonth = i - 1
      end

      if (heating_season_temp_basis[i] == 1.0 or (cooling_season_temp_basis[prevmonth] == 0.0 and cooling_season_temp_basis[i] == 1.0))
        heating_season[i] = 1.0
      else
        heating_season[i] = 0.0
      end

      if (cooling_season_temp_basis[i] == 1.0 or (heating_season_temp_basis[prevmonth] == 0.0 and heating_season_temp_basis[i] == 1.0))
        cooling_season[i] = 1.0
      else
        cooling_season[i] = 0.0
      end
    end

    # Find the first month of cooling and add one month
    (1...12).to_a.each do |i|
      if cooling_season[i] == 1.0
        cooling_season[i - 1] = 1.0
        break
      end
    end

    season_type = []
    (0...12).to_a.each do |month|
      if heating_season[month] == 1.0 and cooling_season[month] == 0.0
        season_type << constants.SeasonHeating
      elsif heating_season[month] == 0.0 and cooling_season[month] == 1.0
        season_type << constants.SeasonCooling
      elsif heating_season[month] == 1.0 and cooling_season[month] == 1.0
        season_type << constants.SeasonOverlap
      else
        season_type << constants.SeasonNone
      end
    end

    # Avoid issues in the minimal building test suite by eliminating
    # cooling and heating seasons
    if misc.SimTestSuiteBuilding == constants.TestBldgMinimal
      cooling_season = Array.new(12, 1.0)
      heating_season = Array.new(12, 1.0)
    end

    # Heating and Cooling Season Schedules
    schedules.heating_season = heating_season
    schedules.cooling_season = cooling_season

    return schedules

  end

  def _processHeatingCoolingSetpoints(hsp, csp, selectedheating, selectedcooling)
    # Heating/Cooling Setpoints

    # Adjust cooling setpoints according to the offset the user has selected in conjunction with the user of ceiling fans.

    hsp = set_variable_list_heating_set_point(hsp)
    csp = set_variable_list_cooling_set_point(csp)

    csp.CoolingSetpointWeekday = csp.CoolingSetpointSchedule[0...24]
    if csp.CoolingSetpointSchedule.length > 24
      csp.CoolingSetpointWeekend = csp.CoolingSetpointSchedule[24...48]
    else
      csp.CoolingSetpointWeekend = csp.CoolingSetpointWeekday
    end
    hsp.HeatingSetpointWeekday = hsp.HeatingSetpointSchedule[0...24]
    if hsp.HeatingSetpointSchedule.length > 24
      hsp.HeatingSetpointWeekend = hsp.HeatingSetpointSchedule[0...24]
    else
      hsp.HeatingSetpointWeekend = hsp.HeatingSetpointWeekday
    end

    # self.cooling_set_point.weekday_hourly_schedule_with_offset = \
    #             [x + self.ceiling_fans.CeilingFanCoolingSetptOffset for x in csp.CoolingSetpointWeekday]
    # self.cooling_set_point.weekend_hourly_schedule_with_offset = \
    #             [x + self.ceiling_fans.CeilingFanCoolingSetptOffset for x in csp.CoolingSetpointWeekend]

    # Thermostatic Control type schedule
    if selectedheating and selectedcooling
      controlType = 4 # Dual Setpoint (Heating and Cooling) with deadband
    elsif selectedcooling
      controlType = 2 # Single Cooling Setpoint
    elsif selectedheating
      controlType = 1 # Single Heating Setpoint
    else
      controlType = 0 # Uncontrolled
    end

    return hsp, csp, controlType

  end

  def _processInteriorShadingSchedule(ish)
    # Assigns window shade multiplier and shading cooling season for each month.

    constants = Constants.new

    #if not ish.IntShadeCoolingMonths.nil?
    #  cooling_season = ish.IntShadeCoolingMonths.item # TODO: what is this?
    #else
    #  cooling_season = [0.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0]
    #end

	monthly_temps = @weather.data.MonthlyAvgDrybulbs
    heat_design_db = @weather.design.HeatingDrybulb

    # create basis lists with zero for every month
    cooling_season_temp_basis = Array.new(monthly_temps.length, 0.0)
    heating_season_temp_basis = Array.new(monthly_temps.length, 0.0)

    monthly_temps.each_with_index do |temp, i|
      if temp < 66.0
        heating_season_temp_basis[i] = 1.0
      elsif temp >= 66.0
        cooling_season_temp_basis[i] = 1.0
      end

      if (i == 0 or i == 11) and heat_design_db < 59.0
        heating_season_temp_basis[i] = 1.0
      elsif i == 6 or i == 7
        cooling_season_temp_basis[i] = 1.0
      end
    end

    cooling_season = Array.new(monthly_temps.length, 0.0)
    heating_season = Array.new(monthly_temps.length, 0.0)

    monthly_temps.each_with_index do |temp, i|
      # Heating overlaps with cooling at beginning of summer
      if i == 0 # January
        prevmonth = 11 # December
      else
        prevmonth = i - 1
      end

      if (heating_season_temp_basis[i] == 1.0 or (cooling_season_temp_basis[prevmonth] == 0.0 and cooling_season_temp_basis[i] == 1.0))
        heating_season[i] = 1.0
      else
        heating_season[i] = 0.0
      end

      if (cooling_season_temp_basis[i] == 1.0 or (heating_season_temp_basis[prevmonth] == 0.0 and heating_season_temp_basis[i] == 1.0))
        cooling_season[i] = 1.0
      else
        cooling_season[i] = 0.0
      end
    end

    # Find the first month of cooling and add one month
    (1...12).to_a.each do |i|
      if cooling_season[i] == 1.0
        cooling_season[i - 1] = 1.0
        break
      end
    end

	
    window_shade_multiplier = []
    window_shade_cooling_season = cooling_season
    (0...constants.MonthNames.length).to_a.each do |i|
      if cooling_season[i] == 1.0
        window_shade_multiplier << ish.IntShadeCoolingMultiplier
      else
        window_shade_multiplier << ish.IntShadeHeatingMultiplier
      end
    end

    # Interior Shading Schedule

    return window_shade_cooling_season, window_shade_multiplier

  end

  def _processInfiltration(si, living_space, garage, finished_basement, space_unfinished_basement, crawlspace, unfinished_attic, selected_garage, selected_fbsmt, selected_ufbsmt, selected_crawl, selected_unfinattic, wind_speed, neighbors, site, geometry)
    # Infiltration calculations.

    # loop thru all the spaces
    spaces = []
    spaces << living_space
    hasGarage = false
    hasFinishedBasement = false
    hasUnfinishedBasement = false
    hasCrawl = false
    hasUnfinAttic = false
    if not selected_garage == "NA"
      hasGarage = true
      spaces << garage
    end
    if not selected_fbsmt == "NA"
      hasFinishedBasement = true
      spaces << finished_basement
    end
    if not selected_ufbsmt == "NA"
      hasUnfinishedBasement = true
      spaces << space_unfinished_basement
    end
    if not selected_crawl == "NA"
      hasCrawl = true
      spaces << crawlspace
    end
    if not selected_unfinattic == "NA"
      hasUnfinAttic = true
      spaces << unfinished_attic
    end

    constants = Constants.new
    properties = Properties.new

    outside_air_density = (2.719 * local_pressure) / (properties.Air.R * (@weather.data.AnnualAvgDrybulb + 460.0))
    inf_conv_factor = 776.25 # [ft/min]/[inH2O^(1/2)*ft^(3/2)/lbm^(1/2)]
    delta_pref = 0.016 # inH2O

    # Assume an average inside temperature
    si.assumed_inside_temp = assumed_inside_temp # deg F, used other places. Make available.

    spaces.each do |space|
      space.inf_method = nil
      space.SLA = nil
      space.ACH = nil
      space.inf_flow = nil
      space.hor_leak_frac = nil
      space.neutral_level = nil
    end

    if not si.InfiltrationLivingSpaceACH50.nil?

      # Living Space Infiltration
      living_space.inf_method = constants.InfMethodASHRAE

      # Based on "Field Validation of Algebraic Equations for Stack and
      # Wind Driven Air Infiltration Calculations" by Walker and Wilson (1998)

      # Pressure Exponent
      si.n_i = 0.67
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

      si.R_i = 0.5 * (1.0 - si.Y_i)
      living_space.hor_leak_frac = si.R_i
      si.X_i = 0.0
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

      si.stack_coef = si.f_s * (0.005974 * outside_air_density * constants.g * living_space.height / (si.assumed_inside_temp + 460.0)) ** si.n_i # inH2O^n/R^n

      # Calculate wind coefficient
      if hasCrawl and crawlspace.CrawlACH > 0

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

      si.wind_coef = si.f_w * ( 0.01285 * outside_air_density / 2.0 ) ** si.n_i # inH2O^n/mph^2n

      living_space.ACH = get_infiltration_ACH_from_SLA(living_space.SLA, geometry.stories, @weather)

      # Convert living space ACH to cfm:
      living_space.inf_flow = living_space.ACH / OpenStudio::convert(1.0,"hr","min").get * living_space.volume # cfm

    elsif not si.InfiltrationLivingSpaceConstantACH.nil?

      # Used for constant ACH
      living_space.inf_method = constants.InfMethodRes
      # ACH; Air exchange rate of above-grade conditioned spaces, due to natural ventilation
      living_space.ACH = si.InfiltrationLivingSpaceConstantACH

      # Convert living space ACH to cfm
      living_space.inf_flow = living_space.ACH / OpenStudio::convert(1.0,"hr","min").get * living_space.volume # cfm

    end

    if hasGarage

      garage.inf_method = constants.InfMethodSG
      garage.hor_leak_frac = 0.4 # DOE-2 Default
      garage.neutral_level = 0.5 # DOE-2 Default
      garage.SLA = get_infiltration_SLA_from_ACH50(si.InfiltrationGarageACH50, 0.67, garage.area, garage.volume)
      garage.ACH = get_infiltration_ACH_from_SLA(garage.SLA, 1.0, @weather)
      # Convert ACH to cfm:
      garage.inf_flow = garage.ACH / OpenStudio::convert(1.0,"hr","min").get * garage.volume # cfm

    end

    if hasFinishedBasement

      finished_basement.inf_method = constants.InfMethodRes # Used for constant ACH
      finished_basement.ACH = finished_basement.FBsmtACH
      # Convert ACH to cfm
      finished_basement.inf_flow = finished_basement.ACH / OpenStudio::convert(1.0,"hr","min").get * finished_basement.volume

    end

    if hasUnfinishedBasement

      space_unfinished_basement.inf_method = constants.InfMethodRes # Used for constant ACH
      space_unfinished_basement.ACH = space_unfinished_basement.UFBsmtACH
      # Convert ACH to cfm
      space_unfinished_basement.inf_flow = space_unfinished_basement.ACH / OpenStudio::convert(1.0,"hr","min").get * space_unfinished_basement.volume

    end

    if hasCrawl

      crawlspace.inf_method = constants.InfMethodRes

      crawlspace.ACH = crawlspace.CrawlACH
      # Convert ACH to cfm
      crawlspace.inf_flow = crawlspace.ACH / OpenStudio::convert(1.0,"hr","min").get * crawlspace.volume

    end

    if hasUnfinAttic

      unfinished_attic.inf_method = constants.InfMethodSG
      unfinished_attic.hor_leak_frac = 0.75 # Same as Energy Gauge USA Attic Model
      unfinished_attic.neutral_level = 0.5 # DOE-2 Default
      unfinished_attic.SLA = unfinished_attic.UASLA

      unfinished_attic.ACH = get_infiltration_ACH_from_SLA(unfinished_attic.SLA, 1.0, @weather)

      # Convert ACH to cfm
      unfinished_attic.inf_flow = unfinished_attic.ACH / OpenStudio::convert(1.0,"hr","min").get * unfinished_attic.volume

    end

    ws = Sim._processWindSpeedCorrection(wind_speed, site, constants, si, neighbors, geometry)

    spaces.each do |space|

      space.f_t_SG = ws.site_terrain_multiplier * ((space.height + space.coord_z) / 32.8) ** ws.site_terrain_exponent / (ws.terrain_multiplier * (ws.height / 32.8) ** ws.terrain_exponent)
      space.f_s_SG = nil
      space.f_w_SG = nil
      space.C_s_SG = nil
      space.C_w_SG = nil
      space.ELA = nil

      if space.inf_method == constants.InfMethodSG

        space.f_s_SG = 2.0 / 3.0 * (1 + space.hor_leak_frac / 2.0) * (2.0 * space.neutral_level * (1.0 - space.neutral_level)) ** 0.5 / (space.neutral_level ** 0.5 + (1.0 - space.neutral_level) ** 0.5)
        space.f_w_SG = ws.shielding_coef * (1.0 - space.hor_leak_frac) ** (1.0 / 3.0) * space.f_t_SG
        space.C_s_SG = space.f_s_SG ** 2.0 * constants.g * space.height / (si.assumed_inside_temp + 460.0)
        space.C_w_SG = space.f_w_SG ** 2.0
        space.ELA = space.SLA * space.area # ft^2

      elsif space.inf_method == constants.InfMethodASHRAE

        space.ELA = space.SLA * space.area # ft^2

      else

        space.ELA = 0 # ft^2
        space.hor_leak_frac = 0

      end

    end

    return si, living_space, ws, garage, finished_basement, space_unfinished_basement, crawlspace, unfinished_attic

  end

	def _processConstructionsExteriorInsulatedWallsWoodStud(wsw, extwallmass, exteriorfinish, wallsh, sc)
		# Set Furring insulation/air properties	
		if wsw.WSWallCavityInsRvalueInstalled == 0
			cavityInsDens = inside_air_dens # lb/ft^3   Assumes that a cavity with an R-value of 0 is an air cavity
			cavityInsSH = get_mat_air.inside_air_sh
		else
			cavityInsDens = get_mat_densepack_generic.rho
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
    dsGapFactor = get_wall_gap_factor(dsw.DSWallInstallGrade, dsw.DSWallFramingFactor)
	
	dsw, overall_wall_Rvalue = get_double_stud_wall_r_assembly(dsw, extwallmass.ExtWallMassGypsumThickness, extwallmass.ExtWallMassGypsumNumLayers, exterior_finish.FinishThickness, exterior_finish.FinishConductivity, wallsh.WallSheathingContInsThickness, wallsh.WallSheathingContInsRvalue, wallsh.WallSheathingHasOSB)
	
    cavityDepth = 2 * dsw.DSWallStudDepth + dsw.DSWallGapDepth
	
	if dsw.DSWallGapDepth > 0
	  cavity_layer_Rvalue = 1.0 / ((1.0 - dsw.MiscFramingFactor - dsGapFactor) / (dsw.DSWallGapDepth / cavityDepth * dsw.DSWallCavityInsRvalue) + dsw.MiscFramingFactor / (dsw.DSWallGapDepth / get_mat_wood.k)) # hr*ft^2*F/Btu
      c.cavity_layer_thickness = OpenStudio::convert(dsw.DSWallGapDepth,"in","ft").get # ft
      c.cavity_layer_conductivity = c.cavity_layer_thickness / cavity_layer_Rvalue # Btu/hr*ft*F
      c.cavity_layer_density = dsw.MiscFramingFactor * get_mat_wood.rho + (1.0 - dsw.MiscFramingFactor - dsGapFactor) * get_mat_densepack_generic.rho # Btu/hr*ft*F
	  c.cavity_layer_spec_heat = (dsw.MiscFramingFactor * get_mat_wood.Cp * get_mat_wood.rho + (1.0 - dsw.MiscFramingFactor - dsGapFactor) * get_mat_densepack_generic.Cp * get_mat_densepack_generic.rho + dsGapFactor * get_mat_air.inside_air_sh * inside_air_dens) / c.cavity_layer_density # Btu/lbm-F	
	else
	  cavity_layer_Rvalue = 0
	end
	
	films = Get_films_constant.new
    sc.stud_layer_thickness = OpenStudio::convert(dsw.DSWallStudDepth,"in","ft").get # ft
    sc.stud_layer_conductivity = sc.stud_layer_thickness / ((overall_wall_Rvalue - (films.vertical + films.outside + wallsh.WallSheathingContInsRvalue + cavity_layer_Rvalue + wallsh.OSBRvalue + (exterior_finish.FinishThickness / exterior_finish.FinishConductivity) + (OpenStudio::convert(extwallmass.ExtWallMassGypsumThickness,"in","ft").get * extwallmass.ExtWallMassGypsumNumLayers / get_mat_gypsum.k))) / 2.0) # Btu/hr*ft*F
    sc.stud_layer_density = dsw.DSWallFramingFactor * get_mat_wood.rho + (1 - dsw.DSWallFramingFactor) * get_mat_densepack_generic.rho # lbm/ft^3
    sc.stud_layer_spec_heat = (dsw.DSWallFramingFactor * get_mat_wood.Cp * get_mat_wood.rho + (1 - dsw.DSWallFramingFactor) * get_mat_densepack_generic.Cp * get_mat_densepack_generic.rho) / sc.stud_layer_density # Btu/lbm-F

    wallsh = _addInsulatedSheathingMaterial(wallsh)

	return sc, c, wallsh

  end
  
  def _processConstructionsExteriorInsulatedWallsSteelStud(ss, ext_wall_mass, exterior_finish, wallsh, sc)
    # Set Furring insulation/air properties
    if ss.SSWallCavityInsRvalueInstalled == 0
        cavityInsDens = inside_air_dens # lbm/ft^3   Assumes that a cavity with an R-value of 0 is an air cavity
        cavityInsSH = get_mat_air.inside_air_sh
    else
        cavityInsDens = get_mat_densepack_generic.rho
        cavityInsSH = get_mat_densepack_generic.Cp
	end
		
    wsGapFactor = get_wall_gap_factor(ss.SSWallInstallGrade, ss.SSWallFramingFactor)	

    overall_wall_Rvalue = get_steel_stud_wall_r_assembly(ss, ext_wall_mass.ExtWallMassGypsumThickness, ext_wall_mass.ExtWallMassGypsumNumLayers, exterior_finish.FinishThickness, exterior_finish.FinishConductivity, wallsh.WallSheathingContInsThickness, wallsh.WallSheathingContInsRvalue, wallsh.WallSheathingHasOSB)
		
    # Create layers for modeling
	films = Get_films_constant.new
    sc.stud_layer_thickness = OpenStudio::convert(ss.SSWallCavityDepth,"in","ft").get # ft
    sc.stud_layer_conductivity = sc.stud_layer_thickness / (overall_wall_Rvalue - (films.vertical + films.outside + wallsh.WallSheathingContInsRvalue + wallsh.OSBRvalue + exterior_finish.FinishRvalue + ext_wall_mass.ExtWallMassGypsumRvalue)) # Btu/hr*ft*F		
    sc.stud_layer_density = ss.SSWallFramingFactor * get_mat_wood.rho + (1 - ss.SSWallFramingFactor - wsGapFactor) * cavityInsDens + wsGapFactor * inside_air_dens 
    sc.stud_layer_spec_heat = (ss.SSWallFramingFactor * get_mat_wood.Cp * get_mat_wood.rho + (1 - ss.SSWallFramingFactor - wsGapFactor) * cavityInsSH * cavityInsDens + wsGapFactor * get_mat_air.inside_air_sh * inside_air_dens) / sc.stud_layer_density		
		
	wallsh = _addInsulatedSheathingMaterial(wallsh)
		
	return sc, wallsh
		
  end

  def _processConstructionsExteriorInsulatedWallsCMU(cmu, ext_wall_mass, exterior_finish, wallsh, fu)
	overall_wall_Rvalue, furring_layer_equiv_Rvalue = get_cmu_wall_r_assembly(cmu, ext_wall_mass.ExtWallMassGypsumThickness, ext_wall_mass.ExtWallMassGypsumNumLayers, exterior_finish.FinishThickness, exterior_finish.FinishConductivity, wallsh.WallSheathingContInsThickness, wallsh.WallSheathingContInsRvalue, wallsh.WallSheathingHasOSB)
	
	# Set Furring insulation/air properties
	films = Get_films_constant.new
	cmu.cmu_layer_conductivity = (OpenStudio.convert(cmu.CMUThickness,"in","ft").get / (overall_wall_Rvalue - (films.vertical + films.outside + furring_layer_equiv_Rvalue + wallsh.WallSheathingContInsRvalue + wallsh.OSBRvalue + exterior_finish.FinishRvalue + ext_wall_mass.ExtWallMassGypsumRvalue))) # Btu/hr*ft*F
	cmu.cmu_layer_density = (cmu.CMUFramingFactor * get_mat_wood.rho + (1.0 - cmu.CMUFramingFactor) * cmu.CMUDensity) # lbm/ft^3)
	cmu.cmu_layer_spec_heat = (cmu.CMUFramingFactor * get_mat_wood.Cp * get_mat_wood.rho + (1.0 - cmu.CMUFramingFactor) * get_mat_concrete.Cp * cmu.CMUDensity) / cmu.cmu_layer_density # Btu/lbm-F
	
	if cmu.CMUFurringCavityDepth != 0
	
		cmuFurringInsRvalue = cmu.CMUFurringInsRvalue
		# Add air film coefficients when no insulation
		if cmuFurringInsRvalue.nil? or cmuFurringInsRvalue == 0
			cmuFurringInsRvalue = get_mat_air.R_air_gap
		end
	
		if cmuFurringInsRvalue == 0
			furring_ins_dens = inside_air_dens # lbm/ft^3   Assumes an empty cavity with air films
			furring_ins_sh = get_mat_air.inside_air_sh
		else
			furring_ins_dens = get_mat_densepack_generic.rho # lbm/ft^3
			furring_ins_sh = get_mat_densepack_generic.Cp
		end
		
		fu.furring_layer_thickness = OpenStudio.convert(cmu.CMUFurringCavityDepth,"in","ft").get # ft
		fu.furring_layer_conductivity = fu.furring_layer_thickness / furring_layer_equiv_Rvalue # Btu/hr*ft*F
		frac = get_mat_2x4(get_mat_wood).width_in / cmu.CMUFurringStudSpacing + cmu.CMUFramingFactor
		fu.furring_layer_density = frac * get_mat_wood.rho + (1.0 - frac) * furring_ins_dens # lbm/ft^3
		fu.furring_layer_spec_heat = (frac * get_mat_wood.Cp * get_mat_wood.rho + (1.0 - frac) * furring_ins_sh * furring_ins_dens) / fu.furring_layer_density # Btu/lbm*F
		
	end
	
	wallsh = _addInsulatedSheathingMaterial(wallsh)
	
	return cmu, fu, wallsh
  
  end
  
  def _processConstructionsExteriorInsulatedWallsSIP(sip, ext_wall_mass, exterior_finish, wallsh)
	int_sheathing = get_sip_sheathing_type(sip.SIPIntSheathingType)
  
	overall_wall_Rvalue, sip.spline_layer_thickness, sip.ins_layer_thickness, cavity_frac = get_sip_wall_r_assembly(sip, int_sheathing, ext_wall_mass.ExtWallMassGypsumThickness, ext_wall_mass.ExtWallMassGypsumNumLayers, exterior_finish.FinishThickness, exterior_finish.FinishConductivity, wallsh.WallSheathingContInsThickness, wallsh.WallSheathingContInsRvalue, wallsh.WallSheathingHasOSB)
  
	int_sheathing_Rvalue = OpenStudio.convert(sip.SIPIntSheathingThick,"in","ft").get / int_sheathing.k
	
	ins_layer_equiv_Rvalue = (1.0 / ((1.0 - sip.SIPFramingFactor) / ((sip.SIPInsThickness - 1.0) / sip.SIPInsThickness * sip.SIPInsRvalue) + sip.SIPFramingFactor / (OpenStudio.convert(sip.SIPInsThickness - 1.0,"in","ft").get / get_mat_wood.k))) # hr*ft^2*F/Btu
	
	films = Get_films_constant.new
	sip.spline_layer_conductivity = (sip.spline_layer_thickness / ((overall_wall_Rvalue - (films.vertical + films.outside + wallsh.WallSheathingContInsRvalue + wallsh.OSBRvalue + ins_layer_equiv_Rvalue + int_sheathing_Rvalue + exterior_finish.FinishRvalue + ext_wall_mass.ExtWallMassGypsumRvalue)) / 2.0)) # Btu/hr*ft*F

	sip.spline_layer_density = (1.0 - cavity_frac) * get_mat_wood.rho + cavity_frac * get_mat_rigid_ins.rho # lbm/ft^3
	sip.spline_layer_spec_heat = ((1.0 - cavity_frac) * get_mat_wood.Cp * get_mat_wood.rho + cavity_frac * get_mat_rigid_ins.Cp * get_mat_rigid_ins.rho) / sip.spline_layer_density # Btu/lbm-F
	
	sip.ins_layer_conductivity = sip.ins_layer_thickness / ins_layer_equiv_Rvalue # Btu/hr*ft*F
	sip.ins_layer_density = sip.SIPFramingFactor * get_mat_wood.rho + (1.0 - sip.SIPFramingFactor) * get_mat_rigid_ins.rho # lbm/ft3
	sip.ins_layer_spec_heat = (sip.SIPFramingFactor * get_mat_wood.Cp * get_mat_wood.rho + (1.0 - sip.SIPFramingFactor) * get_mat_rigid_ins.Cp * get_mat_rigid_ins.rho) / sip.ins_layer_density # Btu/lbm-F
	
	wallsh = _addInsulatedSheathingMaterial(wallsh)
	
	return sip, int_sheathing, wallsh
	
  end
  
  def _processConstructionsExteriorInsulatedWallsICF(icf, ext_wall_mass, exterior_finish, wallsh)
	overall_wall_Rvalue = get_icf_wall_r_assembly(icf, ext_wall_mass.ExtWallMassGypsumThickness, ext_wall_mass.ExtWallMassGypsumNumLayers, exterior_finish.FinishThickness, exterior_finish.FinishConductivity, wallsh.WallSheathingContInsThickness, wallsh.WallSheathingContInsRvalue, wallsh.WallSheathingHasOSB) 
	
	conc_layer_equiv_Rvalue = (1.0 / (icf.ICFFramingFactor / (OpenStudio.convert(icf.ICFConcreteThickness,"in","ft").get / get_mat_wood.k) + (1.0 - icf.ICFFramingFactor) / (OpenStudio.convert(icf.ICFConcreteThickness,"in","ft").get / get_mat_concrete.k))) # hr*ft^2*F/Btu
	
	films = Get_films_constant.new
	icf.ins_layer_thickness = OpenStudio.convert(icf.ICFInsThickness,"in","ft").get # ft
	icf.ins_layer_conductivity = (icf.ins_layer_thickness / ((overall_wall_Rvalue - (films.vertical + films.outside + wallsh.WallSheathingContInsRvalue + wallsh.OSBRvalue + conc_layer_equiv_Rvalue + exterior_finish.FinishRvalue + ext_wall_mass.ExtWallMassGypsumRvalue)) / 2.0)) # Btu/hr*ft*F
	icf.ins_layer_density = icf.ICFFramingFactor * get_mat_wood.rho + (1.0 - icf.ICFFramingFactor) * get_mat_rigid_ins.rho # lbm/ft^3
	icf.ins_layer_spec_heat = (icf.ICFFramingFactor * get_mat_wood.Cp * get_mat_wood.rho + (1.0 - icf.ICFFramingFactor) * get_mat_rigid_ins.Cp * get_mat_rigid_ins.rho) / icf.ins_layer_density # Btu/lbm-F
	
	icf.conc_layer_thickness = OpenStudio.convert(icf.ICFConcreteThickness,"in","ft").get # ft
	icf.conc_layer_conductivity = icf.conc_layer_thickness / conc_layer_equiv_Rvalue # Btu/hr*ft*F
	icf.conc_layer_density = icf.ICFFramingFactor * get_mat_wood.rho + (1.0 - icf.ICFFramingFactor) * get_mat_concrete.rho # lbm/ft^3
	icf.conc_layer_spec_heat = (icf.ICFFramingFactor * get_mat_wood.Cp * get_mat_wood.rho + (1.0 - icf.ICFFramingFactor) * get_mat_concrete.Cp * get_mat_concrete.rho) / icf.conc_layer_density # lbm/ft^3
	
	wallsh = _addInsulatedSheathingMaterial(wallsh)
	
	return icf, wallsh
	
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
    # Location Info
    local_pressure = 2.7128 ** (-0.0000368 * @weather.header.Altitude) # atm

		return local_pressure
  end

  def self._processWindSpeedCorrection(wind_speed, site, constants, infiltration, neighbors, geometry)
    # Wind speed correction
    wind_speed.height = 32.8 # ft (Standard weather station height)

    # Open, Unrestricted at Weather Station
    wind_speed.terrain_multiplier = 1.0 # Used for DOE-2's correlation
    wind_speed.terrain_exponent = 0.15 # Used in both DOE-2 and E+ (E+ value adjusted for agreement with DOE-2)
    wind_speed.boundary_layer_thickness = 885.8 # ft (Used for E+'s correlation (E+ value adjusted for agreement with DOE-2))

    if site.TerrainType == constants.TerrainOcean
      wind_speed.site_terrain_multiplier = 1.30 # Used for DOE-2's correlation
      wind_speed.site_terrain_exponent = 0.10 # Used in both DOE-2 and E+ (E+ value adjusted for agreement with DOE-2)
      wind_speed.site_boundary_layer_thickness = 333.9 # ft (Used for E+'s correlation (E+ value adjusted for agreement with DOE-2))
    elsif site.TerrainType == constants.TerrainPlains
      wind_speed.site_terrain_multiplier = 1.00 # Used for DOE-2's correlation
      wind_speed.site_terrain_exponent = 0.15 # Used in both DOE-2 and E+ (E+ value adjusted for agreement with DOE-2)
      wind_speed.site_boundary_layer_thickness = 885.8 # ft (Used for E+'s correlation (E+ value adjusted for agreement with DOE-2))
    elsif site.TerrainType == constants.TerrainRural
      wind_speed.site_terrain_multiplier = 0.85 # Used for DOE-2's correlation
      wind_speed.site_terrain_exponent = 0.20 # Used in both DOE-2 and E+ (E+ value adjusted for agreement with DOE-2)
      wind_speed.site_boundary_layer_thickness = 875.8 # ft (Used for E+'s correlation (E+ value adjusted for agreement with DOE-2))
    elsif site.TerrainType == constants.TerrainSuburban
      wind_speed.site_terrain_multiplier = 0.67 # Used for DOE-2's correlation
      wind_speed.site_terrain_exponent = 0.25 # Used in both DOE-2 and E+ (E+ value adjusted for agreement with DOE-2)
      wind_speed.site_boundary_layer_thickness = 1176 # ft (Used for E+'s correlation (E+ value adjusted for agreement with DOE-2))
    elsif site.TerrainType == constants.TerrainCity
      wind_speed.site_terrain_multiplier = 0.47 # Used for DOE-2's correlation
      wind_speed.site_terrain_exponent = 0.3499 # Used in both DOE-2 and E+ (E+ value adjusted for agreement with DOE-2)
      wind_speed.site_boundary_layer_thickness = 1165.0 # ft (Used for E+'s correlation (E+ value adjusted for agreement with DOE-2))
    end

    wind_speed.ref_wind_speed = 10.0 # mph

    # Local Shielding
    if infiltration.InfiltrationShelterCoefficient == constants.Auto
      if neighbors.NeighborOffset.nil?
        # Typical shelter for isolated rural house
        wind_speed.S_wo = 0.90
      elsif neighbors.NeighborOffset > geometry.building_height
        # Typical shelter caused by other building across the street
        wind_speed.S_wo = 0.70
      elsif neighbors.NeighborOffset <= geometry.building_height
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

  def _processMechanicalVentilation(infil, vent, misc, clothes_dryer, geometry, living_space, schedules)
    # Mechanical Ventilation

    constants = Constants.new
    psychrometrics = Psychrometrics.new

    # Get ASHRAE 62.2 required ventilation rate (excluding infiltration credit)
    ashrae_mv_without_infil_credit = get_mech_vent_whole_house_cfm(1, geometry.num_bedrooms, geometry.finished_floor_area, vent.MechVentASHRAEStandard)	
	
    # Determine mechanical ventilation infiltration credit (per ASHRAE 62.2);
    # only applies to existing buildings
	infil.rate_credit = 0 # default to no credit
    if vent.MechVentInfilCreditForExistingHomes and misc.AgeOfHome > 0

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
    if misc.SimTestSuiteBuilding != constants.TestBldgMinimal
      vent.MechVentBathroomExhaust = 50.0 # cfm, per HSP
      vent.MechVentRangeHoodExhaust = 100.0 # cfm, per HSP
      vent.MechVentSpotFanPower = 0.3 # W/cfm/fan, per HSP
    else
      vent.MechVentBathroomExhaust = 0.0 # cfm
      vent.MechVentRangeHoodExhaust = 0.0 # cfm
      vent.MechVentSpotFanPower = 0.0 # W/cfm/fan
    end

    vent.bath_exhaust_operation = 60.0 # min/day, per HSP
    vent.range_hood_exhaust_operation = 60.0 # min/day, per HSP
    vent.clothes_dryer_exhaust_operation = 60.0 # min/day, per HSP

    vent.num_vent_fans = get_mech_vent_num_vent_fans(vent.MechVentType)

    if vent.MechVentType == constants.VentTypeExhaust
      vent.percent_fan_heat_to_space = 0.0 # Fan heat does not enter space
    elsif vent.MechVentType == constants.VentTypeSupply
      vent.percent_fan_heat_to_space = 1.0 # Fan heat does enter space
    elsif vent.MechVentType == constants.VentTypeBalanced
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

    if vent.MechVentType == constants.VentTypeBalanced and vent.MechVentSensibleEfficiency > 0 and vent.whole_house_vent_rate > 0
      # Must assume an operating condition (HVI seems to use CSA 439)
      t_sup_in = 0
      w_sup_in = 0.0028
      t_exh_in = 22
      w_exh_in = 0.0065
      cp_a = 1006
      p_fan = vent.whole_house_vent_rate * vent.MechVentHouseFanPower                                         # Watts

      m_fan = OpenStudio::convert(vent.whole_house_vent_rate,"cfm","m^3/s").get * 16.02 * psychrometrics.rhoD_fT_w_P(OpenStudio::convert(t_sup_in,"C","F").get, w_sup_in, 14.7) # kg/s

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

        m_fan = OpenStudio::convert(vent.whole_house_vent_rate,"cfm","m^3/s").get * 16.02 * psychrometrics.rhoD_fT_w_P(OpenStudio::convert(t_sup_in,"C","F").get, w_sup_in, 14.7) # kg/s

        t_sup_out_gross = t_sup_in - vent.MechVentHXCoreSensibleEffectiveness * (t_sup_in - t_exh_in)
        t_sup_out = t_sup_out_gross + p_fan / (m_fan * cp_a)

        h_sup_in = psychrometrics.h_fT_w_SI(t_sup_in, w_sup_in)
        h_exh_in = psychrometrics.h_fT_w_SI(t_exh_in, w_exh_in)
        h_sup_out = h_sup_in - (vent.MechVentTotalEfficiency * (m_fan * (h_sup_in - h_exh_in) + p_fan) + p_fan) / m_fan

        w_sup_out = psychrometrics.w_fT_h_SI(t_sup_out, h_sup_out)
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

    constants = Constants.new

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
        nv.season_type << constants.SeasonHeating
      elsif heating_season[month] == 0.0 and cooling_season[month] == 1.0
        nv.season_type << constants.SeasonCooling
      elsif heating_season[month] == 1.0 and cooling_season[month] == 1.0
        nv.season_type << constants.SeasonOverlap
      else
        nv.season_type << constants.SeasonNone
      end
    end

    sch_year = "
    Schedule:Year,
      NatVentTemp,                 !- Name
      TEMPERATURE,                 !- Schedule Type"
    nv.season_type.each_with_index do |ssn_type, month|
      if ssn_type == constants.SeasonHeating
        week_schedule_name = "NatVentHtgSsnTempWeek"
      elsif ssn_type == constants.SeasonCooling
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
      if (nv.season_type[month] == constants.SeasonHeating and nv.NatVentHeatingSeason) or (nv.season_type[month] == constants.SeasonCooling and nv.NatVentCoolingSeason) or (nv.season_type[month] == constants.SeasonOverlap and nv.NatVentOverlapSeason)
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
    nv.C_s = f_s_nv ** 2.0 * constants.g * living_space.height / (infiltration.assumed_inside_temp + 460.0)
    nv.C_w = f_w_nv ** 2.0

    return nv, schedules

  end

	def assumed_inside_temp
		assumed_inside_temp = 73.5
		return assumed_inside_temp
	end
	
	# _processMiscMatProps
	def self.stud_spacing_default
		# Nominal Lumber
		return 16.0 # in
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
    properties = Properties.new
		mat_air.inside_air_dens = 2.719 * local_pressure / (properties.Air.R * (assumed_inside_temp + 460)) # lb/ft^3
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
		# slab.ext_perimeter = 0 # ft
		# slab.area = 0 # ft
		
        # for floor in geometry.floors.floor:
            # if self._getSpace(floor.space_above).finished and \
                # self._getSpace(floor.space_below).spacetype == Constants.SpaceGround:
                # self.slab.ext_perimeter += floor.slab_ext_perimeter
                # self.slab.area += floor.area
		
		# temp tk
		# slab.ext_perimeter = 154.0
		# slab.area = 1482.0
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
		crawlspace_conduction = calc_crawlspace_wall_conductance(cs.CrawlWallContInsRvalueNominal, cs.height)
		#
		
		cci.crawl_ceiling_Rvalue = get_crawlspace_ceiling_r_assembly(cs, carpet, floor_mass)
		
		crawl_ceiling_studlayer_Rvalue = cci.crawl_ceiling_Rvalue - floor_nonstud_layer_Rvalue(floor_mass, carpet)
		
		csGapFactor = get_wall_gap_factor(cs.CrawlCeilingInstallGrade, cs.CrawlCeilingFramingFactor)
		
		if cci.crawl_ceiling_Rvalue > 0
			cci.crawl_ceiling_thickness = mat_2x.thick
			cci.crawl_ceiling_conductivity = cci.crawl_ceiling_thickness / crawl_ceiling_studlayer_Rvalue
			cci.crawl_ceiling_density = cs.CrawlCeilingFramingFactor * get_mat_wood.rho + (1 - cs.CrawlCeilingFramingFactor - csGapFactor) * get_mat_densepack_generic.rho + csGapFactor * inside_air_dens # lbm/ft^3
			cci.crawl_ceiling_spec_heat = (cs.CrawlCeilingFramingFactor * get_mat_wood.Cp * get_mat_wood.rho + (1 - cs.CrawlCeilingFramingFactor - csGapFactor) * get_mat_densepack_generic.Cp * get_mat_densepack_generic.rho + csGapFactor * get_mat_air.inside_air_sh * inside_air_dens) / cci.crawl_ceiling_density # Btu/lbm*F
		end
		
		if cs.CrawlWallContInsRvalueNominal > 0
			crawlspace_wall_thickness = OpenStudio::convert(cs.CrawlWallContInsRvalueNominal / 5.0,"in","ft").get # ft
			crawlspace_wall_conductivity = crawlspace_wall_thickness / cs.CrawlWallContInsRvalueNominal # Btu/hr*ft*F
			crawlspace_wall_density = get_mat_rigid_ins.rho # lbm/ft^3
			crawlspace_wall_spec_heat = get_mat_rigid_ins.Cp # Btu/lbm*F
		end
		
		# Calculate Exterior Crawlspace Wall Area and PerimeterSlabInsulation
		# crawlspace_wall_area = 0 # ft^2
		# cs.ext_perimeter = 0 # ft^2

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
		crawlspace_wall_area = cs.ext_perimeter * cs.height
		
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
			cs.crawlspace_area
			crawlspace_floor_Rvalue = cs.crawlspace_area / (crawlspace_total_UA - crawlspace_wall_area / (crawlspace_US_Rvalue + get_mat_soil12in(get_mat_soil).Rvalue)) - get_mat_soil12in(get_mat_soil).Rvalue # hr*ft^2*F/Btu
			 # (assumes crawlspace floor is dirt with no concrete slab)
		else
			crawlspace_floor_Rvalue = 1000 # hr*ft^2*F/Btu
		end

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
	
	izfGapFactor = get_wall_gap_factor(izf.IntFloorInstallGrade, izf.IntFloorFramingFactor)

    ifi.boundary_floor_thickness = mat_2x6.thick # ft
    ifi.boundary_floor_conductivity = ifi.boundary_floor_thickness / boundaryFloorRvalue # Btu/hr*ft*F
    ifi.boundary_floor_density = izf.IntFloorFramingFactor * mat_wood.rho + (1 - izf.IntFloorFramingFactor - izfGapFactor) * get_mat_densepack_generic.rho  + izfGapFactor * inside_air_dens # lbm/ft^3
    ifi.boundary_floor_spec_heat = (izf.IntFloorFramingFactor * mat_wood.Cp * mat_wood.rho + (1 - izf.IntFloorFramingFactor - izfGapFactor) * get_mat_densepack_generic.Cp * get_mat_densepack_generic.rho + izfGapFactor * get_mat_air.inside_air_sh * inside_air_dens) / ifi.boundary_floor_density # Btu/lbm*F

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

    films = Get_films_constant.new

    door_Uvalue_air_to_air = 0.2 # Btu/hr*ft^2*F, As per 2010 BA Benchmark
    garage_door_Uvalue_air_to_air = 0.2 # Btu/hr*ft^2*F, R-values typically vary from R5 to R10, from the Home Depot website

    door_Rvalue_air_to_air = 1.0 / door_Uvalue_air_to_air
    garage_door_Rvalue_air_to_air = 1.0 / garage_door_Uvalue_air_to_air

    door_Rvalue = door_Rvalue_air_to_air - films.outside - films.vertical
    garage_door_Rvalue = garage_door_Rvalue_air_to_air - films.outside - films.vertical

    d.mat_door_Uvalue = 1.0 / door_Rvalue
    gd.garage_door_Uvalue = 1.0 / garage_door_Rvalue

    d.door_thickness = OpenStudio.convert(1.75,"in","ft").get # ft
    gd.garage_door_thickness = OpenStudio.convert(2.5,"in","ft").get # ft

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

  def _processThermalMassPartitionWall(partitionWallMassFractionOfFloorArea, partition_wall_mass, living_space, finished_basement)

    # Handle Exception for user entry of zero (avoids EPlus complaining about zero value)
    if partitionWallMassFractionOfFloorArea <= 0.0
      partitionWallMassFractionOfFloorArea = 0.0001 # Set approximately to zero
    end

    # Calculate the total partition wall mass areas for conditioned spaces
    partition_wall_mass.living_space_area = partitionWallMassFractionOfFloorArea * living_space.area # ft^2
    partition_wall_mass.finished_basement_area = partitionWallMassFractionOfFloorArea * finished_basement.area # ft^2

    return partition_wall_mass

  end

  def _processThermalMassFurniture(hasFinishedBasement, hasUnfinishedBasement, hasGarage)
    constants = Constants.new

    has_furniture = true
    furnitureWeight = 8.0
    furnitureAreaFraction = 0.4
    furnitureDensity = 40.0
    furnitureConductivity = 0.8004
    furnitureSpecHeat = 0.29
    furnitureSolarAbsorptance = 0.6

    if furnitureDensity < 60.0
      living_space_furn_type = constants.FurnTypeLight
      finished_basement_furn_type = constants.FurnTypeLight
    else
      living_space_furn_type = constants.FurnTypeHeavy
      finished_basement_furn_type = constants.FurnTypeHeavy
    end

    # Living Space Furniture
    living_space_furn = Furniture.new(living_space_furn_type, furnitureDensity, furnitureConductivity, furnitureSpecHeat, furnitureAreaFraction, furnitureWeight, furnitureSolarAbsorptance)

    if has_furniture
      living_space_furn.thickness = living_space_furn.total_mass / (living_space_furn.density * living_space_furn.area_frac) # ft
    else
      living_space_furn.thickness = 0.00001 # ft. Set greater than EnergyPlus lower limit of zero.
    end

    # Finished Basement Furniture
    if hasFinishedBasement

      finished_basement_furn = Furniture.new(finished_basement_furn_type, furnitureDensity, furnitureConductivity, furnitureSpecHeat, furnitureAreaFraction, furnitureWeight, furnitureSolarAbsorptance)

      if has_furniture
        finished_basement_furn.thickness = finished_basement_furn.total_mass / (finished_basement_furn.density * finished_basement_furn.area_frac) # ft
      else
        finished_basement_furn.thickness = 0.00001 # ft, Set greater than the EnergyPlus lower limit of zero.
      end

    end

    # Unfinished Basement Furniture with hard-coded variables
    if hasUnfinishedBasement

      furn_type_ubsmt = constants.FurnTypeLight
      if furn_type_ubsmt == constants.FurnTypeLight
        ubsmt_furn = Furniture.new(furn_type_ubsmt, 40.0, 0.0667, get_mat_wood.Cp, 0.4, 8.0, nil)
      elsif furn_type_ubsmt == constants.FurnTypeHeavy
        ubsmt_furn = Furniture.new(furn_type_ubsmt, 80.0, 0.0939, 0.35, 0.4, 8.0, nil)
      end

      ubsmt_furn.thickness = ubsmt_furn.total_mass / (ubsmt_furn.density * ubsmt_furn.area_frac)

    end

    # Garage Furniture with hard-coded variables
    if hasGarage

      furn_type_grg = constants.FurnTypeLight
      if furn_type_grg == constants.FurnTypeLight
        garage_furn = Furniture.new(furn_type_grg, 40.0, 0.0667, get_mat_wood.Cp, 0.1, 2.0, nil)
      elsif furn_type_grg == constants.FurnTypeHeavy
        garage_furn = Furniture.new(furn_type_grg, 80.0, 0.0939, 0.35, 0.1, 2.0, nil)
      end

      garage_furn.thickness = garage_furn.total_mass / (garage_furn.density * garage_furn.area_frac)

    end

    return living_space_furn, finished_basement_furn, ubsmt_furn, garage_furn, has_furniture

  end

  def _processFilmResistances
    # Film Resistances
    # The following film resistance are used only in sim.py and DOE2

    cdd = @weather.data.CDD65F
    hdd = @weather.data.HDD65F

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

  def _processAirSystem(supply, furnace=nil, air_conditioner=nil, heat_pump=nil, hasFurnace=false, hasCoolingEquipment=false, hasAirConditioner=false, hasHeatPump=false, hasMiniSplitHP=false, hasRoomAirConditioner=false, hasGroundSourceHP=false, test_suite=nil)
    # Air System

    if air_conditioner.ACCoolingInstalledSEER == 999
      air_conditioner.IsIdealAC = true
    else
      air_conditioner.IsIdealAC = false
    end

    supply.static = 249.1 * 0.5 # Pascal

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

      if hasAirConditioner

        ac = air_conditioner

        # Cooling Coil
        if ac.IsIdealAC
          supply = get_cooling_coefficients(ac.ACNumberSpeeds, true, false, supply)
        else
          supply = get_cooling_coefficients(ac.ACNumberSpeeds, false, false, supply)
        end

        supply.CFM_TON_Rated = calc_cfm_ton_rated(ac.ACRatedAirFlowRate, ac.ACFanspeedRatio, ac.ACCapacityRatio)
        supply = Sim._processAirSystemCoolingCoil(ac.ACNumberSpeeds, ac.ACCoolingEER, ac.ACCoolingInstalledSEER, ac.ACSupplyFanPowerInstalled, ac.ACSupplyFanPowerRated, ac.ACSHRRated, ac.ACCapacityRatio, ac.ACFanspeedRatio, ac.ACCondenserType, ac.ACCrankcase, ac.ACCrankcaseMaxT, ac.ACEERCapacityDerateFactor, test_suite, air_conditioner, supply, hasHeatPump)

      end

      if hasHeatPump

        hp = heat_pump

        # Cooling Coil
        supply = get_cooling_coefficients(hp.HPNumberSpeeds, false, true, supply)
        supply.CFM_TON_Rated = calc_cfm_ton_rated(hp.HPRatedAirFlowRateCooling, hp.HPFanspeedRatioCooling, hp.HPCapacityRatio)
        supply = Sim._processAirSystemCoolingCoil(hp.HPNumberSpeeds, hp.HPCoolingEER, hp.HPCoolingInstalledSEER, hp.HPSupplyFanPowerInstalled, hp.HPSupplyFanPowerRated, hp.HPSHRRated, hp.HPCapacityRatio, hp.HPFanspeedRatioCooling, hp.HPCondenserType, hp.HPCrankcase, hp.HPCrankcaseMaxT, hp.HPEERCapacityDerateFactor, test_suite, air_conditioner, supply, hasHeatPump)

        # Heating Coil
        supply = get_heating_coefficients(supply.Number_Speeds, false, supply)
        supply.CFM_TON_Rated_Heat = calc_cfm_ton_rated(hp.HPRatedAirFlowRateHeating, hp.HPFanspeedRatioHeating, hp.HPCapacityRatio)
        supply = Sim._processAirSystemHeatingCoil(hp.HPHeatingCOP, hp.HPHeatingInstalledHSPF, hp.HPSupplyFanPowerRated, hp.HPCapacityRatio, hp.HPFanspeedRatioHeating, hp.HPMinT, hp.HPCOPCapacityDerateFactor, test_suite, supply)

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

  def self._processAirSystemCoolingCoil(number_Speeds, coolingEER, coolingSEER, supplyFanPower, supplyFanPower_Rated, shr_Rated, capacity_Ratio, fanspeed_Ratio, condenserType, crankcase, crankcase_MaxT, eer_CapacityDerateFactor, test_suite, air_conditioner, supply, hasHeatPump)

    # if len(Capacity_Ratio) > len(set(Capacity_Ratio)):
    #     SimError("Capacity Ratio values must be unique ({})".format(Capacity_Ratio))

    # Curves are hardcoded for both one and two speed models
    supply.Number_Speeds = number_Speeds

    if test_suite.min_test_ideal_loads or air_conditioner.IsIdealAC
      supply = get_cooling_coefficients(supply.Number_Speeds, true, nil, supply)
    end

    supply.CoolingEIR = Array.new
    supply.SHR_Rated = Array.new
    (0...supply.Number_Speeds).to_a.each do |speed|

      if air_conditioner.IsIdealAC
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

    if test_suite.min_test_ideal_loads or air_conditioner.IsIdealAC
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
    supply.eff = OpenStudio::convert(supply.static / supply.fan_power,"cfm","m^3/s").get # Overall Efficiency of the Supply Fan, Motor and Drive
    supply.min_flow_ratio = fanspeed_Ratio[0] / fanspeed_Ratio[-1]

    supply.EER_CapacityDerateFactor = eer_CapacityDerateFactor

    return supply

  end

  def self._processAirSystemHeatingCoil(heatingCOP, heatingHSPF, supplyFanPower_Rated, capacity_Ratio, fanspeed_Ratio_Heating, min_T, cop_CapacityDerateFactor, test_suite, supply)

    # if len(Capacity_Ratio) > len(set(Capacity_Ratio)):
    #     SimError("Capacity Ratio values must be unique ({})".format(Capacity_Ratio))

    if test_suite.min_test_ideal_loads
      get_heating_coeffcients(supply.Number_Speeds, true, supply)
    end

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

    if test_suite.min_test_ideal_loads
      supply.HEAT_CLOSS_FPLR_SPEC_coefficients = [1, 0, 0]
    end

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
	
	gapFactor = get_wall_gap_factor(cs.CrawlCeilingInstallGrade, cs.CrawlCeilingFramingFactor)
	
	path_fracs = [cs.CrawlCeilingFramingFactor, 1 - cs.CrawlCeilingFramingFactor - gapFactor, gapFactor]
	
	crawl_ceiling = Construction.new(path_fracs)
	
	# Interior Film
	crawl_ceiling.addlayer(thickness=OpenStudio::convert(1.0,"in","ft").get, conductivity_list=[OpenStudio::convert(1.0,"in","ft").get / films.floor_reduced])
	
	# Stud/cavity layer
	if cs.CrawlCeilingCavityInsRvalueNominal == 0
		cavity_k = 1000000000
	else
		cavity_k = (mat_2x.thick / cs.CrawlCeilingCavityInsRvalueNominal)
	end
	gap_k = mat_2x.thick / get_mat_air.R_air_gap
	
	crawl_ceiling.addlayer(thickness=mat_2x.thick, conductivity_list=[mat_wood.k, cavity_k, gap_k])

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
			return false
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
			return false
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
      spaceArea_UAtc = spaceArea_UAtc - spaceArea_UAtc_Perim + Math::log((rfEdgeW_UAtc * Math::tan(rfTilt / 180 * Math::PI) + rfEdgeMinH_UAtc) / rfEdgeMinH_UAtc) / Math::tan(rfTilt / 180 * Math::PI) * rfPerimeter_UAtc * OpenStudio::convert(uatc.UACeilingInsThickness,"in","ft").get
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

def set_variable_list_heating_set_point(category)
  # Convert to Weekday/Weekend 24-hour lists
  if not category.HeatingSetpointConstantSetpoint.nil?
    category.HeatingSetpointSchedule = Array.new(48, category.HeatingSetpointConstantSetpoint)
  end
  return category
end

def set_variable_list_cooling_set_point(category)
  # Convert to Weekday/Weekend 24-hour lists
  if not category.CoolingSetpointConstantSetpoint.nil?
    category.CoolingSetpointSchedule = Array.new(48, category.CoolingSetpointConstantSetpoint)
  end
  return category
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
  constants = Constants.new
  if not [1.0, 2.0, 4.0, constants.Num_Speeds_MSHP].include? num_speeds
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
      elsif num_speeds == constants.Num_Speeds_MSHP
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

def get_mech_vent_num_vent_fans(vent_type)
	constants = Constants.new
    if vent_type == constants.VentTypeExhaust
        return 1 # One fan for unbalanced airflow
    elsif vent_type == constants.VentTypeSupply
        return 1 # One fan for unbalanced airflow
    elsif vent_type == constants.VentTypeBalanced
        return 2 # Two fans for balanced airflow
    end
	return 1 # Default to one fan
end

class Process_clothes_washer
  #CW energy use comes from the measure (user specified), schedule is here
  
  def initialize
  
    #hard coded convective, radiative, latent, and lost fractions for clothes washers
    @clothes_w_lat = 0.00
    @clothes_w_rad = 0.48
    @clothes_w_lost = 0.2
    @clothes_w_conv = 0.32
    #Clothes washer weekday, weekend schedule and monthly multipliers
	

    #CW weekday, weekend schedule and monthly multipliers
	
	#Right now hard coded simple schedules
	#TODO: Schedule inputs. Should be 24 or 48 hourly + 12 monthly, is 36-60 inputs too much? how to handle 8760 schedules (from a file?)
	@monthly_mult_cw = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0]
	hourly_cw = [0.009, 0.007, 0.004, 0.004, 0.007, 0.011, 0.022, 0.049, 0.073, 0.086, 0.084, 0.075, 0.067, 0.060, 0.049, 0.052, 0.050, 0.049, 0.049, 0.049, 0.049, 0.047, 0.032, 0.017]
	@weekday_hourly_cw = hourly_cw.collect {|n| n * 1.04 * 0.94}
    @weekend_hourly_cw = hourly_cw.collect {|n| n * 1.04 * 1.15}

  end

  def Clothes_w_lat
    return @clothes_w_lat
  end

  def Clothes_w_rad
    return @clothes_w_rad
  end

  def Clothes_w_lost
    return @clothes_w_lost
  end

  def Clothes_w_conv
    return @clothes_w_conv
  end

  def Monthly_mult_cw
    return @monthly_mult_cw
  end

  def Weekday_hourly_cw
    return @weekday_hourly_cw
  end

  def Weekend_hourly_cw
    return @weekend_hourly_cw
  end

  def Sum_cw_max
    #if sum != 1, normalize to get correct max val
    sum_cw_wkdy = 0
    sum_cw_wknd = 0
	sum_cw_max = 0
	
    @weekday_hourly_cw.each do |v|
      sum_cw_wkdy = sum_cw_wkdy + v
    end

    @weekend_hourly_cw.each do |v|
      sum_cw_wknd = sum_cw_wkdy + v
    end

	if sum_cw_wkdy < sum_cw_wknd
		sum_cw_max = sum_cw_wknd
	else
		sum_cw_max = sum_cw_wkdy
	end
	
    return sum_cw_max
  end

  def Maxval_cw
    #get max schedule value
    if @weekday_hourly_cw.max > @weekend_hourly_cw.max
      return @monthly_mult_cw.max * @weekday_hourly_cw.max #/ sum_range_wkdy
    else
      return @monthly_mult_cw.max * @weekend_hourly_cw.max #/ sum_range_wknd
    end
  end
end

class Process_clothes_dryer
  #CW energy use comes from the measure (user specified), schedule is here
  
  def initialize
  
    #hard coded convective, radiative, latent, and lost fractions for clothes washers
    @cd_lat_e = 0.05
    @cd_rad_e = 0.09
    @cd_lost_e = 0.8
    @cd_conv_e = 0.06
	
	@cd_lat_g = 0.05
    @cd_rad_g = 0.06
    @cd_lost_g = 0.85
    @cd_conv_g = 0.04
	
	@cd_lat_e_g = 0.00
    @cd_rad_e_g = 0.6
    @cd_lost_e_g = 0.0
    @cd_conv_e_g = 0.4
    #Clothes washer weekday, weekend schedule and monthly multipliers
	

    #CW weekday, weekend schedule and monthly multipliers
	
	#Right now hard coded simple schedules
	#TODO: Schedule inputs. Should be 24 or 48 hourly + 12 monthly, is 36-60 inputs too much? how to handle 8760 schedules (from a file?)
	@monthly_mult_cd = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0]
	hourly_cd = [0.010, 0.006, 0.004, 0.002, 0.004, 0.006, 0.016, 0.032, 0.048, 0.068, 0.078, 0.081, 0.074, 0.067, 0.057, 0.061, 0.055, 0.054, 0.051, 0.051, 0.052, 0.054, 0.044, 0.024]
	@weekday_hourly_cd = hourly_cd.collect {|n| n * 1.04 * 0.94}
    @weekend_hourly_cd = hourly_cd.collect {|n| n * 1.04 * 1.15}
  end

  def Clothes_d_lat_e
    return @cd_lat_e
  end

  def Clothes_d_rad_e
    return @cd_rad_e
  end

  def Clothes_d_lost_e
    return @cd_lost_e
  end

  def Clothes_d_conv_e
    return @cd_conv_e
  end
  
    def Clothes_d_lat_g
    return @cd_lat_g
  end

  def Clothes_d_rad_g
    return @cd_rad_g
  end

  def Clothes_d_lost_g
    return @cd_lost_g
  end

  def Clothes_d_conv_g
    return @cd_conv_g
  end
  
  def Clothes_d_lat_e_g
    return @cd_lat_e_g
  end

  def Clothes_d_rad_e_g
    return @cd_rad_e_g
  end

  def Clothes_d_lost_e_g
    return @cd_lost_e_g
  end

  def Clothes_d_conv_e_g
    return @cd_conv_e_g
  end

  def Monthly_mult_cd
    return @monthly_mult_cd
  end

  def Weekday_hourly_cd
    return @weekday_hourly_cd
  end

  def Weekend_hourly_cd
    return @weekend_hourly_cd
  end

  def Sum_cd_max
    #if sum != 1, normalize to get correct max val
    sum_cd_wkdy = 0
    sum_cd_wknd = 0
	sum_cd_max = 0
	
    @weekday_hourly_cd.each do |v|
      sum_cd_wkdy = sum_cd_wkdy + v
    end

    @weekend_hourly_cd.each do |v|
      sum_cd_wknd = sum_cd_wkdy + v
    end

	if sum_cd_wkdy < sum_cd_wknd
		sum_cd_max = sum_cd_wknd
	else
		sum_cd_max = sum_cd_wkdy
	end
	
    return sum_cd_max
  end

  def Maxval_cd
    #get max schedule value
    if @weekday_hourly_cd.max > @weekend_hourly_cd.max
      return @monthly_mult_cd.max * @weekday_hourly_cd.max #/ sum_range_wkdy
    else
      return @monthly_mult_cd.max * @weekend_hourly_cd.max #/ sum_range_wknd
    end
  end
end

class Process_dishwasher

  def initialize
  
    #hard coded convective, radiative, latent, and lost fractions for dishwashers
    @dw_lat = 0.15
    @dw_rad = 0.36
    @dw_lost = 0.27
    @dw_conv = 0.24
    #Diswasher weekday, weekend schedule and monthly multipliers
	

    #DW weekday, weekend schedule and monthly multipliers
	
	#Right now hard coded simple schedules
	#TODO: Schedule inputs. Should be 24 or 48 hourly + 12 monthly, is 36-60 inputs too much? how to handle 8760 schedules (from a file?)
	@monthly_mult_cw = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0]
	@weekday_hourly_cw = [0.00934, 0.00747, 0.00373, 0.00373,0.00747, 0.01121, 0.02242, 0.04859,0.07289, 0.08598, 0.08411, 0.07476,0.06728, 0.05981, 0.05233, 0.04859,0.05046, 0.04859, 0.04859, 0.04859,0.04859, 0.04672, 0.03177, 0.01682]
	@weekend_hourly_cw = @weekday_hourly_cw
	@monthly_mult_dw = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0]
    hourly_dw = [0.015, 0.007, 0.005, 0.003, 0.003, 0.010, 0.020, 0.031, 0.058, 0.065, 0.056, 0.048, 0.041, 0.046, 0.036, 0.038, 0.038, 0.049, 0.087, 0.111, 0.090, 0.067, 0.044, 0.031]
    @weekday_hourly_dw = hourly_dw.collect {|n| n * 1.04 * 0.98}
    @weekend_hourly_dw = hourly_dw.collect {|n| n * 1.04 * 1.05}

  end

  def Dw_lat
    return @dw_lat
  end

  def Dw_rad
    return @dw_rad
  end

  def Dw_lost
    return @dw_lost
  end

  def Dw_conv
    return @dw_conv
  end

  def Monthly_mult_dw
    return @monthly_mult_dw
  end

  def Weekday_hourly_dw
    return @weekday_hourly_dw
  end

  def Weekend_hourly_dw
    return @weekend_hourly_dw
  end

  def Sum_dw_max
    #if sum != 1, normalize to get correct max val
    sum_dw_wkdy = 0
    sum_dw_wknd = 0
	sum_dw_max = 0

    @weekday_hourly_dw.each do |v|
      sum_dw_wkdy = sum_dw_wkdy + v
    end

    @weekend_hourly_dw.each do |v|
      sum_dw_wknd = sum_dw_wkdy + v
    end

	if sum_dw_wkdy < sum_dw_wknd
		sum_dw_max = sum_dw_wknd
	else
		sum_dw_max = sum_dw_wkdy
	end
	
    return sum_dw_max
  end

  def Maxval_dw
    #get max schedule value
    if @weekday_hourly_dw.max > @weekend_hourly_dw.max
      return @monthly_mult_dw.max * @weekday_hourly_dw.max #/ sum_range_wkdy
    else
      return @monthly_mult_dw.max * @weekend_hourly_dw.max #/ sum_range_wknd
    end
  end
end

class Process_mels
  #MEL energy use comes from the measure (user specified), schedule is here
  
  def initialize
  
    #hard coded convective, radiative, latent, and lost fractions for MELs
	@mel_lat_cf = 0.021
	@mel_rad_cf = 0.558
	@mel_lost_cf = 0.049
	@mel_conv_cf = 0.372
  
	@mel_lat = 0.022
	@mel_rad = 0.555
	@mel_lost = 0.053
	@mel_conv = 0.37
	
    #DW weekday, weekend schedule and monthly multipliers
	
	#Right now hard coded simple schedules
	#TODO: Schedule inputs. Should be 24 or 48 hourly + 12 monthly, is 36-60 inputs too much? how to handle 8760 schedules (from a file?)
	@monthly_mult_mel = [1.248, 1.257, 0.993, 0.989, 0.993, 0.827, 0.821, 0.821, 0.827, 0.99, 0.987, 1.248]
    @weekday_hourly_mel = [0.04, 0.037, 0.037, 0.036, 0.033, 0.036, 0.043, 0.047, 0.034, 0.023, 0.024, 0.025, 0.024, 0.028, 0.031, 0.032, 0.039, 0.053, 0.063, 0.067, 0.071, 0.069, 0.059, 0.05]
    @weekend_hourly_mel = @weekday_hourly_mel

  end

  def Mel_lat
    return @mel_lat
  end

  def Mel_rad
    return @mel_rad
  end

  def Mel_lost
    return @mel_lost
  end

  def Mel_conv
    return @mel_conv
  end
  
  def Mel_lat_cf
    return @mel_lat_cf
  end

  def Mel_rad_cf
    return @mel_rad_cf
  end

  def Mel_lost_cf
    return @mel_lost_cf
  end

  def Mel_conv_cf
    return @mel_conv_cf
  end

  def Monthly_mult_mel
    return @monthly_mult_mel
  end

  def Weekday_hourly_mel
    return @weekday_hourly_mel
  end

  def Weekend_hourly_mel
    return @weekend_hourly_mel
  end

  def Sum_mel_max
    #if sum != 1, normalize to get correct max val
    sum_mel_wkdy = 0
    sum_mel_wknd = 0
	sum_mel_max = 0
	
    @weekday_hourly_mel.each do |v|
      sum_mel_wkdy = sum_mel_wkdy + v
    end

    @weekend_hourly_mel.each do |v|
      sum_mel_wknd = sum_mel_wkdy + v
    end
	
	if sum_mel_wkdy < sum_mel_wknd
		sum_mel_max = sum_mel_wknd
	else
		sum_mel_max = sum_mel_wkdy
	end

    return sum_mel_max
  end

  def Maxval_mel
    #get max schedule value
    if @weekday_hourly_mel.max > @weekend_hourly_mel.max
      return @monthly_mult_mel.max * @weekday_hourly_mel.max #/ sum_range_wkdy
    else
      return @monthly_mult_mel.max * @weekend_hourly_mel.max #/ sum_range_wknd
    end
  end
end

class Process_lighting
  #Lighting energy use comes from the measure (user specified), some schedule info and other misc stuff is here
  
  #hard coded convective, radiative, latent, and lost fractions for fridges
  def initialize
	@ltg_rad = 0.6
	@ltg_rep = 0.0
	@ltg_vis = 0.2
	@ltg_raf = 0.00
	
	@bab_er_cfl = 0.27
	@bab_er_led = 0.30
	@bab_er_lfl = 0.17
  
	@bab_frac_inc = 0.66
	@bab_frac_cfl = 0.21
	@bab_frac_led = 0.00
	@bab_frac_lfl = 0.13
  
  #Lighting schedule stuff
  
	@dec_kws = [0.075, 0.055, 0.040, 0.035, 0.030, 0.025, 0.025, 0.025, 0.025, 0.025, 0.025, 0.030, 0.045, 0.075, 0.130, 0.160, 0.140, 0.100, 0.075, 0.065, 0.060, 0.050, 0.045, 0.045, 0.045, 0.045, 0.045, 0.045, 0.050, 0.060, 0.080, 0.130, 0.190, 0.230, 0.250, 0.260, 0.260, 0.250, 0.240, 0.225, 0.225, 0.220, 0.210, 0.200, 0.180, 0.155, 0.125, 0.100]
	@june_kws = [0.060, 0.040, 0.035, 0.025, 0.020, 0.020, 0.020, 0.020, 0.020, 0.020, 0.020, 0.020, 0.020, 0.025, 0.030, 0.030, 0.025, 0.020, 0.015, 0.015, 0.015, 0.015, 0.015, 0.015, 0.015, 0.015, 0.015, 0.015, 0.015, 0.015, 0.015, 0.015, 0.020, 0.020, 0.020, 0.025, 0.025, 0.030, 0.030, 0.035, 0.045, 0.060, 0.085, 0.125, 0.145, 0.130, 0.105, 0.080]
            
	@amplConst1 = 0.929707907917098
	@sunsetLag1 = 2.45016230615269
	@stdDevCons1 = 1.58679810983444
	@amplConst2 = 1.1372291802273
	@sunsetLag2 = 20.1501965859073
	@stdDevCons2 = 2.36567663279954
  end

  def StdDevCons1
	return @stdDevCons1
  end
  
  def StdDevCons2
	return @stdDevCons2
  end
  
  def SunsetLag1
	return @sunsetLag1
  end
  
  def SunsetLag2
	return @sunsetLag2
  end
  
  def AmplConst1
	return @amplConst1
  end
  
  def AmplConst2
	return @amplConst2
  end
  
  def Dec_kws
	return @dec_kws
  end
  
  def June_kws
	return @june_kws
  end
  
  def Bab_frac_inc
	return @bab_frac_inc
  end
  
  def Bab_frac_cfl
	return @bab_frac_cfl
  end
  
  def Bab_frac_led
	return @bab_frac_led
  end
  
  def Bab_frac_lfl
	return @bab_frac_lfl
  end
  
  def Bab_er_cfl
	return @bab_er_cfl
  end
  
  def Bab_er_led
	return @bab_er_led
  end
  
  def Bab_er_lfl
	return @bab_er_lfl
  end
  
  def Ltg_rad
	return @ltg_rad
  end
  
  def Ltg_rep
	return @ltg_rep
  end
  
  def Ltg_vis
	return @ltg_vis
  end
  
  def Ltg_raf
	return @ltg_raf
  end

end

class Process_occupants
  #MEL energy use comes from the measure (user specified), schedule is here
  
  def initialize
  
    #hard coded convective, radiative, latent, and lost fractions for MELs
	@occ_lat = 0.427
	@occ_rad = 0.32
	@occ_lost = 0.00
	@occ_conv = 0.253
	
    #DW weekday, weekend schedule and monthly multipliers
	
	#Right now hard coded simple schedules
	#TODO: Schedule inputs. Should be 24 or 48 hourly + 12 monthly, is 36-60 inputs too much? how to handle 8760 schedules (from a file?)
	@monthly_mult_occ = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0,]
    @weekday_hourly_occ = [1.00000, 1.00000, 1.00000, 1.00000, 1.00000, 1.00000, 1.00000, 0.88310, 0.40861, 0.24189, 0.24189, 0.24189, 0.24189, 0.24189, 0.24189, 0.24189, 0.29498, 0.55310, 0.89693, 0.89693, 0.89693, 1.00000, 1.00000, 1.00000]
    @weekend_hourly_occ = @weekday_hourly_occ

  end

  def Occ_lat
    return @occ_lat
  end

  def Occ_rad
    return @occ_rad
  end

  def Occ_lost
    return @occ_lost
  end

  def Occ_conv
    return @occ_conv
  end
  
  def Monthly_mult_occ
    return @monthly_mult_occ
  end

  def Weekday_hourly_occ
    return @weekday_hourly_occ
  end

  def Weekend_hourly_occ
    return @weekend_hourly_occ
  end

end
