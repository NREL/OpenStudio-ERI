# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

# start the measure
class CreateResidentialOverhangs < OpenStudio::Ruleset::ModelUserScript

  # human readable name
  def name
    return "Add/Replace Residential Overhangs"
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

    depth = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("depth", true)
    depth.setDisplayName("Depth")
	depth.setUnits("ft")
    depth.setDescription("Depth of the overhang. The distance from the wall surface in the direction normal to the wall surface.")
    depth.setDefaultValue(2.0)
    args << depth

    offset = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("offset", true)
    offset.setDisplayName("Offset")
	offset.setUnits("ft")
    offset.setDescription("Height of the overhangs above windows, relative to the top of the window framing.")
    offset.setDefaultValue(0.5)
    args << offset

	# TODO: addOverhang() sets WidthExtension=Offset*2.
    # width_extension = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("width_extension", true)
    # width_extension.setDisplayName("Width Extension")
	# width_extension.setUnits("ft")
    # width_extension.setDescription("Length that the overhang extends beyond the window width, relative to the outside of the window framing.")
    # width_extension.setDefaultValue(1.0)
    # args << width_extension

	facade_bools = OpenStudio::StringVector.new
	facade_bools << "First Story, Front"
	facade_bools << "First Story, Back"
	facade_bools << "First Story, Left"	
	facade_bools << "First Story, Right"
	facade_bools << "Second Story, Front"
	facade_bools << "Second Story, Back"
	facade_bools << "Second Story, Left"	
	facade_bools << "Second Story, Right"
	facade_bools << "Third Story, Front"
	facade_bools << "Third Story, Back"
	facade_bools << "Third Story, Left"	
	facade_bools << "Third Story, Right"
	facade_bools << "Fourth Story, Front"
	facade_bools << "Fourth Story, Back"
	facade_bools << "Fourth Story, Left"	
	facade_bools << "Fourth Story, Right"
	facade_bools << "Fifth Story, Front"
	facade_bools << "Fifth Story, Back"
	facade_bools << "Fifth Story, Left"	
	facade_bools << "Fifth Story, Right"
	facade_bools << "Sixth Story, Front"
	facade_bools << "Sixth Story, Back"
	facade_bools << "Sixth Story, Left"	
	facade_bools << "Sixth Story, Right"
	facade_bools.each do |facade_bool|
		story = facade_bool.split(',')[0]
		facade = facade_bool.split(',')[1].gsub(" ", "")
		arg = OpenStudio::Ruleset::OSArgument::makeBoolArgument(facade_bool.downcase.gsub(" ", "_").gsub(",", ""), true)
		arg.setDisplayName(facade_bool)
		arg.setDescription("Specifies the presence of overhangs on #{facade.downcase} windows on the #{story.downcase}.")
		arg.setDefaultValue(true)
		args << arg
	end	
	
    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end
	
	depth = OpenStudio.convert(runner.getDoubleArgumentValue("depth",user_arguments), "ft", "m").get
	offset = OpenStudio.convert(runner.getDoubleArgumentValue("offset",user_arguments), "ft", "m").get
	# width_extension = OpenStudio.convert(runner.getDoubleArgumentValue("width_extension",user_arguments), "ft", "m").get
	facade_bools = OpenStudio::StringVector.new
	facade_bools << "First Story, Front"
	facade_bools << "First Story, Back"
	facade_bools << "First Story, Left"	
	facade_bools << "First Story, Right"
	facade_bools << "Second Story, Front"
	facade_bools << "Second Story, Back"
	facade_bools << "Second Story, Left"	
	facade_bools << "Second Story, Right"
	facade_bools << "Third Story, Front"
	facade_bools << "Third Story, Back"
	facade_bools << "Third Story, Left"	
	facade_bools << "Third Story, Right"
	facade_bools << "Fourth Story, Front"
	facade_bools << "Fourth Story, Back"
	facade_bools << "Fourth Story, Left"	
	facade_bools << "Fourth Story, Right"
	facade_bools << "Fifth Story, Front"
	facade_bools << "Fifth Story, Back"
	facade_bools << "Fifth Story, Left"	
	facade_bools << "Fifth Story, Right"
	facade_bools << "Sixth Story, Front"
	facade_bools << "Sixth Story, Back"
	facade_bools << "Sixth Story, Left"	
	facade_bools << "Sixth Story, Right"	
	facade_bools_hash = Hash.new
	facade_bools.each do |facade_bool|
		facade_bools_hash[facade_bool] = runner.getBoolArgumentValue(facade_bool.downcase.gsub(" ", "_").gsub(",", ""),user_arguments)
	end	

	# error checking
	if depth <= 0
		runner.registerError("Overhang depth too small.")
		return false
	end
	if offset < 0
		runner.registerError("Overhang offset too small.")
		return false
	end
	# if width_extension < 0 
		# runner.registerError("Overhang width extension too small.")
		# return false
	# end
	
	# get building orientation
	building_orientation = model.getBuilding.northAxis.round
		
	subsurfaces = model.getSubSurfaces
	subsurfaces.each do |subsurface|
		
		next if not subsurface.subSurfaceType.include? "Window"
	
		# get subsurface azimuth to determine facade
		window_azimuth = OpenStudio::Quantity.new(subsurface.azimuth, OpenStudio::createSIAngle)
		window_orientation = (OpenStudio.convert(window_azimuth, OpenStudio::createIPAngle).get.value + building_orientation).round
	
		# get the story that this subsurface is on
		story = nil
		spaces = model.getSpaces
		spaces.each do |space|
			ss = space.surfaces
			ss.each do |s|
				sbs = s.subSurfaces
				sbs.each do |sb|
					if sb.name.to_s == subsurface.name.to_s
						if space.buildingStory.is_initialized
							story = space.buildingStory.get.name.to_s
							break
						end
					end
				end				
			end
		end
			
		if window_orientation - 180 == building_orientation
			facade = "Front"
		elsif window_orientation - 90 == building_orientation
			facade = "Right"
		elsif window_orientation - 0 == building_orientation
			facade = "Back"
		elsif window_orientation - 270 == building_orientation
			facade = "Left"
		end
		
		unless facade_bools_hash["#{story} Story, #{facade}"]
			next
		end

		overhang = subsurface.addOverhang(depth, offset)
		overhang.get.setName("#{subsurface.name} - Overhang")
		
		runner.registerInfo("#{overhang.get.name.to_s} added.")

	end
	
	return true
	
  end
  
end

# register the measure to be used by the application
CreateResidentialOverhangs.new.registerWithApplication
