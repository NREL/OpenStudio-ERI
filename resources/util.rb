
# Add classes or functions here than can be used across a variety of our python classes and modules.
require "#{File.dirname(__FILE__)}/constants"
require "#{File.dirname(__FILE__)}/unit_conversions"

class HelperMethods
    
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
    
    def self.remove_unused_materials_and_constructions(model, runner)
        # Constructions not used by surfaces or subsurfaces:
        used_constructions = []
        model.getSpaces.each do |space|
            space.surfaces.each do |surface|
                next if not surface.construction.is_initialized
                used_constructions << surface.construction.get
                surface.subSurfaces.each do |subsurface|
                    next if not subsurface.construction.is_initialized
                    used_constructions << subsurface.construction.get
                end
            end
        end
        model.getConstructions.each do |construction|
            if not used_constructions.include? construction
                construction.remove
                runner.registerInfo("Removed construction '#{construction.name}' because it was orphaned.")
            end
        end
        # Materials not used by constructions:
        used_materials = []
        model.getConstructions.each do |construction|
            construction.layers.each do |material|
                used_materials << material
            end
        end
        model.getStandardOpaqueMaterials.each do |material|
            if not used_materials.include? material
                material.remove
                runner.registerInfo("Removed material '#{material.name}' because it was orphaned.")
            end
        end
        model.getMasslessOpaqueMaterials.each do |material|
            if not used_materials.include? material
                material.remove
                runner.registerInfo("Removed material '#{material.name}' because it was orphaned.")
            end
        end
    end

end

class SimpleMaterial

    def initialize(name=nil, rvalue=nil)
        @name = name
        @rvalue = rvalue
    end
    
    attr_accessor :name, :rvalue

    def self.Adiabatic
        return SimpleMaterial.new(name='Adiabatic', rvalue=1000)
    end

end

class GlazingMaterial

    def initialize(name=nil, ufactor=nil, shgc=nil)
        @name = name
        @ufactor = ufactor
        @shgc = shgc
    end
    
    attr_accessor :name, :ufactor, :shgc
end

class Material

    def initialize(name=nil, thick_in=nil, mat_base=nil, cond=nil, dens=nil, sh=nil, tAbs=nil, sAbs=nil, vAbs=nil, rvalue=nil)
        @name = name
        
        if not thick_in.nil?
            @thick_in = thick_in
            @thick = OpenStudio::convert(@thick_in,"in","ft").get
        end
        
        if not mat_base.nil?
            @k = mat_base.k
            @rho = mat_base.rho
            @cp = mat_base.cp
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
    
    attr_accessor :name, :thick, :thick_in, :k, :rho, :cp, :rvalue, :tAbs, :sAbs, :vAbs
    
    def self.AirCavity(thick_in)
        rvalue = Gas.AirGapRvalue
        return Material.new(name=nil, thick_in=thick_in, mat_base=nil, cond=OpenStudio::convert(thick_in,"in","ft").get/rvalue, dens=Gas.Air.rho, sh=Gas.Air.cp)
    end
    
    def self.AirFilmOutside
        rvalue = 0.197 # hr-ft-F/Btu
        return Material.new(name=nil, thick_in=1.0, mat_base=nil, cond=OpenStudio::convert(1.0,"in","ft").get/rvalue)
    end

    def self.AirFilmVertical
        rvalue = 0.68 # hr-ft-F/Btu (ASHRAE 2005, F25.2, Table 1)
        return Material.new(name=nil, thick_in=1.0, mat_base=nil, cond=OpenStudio::convert(1.0,"in","ft").get/rvalue)
    end

    def self.AirFilmFlatEnhanced
        rvalue = 0.61 # hr-ft-F/Btu (ASHRAE 2005, F25.2, Table 1)
        return Material.new(name=nil, thick_in=1.0, mat_base=nil, cond=OpenStudio::convert(1.0,"in","ft").get/rvalue)
    end

    def self.AirFilmFlatReduced
        rvalue = 0.92 # hr-ft-F/Btu (ASHRAE 2005, F25.2, Table 1)
        return Material.new(name=nil, thick_in=1.0, mat_base=nil, cond=OpenStudio::convert(1.0,"in","ft").get/rvalue)
    end

    def self.AirFilmFloorAverage
        # For floors between conditioned spaces where heat does not flow across
        # the floor; heat transfer is only important with regards to the thermal
        rvalue = (Material.AirFilmFlatReduced.rvalue + Material.AirFilmFlatEnhanced.rvalue) / 2.0 # hr-ft-F/Btu
        return Material.new(name=nil, thick_in=1.0, mat_base=nil, cond=OpenStudio::convert(1.0,"in","ft").get/rvalue)
    end

    def self.AirFilmFloorReduced
        # For floors above unconditioned basement spaces, where heat will
        # always flow down through the floor.
        rvalue = Material.AirFilmFlatReduced.rvalue # hr-ft-F/Btu
        return Material.new(name=nil, thick_in=1.0, mat_base=nil, cond=OpenStudio::convert(1.0,"in","ft").get/rvalue)
    end

    def self.AirFilmSlopeEnhanced(highest_roof_pitch)
        # Correlation functions used to interpolate between values provided
        # in ASHRAE 2005, F25.2, Table 1 - which only provides values for
        # 0, 45, and 90 degrees. Values are for non-reflective materials of 
        # emissivity = 0.90.
        rvalue = 0.002 * Math::exp(0.0398 * highest_roof_pitch) + 0.608 # hr-ft-F/Btu (evaluates to film_flat_enhanced at 0 degrees, 0.62 at 45 degrees, and film_vertical at 90 degrees)
        return Material.new(name=nil, thick_in=1.0, mat_base=nil, cond=OpenStudio::convert(1.0,"in","ft").get/rvalue)
    end

    def self.AirFilmSlopeReduced(highest_roof_pitch)
        # Correlation functions used to interpolate between values provided
        # in ASHRAE 2005, F25.2, Table 1 - which only provides values for
        # 0, 45, and 90 degrees. Values are for non-reflective materials of 
        # emissivity = 0.90.
        rvalue = 0.32 * Math::exp(-0.0154 * highest_roof_pitch) + 0.6 # hr-ft-F/Btu (evaluates to film_flat_reduced at 0 degrees, 0.76 at 45 degrees, and film_vertical at 90 degrees)
        return Material.new(name=nil, thick_in=1.0, mat_base=nil, cond=OpenStudio::convert(1.0,"in","ft").get/rvalue)
    end

    def self.AirFilmSlopeEnhancedReflective(highest_roof_pitch)
        # Correlation functions used to interpolate between values provided
        # in ASHRAE 2005, F25.2, Table 1 - which only provides values for
        # 0, 45, and 90 degrees. Values are for reflective materials of 
        # emissivity = 0.05.
        rvalue = 0.00893 * Math::exp(0.0419 * highest_roof_pitch) + 1.311 # hr-ft-F/Btu (evaluates to 1.32 at 0 degrees, 1.37 at 45 degrees, and 1.70 at 90 degrees)
        return Material.new(name=nil, thick_in=1.0, mat_base=nil, cond=OpenStudio::convert(1.0,"in","ft").get/rvalue)
    end

    def self.AirFilmSlopeReducedReflective(highest_roof_pitch)
        # Correlation functions used to interpolate between values provided
        # in ASHRAE 2005, F25.2, Table 1 - which only provides values for
        # 0, 45, and 90 degrees. Values are for reflective materials of 
        # emissivity = 0.05.
        rvalue = 2.999 * Math::exp(-0.0333 * highest_roof_pitch) + 1.551 # hr-ft-F/Btu (evaluates to 4.55 at 0 degrees, 2.22 at 45 degrees, and 1.70 at 90 degrees)
        return Material.new(name=nil, thick_in=1.0, mat_base=nil, cond=OpenStudio::convert(1.0,"in","ft").get/rvalue)
    end

    def self.AirFilmRoof(highest_roof_pitch)
        # Use weighted average between enhanced and reduced convection based on degree days.
        #hdd_frac = hdd65f / (hdd65f + cdd65f)
        #cdd_frac = cdd65f / (hdd65f + cdd65f)
        #return Material.AirFilmSlopeEnhanced(highest_roof_pitch).rvalue * hdd_frac + Material.AirFilmSlopeReduced(highest_roof_pitch).rvalue * cdd_frac # hr-ft-F/Btu
        # Simplification to not depend on weather
        rvalue = (Material.AirFilmSlopeEnhanced(highest_roof_pitch).rvalue + Material.AirFilmSlopeReduced(highest_roof_pitch).rvalue) / 2.0 # hr-ft-F/Btu
        return Material.new(name=nil, thick_in=1.0, mat_base=nil, cond=OpenStudio::convert(1.0,"in","ft").get/rvalue)
    end

    def self.AirFilmRoofRadiantBarrier(highest_roof_pitch)
        # Use weighted average between enhanced and reduced convection based on degree days.
        #hdd_frac = hdd65f / (hdd65f + cdd65f)
        #cdd_frac = cdd65f / (hdd65f + cdd65f)
        #return Material.AirFilmSlopeEnhancedReflective(highest_roof_pitch).rvalue * hdd_frac + Material.AirFilmSlopeReducedReflective(highest_roof_pitch).rvalue * cdd_frac # hr-ft-F/Btu
        # Simplification to not depend on weather
        rvalue = (Material.AirFilmSlopeEnhancedReflective(highest_roof_pitch).rvalue + Material.AirFilmSlopeReducedReflective(highest_roof_pitch).rvalue) / 2.0 # hr-ft-F/Btu
        return Material.new(name=nil, thick_in=1.0, mat_base=nil, cond=OpenStudio::convert(1.0,"in","ft").get/rvalue)
    end

    def self.CarpetBare(carpetFloorFraction=0.8, carpetPadRValue=2.08)
        thickness = 0.5 # in
        return Material.new(name=Constants.MaterialFloorCarpet, thick_in=thickness, mat_base=nil, cond=OpenStudio::convert(thickness,"in","ft").get / (carpetPadRValue * carpetFloorFraction), dens=3.4, sh=0.32, tAbs=0.9, sAbs=0.9)
    end

    def self.Concrete8in
        return Material.new(name='Concrete-8in', thick_in=8, mat_base=BaseMaterial.Concrete, cond=nil, dens=nil, sh=nil, tAbs=0.9)
    end

    def self.Concrete4in
        return Material.new(name='Concrete-4in', thick_in=4, mat_base=BaseMaterial.Concrete, cond=nil, dens=nil, sh=nil, tAbs=0.9)
    end
    
    def self.DefaultCarpet
        return Material.CarpetBare
    end
    
    def self.DefaultCeilingMass
        mat = Material.GypsumWall1_2in
        mat.name = Constants.MaterialCeilingMass
        return mat
    end
    
    def self.DefaultExteriorFinish
        thick_in = 0.375
        return Material.new(name=Constants.MaterialWallExtFinish, thick_in=thick_in, mat_base=nil, cond=OpenStudio::convert(thick_in,"in","ft").get/0.6, dens=11.1, sh=0.25, tAbs=0.9, sAbs=0.3, vAbs=0.3)
    end
    
    def self.DefaultFloorMass
        mat = Material.MassFloor(0.625, 0.8004, 34.0, 0.29) # Wood Surface
        mat.name = Constants.MaterialFloorMass
        return mat
    end
    
    def self.DefaultWallMass
        mat = Material.GypsumWall1_2in
        mat.name = Constants.MaterialWallMass
        return mat
    end
    
    def self.DefaultWallSheathing
        mat = Material.Plywood1_2in
        mat.name = Constants.MaterialWallSheathing
        return mat
    end

    def self.GypsumWall1_2in
        return Material.new(name='WallGypsumBoard-1_2in', thick_in=0.5, mat_base=BaseMaterial.Gypsum, cond=nil, dens=nil, sh=nil, tAbs=0.9, sAbs=Constants.DefaultSolarAbsWall, vAbs=0.1)
    end

    def self.GypsumCeiling1_2in
        return Material.new(name='CeilingGypsumBoard-1_2in', thick_in=0.5, mat_base=BaseMaterial.Gypsum, cond=nil, dens=nil, sh=nil, tAbs=0.9, sAbs=Constants.DefaultSolarAbsCeiling, vAbs=0.1)
    end

    def self.MassFloor(floorMassThickness, floorMassConductivity, floorMassDensity, floorMassSpecificHeat)
        return Material.new(name='FloorMass', thick_in=floorMassThickness, mat_base=nil, cond=OpenStudio::convert(floorMassConductivity,"in","ft").get, dens=floorMassDensity, sh=floorMassSpecificHeat, tAbs=0.9, sAbs=Constants.DefaultSolarAbsFloor)
    end

    def self.MassPartitionWall(partitionWallMassThickness, partitionWallMassConductivity, partitionWallMassDensity, partitionWallMassSpecHeat)
        return Material.new(name='PartitionWallMass', thick_in=partitionWallMassThickness, mat_base=nil, cond=OpenStudio::convert(partitionWallMassConductivity,"in","ft").get, dens=partitionWallMassDensity, sh=partitionWallMassSpecHeat, tAbs=0.9, sAbs=Constants.DefaultSolarAbsWall, vAbs=0.1)
    end

    def self.Soil12in
        return Material.new(name='Soil-12in', thick_in=12, mat_base=BaseMaterial.Soil)
    end

    def self.Stud2x(thick_in)
        return Material.new(name="Stud2x#{thick_in.to_s}", thick_in=thick_in, mat_base=BaseMaterial.Wood)
    end
    
    def self.Stud2x4
        return Material.new(name='Stud2x4', thick_in=3.5, mat_base=BaseMaterial.Wood)
    end

    def self.Stud2x6
        return Material.new(name='Stud2x6', thick_in=5.5, mat_base=BaseMaterial.Wood)
    end

    def self.Plywood1_2in
        return Material.new(name='Plywood-1_2in', thick_in=0.5, mat_base=BaseMaterial.Wood)
    end

    def self.Plywood3_4in
        return Material.new(name='Plywood-3_4in', thick_in=0.75, mat_base=BaseMaterial.Wood)
    end

    def self.Plywood3_2in
        return Material.new(name='Plywood-3_2in', thick_in=1.5, mat_base=BaseMaterial.Wood)
    end

    def self.RadiantBarrier
        return Material.new(name='RadiantBarrier', thick_in=0.00084, mat_base=nil, cond=135.8, dens=168.6, sh=0.22, tAbs=0.05, sAbs=0.05, vAbs=0.05)
    end

    def self.RoofMaterial(roofMatEmissivity, roofMatAbsorptivity)
        return Material.new(name='RoofingMaterial', thick_in=0.375, mat_base=nil, cond=0.094, dens=70, sh=0.35, tAbs=roofMatEmissivity, sAbs=roofMatAbsorptivity, vAbs=roofMatAbsorptivity)
    end

    # TODO: Eventually remove
    def self.StudAndAir
        mat_2x4 = Material.Stud2x4
        u_stud_path = Constants.DefaultFramingFactorInterior / Material.Stud2x4.rvalue
        u_air_path = (1 - Constants.DefaultFramingFactorInterior) / Gas.AirGapRvalue
        stud_and_air_Rvalue = 1 / (u_stud_path + u_air_path)
        mat_stud_and_air_wall = BaseMaterial.new(rho=(mat_2x4.width_in / Constants.DefaultStudSpacing) * mat_2x4.rho + (1 - mat_2x4.width_in / Constants.DefaultStudSpacing) * Gas.Air.cp, cp=((mat_2x4.width_in / Constants.DefaultStudSpacing) * mat_2x4.cp * mat_2x4.rho + (1 - mat_2x4.width_in / Constants.DefaultStudSpacing) * Gas.Air.cp * Gas.Air.cp) / ((mat_2x4.width_in / Constants.DefaultStudSpacing) * mat_2x4.rho + (1 - mat_2x4.width_in / Constants.DefaultStudSpacing) * Gas.Air.cp), k=(mat_2x4.thick / stud_and_air_Rvalue))
        return Material.new(name='StudAndAirWall', thick_in=mat_2x4.thick_in, mat_base=mat_stud_and_air_wall)
    end

end

class Construction

    # Facilitates creating an OpenStudio construction (with accompanying OpenStudio Materials)
    # from Material objects. Handles parallel paths as well.

    def initialize(path_widths, name=nil, type=nil)
        @name = name
        @type = type
        @path_widths = path_widths
        @path_fracs = []
        @sum_path_fracs = @path_widths.inject(:+)
        path_widths.each do |path_width|
            @path_fracs << path_width / path_widths.inject{ |sum, n| sum + n }
        end         
        @layers_materials = []
        @layers_includes = []
        @layers_names = []
        @remove_materials = []
    end
    
    def addlayer(materials, include_in_construction, name=nil)
        # materials: Either a Material object or a list of Material objects
        # include_in_construction: false if an assumed, default layer that should not be included 
        #                          in the resulting construction but is used to calculate the 
        #                          effective R-value.
        # name: Name of the layer; required if multiple materials are provided. Otherwise the 
        #       Material.name will be used.
        if not materials.kind_of?(Array)
            @layers_materials << [materials]
        else
            @layers_materials << materials
        end
        @layers_includes << include_in_construction
        @layers_names << name
    end
    
    def removelayer(name)
        @remove_materials << name
    end
    
    def printlayers(runner)
        @path_fracs.each do |path_frac|
            runner.registerInfo("path_frac: #{path_frac.round(5).to_s}")
        end
        runner.registerInfo("======")
        @layers_materials.each do |layer_materials|
            runner.registerInfo("layer thick: #{layer_materials[0].thick.round(5).to_s}")
            layer_materials.each do |mat|
                runner.registerInfo("layer cond:  #{mat.k.round(5).to_s}")
            end
            runner.registerInfo("------")
        end
    end
    
    def assembly_rvalue(runner)
        # Calculate overall R-value for assembly
        if not validated?(runner)
            return nil
        end
        u_overall = 0
        @path_fracs.each_with_index do |path_frac,path_num|
            # For each parallel path, sum series:
            r_path = 0
            @layers_materials.each do |layer_materials|
                if layer_materials.size == 1
                    # One material for this layer
                    r_path += layer_materials[0].rvalue
                else
                    # Multiple parallel materials for this layer, use appropriate one
                    r_path += layer_materials[path_num].rvalue
                end
            end
            u_overall += 1.0 / r_path * path_frac
        end
        r_overall = 1.0 / u_overall
        return r_overall
    end
    
    # Creates constructions as needed and assigns to surfaces.
    # Leave name as nil if the materials (e.g., exterior finish) apply to multiple constructions.
    def create_and_assign_constructions(surfaces, runner, model, name=nil)
    
        if not validated?(runner)
            return false
        end
        
        # Uncomment the following line to debug
        #printlayers(runner)
        
        # Create materials
        materials = []
        @layers_materials.each_with_index do |layer_materials,layer_num|
            next if not @layers_includes[layer_num]
            if layer_materials.size == 1
                if not @layers_names[layer_num].nil?
                    mat_name = @layers_names[layer_num]
                else
                    mat_name = layer_materials[0].name
                end
                mat = create_os_material(model, runner, layer_materials[0], mat_name)
            else
                parallel_path_mat = get_parallel_material(layer_num, runner)
                mat = create_os_material(model, runner, parallel_path_mat)
            end
            materials << mat
        end
        
        construction_map = {} # Used to create new constructions only for each existing unique construction
        rev_construction_map = {} # Used for adjacent surfaces, which get reverse constructions
        surfaces.each do |surface|
            # Get construction name, if available
            constr_name = nil
            if surface.construction.is_initialized
                constr_name = surface.construction.get.name.to_s
            end

            # Assign construction to surface
            if not construction_map.include? constr_name
                # Create new construction
                if not create_and_assign_construction(surface, materials, runner, model, name)
                    return false
                end
                construction_map[constr_name] = surface.construction.get
                runner.registerInfo("Construction '#{surface.construction.get.name.to_s}' was created.")
            else
                # Re-use recently created construction
                surface.setConstruction(construction_map[constr_name])
            end
            runner.registerInfo("Surface '#{surface.name.to_s}' has been assigned construction '#{surface.construction.get.name.to_s}'.")
            
            # Assign reverse construction to adjacent surface as needed
            next if not surface.adjacentSurface.is_initialized or surface.is_a? OpenStudio::Model::SubSurface
            rev_constr_name = "Rev#{surface.construction.get.name.to_s}"
            adjacent_surface = surface.adjacentSurface.get
            if not rev_construction_map.include? rev_constr_name
                # Create adjacent construction
                num_prev_constructions = model.getConstructions.size
                revconstr = surface.construction.get.to_Construction.get.reverseConstruction
                if model.getConstructions.size != num_prev_constructions
                    # If the reverse construction already found (or the construction has 
                    # only a single layer), we won't get a new construction here.
                    revconstr.setName(rev_constr_name)
                    runner.registerInfo("Construction '#{revconstr.name.to_s}' was created.")
                end
                adjacent_surface.setConstruction(revconstr)
                rev_construction_map[rev_constr_name] = adjacent_surface.construction.get
                if model.getConstructions.size != num_prev_constructions
                
                end
            else
                # Re-use recently created adjacent construction
                adjacent_surface.setConstruction(rev_construction_map[rev_constr_name])
            end
            runner.registerInfo("Surface '#{adjacent_surface.name.to_s}' has been assigned construction '#{adjacent_surface.construction.get.name.to_s}'.")
            
        end
        return true
    end
    
    def self.GetWallGapFactor(installGrade, framingFactor, cavityInsulRvalue)

        if cavityInsulRvalue <= 0
            return 0 # Gap factor only applies when there is cavity insulation
        elsif installGrade == 1
            return 0
        elsif installGrade == 2
            return 0.02 * (1 - framingFactor)
        elsif installGrade == 3
            return 0.05 * (1 - framingFactor)
        else
            return 0
        end

    end

    # FIXME: Eventually remove
    def self.GetFloorNonStudLayerR(floorMassThickness, floorMassConductivity, floorMassDensity, floorMassSpecificHeat, carpetFloorFraction, carpetPadRValue)
        return (2.0 * Material.AirFilmFloorReduced.rvalue + Material.MassFloor(floorMassThickness, floorMassConductivity, floorMassDensity, floorMassSpecificHeat).rvalue + (carpetPadRValue * carpetFloorFraction) + Material.Plywood3_4in.rvalue)
    end
    
    def self.GetBasementConductionFactor(bsmtWallInsulationHeight, bsmtWallInsulRvalue)
        if bsmtWallInsulationHeight == 4
            return (1.689 / (0.430 + bsmtWallInsulRvalue) ** 0.164)
        else
            return (2.494 / (1.673 + bsmtWallInsulRvalue) ** 0.488)
        end
    end
    
    private
    
        def get_parallel_material(curr_layer_num, runner)
            # Returns a Material object with effective properties for the specified
            # parallel path layer of the construction.
        
            mat = Material.new(name=@layers_names[curr_layer_num])
            
            curr_layer_materials = @layers_materials[curr_layer_num]
            
            r_overall = assembly_rvalue(runner)
            
            # Calculate individual R-values for each layer
            # Also calculate sum of R-values for individual parallel path layers
            sum_r_parallels = 0
            layer_rvalues = []
            @layers_materials.each do |layer_materials|
                r_path = 0
                layer_materials.each do |layer_material|
                    r_path += layer_material.thick / layer_material.k
                end
                layer_rvalues << r_path
                if layer_materials.size > 1
                    sum_r_parallels += r_path
                end
            end
            
            # Subtract out series layers to calculate R-value across all parallel 
            # path layers
            r_parallel = r_overall
            @layers_materials.each_with_index do |layer_materials,layer_num|
                if layer_materials.size == 1
                    r_parallel -= layer_rvalues[layer_num]
                end
            end
            
            # Material R-value
            # Apportion R-value to the current parallel path layer
            mat.rvalue = layer_rvalues[curr_layer_num] / sum_r_parallels * r_parallel
            
            # Material thickness and conductivity
            mat.thick_in = curr_layer_materials[0].thick_in # All paths have equal thickness
            mat.thick = curr_layer_materials[0].thick # All paths have equal thickness
            mat.k = mat.thick / mat.rvalue
            
            # Material density
            mat.rho = 0
            @path_fracs.each_with_index do |path_frac,path_num|
                mat.rho += curr_layer_materials[path_num].rho * path_frac
            end
            
            # Material specific heat
            mat.cp = 0
            @path_fracs.each_with_index do |path_frac,path_num|
                mat.cp += (curr_layer_materials[path_num].cp * curr_layer_materials[path_num].rho * path_frac) / mat.rho
            end
            
            return mat
        end

        def validated?(runner)
            # Check that sum of path fracs equal 1
            if @sum_path_fracs <= 0.99 or @sum_path_fracs >= 1.01
                runner.registerError("Invalid construction: Sum of path fractions (#{@sum_path_fracs.to_s}) is not 1.")
                return false
            end
            
            # Check that all path fractions are not negative
            @path_fracs.each do |path_frac|
                if path_frac < 0
                    runner.registerError("Invalid construction: Path fraction (#{path_frac.to_s}) must be greater than or equal to 0.")
                    return false
                end
            end
            
            # Check if all materials are GlazingMaterial
            all_glazing = true
            @layers_materials.each do |layer_materials|
                layer_materials.each do |mat|
                    if not mat.is_a? GlazingMaterial
                        all_glazing = false
                    end
                end
            end
            if all_glazing
                # Check that no parallel materials
                @layers_materials.each do |layer_materials|
                    if layer_materials.size > 1
                        runner.registerError("Invalid construction: Cannot have multiple GlazingMaterials in a single layer.")
                        return false
                    end
                end
                return true
            end
        
            # Check for valid object types
            @layers_materials.each do |layer_materials|
                layer_materials.each do |mat|
                    if not mat.is_a? SimpleMaterial and not mat.is_a? Material
                        runner.registerError("Invalid construction: Materials must be instances of SimpleMaterial or Material classes.")
                        return false
                    end
                end
            end
            
            # Check if invalid number of materials in a layer
            @layers_materials.each do |layer_materials|
                if layer_materials.size > 1 and layer_materials.size < @path_fracs.size
                    runner.registerError("Invalid construction: Layer must either have one material or same number of materials as paths.")
                    return false
                end
            end
        
            # Check if multiple materials in a given layer have differing thicknesses
            @layers_materials.each do |layer_materials|
                if layer_materials.size > 1
                    thick_in = nil
                    layer_materials.each do |mat|
                        if thick_in.nil?
                            thick_in = mat.thick_in
                        elsif thick_in != mat.thick_in
                            runner.registerError("Invalid construction: Materials in a layer have different thicknesses.")
                            return false
                        end
                    end
                end
            end
            
            # Check if multiple non-contiguous parallel layers
            found_parallel = false
            last_parallel = false
            @layers_materials.each do |layer_materials|
                if layer_materials.size > 1
                    if not found_parallel
                        found_parallel = true
                    elsif not last_parallel
                        runner.registerError("Invalid construction: Non-contiguous parallel layers found.")
                        return false
                    end
                end
                last_parallel = (layer_materials.size > 1)
            end
            
            # Check if name not provided for a parallel layer
            # Check if name not provided for non-parallel layer
            @layers_materials.each_with_index do |layer_materials,layer_num|
                next if not @layers_includes[layer_num]
                if layer_materials.size > 1
                    if @layers_names[layer_num].nil?
                        runner.registerError("Invalid construction: No layer name provided for parallel layer.")
                        return false
                    end
                else
                    if @layers_names[layer_num].nil? and layer_materials[0].name.nil?
                        runner.registerError("Invalid construction: Neither layer name nor material name provided for non-parallel layer.")
                        return false
                    end
                end
            end
            
            # If we got this far, we're good
            return true
        end
        
        # Returns a boolean denoting whether the execution was successful
        def create_and_assign_construction(surface, materials, runner, model, name)
        
            if (not surface.construction.is_initialized or not surface.construction.get.to_LayeredConstruction.is_initialized) or materials[0].is_a? GlazingMaterial
                # Assign new construction and return true
                constr = OpenStudio::Model::Construction.new(materials)
                if not name.nil?
                    constr.setName(name)
                end
                surface.setConstruction(constr)
                return true
            end
            
            # Otherwise, clone construction and assign material layers as appropriate
            constr = surface.construction.get.clone(model).to_LayeredConstruction.get
            if not name.nil?
                constr.setName(name)
            end
            materials.each do |material|
                assign_material(constr, surface, material, runner, model)
            end
            @remove_materials.each do |material_name|
                remove_material(constr, material_name)
            end
            surface.setConstruction(constr)
            return true
        end
        
        def assign_material(constr, surface, material, runner, model)
            num_layers = constr.numLayers
            
            # Note: The only way to determine types of layers (exterior finish, etc.) is by name.
            # Defines the target layer positions for the materials when the construction is complete.
            # Position 0 is outside most layer.
            if surface.surfaceType.downcase == "wall"
                target_positions_std = {Constants.MaterialWallExtFinish => 0,
                                        Constants.MaterialWallRigidIns => 1,
                                        Constants.MaterialWallSheathing => 2, 
                                        Constants.MaterialWallMass => num_layers,
                                        Constants.MaterialWallMass2 => num_layers+1}
                target_position_non_std = target_positions_std[Constants.MaterialWallSheathing] + 1
            elsif surface.surfaceType.downcase == "floor"
                target_positions_std = {Constants.MaterialCeilingMass => 0,
                                        Constants.MaterialCeilingMass2 => 1,
                                        Constants.MaterialFloorMass => num_layers,
                                        Constants.MaterialFloorCarpet => num_layers+1}
                target_position_non_std = target_positions_std[Constants.MaterialCeilingMass2] + 1
            elsif surface.surfaceType.downcase == "roofceiling"
                
            end

            # Determine current positions of any standard materials
            std_mat_positions = target_positions_std.clone
            std_mat_positions.each { |k, v| std_mat_positions[k] = nil } #re-init
            constr.layers.each_with_index do |layer, index|
                std_mat_positions.keys.each do |layer_name|
                    if layer.name.to_s.start_with? layer_name
                        std_mat_positions[layer_name] = index
                    end
                end
            end

            # Is the current material a standard material?
            standard_mat = nil
            target_positions_std.keys.each do |std_mat|
                if material.name.to_s.start_with? std_mat
                    standard_mat = std_mat
                end
            end

            if standard_mat.nil?
                # Remove any layers other than standard materials
                constr.layers.reverse.each_with_index do |layer, index|
                    layer_index = num_layers - 1 - index
                    if not std_mat_positions.values.include? layer_index
                        constr.eraseLayer(layer_index)
                    end
                end
            end
            
            if not standard_mat.nil? and not std_mat_positions[standard_mat].nil?
                # Standard layer already exists, replace it
                constr.setLayer(std_mat_positions[standard_mat], material)
            else
                # Add at appropriate position
                if standard_mat.nil?
                    final_pos = target_position_non_std
                else
                    final_pos = target_positions_std[standard_mat]
                end
                insert_pos = 0
                for pos in (final_pos-1).downto(0)
                    mat = target_positions_std.key(pos)
                    next if not std_mat_positions.key? mat
                    if not std_mat_positions[mat].nil?
                        insert_pos = pos + 1
                        break
                    end
                end
                if insert_pos > constr.numLayers
                    insert_pos = constr.numLayers
                end
                constr.insertLayer(insert_pos, material)
            end

        end

        def remove_material(constr, material_name)
            # Remove layer if it matches this name
            num_layers = constr.numLayers
            constr.layers.reverse.each_with_index do |layer, index|
                layer_index = num_layers - 1 - index
                if layer.name.to_s.start_with? material_name
                    constr.eraseLayer(layer_index)
                end
            end
        end
        
        # Creates an OpenStudio Material from our own Material object
        def create_os_material(model, runner, material, name=nil)
            if name.nil?
                name = material.name
            end
            if material.is_a? SimpleMaterial
                mat = OpenStudio::Model::MasslessOpaqueMaterial.new(model)
                mat.setName(name)
                mat.setRoughness("Rough")
                mat.setThermalResistance(OpenStudio::convert(material.rvalue,"hr*ft^2*R/Btu","m^2*K/W").get)
            elsif material.is_a? GlazingMaterial
                mat = OpenStudio::Model::SimpleGlazing.new(model)
                mat.setName(name)
                mat.setUFactor(material.ufactor)
                mat.setSolarHeatGainCoefficient(material.shgc)
            else
                mat = OpenStudio::Model::StandardOpaqueMaterial.new(model)
                mat.setName(name)
                mat.setRoughness("Rough")
                mat.setThickness(OpenStudio::convert(material.thick_in,"in","m").get)
                mat.setConductivity(OpenStudio::convert(material.k,"Btu/hr*ft*R","W/m*K").get)
                mat.setDensity(OpenStudio::convert(material.rho,"lb/ft^3","kg/m^3").get)
                mat.setSpecificHeat(OpenStudio::convert(material.cp,"Btu/lb*R","J/kg*K").get)
                if not material.tAbs.nil?
                    mat.setThermalAbsorptance(material.tAbs)
                end
                if not material.sAbs.nil?
                    mat.setSolarAbsorptance(material.sAbs)
                end
                if not material.vAbs.nil?
                    mat.setVisibleAbsorptance(material.vAbs)
                end
            end
            runner.registerInfo("Material '#{mat.name.to_s}' was created.")
            return mat
        end

end

class BaseMaterial
    def initialize(rho, cp, k)
        @rho = rho
        @cp = cp
        @k = k
    end
    
    attr_accessor :rho, :cp, :k

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
    
    attr_accessor :rho, :cp, :k, :mu, :h_fg, :t_frz, :t_boil, :t_crit

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
    
    attr_accessor :rho, :cp, :k, :mu, :m, :r
  
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