# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

# start the measure
class CreateResidentialEaves < OpenStudio::Ruleset::ModelUserScript

  def initialize_transformation_matrix(m)
	m[0,0] = 1
	m[1,1] = 1
	m[2,2] = 1
	m[3,3] = 1
	return m
  end

  # human readable name
  def name
    return "Set Residential Eaves"
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

    #make a choice argument for attic
    selected_attic = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedattic", spacetype_handles, spacetype_display_names, true)
    selected_attic.setDisplayName("Attic Space")
	selected_attic.setDescription("The attic space type.")
    args << selected_attic

	#make a choice argument for garage
    selected_garage = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedgarage", spacetype_handles, spacetype_display_names, true)
    selected_garage.setDisplayName("Garage Space")
	selected_garage.setDescription("The garage space type.")
    args << selected_garage	
	
	#make a choice argument for model objects
	roof_structure_display_names = OpenStudio::StringVector.new
	roof_structure_display_names << "Truss, Cantilever"
	roof_structure_display_names << "Rafter"
	
	#make a choice argument for roof type
	roof_structure = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("roof_structure", roof_structure_display_names, true)
	roof_structure.setDisplayName("Roof Structure")
	roof_structure.setDescription("The roof structure of the building.")
    roof_structure.setDefaultValue("Truss, Cantilever")
	args << roof_structure	
	
	#make a choice argument for eaves depth
	eaves_depth = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("eaves_depth", true)
	eaves_depth.setDisplayName("Eaves Depth")
	eaves_depth.setUnits("ft")
	eaves_depth.setDescription("The eaves depth of the roof.")
    eaves_depth.setDefaultValue(2.0)
	args << eaves_depth
	
    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end
	
	selected_attic = runner.getOptionalWorkspaceObjectChoiceValue("selectedattic",user_arguments,model)
	selected_garage = runner.getOptionalWorkspaceObjectChoiceValue("selectedgarage",user_arguments,model)
	roof_structure = runner.getStringArgumentValue("roof_structure",user_arguments)
	eaves_depth = OpenStudio.convert(runner.getDoubleArgumentValue("eaves_depth",user_arguments),"ft","m").get

    spaces = model.getSpaces
    spaces.each do |space|
      if selected_attic.get.handle.to_s == space.spaceType.get.handle.to_s
	    story = space.buildingStory.get
		attic_height = story.nominalFloortoFloorHeight.to_f
		attic_width = 0.0
		attic_length = 0.0
		attic_increase = 0.0
		attic_run = 0.0
		space.surfaces.each do |surface|
			if surface.surfaceType.downcase == "floor" and surface.outsideBoundaryCondition.downcase == "surface"
				least_x = 1000
				greatest_x = -1000
				least_y = 1000
				greatest_y = -1000
				vertices = surface.vertices
				vertices.each do |vertex|
				  if vertex.x < least_x
					least_x = vertex.x
				  end
				  if vertex.x > greatest_x
					greatest_x = vertex.x
				  end
				  if vertex.y < least_y
					least_y = vertex.y
				  end
				  if vertex.y > greatest_y
					greatest_y = vertex.y
				  end		  
				end
				attic_length = greatest_x - least_x
				attic_width = greatest_y - least_y
				if attic_length > attic_width
					attic_run = attic_width / 2.0
				else
					attic_run = attic_length / 2.0
				end
				roof_pitch = attic_height / attic_run
				attic_increase = roof_pitch * eaves_depth
			end
		end
		if roof_structure == "Truss, Cantilever"
			space.surfaces.each do |surface|
				if surface.surfaceType.downcase == "roofceiling" and surface.outsideBoundaryCondition.downcase == "outdoors"
					# raise the roof
					m = initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
					m[2,3] = attic_increase
					transformation = OpenStudio::Transformation.new(m)
					vertices = surface.vertices
					new_vertices = transformation * vertices
					surface.setVertices(new_vertices)				
				elsif surface.surfaceType.downcase == "wall" and surface.outsideBoundaryCondition.downcase == "outdoors"
					x_s = []
					y_s = []
					z_s = []
					vertices = surface.vertices
					vertices.each do |vertex|
						x_s << vertex.x
						y_s << vertex.y
						z_s << vertex.z
					end
					max_z = z_s.each_with_index.max
					top_pt = OpenStudio::Point3d.new(x_s[max_z[1]], y_s[max_z[1]], z_s[max_z[1]] + attic_increase)
					if x_s.uniq.size == 1 # orientation of this wall is along y-axis
						min_y = y_s.each_with_index.min
						max_y = y_s.each_with_index.max 
						min_pt = OpenStudio::Point3d.new(x_s[min_y[1]], y_s[min_y[1]] - eaves_depth, z_s[min_y[1]])
						max_pt = OpenStudio::Point3d.new(x_s[max_y[1]], y_s[max_y[1]] + eaves_depth, z_s[max_y[1]])
					else # orientation of this wall is along the x-axis
						min_x = x_s.each_with_index.min
						max_x = x_s.each_with_index.max 
						min_pt = OpenStudio::Point3d.new(x_s[min_x[1]] - eaves_depth, y_s[min_x[1]], z_s[min_x[1]])
						max_pt = OpenStudio::Point3d.new(x_s[max_x[1]] + eaves_depth, y_s[max_x[1]], z_s[max_x[1]])						
					end
					new_vertices = OpenStudio::Point3dVector.new
					new_vertices << top_pt
					new_vertices << min_pt
					new_vertices << max_pt
					surface.setVertices(new_vertices)				
				end
			end
		end
		shading_surface_group = OpenStudio::Model::ShadingSurfaceGroup.new(model)
		space.surfaces.each do |surface|
			if surface.surfaceType.downcase == "roofceiling" and surface.outsideBoundaryCondition.downcase == "outdoors"
				
				# add the shading surfaces
				new_surface_down = surface.clone.to_Surface.get
				new_surface_left = surface.clone.to_Surface.get
				new_surface_right = surface.clone.to_Surface.get
				m_down_top = initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
				m_down_bottom = initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
				m_left_top_left = initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
				m_left_top_right = initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
				m_left_bottom_right = initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
				m_left_bottom_left = initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
				m_right_top_left = initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
				m_right_top_right = initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
				m_right_bottom_right = initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
				m_right_bottom_left = initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))				
				vertices = new_surface_down.vertices
				if vertices[0].z != vertices[1].z
					if vertices[0].x == vertices[1].x # slopes along y-axis
						if vertices[0].y > vertices[1].y
							gradient = "neg_y"								
						else
							gradient = "pos_y"								
						end
					else # slopes along x-axis
						if vertices[0].x > vertices[1].x
							gradient = "neg_x"
						else
							gradient = "pos_x"
						end			
					end
				else # vertices[0].z != vertices[3].z
					if vertices[0].x == vertices[3].x # slopes along y-axis
						if vertices[0].y > vertices[3].y # vertices[0] at the top and vertices[3] at the bottom
							if vertices[0].x > vertices[1].x # vertices[0] at the right and vertices[1] at the left
								top_right = vertices[0]
								top_left = vertices[1]
								bottom_left = vertices[2]
								bottom_right = vertices[3]
							else # vertices[1] at the right and vertices[0] at the left
								top_left = vertices[0]
								top_right = vertices[1]
								bottom_right = vertices[2]
								bottom_left = vertices[3]						
							end
							# slopes in neg y
							m_down_top[0,3] = 0
							m_down_top[1,3] = -attic_run
							m_down_top[2,3] = -attic_height
							m_down_bottom[0,3] = 0
							m_down_bottom[1,3] = -eaves_depth
							m_down_bottom[2,3] = -attic_increase
							m_left_top_left[0,3] = -eaves_depth
							m_left_top_left[1,3] = 0
							m_left_top_left[2,3] = 0
							m_left_top_right[0,3] = -attic_length
							m_left_top_right[1,3] = 0
							m_left_top_right[2,3] = 0
							m_left_bottom_right[0,3] = -attic_length
							m_left_bottom_right[1,3] = -eaves_depth
							m_left_bottom_right[2,3] = -attic_increase
							m_left_bottom_left[0,3] = -eaves_depth
							m_left_bottom_left[1,3] = -eaves_depth
							m_left_bottom_left[2,3] = -attic_increase
							m_right_top_left[0,3] = attic_length
							m_right_top_left[1,3] = 0
							m_right_top_left[2,3] = 0
							m_right_top_right[0,3] = eaves_depth
							m_right_top_right[1,3] = 0
							m_right_top_right[2,3] = 0
							m_right_bottom_right[0,3] = eaves_depth
							m_right_bottom_right[1,3] = -eaves_depth
							m_right_bottom_right[2,3] = -attic_increase
							m_right_bottom_left[0,3] = attic_length
							m_right_bottom_left[1,3] = -eaves_depth
							m_right_bottom_left[2,3] = -attic_increase								
						else # vertices[3] at the bottom and vertices[0] at the top
							if vertices[3].x > vertices[1].x # vertices [3] at the right and vertices[1] at the left
								bottom_right = vertices[3]
								bottom_left = vertices[2]
								top_left = vertices[1]
								top_right = vertices[0]
							else # vertices[1] at the right and vertices[3] at the left 
								bottom_left = vertices[3]
								bottom_right = vertices[2]
								top_right = vertices[1]
								top_left = vertices[0]									
							end
							# slopes in pos y
							m_down_top[0,3] = 0
							m_down_top[1,3] = attic_run
							m_down_top[2,3] = -attic_height
							m_down_bottom[0,3] = 0
							m_down_bottom[1,3] = eaves_depth
							m_down_bottom[2,3] = -attic_increase
							m_left_top_left[0,3] = -eaves_depth
							m_left_top_left[1,3] = 0
							m_left_top_left[2,3] = 0
							m_left_top_right[0,3] = -attic_length
							m_left_top_right[1,3] = 0
							m_left_top_right[2,3] = 0
							m_left_bottom_right[0,3] = -attic_length
							m_left_bottom_right[1,3] = eaves_depth
							m_left_bottom_right[2,3] = -attic_increase
							m_left_bottom_left[0,3] = -eaves_depth
							m_left_bottom_left[1,3] = eaves_depth
							m_left_bottom_left[2,3] = -attic_increase
							m_right_top_left[0,3] = attic_length
							m_right_top_left[1,3] = 0
							m_right_top_left[2,3] = 0
							m_right_top_right[0,3] = eaves_depth
							m_right_top_right[1,3] = 0
							m_right_top_right[2,3] = 0
							m_right_bottom_right[0,3] = eaves_depth
							m_right_bottom_right[1,3] = eaves_depth
							m_right_bottom_right[2,3] = -attic_increase
							m_right_bottom_left[0,3] = attic_length
							m_right_bottom_left[1,3] = eaves_depth
							m_right_bottom_left[2,3] = -attic_increase								
						end
					else # slopes along x-axis
						if vertices[0].y > vertices[3].y # vertices[0] at the left and vertices[3] at the right
							if vertices[0].x > vertices[1].x # vertices[0] at the top and vertices[1] at bottom 
								bottom_right = vertices[2]
								bottom_left = vertices[1]
								top_left = vertices[0]
								top_right = vertices[3]
							else # vertices[0] at the bottom and vertices[1] at the top
								bottom_left = vertices[0]
								bottom_right = vertices[3]
								top_right = vertices[2]
								top_left = vertices[1]									
							end
							# slopes in neg x
							m_down_top[0,3] = -attic_run
							m_down_top[1,3] = 0
							m_down_top[2,3] = -attic_height
							m_down_bottom[0,3] = -eaves_depth
							m_down_bottom[1,3] = 0
							m_down_bottom[2,3] = -attic_increase
							m_left_top_left[0,3] = 0
							m_left_top_left[1,3] = eaves_depth
							m_left_top_left[2,3] = 0
							m_left_top_right[0,3] = 0
							m_left_top_right[1,3] = attic_width
							m_left_top_right[2,3] = 0
							m_left_bottom_right[0,3] = -eaves_depth
							m_left_bottom_right[1,3] = attic_width
							m_left_bottom_right[2,3] = -attic_increase
							m_left_bottom_left[0,3] = -eaves_depth
							m_left_bottom_left[1,3] = eaves_depth
							m_left_bottom_left[2,3] = -attic_increase
							m_right_top_left[0,3] = 0
							m_right_top_left[1,3] = -attic_width
							m_right_top_left[2,3] = 0
							m_right_top_right[0,3] = 0
							m_right_top_right[1,3] = -eaves_depth
							m_right_top_right[2,3] = 0
							m_right_bottom_right[0,3] = -eaves_depth
							m_right_bottom_right[1,3] = -eaves_depth
							m_right_bottom_right[2,3] = -attic_increase
							m_right_bottom_left[0,3] = -eaves_depth
							m_right_bottom_left[1,3] = -attic_width
							m_right_bottom_left[2,3] = -attic_increase
						else # vertices[3] at the right and vertices[0] at the left
							if vertices[0].x > vertices[1].x # vertices[0] at the bottom and vertices[1] at top
								bottom_right = vertices[3]
								bottom_left = vertices[0]
								top_left = vertices[1]
								top_right = vertices[2]
							else # vertices[1] at the bottom and vertices[0] at the top
								bottom_left = vertices[1]
								bottom_right = vertices[2]
								top_right = vertices[3]
								top_left = vertices[0]									
							end
							# slopes in pos x
							m_down_top[0,3] = attic_run
							m_down_top[1,3] = 0
							m_down_top[2,3] = -attic_height
							m_down_bottom[0,3] = eaves_depth
							m_down_bottom[1,3] = 0
							m_down_bottom[2,3] = -attic_increase
							m_left_top_left[0,3] = 0
							m_left_top_left[1,3] = -eaves_depth
							m_left_top_left[2,3] = 0
							m_left_top_right[0,3] = 0
							m_left_top_right[1,3] = -attic_width
							m_left_top_right[2,3] = 0
							m_left_bottom_right[0,3] = eaves_depth
							m_left_bottom_right[1,3] = -attic_width
							m_left_bottom_right[2,3] = -attic_increase
							m_left_bottom_left[0,3] = eaves_depth
							m_left_bottom_left[1,3] = -eaves_depth
							m_left_bottom_left[2,3] = -attic_increase
							m_right_top_left[0,3] = 0
							m_right_top_left[1,3] = attic_width
							m_right_top_left[2,3] = 0
							m_right_top_right[0,3] = 0
							m_right_top_right[1,3] = eaves_depth
							m_right_top_right[2,3] = 0
							m_right_bottom_right[0,3] = eaves_depth
							m_right_bottom_right[1,3] = eaves_depth
							m_right_bottom_right[2,3] = -attic_increase
							m_right_bottom_left[0,3] = eaves_depth
							m_right_bottom_left[1,3] = attic_width
							m_right_bottom_left[2,3] = -attic_increase
						end			
					end						
				end
				
				# lower eaves
				transformation_down_top = OpenStudio::Transformation.new(m_down_top)
				transformation_down_bottom = OpenStudio::Transformation.new(m_down_bottom)
				new_vertices_down = OpenStudio::Point3dVector.new
				new_vertices_down << transformation_down_top * top_left
				new_vertices_down << transformation_down_top * top_right
				new_vertices_down << transformation_down_bottom * bottom_right
				new_vertices_down << transformation_down_bottom * bottom_left					
				new_surface_down.setVertices(new_vertices_down)		
				shading_surface = OpenStudio::Model::ShadingSurface.new(new_surface_down.vertices, model)
				shading_surface.setName("eaves")
				shading_surface.setShadingSurfaceGroup(shading_surface_group)								
				new_surface_down.remove
				
				# left eaves
				transformation_left_top_left = OpenStudio::Transformation.new(m_left_top_left)
				transformation_left_top_right = OpenStudio::Transformation.new(m_left_top_right)
				transformation_left_bottom_right = OpenStudio::Transformation.new(m_left_bottom_right)
				transformation_left_bottom_left = OpenStudio::Transformation.new(m_left_bottom_left)
				new_vertices_left = OpenStudio::Point3dVector.new
				new_vertices_left << transformation_left_top_left * top_left
				new_vertices_left << transformation_left_top_right * top_right
				new_vertices_left << transformation_left_bottom_right * bottom_right
				new_vertices_left << transformation_left_bottom_left * bottom_left
				new_surface_left.setVertices(new_vertices_left)		
				shading_surface = OpenStudio::Model::ShadingSurface.new(new_surface_left.vertices, model)
				shading_surface.setName("eaves")
				shading_surface.setShadingSurfaceGroup(shading_surface_group)								
				new_surface_left.remove

				# right eaves
				transformation_right_top_left = OpenStudio::Transformation.new(m_right_top_left)
				transformation_right_top_right = OpenStudio::Transformation.new(m_right_top_right)
				transformation_right_bottom_right = OpenStudio::Transformation.new(m_right_bottom_right)
				transformation_right_bottom_left = OpenStudio::Transformation.new(m_right_bottom_left)
				new_vertices_right = OpenStudio::Point3dVector.new
				new_vertices_right << transformation_right_top_left * top_left
				new_vertices_right << transformation_right_top_right * top_right
				new_vertices_right << transformation_right_bottom_right * bottom_right
				new_vertices_right << transformation_right_bottom_left * bottom_left
				new_surface_right.setVertices(new_vertices_right)		
				shading_surface = OpenStudio::Model::ShadingSurface.new(new_surface_right.vertices, model)
				shading_surface.setName("eaves")
				shading_surface.setShadingSurfaceGroup(shading_surface_group)								
				new_surface_right.remove					

			end
		end		
	  # elsif selected_garage.get.handle.to_s == space.spaceType.get.handle.to_s
	    # story = space.buildingStory.get
		# attic_height = story.nominalFloortoFloorHeight.to_f
		# attic_length = 0.0
		# attic_increase = 0.0
		# attic_run = 0.0
		# space.surfaces.each do |surface|
			# least_x = 1000
			# greatest_x = -1000
			# least_y = 1000
			# greatest_y = -1000
			# vertices = surface.vertices
			# vertices.each do |vertex|
			  # if vertex.x < least_x
				# least_x = vertex.x
			  # end
			  # if vertex.x > greatest_x
				# greatest_x = vertex.x
			  # end
			  # if vertex.y < least_y
				# least_y = vertex.y
			  # end
			  # if vertex.y > greatest_y
				# greatest_y = vertex.y
			  # end		  
			# end
			# attic_length = greatest_x - least_x
			# attic_width = greatest_y - least_y
			# if attic_length > attic_width
				# attic_run = attic_width / 2.0
			# else
				# attic_run = attic_length / 2.0
			# end
			# roof_pitch = attic_height / attic_run
			# attic_increase = roof_pitch * eaves_depth
		# end
		# if roof_structure == "Truss, Cantilever"
			# shading_surface_group = OpenStudio::Model::ShadingSurfaceGroup.new(model)
			# space.surfaces.each do |surface|
				# if surface.surfaceType.downcase == "roofceiling" and surface.outsideBoundaryCondition.downcase == "outdoors"
					
					# raise the roof
					# m = initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
					# m[2,3] = attic_increase
					# transformation = OpenStudio::Transformation.new(m)
					# vertices = surface.vertices
					# new_vertices = transformation * vertices
					# surface.setVertices(new_vertices)
					
					# add the shading surfaces
					# new_surface_down = surface.clone.to_Surface.get
					# new_surface_left = surface.clone.to_Surface.get
					# new_surface_right = surface.clone.to_Surface.get
					# m_down_top = initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
					# m_down_bottom = initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
					# m_left_top_left = initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
					# m_left_top_right = initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
					# m_left_bottom_right = initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
					# m_left_bottom_left = initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
					# m_right_top_left = initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
					# m_right_top_right = initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
					# m_right_bottom_right = initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
					# m_right_bottom_left = initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))				
					# vertices = new_surface_down.vertices
					# if vertices[0].z != vertices[1].z
						# if vertices[0].x == vertices[1].x # slopes along y-axis
							# if vertices[0].y > vertices[1].y
								# gradient = "neg_y"								
							# else
								# gradient = "pos_y"								
							# end
						# else
							# if vertices[0].x > vertices[1].x
								# gradient = "neg_x"
							# else
								# gradient = "pos_x"
							# end			
						# end
					# else # vertices[0].z != vertices[3].z
						# if vertices[0].x == vertices[3].x # slopes along y-axis
							# if vertices[0].y > vertices[3].y # vertices[0] at the top and vertices[3] at the bottom
								# if vertices[0].x > vertices[1].x # vertices[0] at the right and vertices[1] at the left
									# top_right = vertices[0]
									# top_left = vertices[1]
									# bottom_left = vertices[2]
									# bottom_right = vertices[3]
								# else # vertices[1] at the right and vertices[0] at the left
									# top_left = vertices[0]
									# top_right = vertices[1]
									# bottom_right = vertices[2]
									# bottom_left = vertices[3]									
								# end
								# slopes in neg y
								# m_down_top[0,3] = 0
								# m_down_top[1,3] = -attic_run
								# m_down_top[2,3] = -attic_height
								# m_down_bottom[0,3] = 0
								# m_down_bottom[1,3] = -eaves_depth
								# m_down_bottom[2,3] = -attic_increase
								# m_left_top_left[0,3] = -eaves_depth
								# m_left_top_left[1,3] = 0
								# m_left_top_left[2,3] = 0
								# m_left_top_right[0,3] = -attic_length
								# m_left_top_right[1,3] = 0
								# m_left_top_right[2,3] = 0
								# m_left_bottom_right[0,3] = -attic_length
								# m_left_bottom_right[1,3] = -eaves_depth
								# m_left_bottom_right[2,3] = -attic_increase
								# m_left_bottom_left[0,3] = -eaves_depth
								# m_left_bottom_left[1,3] = -eaves_depth
								# m_left_bottom_left[2,3] = -attic_increase
								# m_right_top_left[0,3] = attic_length
								# m_right_top_left[1,3] = 0
								# m_right_top_left[2,3] = 0
								# m_right_top_right[0,3] = eaves_depth
								# m_right_top_right[1,3] = 0
								# m_right_top_right[2,3] = 0
								# m_right_bottom_right[0,3] = eaves_depth
								# m_right_bottom_right[1,3] = -eaves_depth
								# m_right_bottom_right[2,3] = -attic_increase
								# m_right_bottom_left[0,3] = attic_length
								# m_right_bottom_left[1,3] = -eaves_depth
								# m_right_bottom_left[2,3] = -attic_increase								
							# else # vertices[3] at the bottom and vertices[0] at the top
								# if vertices[3].x > vertices[1].x # vertices [3] at the right and vertices[1] at the left
									# bottom_right = vertices[3]
									# bottom_left = vertices[2]
									# top_left = vertices[1]
									# top_right = vertices[0]
								# else # vertices[1] at the right and vertices[3] at the left 
									# bottom_left = vertices[3]
									# bottom_right = vertices[2]
									# top_right = vertices[1]
									# top_left = vertices[0]									
								# end
								# slopes in pos y
								# m_down_top[0,3] = 0
								# m_down_top[1,3] = attic_run
								# m_down_top[2,3] = -attic_height
								# m_down_bottom[0,3] = 0
								# m_down_bottom[1,3] = eaves_depth
								# m_down_bottom[2,3] = -attic_increase
								# m_left_top_left[0,3] = -eaves_depth
								# m_left_top_left[1,3] = 0
								# m_left_top_left[2,3] = 0
								# m_left_top_right[0,3] = -attic_length
								# m_left_top_right[1,3] = 0
								# m_left_top_right[2,3] = 0
								# m_left_bottom_right[0,3] = -attic_length
								# m_left_bottom_right[1,3] = eaves_depth
								# m_left_bottom_right[2,3] = -attic_increase
								# m_left_bottom_left[0,3] = -eaves_depth
								# m_left_bottom_left[1,3] = eaves_depth
								# m_left_bottom_left[2,3] = -attic_increase
								# m_right_top_left[0,3] = attic_length
								# m_right_top_left[1,3] = 0
								# m_right_top_left[2,3] = 0
								# m_right_top_right[0,3] = eaves_depth
								# m_right_top_right[1,3] = 0
								# m_right_top_right[2,3] = 0
								# m_right_bottom_right[0,3] = eaves_depth
								# m_right_bottom_right[1,3] = eaves_depth
								# m_right_bottom_right[2,3] = -attic_increase
								# m_right_bottom_left[0,3] = attic_length
								# m_right_bottom_left[1,3] = eaves_depth
								# m_right_bottom_left[2,3] = -attic_increase								
							# end
						# else # slopes along x-axis
							# if vertices[0].x > vertices[3].x # vertices[0] at the top and vertices[3] at the bottom
								# if vertices[0].y > vertices[1].y # vertices [0] at the left and vertices[1] at the right
									# top_left = vertices[0]
									# top_right = vertices[1]
									# bottom_right = vertices[2]
									# bottom_left = vertices[3]
								# else # vertices[1] at the left and vertices[0] at the right
									# top_left = vertices[1]
									# top_right = vertices[0]
									# bottom_right = vertices[3]
									# bottom_left = vertices[2]								
								# end							
								# slopes in neg x
								# m_down_top[0,3] = -attic_run
								# m_down_top[1,3] = 0
								# m_down_top[2,3] = -attic_height
								# m_down_bottom[0,3] = -eaves_depth
								# m_down_bottom[1,3] = 0
								# m_down_bottom[2,3] = -attic_increase
								# m_left_top_left[0,3] = 0
								# m_left_top_left[1,3] = eaves_depth
								# m_left_top_left[2,3] = 0
								# m_left_top_right[0,3] = 0
								# m_left_top_right[1,3] = attic_length
								# m_left_top_right[2,3] = 0
								# m_left_bottom_right[0,3] = -eaves_depth
								# m_left_bottom_right[1,3] = attic_length
								# m_left_bottom_right[2,3] = -attic_increase
								# m_left_bottom_left[0,3] = -eaves_depth
								# m_left_bottom_left[1,3] = eaves_depth
								# m_left_bottom_left[2,3] = -attic_increase
								# m_right_top_left[0,3] = 0
								# m_right_top_left[1,3] = -attic_length
								# m_right_top_left[2,3] = 0
								# m_right_top_right[0,3] = 0
								# m_right_top_right[1,3] = -eaves_depth
								# m_right_top_right[2,3] = 0
								# m_right_bottom_right[0,3] = eaves_depth
								# m_right_bottom_right[1,3] = -eaves_depth
								# m_right_bottom_right[2,3] = -attic_increase
								# m_right_bottom_left[0,3] = eaves_depth
								# m_right_bottom_left[1,3] = -attic_length
								# m_right_bottom_left[2,3] = -attic_increase								
							# else
								# gradient = "pos_x"
							# end			
						# end						
					# end
					
					# lower eaves
					# transformation_down_top = OpenStudio::Transformation.new(m_down_top)
					# transformation_down_bottom = OpenStudio::Transformation.new(m_down_bottom)
					# new_vertices_down = OpenStudio::Point3dVector.new
					# new_vertices_down << transformation_down_top * top_left
					# new_vertices_down << transformation_down_top * top_right
					# new_vertices_down << transformation_down_bottom * bottom_right
					# new_vertices_down << transformation_down_bottom * bottom_left					
					# new_surface_down.setVertices(new_vertices_down)		
					# shading_surface = OpenStudio::Model::ShadingSurface.new(new_surface_down.vertices, model)
					# shading_surface.setName("eaves")
					# shading_surface.setShadingSurfaceGroup(shading_surface_group)								
					# new_surface_down.remove
					
					# left eaves
					# transformation_left_top_left = OpenStudio::Transformation.new(m_left_top_left)
					# transformation_left_top_right = OpenStudio::Transformation.new(m_left_top_right)
					# transformation_left_bottom_right = OpenStudio::Transformation.new(m_left_bottom_right)
					# transformation_left_bottom_left = OpenStudio::Transformation.new(m_left_bottom_left)
					# new_vertices_left = OpenStudio::Point3dVector.new
					# new_vertices_left << transformation_left_top_left * top_left
					# new_vertices_left << transformation_left_top_right * top_right
					# new_vertices_left << transformation_left_bottom_right * bottom_right
					# new_vertices_left << transformation_left_bottom_left * bottom_left
					# new_surface_left.setVertices(new_vertices_left)		
					# shading_surface = OpenStudio::Model::ShadingSurface.new(new_surface_left.vertices, model)
					# shading_surface.setName("eaves")
					# shading_surface.setShadingSurfaceGroup(shading_surface_group)								
					# new_surface_left.remove

					# right eaves
					# transformation_right_top_left = OpenStudio::Transformation.new(m_right_top_left)
					# transformation_right_top_right = OpenStudio::Transformation.new(m_right_top_right)
					# transformation_right_bottom_right = OpenStudio::Transformation.new(m_right_bottom_right)
					# transformation_right_bottom_left = OpenStudio::Transformation.new(m_right_bottom_left)
					# new_vertices_right = OpenStudio::Point3dVector.new
					# new_vertices_right << transformation_right_top_left * top_left
					# new_vertices_right << transformation_right_top_right * top_right
					# new_vertices_right << transformation_right_bottom_right * bottom_right
					# new_vertices_right << transformation_right_bottom_left * bottom_left
					# new_surface_right.setVertices(new_vertices_right)		
					# shading_surface = OpenStudio::Model::ShadingSurface.new(new_surface_right.vertices, model)
					# shading_surface.setName("eaves")
					# shading_surface.setShadingSurfaceGroup(shading_surface_group)								
					# new_surface_right.remove					
					
				# elsif surface.surfaceType.downcase == "wall" and surface.outsideBoundaryCondition.downcase == "outdoors"
					# x_s = []
					# y_s = []
					# z_s = []
					# vertices = surface.vertices
					# vertices.each do |vertex|
						# x_s << vertex.x
						# y_s << vertex.y
						# z_s << vertex.z
					# end
					# max_z = z_s.each_with_index.max
					# top_pt = OpenStudio::Point3d.new(x_s[max_z[1]], y_s[max_z[1]], z_s[max_z[1]] + attic_increase)
					# if x_s.uniq.size == 1 # orientation of this wall is along y-axis
						# min_y = y_s.each_with_index.min
						# max_y = y_s.each_with_index.max 
						# min_pt = OpenStudio::Point3d.new(x_s[min_y[1]], y_s[min_y[1]] - eaves_depth, z_s[min_y[1]])
						# max_pt = OpenStudio::Point3d.new(x_s[max_y[1]], y_s[max_y[1]] + eaves_depth, z_s[max_y[1]])
					# else # orientation of this wall is along the x-axis
						# min_x = x_s.each_with_index.min
						# max_x = x_s.each_with_index.max 
						# min_pt = OpenStudio::Point3d.new(x_s[min_x[1]] - eaves_depth, y_s[min_x[1]], z_s[min_x[1]])
						# max_pt = OpenStudio::Point3d.new(x_s[max_x[1]] + eaves_depth, y_s[max_x[1]], z_s[max_x[1]])						
					# end
					# new_vertices = OpenStudio::Point3dVector.new
					# new_vertices << top_pt
					# new_vertices << min_pt
					# new_vertices << max_pt
					# surface.setVertices(new_vertices)
				# end
			# end		
		# end
	  end
    end		

    return true

  end
  
end

# register the measure to be used by the application
CreateResidentialEaves.new.registerWithApplication
