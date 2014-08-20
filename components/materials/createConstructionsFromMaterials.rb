require 'C:/Program Files (x86)/OpenStudio 1.3.1/Ruby/openstudio'
require 'win32ole'
require 'bcl'

class ConstructionFromMaterials

  def initialize

    # get EP and OS versions
    @epversion = OpenStudio::Workspace.new("Draft".to_StrictnessLevel,"EnergyPlus".to_IddFileType).iddFile.version
    @osversion = OpenStudio::Workspace.new.iddFile.version

    # load and attach the material objects
    @version_translator = OpenStudio::OSVersion::VersionTranslator.new

    # open MaterialsTest.xlsx
    root_path = "#{File.dirname(__FILE__)}"
    materials_path = "#{root_path}/lib/Materials.xlsx"
    xl = WIN32OLE::new('Excel.Application')
    wb = xl.workbooks.open(materials_path)
    ws = wb.worksheets("All Materials")
    @data = ws.range('A2:AB657').value
    wb.Close(0)
    xl.Quit

    # path to osm files
    @materials_files_path = "#{root_path}/osm_files"

  end

  # create hash to store uids in
  def create_hash(folder)
    dir = "C:/OpenStudio/OS-BEopt/components/constructions/#{folder}"
    uid_file = dir + "/uid_hash.txt"
    uid_hash = nil
    if File.exists?(uid_file)
      File.open(uid_file, 'r') do |file|
        uid_hash = Marshal.load(file)
        if (uid_hash.class != Hash) or uid_hash.nil?
          raise "Invalid Hash read from disk"
        end
      end
    else
      uid_hash = Hash.new
    end
    return uid_file, uid_hash
  end

  # save the uid hash for next time
  def save_uid_hash(folder)
    uid_file, uid_hash = create_hash(folder)
    File.open(uid_file, 'w') do |file|
      Marshal.dump(uid_hash, file)
    end
  end

  def create_mat_object(model, mat_path)

    if @version_translator.loadModel("#{@materials_files_path}/#{mat_path}.osm").get.getStandardOpaqueMaterials.length > 0

      mat_object = OpenStudio::Model::StandardOpaqueMaterial.new(model)
      mat_object.setName(@version_translator.loadModel("#{@materials_files_path}/#{mat_path}.osm").get.getStandardOpaqueMaterials[0].name.to_s)
      mat_object.setRoughness(@version_translator.loadModel("#{@materials_files_path}/#{mat_path}.osm").get.getStandardOpaqueMaterials[0].roughness.to_s)
      mat_object.setThickness(@version_translator.loadModel("#{@materials_files_path}/#{mat_path}.osm").get.getStandardOpaqueMaterials[0].thickness)
      mat_object.setConductivity(@version_translator.loadModel("#{@materials_files_path}/#{mat_path}.osm").get.getStandardOpaqueMaterials[0].conductivity)
      mat_object.setDensity(@version_translator.loadModel("#{@materials_files_path}/#{mat_path}.osm").get.getStandardOpaqueMaterials[0].density)
      mat_object.setSpecificHeat(@version_translator.loadModel("#{@materials_files_path}/#{mat_path}.osm").get.getStandardOpaqueMaterials[0].specificHeat)

      if not @version_translator.loadModel("#{@materials_files_path}/#{mat_path}.osm").get.getStandardOpaqueMaterials[0].isThermalAbsorptanceDefaulted
        mat_object.setThermalAbsorptance(@version_translator.loadModel("#{@materials_files_path}/#{mat_path}.osm").get.getStandardOpaqueMaterials[0].thermalAbsorptance)
      end
      if not @version_translator.loadModel("#{@materials_files_path}/#{mat_path}.osm").get.getStandardOpaqueMaterials[0].isSolarAbsorptanceDefaulted
        mat_object.setSolarAbsorptance(@version_translator.loadModel("#{@materials_files_path}/#{mat_path}.osm").get.getStandardOpaqueMaterials[0].solarAbsorptance)
      end
      if not @version_translator.loadModel("#{@materials_files_path}/#{mat_path}.osm").get.getStandardOpaqueMaterials[0].isVisibleAbsorptanceDefaulted
        mat_object.setVisibleAbsorptance(@version_translator.loadModel("#{@materials_files_path}/#{mat_path}.osm").get.getStandardOpaqueMaterials[0].visibleAbsorptance)
      end

    elsif @version_translator.loadModel("#{@materials_files_path}/#{mat_path}.osm").get.getMasslessOpaqueMaterials.length > 0

      mat_object = OpenStudio::Model::MasslessOpaqueMaterial.new(model)
      mat_object.setName(@version_translator.loadModel("#{@materials_files_path}/#{mat_path}.osm").get.getMasslessOpaqueMaterials[0].name.to_s)
      mat_object.setRoughness(@version_translator.loadModel("#{@materials_files_path}/#{mat_path}.osm").get.getMasslessOpaqueMaterials[0].roughness.to_s)
      mat_object.setThermalResistance(@version_translator.loadModel("#{@materials_files_path}/#{mat_path}.osm").get.getMasslessOpaqueMaterials[0].thermalResistance)

    end

    return mat_object

  end

  def make(build_dir, calc_layers, fixed_layers, tag)

    # load master taxonomy to validate components
    taxonomy = BCL::MasterTaxonomy.new

    # component_name, construction_name, Sub-Category, folder_name
    category = {"wood stud wall uninsulated"=>["Wood Stud Wall", "ExtInsFinWall", "Wood Stud", "wood stud wall"],
                "wood stud wall"=>["Wood Stud Wall", "ExtInsFinWall", "Wood Stud", "wood stud wall"],
                "double wood stud wall"=>["Double Wood Stud Wall", "ExtInsFinWall", "Double Wood Stud", "double wood stud wall"],
                "cmu wall"=>["CMU Wall", "ExtInsFinWall", "CMU", "cmu wall"],
                "sip wall"=>["SIP Wall", "ExtInsFinWall", "SIP", "sip wall"],
                "icf wall"=>["ICF Wall", "ExtInsFinWall", "ICF", "icf wall"],
                "other wall"=>["Other Wall", "ExtInsFinWall", "Other", "other wall"],
                "other wall superinsulated"=>["Other Wall", "ExtInsFinWall", "Other", "other wall"],
                "slab floor uninsulated"=>["Slab Floor", "Slab", "Slab", "slab"],
                "slab floor"=>["Slab Floor", "Slab", "Slab", "slab"],
                "crawlspace wall uninsulated"=>["Crawlspace Wall", "GrndInsUnfinCSWall", "Crawlspace", "crawlspace"],
                "crawlspace wall"=>["Crawlspace Wall", "GrndInsUnfinCSWall", "Crawlspace", "crawlspace"],
                "crawlspace ceiling"=>["Crawlspace Ceiling", "UnfinCSInsFinFloor", "Crawlspace", "crawlspace"],
                "crawlspace ceiling uninsulated"=>["Crawlspace Ceiling", "UnfinCSInsFinFloor", "Crawlspace", "crawlspace"],
                "crawlspace floor"=>["Crawlspace Floor", "GrndUninsUnfinCSFloor", "Crawlspace", "crawlspace"],
                "crawlspace floor uninsulated"=>["Crawlspace Floor", "GrndUninsUnfinCSFloor", "Crawlspace", "crawlspace"],
                "crawlspace rim joist"=>["Crawlspace Rim Joist", "CSRimJoist", "Crawlspace", "crawlspace"],
                "crawlspace rim joist uninsulated"=>["Crawlspace Rim Joist", "CSRimJoist", "Crawlspace", "crawlspace"],
                "garage floor"=>["Garage", "GrndUninsUnfinGrgFloor", nil, "garage"],
                "garage roof"=>["Garage", "UnfinUninsExtGrgRoof", nil, "garage"],
                "garage wall"=>["Garage", "ExtUninsUnfinWall", nil, "garage"],
                "door"=>["Door", "LivingDoors", nil, "door"]}[build_dir]

    options = []
    @data.each do |material_row|
      if not category[2].nil?
        if category[2] == material_row[1]
          option = material_row[2].split("_")[1]
          if not options.include? option
            if ["wood stud wall uninsulated", "slab floor uninsulated", "crawlspace wall uninsulated", "crawlspace ceiling uninsulated", "crawlspace floor uninsulated", "crawlspace rim joist uninsulated"].include? build_dir
              if option.include? "Uninsulated"
                options << option
              end
            elsif ["crawlspace ceiling"].include? build_dir
              if option.include? "Ceiling"
                options << option
              end
            elsif ["crawlspace wall"].include? build_dir
              if option.include? "Wall"
                options << option
              end
            elsif ["other wall superinsulated"].include? build_dir
              if option.include? "Superinsulated"
                options << option
              end
            else
              if not option.include? "Uninsulated" and not option.include? "Superinsulated"
                options << option
              end
            end
          end
        end
      end
    end

    if ["garage floor"].include? build_dir
      options << "4 in Concrete Slab Floor"
    elsif ["garage roof"].include? build_dir
      options << "Uninsulated Unfinished Roof"
    elsif ["garage wall"].include? build_dir
      options << "Uninsulated Unfinished Wall"
    elsif ["door"].include? build_dir
      options << "Door"
    end

    options.each do |option|

      # make a model to hold everything
      model = OpenStudio::Model::Model.new

      # create the construction
      construction = OpenStudio::Model::Construction.new(model)
      construction.setName("#{category[1]}")

      fixed_layers.each_with_index do |mat_path,key|

        mat_object = create_mat_object(model, mat_path)

        construction.insertLayer(key,mat_object)

      end

      calc_layers.each do |key,value|

        mat_path = "#{value}_#{option}".gsub(" ","_").gsub("/","_").gsub("-","_").gsub("___","_").gsub("__","_").gsub("in.","in").gsub(",","").gsub('"',"_in").strip

        # tk need to figure out how to handle the massless objects

        mat_object = create_mat_object(model, mat_path)

        construction.insertLayer(key,mat_object)

      end

      # create the component
      option = option.gsub('"',"in").gsub("/","ith")
      comp_name = "#{category[0]} - #{option}"

      new_comp = BCL::Component.new("C:/OpenStudio/OS-BEopt/components/constructions/#{category[3]}")
      new_comp.name = "#{comp_name}"

      # look up uid for name (use old E+ name as key)
      uid_file, uid_hash = create_hash(category[3])
      previous_uid = uid_hash[option.downcase]
      if previous_uid
        new_comp.uid = previous_uid
      else
        uid_hash[option.downcase] = new_comp.uid
        save_uid_hash(category[3])
      end

      #add_tag(tag_name)
      new_comp.add_tag(tag)

      osversion = OpenStudio::Workspace.new.iddFile.version
      file_str = new_comp.resolve_path + "/#{new_comp.name}_v#{@osversion}.osm"
      model.save(OpenStudio::Path.new(file_str), true)
      #new_comp.add_file("OpenStudio", "#{@osversion}", file_str, "#{new_comp.name}_v#{@osversion}.osm", "osm")

      epversion = OpenStudio::Workspace.new("Draft".to_StrictnessLevel,"EnergyPlus".to_IddFileType).iddFile.version
      forward_translator = OpenStudio::EnergyPlus::ForwardTranslator.new
      new_workspace = forward_translator.translateModel(model)
      file_str = new_comp.resolve_path + "/#{new_comp.name}_v#{@epversion}.idf"
      new_workspace.save(OpenStudio::Path.new(file_str), true)
      #new_comp.add_file("EnergyPlus", "#{@epversion}", file_str, "#{new_comp.name}_v#{@epversion}.idf", "idf")

      file_str = new_comp.resolve_path + "/#{new_comp.name}_v#{@osversion}.osc"
      component = construction.createComponent
      component.save(OpenStudio::Path.new(file_str), true)
      #new_comp.add_file("OpenStudio", "#{@osversion}", file_str, "#{new_comp.name}_v#{@osversion}.osc", "osc")

      taxonomy.check_component(new_comp)

      #new_comp.save_tar_gz(false)

    end

  end

end

c = ConstructionFromMaterials.new

# instructions
# c.make("folder name", {layer=>"calculated_properties_layer", ...}, ["outside_layer", ...])

# walls
c.make("wood stud wall uninsulated", {2=>"StudandCavity"}, ["Exterior_Finish_Vinyl_Light", "Plywood_1_2in", "GypsumBoard_1_2in"], "Construction Assembly.Wall.Exterior Wall")
c.make("wood stud wall", {2=>"StudandCavity"}, ["Exterior_Finish_Vinyl_Light", "Plywood_1_2in", "GypsumBoard_1_2in"], "Construction Assembly.Wall.Exterior Wall")
c.make("double wood stud wall", {2=>"StudandCavity", 3=>"Cavity", 4=>"StudandCavity"}, ["Exterior_Finish_Vinyl_Light", "Plywood_1_2in", "GypsumBoard_1_2in"], "Construction Assembly.Wall.Exterior Wall")
c.make("cmu wall", {1=>"CMU", 2=>"Furring"}, ["Exterior_Finish_Vinyl_Light", "GypsumBoard_1_2in"], "Construction Assembly.Wall.Exterior Wall")
c.make("sip wall", {1=>"SplineLayer", 2=>"WallIns",3=>"SplineLayer", 4=>"IntSheathing"}, ["Exterior_Finish_Vinyl_Light", "GypsumBoard_1_2in"], "Construction Assembly.Wall.Exterior Wall")
c.make("icf wall", {1=>"ICFInsForm", 2=>"ICFConcrete", 3=>"ICFInsForm"}, ["Exterior_Finish_Vinyl_Light", "GypsumBoard_1_2in"], "Construction Assembly.Wall.Exterior Wall")
c.make("other wall", {1=>"Layer1", 2=>"Layer2", 3=>"Layer3"}, ["Exterior_Finish_Vinyl_Light", "GypsumBoard_1_2in"], "Construction Assembly.Wall.Exterior Wall")
c.make("other wall superinsulated", {1=>"Layer1"}, ["Exterior_Finish_Vinyl_Light", "GypsumBoard_1_2in"], "Construction Assembly.Wall.Exterior Wall")

# foundations/floors
c.make("slab floor uninsulated", {0=>"Mat-Fic-Slab"}, ["Soil_12in", "SlabMass", "SlabCarpetBareEquivalentMaterial_80%_Carpet"], "Construction Assembly.Floor.Exterior Slab")
c.make("slab floor", {0=>"Mat-Fic-Slab"}, ["Soil_12in", "SlabMass", "SlabCarpetBareEquivalentMaterial_80%_Carpet"], "Construction Assembly.Floor.Exterior Slab")
c.make("crawlspace wall uninsulated", {0=>"CWall_FicR"}, ["Soil_12in", "Concrete_8in"], "Construction Assembly.Wall.Exterior Wall")
c.make("crawlspace wall", {2=>"CWallIns"}, ["Soil_12in", "Concrete_8in"], "Construction Assembly.Wall.Exterior Wall")
c.make("crawlspace ceiling uninsulated", {0=>"CrawlCeilingIns"}, ["Plywood_3_4in", "Floor_Mass_Wood_Surface", "CarpetBareLayer_80%_Carpet"], "Construction Assembly.Floor.Exposed Floor")
c.make("crawlspace ceiling", {0=>"CrawlCeilingIns"}, ["Plywood_3_4in", "Floor_Mass_Wood_Surface", "CarpetBareLayer_80%_Carpet"], "Construction Assembly.Floor.Exposed Floor")
c.make("crawlspace floor uninsulated", {0=>"CFloor_FicR"}, ["Soil_12in"], "Construction Assembly.Floor.Exposed Floor")
c.make("crawlspace floor", {0=>"CFloor_FicR"}, ["Soil_12in"], "Construction Assembly.Floor.Exposed Floor")
c.make("crawlspace rim joist uninsulated", {2=>"CSJoistandCavity"}, ["Exterior_Finish_Vinyl_Light", "Plywood_3_2in"], "Construction Assembly.Wall.Exterior Wall")
c.make("crawlspace rim joist", {2=>"CSJoistandCavity"}, ["Exterior_Finish_Vinyl_Light", "Plywood_3_2in"], "Construction Assembly.Wall.Exterior Wall")

# ceilings/roofs

# garage
c.make("garage floor", {}, ["Adiabatic", "Soil_12in", "Concrete_4in"], "Construction Assembly.Floor.Exterior Slab")
c.make("garage roof", {}, ["Roofing_Material_Asphalt_Shingles_Medium", "Plywood_3_4in", "GrgRoofStudandAir"], "Construction Assembly.Roof Ceiling.Exterior Roof")
c.make("garage wall", {}, ["Exterior_Finish_Vinyl_Light", "Plywood_1_2in", "StudandAirWall"], "Construction Assembly.Wall.Exterior Wall")

# doors
c.make("door", {}, ["DoorMaterial"], "Construction Assembly.Fenestration.Door")
