# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

# start the measure
class CreateBasicGeometry < OpenStudio::Ruleset::ModelUserScript

  # human readable name
  def name
    return "Create Residential Geometry"
  end

  # human readable description
  def description
    return ""
  end

  # human readable description of modeling approach
  def modeler_description
    return ""
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make an argument for total living space floor area
    total_bldg_area = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("total_bldg_area",true)
    total_bldg_area.setDisplayName("Living Space Area")
	total_bldg_area.setUnits("ft^2")
	total_bldg_area.setDescription("The total area of the living space above grade.")
    total_bldg_area.setDefaultValue(2000.0)
    args << total_bldg_area
	
    #make an argument for living space height
    living_height = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("living_height",true)
    living_height.setDisplayName("Living Space Wall Height (Per Floor)")
	living_height.setUnits("ft")
	living_height.setDescription("The height of the living space walls.")
    living_height.setDefaultValue(8.0)
    args << living_height	
	
    #make an argument for number of floors
    num_floors = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("num_floors",true)
    num_floors.setDisplayName("Num Floors")
	num_floors.setUnits("#")
	num_floors.setDescription("The number of living space floors above grade.")
    num_floors.setDefaultValue(2)
    args << num_floors
	
    #make an argument for aspect ratio
    aspect_ratio = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("aspect_ratio",true)
    aspect_ratio.setDisplayName("Aspect Ratio")
	aspect_ratio.setUnits("NS/EW")
	aspect_ratio.setDescription("The ratio of the north/south wall length to the east/west wall length")
    aspect_ratio.setDefaultValue(2.0)
    args << aspect_ratio
	
	#make a double argument for garage area
	garage_area = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("garage_area", true)
	garage_area.setDisplayName("Garage Area")
	garage_area.setUnits("ft^2")
	garage_area.setDescription("The total area of the garage.")
    garage_area.setDefaultValue(400.0)
	args << garage_area
	
	#make a double argument for garage height
	garage_height = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("garage_height", true)
	garage_height.setDisplayName("Garage Height")
	garage_height.setUnits("ft")
	garage_height.setDescription("The height of the garage walls.")
    garage_height.setDefaultValue(8.0)
	args << garage_height	
	
	#make a choice argument for model objects
	garage_pos_display_names = OpenStudio::StringVector.new
	garage_pos_display_names << "Right"
	garage_pos_display_names << "Left"
	garage_pos_display_names << "Front"
	
	#make a choice argument for garage position
	garage_pos = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("garage_pos", garage_pos_display_names, true)
	garage_pos.setDisplayName("Garage Position")
	garage_pos.setDescription("The position of the garage.")
    garage_pos.setDefaultValue("Right")
	args << garage_pos

	#make a double argument for garage protrusion
	garage_protrusion = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("garage_protrusion", true)
	garage_protrusion.setDisplayName("Garage Protrusion")
	garage_protrusion.setUnits("%")
	garage_protrusion.setDescription("The percentage that the garage protrudes from the living space.")
    garage_protrusion.setDefaultValue(100.0)
	args << garage_protrusion		
	
	#make a choice argument for model objects
	foundation_display_names = OpenStudio::StringVector.new
	foundation_display_names << "slab"
	foundation_display_names << "crawlspace"
	foundation_display_names << "unfinished_basement"
	foundation_display_names << "finished_basement"
	foundation_display_names << "pier_and_beam"
	
	#make a choice argument for foundation type
	foundation_type = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("foundation_type", foundation_display_names, true)
	foundation_type.setDisplayName("Foundation Type")
	foundation_type.setDescription("The foundation type of the building.")
    foundation_type.setDefaultValue("slab")
	args << foundation_type

    #make an argument for foundation height
    foundation_height = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("foundation_height",true)
    foundation_height.setDisplayName("Foundation Height")
	foundation_height.setUnits("ft")
	foundation_height.setDescription("The height of the foundation walls.")
    foundation_height.setDefaultValue(0.0)
    args << foundation_height
	
	#make a choice argument for model objects
	attic_type_display_names = OpenStudio::StringVector.new
	attic_type_display_names << "unfinished_attic"
	# attic_type_display_names << "finished_attic"
	
	#make a choice argument for roof type
	attic_type = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("attic_type", attic_type_display_names, true)
	attic_type.setDisplayName("Attic Type")
	attic_type.setDescription("The attic type of the building.")
    attic_type.setDefaultValue("unfinished_attic")
	args << attic_type	
	
	#make a choice argument for model objects
	roof_type_display_names = OpenStudio::StringVector.new
	roof_type_display_names << "Gable"
	# roof_type_display_names << "Hip"
	
	#make a choice argument for roof type
	roof_type = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("roof_type", roof_type_display_names, true)
	roof_type.setDisplayName("Roof Type")
	roof_type.setDescription("The roof type of the building.")
    roof_type.setDefaultValue("Gable")
	args << roof_type
	
	#make a choice argument for model objects
	roof_pitch_display_names = OpenStudio::StringVector.new
	roof_pitch_display_names << "1:12"
	roof_pitch_display_names << "2:12"
	roof_pitch_display_names << "3:12"
	roof_pitch_display_names << "4:12"
	roof_pitch_display_names << "5:12"
	roof_pitch_display_names << "6:12"
	roof_pitch_display_names << "7:12"
	roof_pitch_display_names << "8:12"
	roof_pitch_display_names << "9:12"
	roof_pitch_display_names << "10:12"
	roof_pitch_display_names << "11:12"
	roof_pitch_display_names << "12:12"
	
	#make a choice argument for roof pitch
	roof_pitch = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("roof_pitch", roof_pitch_display_names, true)
	roof_pitch.setDisplayName("Roof Pitch")
	roof_pitch.setDescription("The roof pitch of the unfinished attic.")
    roof_pitch.setDefaultValue("6:12")
	args << roof_pitch
		
    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

	total_bldg_area = OpenStudio.convert(runner.getDoubleArgumentValue("total_bldg_area",user_arguments),"ft^2","m^2").get
	living_height = OpenStudio.convert(runner.getDoubleArgumentValue("living_height",user_arguments),"ft","m").get
	num_floors = runner.getIntegerArgumentValue("num_floors",user_arguments)
	aspect_ratio = runner.getDoubleArgumentValue("aspect_ratio",user_arguments)
	garage_area = OpenStudio.convert(runner.getDoubleArgumentValue("garage_area",user_arguments),"ft^2","m^2").get
	garage_height = OpenStudio::convert(runner.getDoubleArgumentValue("garage_height",user_arguments),"ft","m").get
	garage_pos = runner.getStringArgumentValue("garage_pos",user_arguments)
	garage_protrusion = runner.getDoubleArgumentValue("garage_protrusion",user_arguments)
	foundation_type = runner.getStringArgumentValue("foundation_type",user_arguments)
	foundation_height = OpenStudio.convert(runner.getDoubleArgumentValue("foundation_height",user_arguments),"ft","m").get
	attic_type = runner.getStringArgumentValue("attic_type",user_arguments)
	roof_type = runner.getStringArgumentValue("roof_type",user_arguments)
	roof_pitch = {"1:12"=>1.0/12.0, "2:12"=>2.0/12.0, "3:12"=>3.0/12.0, "4:12"=>4.0/12.0, "5:12"=>5.0/12.0, "6:12"=>6.0/12.0, "7:12"=>7.0/12.0, "8:12"=>8.0/12.0, "9:12"=>9.0/12.0, "10:12"=>10.0/12.0, "11:12"=>11.0/12.0, "12:12"=>12.0/12.0}[runner.getStringArgumentValue("roof_pitch",user_arguments)]

	# calculate the footprint of the building
    footprint = total_bldg_area / num_floors
	
	# calculate the dimensions of the building
	width = Math.sqrt(footprint / aspect_ratio)
    length = footprint / width
	
	# starting spaces
    starting_spaces = model.getSpaces
    runner.registerInitialCondition("The building started with #{starting_spaces.size} spaces.")

	# create living spacetype
	living_spacetype = OpenStudio::Model::SpaceType.new(model)
	living_spacetype.setName("living_spacetype")
	
	# create living zone
	living_zone = OpenStudio::Model::ThermalZone.new(model)
	living_zone.setName("living")
	
    # loop through the number of floors
    for floor in (0..num_floors-1)
	
		z = living_height * floor

		# Create a new story within the building
		story = OpenStudio::Model::BuildingStory.new(model)
		story.setNominalFloortoFloorHeight(living_height)
		story.setName("Story #{floor+1}")

		# make points
		nw_point = OpenStudio::Point3d.new(0,width,z)
		ne_point = OpenStudio::Point3d.new(length,width,z)
		se_point = OpenStudio::Point3d.new(length,0,z)
		sw_point = OpenStudio::Point3d.new(0,0,z)

		# make polygons
        living_polygon = OpenStudio::Point3dVector.new
        living_polygon << sw_point
        living_polygon << nw_point
        living_polygon << ne_point
        living_polygon << se_point
		
		# make space
        living_space = OpenStudio::Model::Space::fromFloorPrint(living_polygon, living_height, model)
        living_space = living_space.get
        living_space.setBuildingStory(story)
		living_space_name = "living_floor_#{floor+1}"
        living_space.setName(living_space_name)
		runner.registerInfo("Set #{living_space_name}.")
		
		# set these to the living zone
		living_space.setThermalZone(living_zone)
		
		# set these to the living spacetype
		living_space.setSpaceType(living_spacetype)

		# TODO: front door
		# Door
		# if floor==0
			# spaces = model.getSpaces
			# spaces.each do |space|
				# if space.spaceType.get.name.to_s == "living"
					# surfaces = space.surfaces
					# surfaces.each do |surface|
						# surface_type = surface.surfaceType
						# if surface_type=="Wall"
							
						# end
					# end
				# end
			# end		
		# end
		
		# TODO: is there a surface between living floors and is it Adiabatic instead of Surface?
		# Adiabatic floors
		# if floor==1

		# end
		# TODO: foundation walls to Outdoors with rim joist constructions
		
		if garage_area > 0 and floor==0
			
			# create living spacetype
			garage_spacetype = OpenStudio::Model::SpaceType.new(model)
			garage_spacetype.setName("garage_spacetype")
			
			# create garage zone
			garage_zone = OpenStudio::Model::ThermalZone.new(model)
			garage_zone.setName("garage")		
			
			# calculate the dimensions of the garage
			garage_width = Math.sqrt(garage_area / 1.0)
			garage_length = garage_area / garage_width
			garage_attic_height = (garage_width / 2.0) * roof_pitch
			
			# make points and polygons
			if garage_pos == "Right"
				garage_nwl_point = OpenStudio::Point3d.new(length,width,z)
				garage_nel_point = OpenStudio::Point3d.new(length+garage_length,width,z)
				garage_sel_point = OpenStudio::Point3d.new(length+garage_length,width-garage_width,z)
				garage_swl_point = OpenStudio::Point3d.new(length,width-garage_width,z)
				garage_nwu_point = OpenStudio::Point3d.new(length,width,garage_height)
				garage_neu_point = OpenStudio::Point3d.new(length+garage_length,width,garage_height)
				garage_seu_point = OpenStudio::Point3d.new(length+garage_length,width-garage_width,garage_height)
				garage_swu_point = OpenStudio::Point3d.new(length,width-garage_width,garage_height)
				garageroof_w_point = OpenStudio::Point3d.new(length,width-garage_width/2.0,garage_height+garage_attic_height)
				garageroof_e_point = OpenStudio::Point3d.new(length+garage_length,width-garage_width/2.0,garage_height+garage_attic_height)		
				door_wl_point = OpenStudio::Point3d.new(length+0.5,width-garage_width,0)
				door_wu_point = OpenStudio::Point3d.new(length+0.5,width-garage_width,2.1336)
				door_eu_point = OpenStudio::Point3d.new(length+garage_length-0.5,width-garage_width,2.1336)
				door_el_point = OpenStudio::Point3d.new(length+garage_length-0.5,width-garage_width,0)
				
				polygon_su = OpenStudio::Point3dVector.new
				polygon_su << garage_seu_point
				polygon_su << garageroof_e_point
				polygon_su << garageroof_w_point
				polygon_su << garage_swu_point
				
				polygon_nu = OpenStudio::Point3dVector.new	
				polygon_nu << garage_neu_point
				polygon_nu << garage_nwu_point
				polygon_nu << garageroof_w_point
				polygon_nu << garageroof_e_point
				
				polygon_wu = OpenStudio::Point3dVector.new
				polygon_wu << garage_nwu_point
				polygon_wu << garage_swu_point
				polygon_wu << garageroof_w_point
				
				polygon_eu = OpenStudio::Point3dVector.new
				polygon_eu << garage_neu_point
				polygon_eu << garageroof_e_point
				polygon_eu << garage_seu_point				
			elsif garage_pos == "Left"
				garage_nwl_point = OpenStudio::Point3d.new(-garage_length,width,z)
				garage_nel_point = OpenStudio::Point3d.new(0,width,z)
				garage_sel_point = OpenStudio::Point3d.new(0,width-garage_width,z)
				garage_swl_point = OpenStudio::Point3d.new(-garage_length,width-garage_width,z)
				garage_nwu_point = OpenStudio::Point3d.new(-garage_length,width,garage_height)
				garage_neu_point = OpenStudio::Point3d.new(0,width,garage_height)
				garage_seu_point = OpenStudio::Point3d.new(0,width-garage_width,garage_height)
				garage_swu_point = OpenStudio::Point3d.new(-garage_length,width-garage_width,garage_height)
				garageroof_w_point = OpenStudio::Point3d.new(-garage_length,width-garage_width/2.0,garage_height+garage_attic_height)
				garageroof_e_point = OpenStudio::Point3d.new(0,width-garage_width/2.0,garage_height+garage_attic_height)		
				door_wl_point = OpenStudio::Point3d.new(-garage_length+0.5,width-garage_width,0)
				door_wu_point = OpenStudio::Point3d.new(-garage_length+0.5,width-garage_width,2.1336)
				door_eu_point = OpenStudio::Point3d.new(-0.5,width-garage_width,2.1336)
				door_el_point = OpenStudio::Point3d.new(-0.5,width-garage_width,0)

				polygon_su = OpenStudio::Point3dVector.new
				polygon_su << garage_seu_point
				polygon_su << garageroof_e_point
				polygon_su << garageroof_w_point
				polygon_su << garage_swu_point
				
				polygon_nu = OpenStudio::Point3dVector.new	
				polygon_nu << garage_neu_point
				polygon_nu << garage_nwu_point
				polygon_nu << garageroof_w_point
				polygon_nu << garageroof_e_point
				
				polygon_wu = OpenStudio::Point3dVector.new
				polygon_wu << garage_nwu_point
				polygon_wu << garage_swu_point
				polygon_wu << garageroof_w_point
				
				polygon_eu = OpenStudio::Point3dVector.new
				polygon_eu << garage_neu_point
				polygon_eu << garageroof_e_point
				polygon_eu << garage_seu_point				
			elsif garage_pos == "Front"
				garage_nel_point = OpenStudio::Point3d.new(length,0,z)
				garage_sel_point = OpenStudio::Point3d.new(length,-garage_width,z)
				garage_swl_point = OpenStudio::Point3d.new(length-garage_length,-garage_width,z)
				garage_nwl_point = OpenStudio::Point3d.new(length-garage_length,0,z)
				garage_neu_point = OpenStudio::Point3d.new(length,0,garage_height)
				garage_seu_point = OpenStudio::Point3d.new(length,-garage_width,garage_height)
				garage_swu_point = OpenStudio::Point3d.new(length-garage_length,-garage_width,garage_height)
				garage_nwu_point = OpenStudio::Point3d.new(length-garage_length,0,garage_height)
				garageroof_n_point = OpenStudio::Point3d.new(length-garage_length/2.0,0,garage_height+garage_attic_height)
				garageroof_s_point = OpenStudio::Point3d.new(length-garage_length/2.0,-garage_width,garage_height+garage_attic_height)
				door_wl_point = OpenStudio::Point3d.new(length+0.5-garage_length,-garage_width,0)
				door_wu_point = OpenStudio::Point3d.new(length+0.5-garage_length,-garage_width,2.1336)
				door_eu_point = OpenStudio::Point3d.new(length-0.5,-garage_width,2.1336)
				door_el_point = OpenStudio::Point3d.new(length-0.5,-garage_width,0)
				
				polygon_su = OpenStudio::Point3dVector.new
				polygon_su << garage_seu_point
				polygon_su << garageroof_s_point
				polygon_su << garage_swu_point
				
				polygon_nu = OpenStudio::Point3dVector.new	
				polygon_nu << garage_neu_point
				polygon_nu << garage_nwu_point
				polygon_nu << garageroof_n_point
				
				polygon_wu = OpenStudio::Point3dVector.new
				polygon_wu << garage_nwu_point
				polygon_wu << garage_swu_point
				polygon_wu << garageroof_s_point
				polygon_wu << garageroof_n_point
				
				polygon_eu = OpenStudio::Point3dVector.new
				polygon_eu << garage_neu_point
				polygon_eu << garageroof_n_point
				polygon_eu << garageroof_s_point
				polygon_eu << garage_seu_point				
			end
			
			# make polygons
			polygon_g = OpenStudio::Point3dVector.new
			polygon_g << garage_nwl_point
			polygon_g << garage_nel_point
			polygon_g << garage_sel_point
			polygon_g << garage_swl_point

			polygon_w = OpenStudio::Point3dVector.new
			polygon_w << garage_swl_point
			polygon_w << garage_swu_point
			polygon_w << garage_nwu_point
			polygon_w << garage_nwl_point

			polygon_e = OpenStudio::Point3dVector.new
			polygon_e << garage_sel_point
			polygon_e << garage_nel_point
			polygon_e << garage_neu_point
			polygon_e << garage_seu_point

			polygon_s = OpenStudio::Point3dVector.new
			polygon_s << garage_sel_point
			polygon_s << garage_seu_point
			polygon_s << garage_swu_point
			polygon_s << garage_swl_point

			polygon_n = OpenStudio::Point3dVector.new
			polygon_n << garage_nel_point
			polygon_n << garage_nwl_point
			polygon_n << garage_nwu_point
			polygon_n << garage_neu_point
			
			door_polygon = OpenStudio::Point3dVector.new
			door_polygon << door_wl_point
			door_polygon << door_wu_point
			door_polygon << door_eu_point
			door_polygon << door_el_point		
			
			# make surfaces
			surface_g = OpenStudio::Model::Surface.new(polygon_g, model)
			surface_g.setSurfaceType("Floor") 
			surface_g.setOutsideBoundaryCondition("Ground") 
			surface_w = OpenStudio::Model::Surface.new(polygon_w, model)
			surface_w.setSurfaceType("Wall")
			surface_w.setOutsideBoundaryCondition("Outdoors")	
			surface_e = OpenStudio::Model::Surface.new(polygon_e, model)
			surface_e.setSurfaceType("Wall") 
			surface_e.setOutsideBoundaryCondition("Outdoors") 
			surface_s = OpenStudio::Model::Surface.new(polygon_s, model)
			surface_s.setSurfaceType("Wall") 
			surface_s.setOutsideBoundaryCondition("Outdoors")
			surface_n = OpenStudio::Model::Surface.new(polygon_n, model)
			surface_n.setSurfaceType("Wall")
			surface_n.setOutsideBoundaryCondition("Outdoors") 
			surface_su = OpenStudio::Model::Surface.new(polygon_su, model)
			surface_su.setOutsideBoundaryCondition("Outdoors")
			surface_nu = OpenStudio::Model::Surface.new(polygon_nu, model)
			surface_nu.setOutsideBoundaryCondition("Outdoors")		
			surface_wu = OpenStudio::Model::Surface.new(polygon_wu, model)
			surface_wu.setOutsideBoundaryCondition("Outdoors")
			surface_eu = OpenStudio::Model::Surface.new(polygon_eu, model)
			surface_eu.setOutsideBoundaryCondition("Outdoors")
			if garage_pos == "Front"
				surface_su.setSurfaceType("Wall") 
				surface_nu.setSurfaceType("Wall") 
				surface_wu.setSurfaceType("RoofCeiling")
				surface_eu.setSurfaceType("RoofCeiling") 			
			else
				surface_su.setSurfaceType("RoofCeiling") 
				surface_nu.setSurfaceType("RoofCeiling") 
				surface_wu.setSurfaceType("Wall") 
				surface_eu.setSurfaceType("Wall") 
			end
			
			# make subsurfaces
			door_sub_surface = OpenStudio::Model::SubSurface.new(door_polygon, model)
			door_sub_surface.setSubSurfaceType("Door")
			door_sub_surface.setSurface(surface_s)			
			
			# assign surfaces to the space
			garage_space = OpenStudio::Model::Space.new(model)
			surface_g.setSpace(garage_space)
			surface_w.setSpace(garage_space)
			surface_e.setSpace(garage_space)
			surface_s.setSpace(garage_space)
			surface_n.setSpace(garage_space)
			surface_su.setSpace(garage_space)
			surface_nu.setSpace(garage_space)
			surface_wu.setSpace(garage_space)
			surface_eu.setSpace(garage_space)
		
			garage_space.setBuildingStory(story)
			garage_space.setName("garage")
			runner.registerInfo("Set garage.")
			
			# set this to the garage zone
			garage_space.setThermalZone(garage_zone)
			
			# set this to the garage spacetype
			garage_space.setSpaceType(garage_spacetype)
	
		end
		
		# set vertical story position
		story.setNominalZCoordinate(z)
		
	end
	
	# Foundation
	if ['crawlspace', 'unfinished_basement', 'finished_basement', 'pier_and_beam'].include? foundation_type
		
		# create foundation spacetype
		foundation_spacetype = OpenStudio::Model::SpaceType.new(model)
		foundation_spacetype.setName("#{foundation_type}_spacetype")		
		
		# create foundation zone
		foundation_zone = OpenStudio::Model::ThermalZone.new(model)
		foundation_zone.setName(foundation_type)
				
		# Create a new story within the building
		story = OpenStudio::Model::BuildingStory.new(model)
		story.setNominalFloortoFloorHeight(foundation_height)
		story.setName("Foundation")
		
		# make points
		nw_point = OpenStudio::Point3d.new(0,width,-foundation_height)
		ne_point = OpenStudio::Point3d.new(length,width,-foundation_height)
		se_point = OpenStudio::Point3d.new(length,0,-foundation_height)
		sw_point = OpenStudio::Point3d.new(0,0,-foundation_height)

		# make polygons
        foundation_polygon = OpenStudio::Point3dVector.new
        foundation_polygon << sw_point
        foundation_polygon << nw_point
        foundation_polygon << ne_point
        foundation_polygon << se_point
		
		# make space
		foundation_space = OpenStudio::Model::Space::fromFloorPrint(foundation_polygon, foundation_height, model)
		foundation_space = foundation_space.get
        foundation_space.setBuildingStory(story)
        foundation_space.setName(foundation_type)
		runner.registerInfo("Set #{foundation_type}.")

		# set these to the foundation zone
		foundation_space.setThermalZone(foundation_zone)

		# set these to the foundation spacetype
		foundation_space.setSpaceType(foundation_spacetype)		
		
		# set foundation walls to ground
		spaces = model.getSpaces
		spaces.each do |space|
			if space.spaceType.get.name.to_s == "#{foundation_type}_spacetype"
				surfaces = space.surfaces
				surfaces.each do |surface|
					surface_type = surface.surfaceType
					if surface_type == "Wall"
						surface.setOutsideBoundaryCondition("Ground")
					end
				end
			end
		end
		
		# set vertical story position
		story.setNominalZCoordinate(-foundation_height)
		
	end
	
	# Attic
	z = z + living_height
	
	# calculate the dimensions of the attic
	attic_height = (width / 2.0) * roof_pitch
	
	# create foundation spacetype
	attic_spacetype = OpenStudio::Model::SpaceType.new(model)
	attic_spacetype.setName("#{attic_type}_spacetype")	
		
	# create foundation zone
	attic_zone = OpenStudio::Model::ThermalZone.new(model)
	attic_zone.setName(attic_type)
				
	# Create a new story within the building
	story = OpenStudio::Model::BuildingStory.new(model)
	story.setNominalFloortoFloorHeight(attic_height)
	story.setName("Attic")
	
	# make points
	roof_nw_point = OpenStudio::Point3d.new(0,width,z)
	roof_ne_point = OpenStudio::Point3d.new(length,width,z)
	roof_se_point = OpenStudio::Point3d.new(length,0,z)
	roof_sw_point = OpenStudio::Point3d.new(0,0,z)
	roof_w_point = OpenStudio::Point3d.new(0,width/2.0,z+attic_height)
	roof_e_point = OpenStudio::Point3d.new(length,width/2.0,z+attic_height)
	attic_floor_nw_point = OpenStudio::Point3d.new(0,width,z)
	attic_floor_ne_point = OpenStudio::Point3d.new(length,width,z)
	attic_floor_se_point = OpenStudio::Point3d.new(length,0,z)
	attic_floor_sw_point = OpenStudio::Point3d.new(0,0,z)	
	
	# make polygons
	polygon_floor = OpenStudio::Point3dVector.new
	polygon_floor << attic_floor_se_point
	polygon_floor << attic_floor_sw_point
	polygon_floor << attic_floor_nw_point
	polygon_floor << attic_floor_ne_point
	polygon_s_roof = OpenStudio::Point3dVector.new
	polygon_s_roof << roof_e_point
	polygon_s_roof << roof_w_point
	polygon_s_roof << roof_sw_point
	polygon_s_roof << roof_se_point
	polygon_n_roof = OpenStudio::Point3dVector.new	
	polygon_n_roof << roof_w_point
	polygon_n_roof << roof_e_point
	polygon_n_roof << roof_ne_point
	polygon_n_roof << roof_nw_point
	polygon_w_wall = OpenStudio::Point3dVector.new
	polygon_w_wall << roof_w_point
	polygon_w_wall << roof_nw_point
	polygon_w_wall << roof_sw_point
	polygon_e_wall = OpenStudio::Point3dVector.new
	polygon_e_wall << roof_e_point
	polygon_e_wall << roof_se_point
	polygon_e_wall << roof_ne_point
	
	# make surfaces
	surface_floor = OpenStudio::Model::Surface.new(polygon_floor, model)
	surface_floor.setSurfaceType("Floor") 
	surface_floor.setOutsideBoundaryCondition("Surface") 
	surface_s_roof = OpenStudio::Model::Surface.new(polygon_s_roof, model)
	surface_s_roof.setSurfaceType("RoofCeiling") 
	surface_s_roof.setOutsideBoundaryCondition("Outdoors")	
	surface_n_roof = OpenStudio::Model::Surface.new(polygon_n_roof, model)
	surface_n_roof.setSurfaceType("RoofCeiling") 
	surface_n_roof.setOutsideBoundaryCondition("Outdoors")		
	surface_w_wall = OpenStudio::Model::Surface.new(polygon_w_wall, model)
	surface_w_wall.setSurfaceType("Wall") 
	surface_w_wall.setOutsideBoundaryCondition("Outdoors")
	surface_e_wall = OpenStudio::Model::Surface.new(polygon_e_wall, model)
	surface_e_wall.setSurfaceType("Wall") 
	surface_e_wall.setOutsideBoundaryCondition("Outdoors")
	
	# assign surfaces to the space
	attic_space = OpenStudio::Model::Space.new(model)
	surface_floor.setSpace(attic_space)
	surface_s_roof.setSpace(attic_space)
	surface_n_roof.setSpace(attic_space)
	surface_w_wall.setSpace(attic_space)
	surface_e_wall.setSpace(attic_space)
	
    #attic_space.changeTransformation(OpenStudio::Transformation.new(m))
    attic_space.setBuildingStory(story)
    attic_space.setName(attic_type)
	runner.registerInfo("Set #{attic_type}.")

	# set these to the foundation zone
	attic_space.setThermalZone(attic_zone)

	# set these to the foundation spacetype
	attic_space.setSpaceType(attic_spacetype)

	# set vertical story position
	story.setNominalZCoordinate(z)	
	
    # put all of the spaces in the model into a vector
    spaces = OpenStudio::Model::SpaceVector.new
    model.getSpaces.each do |space|
      spaces << space
	end
	
    # intersect and match surfaces for each space in the vector
    OpenStudio::Model.intersectSurfaces(spaces)
	OpenStudio::Model.matchSurfaces(spaces)
	
    # reporting final condition of model
    finishing_spaces = model.getSpaces
    runner.registerFinalCondition("The building finished with #{finishing_spaces.size} spaces.")	
	
    return true

  end
  
end

# register the measure to be used by the application
CreateBasicGeometry.new.registerWithApplication
