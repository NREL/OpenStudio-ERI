# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

# start the measure
class CreateResidentialDoorArea < OpenStudio::Ruleset::ModelUserScript

  def make_rectangle(pt1, pt2, pt3, pt4)
    p = OpenStudio::Point3dVector.new
    p << pt1
    p << pt2
	p << pt3
    p << pt4
    return p
  end

  # human readable name
  def name
    return "Create Residential Door Area"
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

    #make a choice argument for model objects
    spacetype_handles = OpenStudio::StringVector.new
    spacetype_display_names = OpenStudio::StringVector.new

    #putting model object and names into hash
    spacetype_args = model.getSpaceTypes
    spacetype_args_hash = {}
    spacetype_args.each do |spacetype_arg|
      spacetype_args_hash[spacetype_arg.name.to_s] = spacetype_arg
    end

    #looping through sorted hash of model objects
    spacetype_args_hash.sort.map do |key,value|
      spacetype_handles << value.handle.to_s
      spacetype_display_names << key
    end

    #make a choice argument for living space
    selected_living = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedliving", spacetype_handles, spacetype_display_names, true)
    selected_living.setDisplayName("Living Space")
	selected_living.setDescription("The living space type.")
    args << selected_living

	#make a double argument for front door area
	userdefineddoorarea = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefineddoorarea", true)
	userdefineddoorarea.setDisplayName("Door Area")
	userdefineddoorarea.setUnits("ft^2/unit")
	userdefineddoorarea.setDescription("The area of the front door.")
	userdefineddoorarea.setDefaultValue(20.0)
	args << userdefineddoorarea

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end
	
	selected_living = runner.getOptionalWorkspaceObjectChoiceValue("selectedliving",user_arguments,model)
	door_area = OpenStudio::convert(runner.getDoubleArgumentValue("userdefineddoorarea",user_arguments),"ft^2","m^2").get
	
	least_y = 10000
	least_z = 10000
	front_wall_least_x = 10000
	front_wall_least_z = 10000	
	spaces = model.getSpaces
	spaces.each do |space|
		if selected_living.get.handle.to_s == space.spaceType.get.handle.to_s
			# identify front wall	
			surfaces = space.surfaces
			surfaces.each do |surface|
				if surface.surfaceType == "Wall" and surface.outsideBoundaryCondition == "Outdoors"
					y_s = []
					z_s = []
					vertices = surface.vertices
					vertices.each do |vertex|
						y_s << vertex.y
						z_s << vertex.z
					end
					if y_s.inject{|sum,x| sum + x + space.yOrigin} < least_y
						least_y = y_s.inject{|sum,x| sum + x + space.yOrigin}
					end
					if z_s.inject{|sum,x| sum + x + space.zOrigin} < least_z
						least_z = z_s.inject{|sum,x| sum + x + space.zOrigin}
					end
				end
			end
		end
	end
	
	front_wall = nil
	spaces.each do |space|
		if selected_living.get.handle.to_s == space.spaceType.get.handle.to_s
			surfaces = space.surfaces	
			surfaces.each do |surface|
				if surface.surfaceType == "Wall" and surface.outsideBoundaryCondition == "Outdoors"
					y_s = []
					z_s = []
					vertices = surface.vertices
					vertices.each do |vertex|
						y_s << vertex.y
						z_s << vertex.z
					end
					if y_s.inject{|sum,x| sum + x + space.yOrigin} == least_y and z_s.inject{|sum,x| sum + x + space.zOrigin} == least_z
						front_wall = surface.name.to_s
						vertices = surface.vertices
						surface.vertices.each do |vertex|
							if vertex.x < front_wall_least_x
								front_wall_least_x = vertex.x
							end
							if vertex.z < front_wall_least_z
								front_wall_least_z = vertex.z
							end
						end
						break
					end
				end
			end
		end
	end
	
	surfaces = model.getSurfaces
	surfaces.each do |surface|
		if surface.name.to_s == front_wall
			runner.registerInfo(surface.name.to_s)
			sw_point = nil
			vertices = surface.vertices
			vertices.each do |vertex|
				if vertex.x == front_wall_least_x and vertex.z == front_wall_least_z
					sw_point = vertex
				end
			end
		
			door_sw_point = OpenStudio::Point3d.new(sw_point.x + 0.5, sw_point.y, sw_point.z)
			door_nw_point = OpenStudio::Point3d.new(sw_point.x + 0.5, sw_point.y, sw_point.z + 2.1336)
			door_ne_point = OpenStudio::Point3d.new(sw_point.x + 0.5 + (door_area/2.1336), sw_point.y, sw_point.z + 2.1336)
			door_se_point = OpenStudio::Point3d.new(sw_point.x + 0.5 + (door_area/2.1336), sw_point.y, sw_point.z)	
			
			door_polygon = make_rectangle(door_sw_point, door_nw_point, door_ne_point, door_se_point)
			
			door_sub_surface = OpenStudio::Model::SubSurface.new(door_polygon, model)
			door_sub_surface.setSubSurfaceType("Door")
			door_sub_surface.setSurface(surface)			
			
		end
	end

    return true

  end
  
end

# register the measure to be used by the application
CreateResidentialDoorArea.new.registerWithApplication
