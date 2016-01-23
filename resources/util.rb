
# Add classes or functions here than can be used across a variety of our python classes and modules.
require "#{File.dirname(__FILE__)}/constants"
require "#{File.dirname(__FILE__)}/unit_conversions"

class HelperMethods

    # Retrieves the number of bedrooms and bathrooms from the space type
    # They are assigned in the SetResidentialBedroomsAndBathrooms measure.
    def self.get_bedrooms_bathrooms(model, runner=nil)
        nbeds = nil
        nbaths = nil
        model.getSpaces.each do |space|
            space_equipments = space.electricEquipment
            space_equipments.each do |space_equipment|
                name = space_equipment.electricEquipmentDefinition.name.get.to_s
                br_regexpr = /(?<br>\d+\.\d+)\s+Bedrooms/.match(name)
                ba_regexpr = /(?<ba>\d+\.\d+)\s+Bathrooms/.match(name)	
                if br_regexpr
                    nbeds = br_regexpr[:br].to_f
                elsif ba_regexpr
                    nbaths = ba_regexpr[:ba].to_f
                end
            end
        end
        if nbeds.nil? or nbaths.nil?
            if not runner.nil?
                runner.registerError("Could not determine number of bedrooms or bathrooms. Run the 'Add Residential Bedrooms And Bathrooms' measure first.")
            end
        end
        return [nbeds, nbaths]
    end
	
    def self.get_bedrooms_bathrooms_from_idf(workspace, runner=nil)
        nbeds = nil
        nbaths = nil
		electricEquipments = workspace.getObjectsByType("ElectricEquipment".to_IddObjectType)
        electricEquipments.each do |electricEquipment|
			zone_list_name = electricEquipment.getString(1).to_s
			zone_lists = workspace.getObjectsByType("ZoneList".to_IddObjectType)
			zone_lists.each do |zone_list|
				if zone_list.getString(0).to_s == zone_list_name
					zone = zone_list.getString(1).to_s
                    br_regexpr = /(?<br>\d+\.\d+)\s+Bedrooms/.match(electricEquipment.getString(0).to_s)
                    ba_regexpr = /(?<ba>\d+\.\d+)\s+Bathrooms/.match(electricEquipment.getString(0).to_s)	
                    if br_regexpr
                        nbeds = br_regexpr[:br].to_f
                    elsif ba_regexpr
                        nbaths = ba_regexpr[:ba].to_f
                    end
				end
			end
        end
        if nbeds.nil? or nbaths.nil?
            if not runner.nil?
                runner.registerError("Could not determine number of bedrooms or bathrooms. Run the 'Add Residential Bedrooms And Bathrooms' measure first.")
            end
        end
        return [nbeds, nbaths]
    end	
    
	# Removes the number of bedrooms and bathrooms in the model
    def self.remove_bedrooms_bathrooms(model)
        model.getSpaces.each do |space|
            space_equipments = space.electricEquipment
            space_equipments.each do |space_equipment|
                name = space_equipment.electricEquipmentDefinition.name.get.to_s
                br_regexpr = /(?<br>\d+\.\d+)\s+Bedrooms/.match(name)
                ba_regexpr = /(?<ba>\d+\.\d+)\s+Bathrooms/.match(name)	
                if br_regexpr
                    space_equipment.electricEquipmentDefinition.remove
                elsif ba_regexpr
                    space_equipment.electricEquipmentDefinition.remove
                end
            end
        end
    end	
	
    # Retrieves the floor area of the specified space type
    def self.get_floor_area_for_space_type(model, spacetype_handle)
        floor_area = 0
        model.getSpaceTypes.each do |spaceType|
            if spaceType.handle.to_s == spacetype_handle.to_s
                floor_area = OpenStudio.convert(spaceType.floorArea,"m^2","ft^2").get
            end
        end
        return floor_area
    end
    
    # Retrieves the conditioned floor area for the building
    def self.get_building_conditioned_floor_area(model, runner=nil)
        floor_area = 0
        model.getThermalZones.each do |zone|
            if self.zone_is_conditioned(zone)
                runner.registerWarning(zone.name.to_s)
                floor_area += OpenStudio.convert(zone.floorArea,"m^2","ft^2").get
            end
        end
        if floor_area == 0 and not runner.nil?
            runner.registerError("Could not find any conditioned floor area. Please assign HVAC equipment first.")
            return nil
        end
        return floor_area
    end
    
    def self.zone_is_conditioned(zone)
        # FIXME: Ugly hack until we can get conditioned floor area from OS
        if zone.name.to_s == Constants.LivingZone or zone.name.to_s == Constants.FinishedBasementZone
            return true
        end
        return false
    end
    
    def self.get_default_space(model, runner=nil)
        space = nil
        model.getSpaces.each do |s|
            if s.name.to_s == Constants.LivingSpace(1) # Try to return our living space
                return s
            elsif space.nil? # Return first space in list if our living space not found
                space = s
            end
        end
        if space.nil? and not runner.nil?
            runner.registerError("Could not find any spaces in the model.")
        end
        return space
    end
    
    def self.get_space_type_from_string(model, spacetype_s, runner, print_err=true)
        space_type = nil
        model.getSpaceTypes.each do |st|
            if st.name.to_s == spacetype_s
                space_type = st
                break
            end
        end
        if space_type.nil?
            if print_err
                runner.registerError("Could not find space type with the name '#{spacetype_s}'.")
            else
                runner.registerWarning("Could not find space type with the name '#{spacetype_s}'.")
            end
        end
        return space_type
    end
	
    def self.get_space_from_string(model, space_s, runner, print_err=true)
        space = nil
        model.getSpaces.each do |s|
            if s.name.to_s == space_s
                space = s
                break
            end
        end
        if space.nil?
            if print_err
                runner.registerError("Could not find space with the name '#{space_s}'.")
            else
                runner.registerWarning("Could not find space with the name '#{space_s}'.")
            end
        end
        return space
    end

    def self.get_thermal_zone_from_string(model, thermalzone_s, runner, print_err=true)
        thermal_zone = nil
        model.getThermalZones.each do |tz|
            if tz.name.to_s == thermalzone_s
                thermal_zone = tz
                break
            end
        end
        if thermal_zone.nil?
            if print_err
                runner.registerError("Could not find thermal zone with the name '#{thermalzone_s}'.")
            else
                runner.registerWarning("Could not find thermal zone with the name '#{thermalzone_s}'.")
            end
        end
        return thermal_zone
    end

    def self.get_thermal_zone_from_string_from_idf(workspace, thermalzone_s, runner, print_err=true)
        thermal_zone = nil
        workspace.getObjectsByType("Zone".to_IddObjectType).each do |tz|
            if tz.getString(0).to_s == thermalzone_s
                thermal_zone = tz
                break
            end
        end
        if thermal_zone.nil?
            if print_err
                runner.registerError("Could not find thermal zone with the name '#{thermalzone_s}'.")
            else
                runner.registerWarning("Could not find thermal zone with the name '#{thermalzone_s}'.")
            end
        end
        return thermal_zone
    end		
    
	def self.get_space_type_from_surface(model, surface_s, print_err=true)
		space_type_r = nil
		model.getSpaces.each do |space|
			space.surfaces.each do |s|
				if s.name.to_s == surface_s
					space_type_r = space.spaceType.get.name.to_s
					break
				end
			end
		end
        if space_type_r.nil?
            if print_err
                runner.registerError("Could not find surface with the name '#{surface_s}'.")
            else
                runner.registerWarning("Could not find surface with the name '#{surface_s}'.")
            end
        end		
		return space_type_r
	end
    
    def self.remove_object_from_idf_based_on_name(workspace, name_s, object_s, runner=nil)
      workspace.getObjectsByType(object_s.to_IddObjectType).each do |str|
        n = str.getString(0).to_s
        name_s.each do |name|
		  if n.include? name
		    str.remove
		    unless runner.nil?
			  runner.registerInfo("Removed object '#{object_s} - #{n}'")
		    end
			break
		  end
		end
      end
      return workspace
    end
	
    def self.get_plant_loop_from_string(model, plantloop_s, runner, print_err=true)
        plant_loop = nil
        model.getPlantLoops.each do |pl|
            if pl.name.to_s == plantloop_s
                plant_loop = pl
                break
            end
        end
        if plant_loop.nil?
            if print_err
                runner.registerError("Could not find plant loop with the name '#{plantloop_s}'.")
            else
                runner.registerWarning("Could not find plant loop with the name '#{plantloop_s}'.")
            end
        end
        return plant_loop
    end
    
    def self.get_water_heater_setpoint(model, plant_loop, runner)
        waterHeater = nil
        plant_loop.supplyComponents.each do |wh|
            if wh.to_WaterHeaterMixed.is_initialized
                waterHeater = wh.to_WaterHeaterMixed.get
            elsif wh.to_WaterHeaterStratified.is_initialized
                waterHeater = wh.to_WaterHeaterStratified.get
            else
                next
            end
            if waterHeater.setpointTemperatureSchedule.nil?
                runner.registerError("Water heater found without a setpoint temperature schedule.")
                return nil
            end
        end
        if waterHeater.nil?
            runner.registerError("No water heater found; add a residential water heater first.")
            return nil
        end
        min_max_result = Schedule.getMinMaxAnnualProfileValue(model, waterHeater.setpointTemperatureSchedule.get)
        wh_setpoint = OpenStudio.convert((min_max_result['min'] + min_max_result['max'])/2.0, "C", "F").get
        if min_max_result['min'] != min_max_result['max']
            runner.registerWarning("Water heater setpoint is not constant. Using average setpoint temperature of #{wh_setpoint.round} F.")
        end
        return wh_setpoint
    end

end

class Material

    def initialize(name=nil, type=nil, thick=nil, thick_in=nil, width=nil, width_in=nil, mat_base=nil, cond=nil, dens=nil, sh=nil, tAbs=nil, sAbs=nil, vAbs=nil, rvalue=nil)
        @name = name
        @type = type
        
        if !thick.nil?
            @thick = thick
            @thick_in = OpenStudio::convert(@thick,"ft","in").get
        elsif !thick_in.nil?
            @thick_in = thick_in
            @thick = OpenStudio::convert(@thick_in,"in","ft").get
        end
        
        if not width.nil?
            @width = width
            @width_in = OpenStudio::convert(@width,"ft","in").get
        elsif not width_in.nil?
            @width_in = thick_in
            @width = OpenStudio::convert(@width_in,"in","ft").get
        end
        
        if not mat_base.nil?
            @k = mat_base.k
            @rho = mat_base.rho
            @cp = mat_base.Cp
        else
            @k = nil
            @rho = nil
            @cp = nil
        end
        # override the base material if both are included
        if not cond.nil?
            @k = cond
        end
        if not dens.nil?
            @rho = dens
        end
        if not sh.nil?
            @cp = sh
        end
        @tAbs = tAbs
        @sAbs = sAbs
        @vAbs = vAbs
        if not rvalue.nil?
            @rvalue = rvalue
        elsif not @thick.nil? and not @k.nil?
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

    def self.CarpetBare(carpetFloorFraction, carpetPadRValue)
        thickness = 0.5 # in
        return Material.new(name=Constants.MaterialCarpetBareLayer, type=Constants.MaterialTypeProperties, thick=nil, thick_in=thickness, width=nil, width_in=nil, mat_base=nil, cond=OpenStudio::convert(thickness,"in","ft").get / (carpetPadRValue * carpetFloorFraction), dens=3.4, sh=0.32, tAbs=0.9, sAbs=0.9)
    end

    def self.Concrete8in
        return Material.new(name=Constants.MaterialConcrete8in, type=Constants.MaterialTypeProperties, thick=nil, thick_in=8, width=nil, width_in=nil, mat_base=BaseMaterial.Concrete, cond=nil, dens=nil, sh=nil, tAbs=0.9)
    end

    def self.Concrete4in
        return Material.new(name=Constants.MaterialConcrete8in, type=Constants.MaterialTypeProperties, thick=nil, thick_in=4, width=nil, width_in=nil, mat_base=BaseMaterial.Concrete, cond=nil, dens=nil, sh=nil, tAbs=0.9)
    end

    def self.Gypsum1_2in
        return Material.new(name=Constants.MaterialGypsumBoard1_2in, type=Constants.MaterialTypeProperties, thick=nil, thick_in=0.5, width=nil, width_in=nil, mat_base=BaseMaterial.Gypsum, cond=nil, dens=nil, sh=nil, tAbs=0.9, sAbs=Constants.DefaultSolarAbsWall, vAbs=0.1)
    end

    def self.GypsumExtWall
        return Material.new(name=Constants.MaterialGypsumBoard1_2in, type=Constants.MaterialTypeProperties, thick=nil, thick_in=0.5, width=nil, width_in=nil, mat_base=BaseMaterial.Gypsum, cond=nil, dens=nil, sh=nil, tAbs=0.9, sAbs=Constants.DefaultSolarAbsWall, vAbs=0.1)
    end

    def self.GypsumCeiling
        return Material.new(name=Constants.MaterialGypsumBoard1_2in, type=Constants.MaterialTypeProperties, thick=nil, thick_in=0.5, width=nil, width_in=nil, mat_base=BaseMaterial.Gypsum, cond=nil, dens=nil, sh=nil, tAbs=0.9, sAbs=Constants.DefaultSolarAbsCeiling, vAbs=0.1)
    end

    def self.MassFloor(floorMassThickness, floorMassConductivity, floorMassDensity, floorMassSpecificHeat)
        return Material.new(name=Constants.MaterialFloorMass, type=Constants.MaterialTypeProperties, thick=nil, thick_in=floorMassThickness, width=nil, width_in=nil, mat_base=nil, cond=OpenStudio::convert(floorMassConductivity,"in","ft").get, dens=floorMassDensity, sh=floorMassSpecificHeat, tAbs=0.9, sAbs=Constants.DefaultSolarAbsFloor)
    end

    def self.MassPartitionWall(partitionWallMassThickness, partitionWallMassConductivity, partitionWallMassDensity, partitionWallMassSpecHeat)
        return Material.new(name=Constants.MaterialPartitionWallMass, type=Constants.MaterialTypeProperties, thick=nil, thick_in=partitionWallMassThickness, width=nil, width_in=nil, mat_base=nil, cond=OpenStudio::convert(partitionWallMassConductivity,"in","ft").get, dens=partitionWallMassDensity, sh=partitionWallMassSpecHeat, tAbs=0.9, sAbs=Constants.DefaultSolarAbsWall, vAbs=0.1)
    end

    def self.Soil12in
        return Material.new(name=Constants.MaterialSoil12in, type=Constants.MaterialTypeProperties, thick=nil, thick_in=12, width=nil, width_in=nil, mat_base=BaseMaterial.Soil)
    end

    def self.Stud2x(thickness)
        return Material.new(name=Constants.Material2x, type=Constants.MaterialTypeProperties, thick=nil, thick_in=thickness, width=nil, width_in=1.5, mat_base=BaseMaterial.Wood)
    end
    
    def self.Stud2x4
        return Material.new(name=Constants.Material2x4, type=Constants.MaterialTypeProperties, thick=nil, thick_in=3.5, width=nil, width_in=1.5, mat_base=BaseMaterial.Wood)
    end

    def self.Stud2x6
        return Material.new(name=Constants.Material2x6, type=Constants.MaterialTypeProperties, thick=nil, thick_in=5.5, width=nil, width_in=1.5, mat_base=BaseMaterial.Wood)
    end

    def self.Plywood1_2in
        return Material.new(name=Constants.MaterialPlywood1_2in, type=Constants.MaterialTypeProperties, thick=nil, thick_in=0.5, width=nil, width_in=nil, mat_base=BaseMaterial.Wood)
    end

    def self.Plywood3_4in
        return Material.new(name=Constants.MaterialPlywood3_4in, type=Constants.MaterialTypeProperties, thick=nil, thick_in=0.75, width=nil, width_in=nil, mat_base=BaseMaterial.Wood)
    end

    def self.Plywood3_2in
        return Material.new(name=Constants.MaterialPlywood3_2in, type=Constants.MaterialTypeProperties, thick=nil, thick_in=1.5, width=nil, width_in=nil, mat_base=BaseMaterial.Wood)
    end

    def self.RadiantBarrier
        return Material.new(name=Constants.MaterialRadiantBarrier, type=Constants.MaterialTypeProperties, thick=0.0007, thick_in=nil, width=nil, width_in=nil, mat_base=nil, cond=135.8, dens=168.6, sh=0.22, tAbs=0.05, sAbs=0.05, vAbs=0.05)
    end

    def self.RoofMaterial(roofMatEmissivity, roofMatAbsorptivity)
        return Material.new(name=Constants.MaterialRoofingMaterial, type=Constants.MaterialTypeProperties, thick=0.031, thick_in=nil, width=nil, width_in=nil, mat_base=nil, cond=0.094, dens=70, sh=0.35, tAbs=roofMatEmissivity, sAbs=roofMatAbsorptivity, vAbs=roofMatAbsorptivity)
    end

    def self.StudAndAir
        mat_2x4 = Material.Stud2x4
        u_stud_path = Constants.DefaultFramingFactorInterior / Material.Stud2x4.Rvalue
        u_air_path = (1 - Constants.DefaultFramingFactorInterior) / Gas.AirGapRvalue
        stud_and_air_Rvalue = 1 / (u_stud_path + u_air_path)
        mat_stud_and_air_wall = BaseMaterial.new(rho=(mat_2x4.width_in / Constants.DefaultStudSpacing) * mat_2x4.rho + (1 - mat_2x4.width_in / Constants.DefaultStudSpacing) * Gas.Air.Cp, cp=((mat_2x4.width_in / Constants.DefaultStudSpacing) * mat_2x4.Cp * mat_2x4.rho + (1 - mat_2x4.width_in / Constants.DefaultStudSpacing) * Gas.Air.Cp * Gas.Air.Cp) / ((mat_2x4.width_in / Constants.DefaultStudSpacing) * mat_2x4.rho + (1 - mat_2x4.width_in / Constants.DefaultStudSpacing) * Gas.Air.Cp), k=(mat_2x4.thick / stud_and_air_Rvalue))
        return Material.new(name=Constants.MaterialStudandAirWall, type=Constants.MaterialTypeProperties, thick=mat_2x4.thick, thick_in=nil, width=nil, width_in=nil, mat_base=mat_stud_and_air_wall)
    end

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

    def self.GetWallGapFactor(installGrade, framingFactor)

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

    def self.GetWoodStudWallAssemblyR(wallCavityInsFillsCavity, wallCavityInsRvalueInstalled, 
                                      wallInstallGrade, wallCavityDepth, wallFramingFactor, 
                                      prefix, gypsumThickness, gypsumNumLayers, finishThickness, 
                                      finishConductivty, rigidInsThickness, rigidInsRvalue, hasOSB)

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

        mat_wood = BaseMaterial.Wood

        # Add air gap when insulation thickness < cavity depth
        if not wallCavityInsFillsCavity
            wallCavityInsRvalueInstalled += Gas.AirGapRvalue
        end

        gapFactor = Construction.GetWallGapFactor(wallInstallGrade, wallFramingFactor)

        path_fracs = [wallFramingFactor, 1 - wallFramingFactor - gapFactor, gapFactor]
        wood_stud_wall = Construction.new(path_fracs)

        # Interior Film
        wood_stud_wall.addlayer(thickness=OpenStudio::convert(1.0,"in","ft").get, conductivity_list=[OpenStudio::convert(1.0,"in","ft").get / AirFilms.VerticalR])

        # Interior Finish (GWB) - Currently only include if cavity depth > 0
        if wallCavityDepth > 0
            wood_stud_wall.addlayer(thickness=OpenStudio::convert(gypsumThickness,"in","ft").get * gypsumNumLayers, conductivity_list=[BaseMaterial.Gypsum.k])
        end

        # Only if cavity depth > 0, indicating a framed wall
        if wallCavityDepth > 0
            # Stud / Cavity Ins / Gap
            ins_k = OpenStudio::convert(wallCavityDepth,"in","ft").get / wallCavityInsRvalueInstalled
            gap_k = OpenStudio::convert(wallCavityDepth,"in","ft").get / Gas.AirGapRvalue
            wood_stud_wall.addlayer(thickness=OpenStudio::convert(wallCavityDepth,"in","ft").get, conductivity_list=[mat_wood.k,ins_k,gap_k])       
        end

        # OSB sheathing
        if hasOSB
            wood_stud_wall.addlayer(thickness=nil, conductivity_list=nil, material=Material.Plywood1_2in, material_list=nil)
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
            wood_stud_wall.addlayer(thickness=OpenStudio::convert(1.0,"in","ft").get, conductivity_list=[OpenStudio::convert(1.0,"in","ft").get / AirFilms.OutsideR])
        end

        # Get overall wall R-value using parallel paths:
        return wood_stud_wall.Rvalue_parallel

    end

    def self.GetFloorNonStudLayerR(floorMassThickness, floorMassConductivity, floorMassDensity, floorMassSpecificHeat, carpetFloorFraction, carpetPadRValue)
        return (2.0 * AirFilms.FloorReducedR + Material.MassFloor(floorMassThickness, floorMassConductivity, floorMassDensity, floorMassSpecificHeat).Rvalue + (carpetPadRValue * carpetFloorFraction) + Material.Plywood3_4in.Rvalue)
    end
    
    def self.GetRimJoistAssmeblyR(rimJoistInsRvalue, ceilingJoistHeight, wallSheathingContInsThickness, wallSheathingContInsRvalue, drywallThickness, drywallNumLayers, rimjoist_framingfactor, finishThickness, finishConductivity)
        # Returns assembly R-value for crawlspace or unfinished/finished basement rimjoist, including air films.
        
        framingFactor = rimjoist_framingfactor
        
        mat_wood = BaseMaterial.Wood
        mat_2x = Material.Stud2x(ceilingJoistHeight)
        
        path_fracs = [framingFactor, 1 - framingFactor]
        
        prefix_rimjoist = Construction.new(path_fracs)
        
        # Interior Film 
        prefix_rimjoist.addlayer(thickness=OpenStudio::convert(1.0,"in","ft").get, conductivity_list=[OpenStudio::convert(1.0,"in","ft").get / AirFilms.FloorReducedR])

        # Stud/cavity layer
        if rimJoistInsRvalue == 0
            cavity_k = (mat_2x.thick / air.R_air_gap)
        else
            cavity_k = (mat_2x.thick / rimJoistInsRvalue)
        end
            
        prefix_rimjoist.addlayer(thickness=mat_2x.thick, conductivity_list=[mat_wood.k, cavity_k])
        
        # Rim Joist wood layer
        prefix_rimjoist.addlayer(thickness=nil, conductivity_list=nil, material=Material.Plywood3_2in, material_list=nil)
        
        # Wall Sheathing
        if wallSheathingContInsRvalue > 0
            wallsh_k = (wallSheathingContInsThickness / wallSheathingContInsRvalue)
            prefix_rimjoist.addlayer(thickness=OpenStudio::convert(wallSheathingContInsThickness,"in","ft").get, conductivity_list=[wallsh_k])
        end
        prefix_rimjoist.addlayer(thickness=OpenStudio::convert(finishThickness,"in","ft").get, conductivity_list=[finishConductivity])
        
        # Exterior Film
        prefix_rimjoist.addlayer(thickness=OpenStudio::convert(1.0,"in","ft").get, conductivity_list=[OpenStudio::convert(1,"in","ft").get / AirFilms.FloorReducedR])
        
        return prefix_rimjoist.Rvalue_parallel

    end 
    
    def self.GetRimJoistNonStudLayerR
        return (AirFilms.VerticalR + AirFilms.OutsideR + Material.Plywood3_2in.Rvalue)
    end
    
    def self.GetBasementConductionFactor(bsmtWallInsulationHeight, bsmtWallInsulRvalue)
        if bsmtWallInsulationHeight == 4
            return (1.689 / (0.430 + bsmtWallInsulRvalue) ** 0.164)
        else
            return (2.494 / (1.673 + bsmtWallInsulRvalue) ** 0.488)
        end
    end

    
end

class BaseMaterial
	def initialize(rho, cp, k)
		@rho = rho
		@cp = cp
		@k = k
	end
		
	def rho
		return @rho
	end
	
	def Cp
		return @cp
	end
	
	def k
		return @k
	end

    def self.Gypsum
        return BaseMaterial.new(rho=50.0, cp=0.2, k=0.0926)
    end

    def self.Wood
        return BaseMaterial.new(rho=32.0, cp=0.29, k=0.0667)
    end
    
    def self.Concrete
        return BaseMaterial.new(rho=140.0, cp=0.2, k=0.7576)
    end

    def self.Gypcrete
        # http://www.maxxon.com/gyp-crete/data
        return BaseMaterial.new(rho=100.0, cp=0.223, k=0.3952)
    end

    def self.InsulationRigid
        return BaseMaterial.new(rho=2.0, cp=0.29, k=0.017)
    end
    
    def self.InsulationCelluloseDensepack
        return BaseMaterial.new(rho=3.5, cp=0.25, k=nil)
    end

    def self.InsulationCelluloseLoosefill
        return BaseMaterial.new(rho=1.5, cp=0.25, k=nil)
    end

    def self.InsulationFiberglassDensepack
        return BaseMaterial.new(rho=2.2, cp=0.25, k=nil)
    end

    def self.InsulationFiberglassLoosefill
        return BaseMaterial.new(rho=0.5, cp=0.25, k=nil)
    end

    def self.InsulationGenericDensepack
        return BaseMaterial.new(rho=(BaseMaterial.InsulationFiberglassDensepack.rho + BaseMaterial.InsulationCelluloseDensepack.rho) / 2.0, cp=0.25, k=nil)
    end

    def self.InsulationGenericLoosefill
        return BaseMaterial.new(rho=(BaseMaterial.InsulationFiberglassLoosefill.rho + BaseMaterial.InsulationCelluloseLoosefill.rho) / 2.0, cp=0.25, k=nil)
    end

    def self.Soil
        return BaseMaterial.new(rho=115.0, cp=0.1, k=1)
    end

end

class Liquid
    def initialize(rho, cp, k, mu, h_fg, t_frz, t_boil, t_crit)
        @rho    = rho       # Density (lb/ft3)
        @cp     = cp        # Specific Heat (Btu/lbm-R)
        @k      = k         # Thermal Conductivity (Btu/h-ft-R)
        @mu     = mu        # Dynamic Viscosity (lbm/ft-h)
        @h_fg   = h_fg      # Latent Heat of Vaporization (Btu/lbm)
        @t_frz  = t_frz     # Freezing Temperature (degF)
        @t_boil = t_boil    # Boiling Temperature (degF)
        @t_crit = t_crit    # Critical Temperature (degF)
    end

    def rho
        return @rho
    end

    def Cp
        return @cp
    end

    def k
        return @k
    end

    def mu
        return @mu
    end

    def H_fg
        return @h_fg
    end

    def T_frz
        return @t_frz
    end

    def T_boil
        return @t_boil
    end

    def T_crit
        return @t_crit
    end
  
    def self.H2O_l
        # From EES at STP
        return Liquid.new(62.32,0.9991,0.3386,2.424,1055,32.0,212.0,nil)
    end

    def self.R22_l
        # Converted from EnthDR22 f77 in ResAC (Brandemuehl)
        return Liquid.new(nil,0.2732,nil,nil,100.5,nil,-41.35,204.9)
    end
  
end

class Gas
    def initialize(rho, cp, k, mu, m)
        @rho    = rho           # Density (lb/ft3)
        @cp     = cp            # Specific Heat (Btu/lbm-R)
        @k      = k             # Thermal Conductivity (Btu/h-ft-R)
        @mu     = mu            # Dynamic Viscosity (lbm/ft-h)
        @m      = m             # Molecular Weight (lbm/lbmol)
        if @m
            gas_constant = 1.9858 # Gas Constant (Btu/lbmol-R)
            @r  = gas_constant / m # Gas Constant (Btu/lbm-R)
        else
            @r = nil
        end
    end

    def rho
        return @rho
    end

    def Cp
        return @cp
    end

    def k
        return @k
    end

    def mu
        return @mu
    end

    def M
        return @m
    end

    def R
        return @r
    end
  
    def self.Air
        # From EES at STP
        return Gas.new(0.07518,0.2399,0.01452,0.04415,28.97)
    end
    
    def self.AirGapRvalue
        return 1.0 # hr*ft*F/Btu (Assume for all air gap configurations since there is no correction for direction of heat flow in the simulation tools)
    end

    def self.H2O_v
        # From EES at STP
        return Gas.new(nil,0.4495,nil,nil,18.02)
    end
    
    def self.R22_v
        # Converted from EnthDR22 f77 in ResAC (Brandemuehl)
        return Gas.new(nil,0.1697,nil,nil,nil)
    end

    def self.PsychMassRat
        return Gas.H2O_v.M / Gas.Air.M
    end
end

class AirFilms

    def self.OutsideR
        return 0.197 # hr-ft-F/Btu
    end
  
    def self.VerticalR
        return 0.68 # hr-ft-F/Btu (ASHRAE 2005, F25.2, Table 1)
    end
  
    def self.FlatEnhancedR
        return 0.61 # hr-ft-F/Btu (ASHRAE 2005, F25.2, Table 1)
    end
  
    def self.FlatReducedR
        return 0.92 # hr-ft-F/Btu (ASHRAE 2005, F25.2, Table 1)
    end
  
    def self.FloorAverageR
        # For floors between conditioned spaces where heat does not flow across
        # the floor; heat transfer is only important with regards to the thermal
        return (AirFilms.FlatReducedR + AirFilms.FlatEnhancedR) / 2.0 # hr-ft-F/Btu
    end

    def self.FloorReducedR
        # For floors above unconditioned basement spaces, where heat will
        # always flow down through the floor.
        return AirFilms.FlatReducedR # hr-ft-F/Btu
    end
  
    def self.SlopeEnhancedR(highest_roof_pitch)
        # Correlation functions used to interpolate between values provided
        # in ASHRAE 2005, F25.2, Table 1 - which only provides values for
        # 0, 45, and 90 degrees. Values are for non-reflective materials of 
        # emissivity = 0.90.
        return 0.002 * Math::exp(0.0398 * highest_roof_pitch) + 0.608 # hr-ft-F/Btu (evaluates to film_flat_enhanced at 0 degrees, 0.62 at 45 degrees, and film_vertical at 90 degrees)
    end
  
    def self.SlopeReducedR(highest_roof_pitch)
        # Correlation functions used to interpolate between values provided
        # in ASHRAE 2005, F25.2, Table 1 - which only provides values for
        # 0, 45, and 90 degrees. Values are for non-reflective materials of 
        # emissivity = 0.90.
        return 0.32 * Math::exp(-0.0154 * highest_roof_pitch) + 0.6 # hr-ft-F/Btu (evaluates to film_flat_reduced at 0 degrees, 0.76 at 45 degrees, and film_vertical at 90 degrees)
    end
  
    def self.SlopeEnhancedReflectiveR(highest_roof_pitch)
        # Correlation functions used to interpolate between values provided
        # in ASHRAE 2005, F25.2, Table 1 - which only provides values for
        # 0, 45, and 90 degrees. Values are for reflective materials of 
        # emissivity = 0.05.
        return 0.00893 * Math::exp(0.0419 * highest_roof_pitch) + 1.311 # hr-ft-F/Btu (evaluates to 1.32 at 0 degrees, 1.37 at 45 degrees, and 1.70 at 90 degrees)
    end
  
    def self.SlopeReducedReflectiveR(highest_roof_pitch)
        # Correlation functions used to interpolate between values provided
        # in ASHRAE 2005, F25.2, Table 1 - which only provides values for
        # 0, 45, and 90 degrees. Values are for reflective materials of 
        # emissivity = 0.05.
        return 2.999 * Math::exp(-0.0333 * highest_roof_pitch) + 1.551 # hr-ft-F/Btu (evaluates to 4.55 at 0 degrees, 2.22 at 45 degrees, and 1.70 at 90 degrees)
    end
  
    def self.RoofR(highest_roof_pitch)
        # Use weighted average between enhanced and reduced convection based on degree days.
        #hdd_frac = hdd65f / (hdd65f + cdd65f)
        #cdd_frac = cdd65f / (hdd65f + cdd65f)
        #return AirFilms.SlopeEnhancedR(highest_roof_pitch) * hdd_frac + AirFilms.SlopeReducedR(highest_roof_pitch) * cdd_frac # hr-ft-F/Btu
        # Simplification to not depend on weather
        return (AirFilms.SlopeEnhancedR(highest_roof_pitch) + AirFilms.SlopeReducedR(highest_roof_pitch)) / 2.0 # hr-ft-F/Btu
    end
  
    def self.RoofRadiantBarrierR(highest_roof_pitch)
        # Use weighted average between enhanced and reduced convection based on degree days.
        #hdd_frac = hdd65f / (hdd65f + cdd65f)
        #cdd_frac = cdd65f / (hdd65f + cdd65f)
        #return AirFilms.SlopeEnhancedReflectiveR(highest_roof_pitch) * hdd_frac + AirFilms.SlopeReducedReflectiveR(highest_roof_pitch) * cdd_frac # hr-ft-F/Btu
        # Simplification to not depend on weather
        return (AirFilms.SlopeEnhancedReflectiveR(highest_roof_pitch) + AirFilms.SlopeReducedReflectiveR(highest_roof_pitch)) / 2.0 # hr-ft-F/Btu
    end
    
end

class EnergyGuideLabel

    def self.get_energy_guide_gas_cost(date)
        # Search for, e.g., "Representative Average Unit Costs of Energy for Five Residential Energy Sources (1996)"
        if date <= 1991
            # http://books.google.com/books?id=GsY5AAAAIAAJ&pg=PA184&lpg=PA184&dq=%22Representative+Average+Unit+Costs+of+Energy+for+Five+Residential+Energy+Sources%22+1991&source=bl&ots=QuQ83OQ1Wd&sig=jEsENidBQCtDnHkqpXGE3VYoLEg&hl=en&sa=X&ei=3QOjT-y4IJCo8QSsgIHVCg&ved=0CDAQ6AEwBA#v=onepage&q=%22Representative%20Average%20Unit%20Costs%20of%20Energy%20for%20Five%20Residential%20Energy%20Sources%22%201991&f=false
            return 60.54
        elsif date == 1992
            # http://books.google.com/books?id=esk5AAAAIAAJ&pg=PA193&lpg=PA193&dq=%22Representative+Average+Unit+Costs+of+Energy+for+Five+Residential+Energy+Sources%22+1992&source=bl&ots=tiUb_2hZ7O&sig=xG2k0WRDwVNauPhoXEQOAbCF80w&hl=en&sa=X&ei=owOjT7aOMoic9gTw6P3vCA&ved=0CDIQ6AEwAw#v=onepage&q=%22Representative%20Average%20Unit%20Costs%20of%20Energy%20for%20Five%20Residential%20Energy%20Sources%22%201992&f=false
            return 58.0
        elsif date == 1993
            # No data, use prev/next years
            return (58.0 + 60.40)/2.0
        elsif date == 1994
            # http://govpulse.us/entries/1994/02/08/94-2823/rule-concerning-disclosures-of-energy-consumption-and-water-use-information-about-certain-home-appli
            return 60.40
        elsif date == 1995
            # http://www.ftc.gov/os/fedreg/1995/february/950217appliancelabelingrule.pdf
            return 63.0
        elsif date == 1996
            # http://www.gpo.gov/fdsys/pkg/FR-1996-01-19/pdf/96-574.pdf
            return 62.6
        elsif date == 1997
            # http://www.ftc.gov/os/fedreg/1997/february/970205ruleconcerningdisclosures.pdf
            return 61.2
        elsif date == 1998
            # http://www.gpo.gov/fdsys/pkg/FR-1997-12-08/html/97-32046.htm
            return 61.9
        elsif date == 1999
            # http://www.gpo.gov/fdsys/pkg/FR-1999-01-05/html/99-89.htm
            return 68.8
        elsif date == 2000
            # http://www.gpo.gov/fdsys/pkg/FR-2000-02-07/html/00-2707.htm
            return 68.8
        elsif date == 2001
            # http://www.gpo.gov/fdsys/pkg/FR-2001-03-08/html/01-5668.htm
            return 83.7
        elsif date == 2002
            # http://govpulse.us/entries/2002/06/07/02-14333/rule-concerning-disclosures-regarding-energy-consumption-and-water-use-of-certain-home-appliances-an#id963086
            return 65.6
        elsif date == 2003
            # http://www.gpo.gov/fdsys/pkg/FR-2003-04-09/html/03-8634.htm
            return 81.6
        elsif date == 2004
            # http://www.ftc.gov/os/fedreg/2004/april/040430ruleconcerningdisclosures.pdf
            return 91.0
        elsif date == 2005
            # http://www1.eere.energy.gov/buildings/appliance_standards/pdfs/2005_costs.pdf
            return 109.2
        elsif date == 2006
            # http://www1.eere.energy.gov/buildings/appliance_standards/pdfs/2006_energy_costs.pdf
            return 141.5
        elsif date == 2007
            # http://www1.eere.energy.gov/buildings/appliance_standards/pdfs/price_notice_032707.pdf
            return 121.8
        elsif date == 2008
            # http://www1.eere.energy.gov/buildings/appliance_standards/pdfs/2008_forecast.pdf
            return 132.8
        elsif date == 2009
            # http://www1.eere.energy.gov/buildings/appliance_standards/commercial/pdfs/ee_rep_avg_unit_costs.pdf
            return 111.2
        elsif date == 2010
            # http://www.gpo.gov/fdsys/pkg/FR-2010-03-18/html/2010-5936.htm
            return 119.4
        elsif date == 2011
            # http://www1.eere.energy.gov/buildings/appliance_standards/pdfs/2011_average_representative_unit_costs_of_energy.pdf
            return 110.1
        elsif date == 2012
            # http://www.gpo.gov/fdsys/pkg/FR-2012-04-26/pdf/2012-10058.pdf
            return 105.9
        elsif date == 2013
            # http://www.gpo.gov/fdsys/pkg/FR-2013-03-22/pdf/2013-06618.pdf
            return 108.7
        elsif date == 2014
            # http://www.gpo.gov/fdsys/pkg/FR-2014-03-18/pdf/2014-05949.pdf
            return 112.8
        elsif date >= 2015
            # http://www.gpo.gov/fdsys/pkg/FR-2015-08-27/pdf/2015-21243.pdf
            return 100.3
        end
    end
  
    def self.get_energy_guide_elec_cost(date)
        # Search for, e.g., "Representative Average Unit Costs of Energy for Five Residential Energy Sources (1996)"
        if date <= 1991
            # http://books.google.com/books?id=GsY5AAAAIAAJ&pg=PA184&lpg=PA184&dq=%22Representative+Average+Unit+Costs+of+Energy+for+Five+Residential+Energy+Sources%22+1991&source=bl&ots=QuQ83OQ1Wd&sig=jEsENidBQCtDnHkqpXGE3VYoLEg&hl=en&sa=X&ei=3QOjT-y4IJCo8QSsgIHVCg&ved=0CDAQ6AEwBA#v=onepage&q=%22Representative%20Average%20Unit%20Costs%20of%20Energy%20for%20Five%20Residential%20Energy%20Sources%22%201991&f=false
            return 8.24
        elsif date == 1992
            # http://books.google.com/books?id=esk5AAAAIAAJ&pg=PA193&lpg=PA193&dq=%22Representative+Average+Unit+Costs+of+Energy+for+Five+Residential+Energy+Sources%22+1992&source=bl&ots=tiUb_2hZ7O&sig=xG2k0WRDwVNauPhoXEQOAbCF80w&hl=en&sa=X&ei=owOjT7aOMoic9gTw6P3vCA&ved=0CDIQ6AEwAw#v=onepage&q=%22Representative%20Average%20Unit%20Costs%20of%20Energy%20for%20Five%20Residential%20Energy%20Sources%22%201992&f=false
            return 8.25
        elsif date == 1993
            # No data, use prev/next years
            return (8.25 + 8.41)/2.0
        elsif date == 1994
            # http://govpulse.us/entries/1994/02/08/94-2823/rule-concerning-disclosures-of-energy-consumption-and-water-use-information-about-certain-home-appli
            return 8.41
        elsif date == 1995
            # http://www.ftc.gov/os/fedreg/1995/february/950217appliancelabelingrule.pdf
            return 8.67
        elsif date == 1996
            # http://www.gpo.gov/fdsys/pkg/FR-1996-01-19/pdf/96-574.pdf
            return 8.60
        elsif date == 1997
            # http://www.ftc.gov/os/fedreg/1997/february/970205ruleconcerningdisclosures.pdf
            return 8.31
        elsif date == 1998
            # http://www.gpo.gov/fdsys/pkg/FR-1997-12-08/html/97-32046.htm
            return 8.42
        elsif date == 1999
            # http://www.gpo.gov/fdsys/pkg/FR-1999-01-05/html/99-89.htm
            return 8.22
        elsif date == 2000
            # http://www.gpo.gov/fdsys/pkg/FR-2000-02-07/html/00-2707.htm
            return 8.03
        elsif date == 2001
            # http://www.gpo.gov/fdsys/pkg/FR-2001-03-08/html/01-5668.htm
            return 8.29
        elsif date == 2002
            # http://govpulse.us/entries/2002/06/07/02-14333/rule-concerning-disclosures-regarding-energy-consumption-and-water-use-of-certain-home-appliances-an#id963086 
            return 8.28
        elsif date == 2003
            # http://www.gpo.gov/fdsys/pkg/FR-2003-04-09/html/03-8634.htm
            return 8.41
        elsif date == 2004
            # http://www.ftc.gov/os/fedreg/2004/april/040430ruleconcerningdisclosures.pdf
            return 8.60
        elsif date == 2005
            # http://www1.eere.energy.gov/buildings/appliance_standards/pdfs/2005_costs.pdf
            return 9.06
        elsif date == 2006
            # http://www1.eere.energy.gov/buildings/appliance_standards/pdfs/2006_energy_costs.pdf
            return 9.91
        elsif date == 2007
            # http://www1.eere.energy.gov/buildings/appliance_standards/pdfs/price_notice_032707.pdf
            return 10.65
        elsif date == 2008
            # http://www1.eere.energy.gov/buildings/appliance_standards/pdfs/2008_forecast.pdf
            return 10.80
        elsif date == 2009
            # http://www1.eere.energy.gov/buildings/appliance_standards/commercial/pdfs/ee_rep_avg_unit_costs.pdf
            return 11.40
        elsif date == 2010
            # http://www.gpo.gov/fdsys/pkg/FR-2010-03-18/html/2010-5936.htm
            return 11.50
        elsif date == 2011
            # http://www1.eere.energy.gov/buildings/appliance_standards/pdfs/2011_average_representative_unit_costs_of_energy.pdf
            return 11.65
        elsif date == 2012
            # http://www.gpo.gov/fdsys/pkg/FR-2012-04-26/pdf/2012-10058.pdf
            return 11.84
        elsif date == 2013
            # http://www.gpo.gov/fdsys/pkg/FR-2013-03-22/pdf/2013-06618.pdf
            return 12.10
        elsif date == 2014
            # http://www.gpo.gov/fdsys/pkg/FR-2014-03-18/pdf/2014-05949.pdf
            return 12.40
        elsif date >= 2015
            # http://www.gpo.gov/fdsys/pkg/FR-2015-08-27/pdf/2015-21243.pdf
            return 12.70
        end
    end
  
end