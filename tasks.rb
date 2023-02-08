# frozen_string_literal: true

Dir["#{File.dirname(__FILE__)}/hpxml-measures/HPXMLtoOpenStudio/resources/*.rb"].each do |resource_file|
  next if resource_file.include? 'minitest_helper.rb'

  require resource_file
end

def create_test_hpxmls
  this_dir = File.dirname(__FILE__)
  tests_dir = File.join(this_dir, 'workflow/tests')

  # Copy ASHRAE 140 files
  FileUtils.rm_f(Dir.glob('workflow/tests/RESNET_Tests/4.1_Standard_140/*.xml'))
  FileUtils.cp(Dir.glob('hpxml-measures/workflow/tests/ASHRAE_Standard_140/*.xml'), 'workflow/tests/RESNET_Tests/4.1_Standard_140')

  # Hash of HPXML -> Parent HPXML
  hpxmls_files = {
    # These are read from OS-HPXML files
    'RESNET_Tests/4.1_Standard_140/L100AC.xml' => nil,
    'RESNET_Tests/4.1_Standard_140/L100AL.xml' => nil,
    'RESNET_Tests/4.1_Standard_140/L110AC.xml' => nil,
    'RESNET_Tests/4.1_Standard_140/L110AL.xml' => nil,
    'RESNET_Tests/4.1_Standard_140/L120AC.xml' => nil,
    'RESNET_Tests/4.1_Standard_140/L120AL.xml' => nil,
    'RESNET_Tests/4.1_Standard_140/L130AC.xml' => nil,
    'RESNET_Tests/4.1_Standard_140/L130AL.xml' => nil,
    'RESNET_Tests/4.1_Standard_140/L140AC.xml' => nil,
    'RESNET_Tests/4.1_Standard_140/L140AL.xml' => nil,
    'RESNET_Tests/4.1_Standard_140/L150AC.xml' => nil,
    'RESNET_Tests/4.1_Standard_140/L150AL.xml' => nil,
    'RESNET_Tests/4.1_Standard_140/L160AC.xml' => nil,
    'RESNET_Tests/4.1_Standard_140/L160AL.xml' => nil,
    'RESNET_Tests/4.1_Standard_140/L170AC.xml' => nil,
    'RESNET_Tests/4.1_Standard_140/L170AL.xml' => nil,
    'RESNET_Tests/4.1_Standard_140/L200AC.xml' => nil,
    'RESNET_Tests/4.1_Standard_140/L200AL.xml' => nil,
    'RESNET_Tests/4.1_Standard_140/L302XC.xml' => nil,
    'RESNET_Tests/4.1_Standard_140/L322XC.xml' => nil,
    'RESNET_Tests/4.1_Standard_140/L155AC.xml' => nil,
    'RESNET_Tests/4.1_Standard_140/L155AL.xml' => nil,
    'RESNET_Tests/4.1_Standard_140/L202AC.xml' => nil,
    'RESNET_Tests/4.1_Standard_140/L202AL.xml' => nil,
    'RESNET_Tests/4.1_Standard_140/L304XC.xml' => nil,
    'RESNET_Tests/4.1_Standard_140/L324XC.xml' => nil,

    # These are generated on the fly
    'EPA_Tests/SF_National_3.2/SFNHv32_CZ2_FL_gas_slab.xml' => nil,
    'EPA_Tests/SF_National_3.2/SFNHv32_CZ4_MO_gas_vented_crawl.xml' => nil,
    'EPA_Tests/SF_National_3.2/SFNHv32_CZ6_VT_elec_cond_bsmt.xml' => nil,
    'EPA_Tests/SF_National_3.1/SFNHv31_CZ2_FL_elec_slab.xml' => nil,
    'EPA_Tests/SF_National_3.1/SFNHv31_CZ4_MO_elec_vented_crawl.xml' => nil,
    'EPA_Tests/SF_National_3.1/SFNHv31_CZ6_VT_gas_cond_bsmt.xml' => nil,
    'EPA_Tests/SF_National_3.0/SFNHv3_CZ2_FL_gas_slab.xml' => nil,
    'EPA_Tests/SF_National_3.0/SFNHv3_CZ4_MO_gas_vented_crawl.xml' => nil,
    'EPA_Tests/SF_National_3.0/SFNHv3_CZ6_VT_elec_cond_bsmt.xml' => nil,
    'EPA_Tests/MF_National_1.2/MFNCv12_CZ2_FL_gas_ground_corner_slab.xml' => nil,
    'EPA_Tests/MF_National_1.2/MFNCv12_CZ4_MO_gas_top_corner.xml' => nil,
    'EPA_Tests/MF_National_1.2/MFNCv12_CZ6_VT_elec_middle_interior.xml' => nil,
    'EPA_Tests/MF_National_1.1/MFNCv11_CZ2_FL_elec_top_corner.xml' => nil,
    'EPA_Tests/MF_National_1.1/MFNCv11_CZ4_MO_elec_ground_corner_vented_crawl.xml' => nil,
    'EPA_Tests/MF_National_1.1/MFNCv11_CZ6_VT_gas_ground_corner_cond_bsmt.xml' => nil,
    'EPA_Tests/MF_National_1.0/MFNCv1_CZ2_FL_gas_ground_corner_slab.xml' => nil,
    'EPA_Tests/MF_National_1.0/MFNCv1_CZ4_MO_gas_top_corner.xml' => nil,
    'EPA_Tests/MF_National_1.0/MFNCv1_CZ6_VT_elec_middle_interior.xml' => nil,
    'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/01-L100.xml' => 'RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2019_PreAddendumA/01-L100.xml',
    'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/02-L100.xml' => 'RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2019_PreAddendumA/02-L100.xml',
    'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/03-L304.xml' => 'RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2019_PreAddendumA/03-L304.xml',
    'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/04-L324.xml' => 'RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2019_PreAddendumA/04-L324.xml',
    'RESNET_Tests/4.3_HERS_Method/L100A-01.xml' => 'RESNET_Tests/4.1_Standard_140/L100AC.xml',
    'RESNET_Tests/4.3_HERS_Method/L100A-02.xml' => 'RESNET_Tests/4.3_HERS_Method/L100A-01.xml',
    'RESNET_Tests/4.3_HERS_Method/L100A-03.xml' => 'RESNET_Tests/4.3_HERS_Method/L100A-01.xml',
    'RESNET_Tests/4.3_HERS_Method/L100A-04.xml' => 'RESNET_Tests/4.3_HERS_Method/L100A-01.xml',
    'RESNET_Tests/4.3_HERS_Method/L100A-05.xml' => 'RESNET_Tests/4.3_HERS_Method/L100A-01.xml',
    'RESNET_Tests/4.4_HVAC/HVAC1a.xml' => 'RESNET_Tests/4.1_Standard_140/L100AL.xml',
    'RESNET_Tests/4.4_HVAC/HVAC1b.xml' => 'RESNET_Tests/4.4_HVAC/HVAC1a.xml',
    'RESNET_Tests/4.4_HVAC/HVAC2a.xml' => 'RESNET_Tests/4.1_Standard_140/L100AC.xml',
    'RESNET_Tests/4.4_HVAC/HVAC2b.xml' => 'RESNET_Tests/4.4_HVAC/HVAC2a.xml',
    'RESNET_Tests/4.4_HVAC/HVAC2c.xml' => 'RESNET_Tests/4.4_HVAC/HVAC2a.xml',
    'RESNET_Tests/4.4_HVAC/HVAC2d.xml' => 'RESNET_Tests/4.4_HVAC/HVAC2a.xml',
    'RESNET_Tests/4.4_HVAC/HVAC2e.xml' => 'RESNET_Tests/4.4_HVAC/HVAC2a.xml',
    'RESNET_Tests/4.5_DSE/HVAC3a.xml' => 'RESNET_Tests/4.1_Standard_140/L322XC.xml',
    'RESNET_Tests/4.5_DSE/HVAC3b.xml' => 'RESNET_Tests/4.5_DSE/HVAC3a.xml',
    'RESNET_Tests/4.5_DSE/HVAC3c.xml' => 'RESNET_Tests/4.5_DSE/HVAC3b.xml',
    'RESNET_Tests/4.5_DSE/HVAC3d.xml' => 'RESNET_Tests/4.5_DSE/HVAC3c.xml',
    'RESNET_Tests/4.5_DSE/HVAC3e.xml' => 'RESNET_Tests/4.1_Standard_140/L100AL.xml',
    'RESNET_Tests/4.5_DSE/HVAC3f.xml' => 'RESNET_Tests/4.5_DSE/HVAC3e.xml',
    'RESNET_Tests/4.5_DSE/HVAC3g.xml' => 'RESNET_Tests/4.5_DSE/HVAC3f.xml',
    'RESNET_Tests/4.5_DSE/HVAC3h.xml' => 'RESNET_Tests/4.5_DSE/HVAC3g.xml',
    'RESNET_Tests/4.6_Hot_Water/L100AD-HW-01.xml' => 'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AD-HW-01.xml',
    'RESNET_Tests/4.6_Hot_Water/L100AD-HW-02.xml' => 'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AD-HW-02.xml',
    'RESNET_Tests/4.6_Hot_Water/L100AD-HW-03.xml' => 'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AD-HW-03.xml',
    'RESNET_Tests/4.6_Hot_Water/L100AD-HW-04.xml' => 'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AD-HW-04.xml',
    'RESNET_Tests/4.6_Hot_Water/L100AD-HW-05.xml' => 'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AD-HW-05.xml',
    'RESNET_Tests/4.6_Hot_Water/L100AD-HW-06.xml' => 'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AD-HW-06.xml',
    'RESNET_Tests/4.6_Hot_Water/L100AD-HW-07.xml' => 'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AD-HW-07.xml',
    'RESNET_Tests/4.6_Hot_Water/L100AM-HW-01.xml' => 'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AM-HW-01.xml',
    'RESNET_Tests/4.6_Hot_Water/L100AM-HW-02.xml' => 'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AM-HW-02.xml',
    'RESNET_Tests/4.6_Hot_Water/L100AM-HW-03.xml' => 'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AM-HW-03.xml',
    'RESNET_Tests/4.6_Hot_Water/L100AM-HW-04.xml' => 'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AM-HW-04.xml',
    'RESNET_Tests/4.6_Hot_Water/L100AM-HW-05.xml' => 'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AM-HW-05.xml',
    'RESNET_Tests/4.6_Hot_Water/L100AM-HW-06.xml' => 'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AM-HW-06.xml',
    'RESNET_Tests/4.6_Hot_Water/L100AM-HW-07.xml' => 'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AM-HW-07.xml',
    'RESNET_Tests/Other_HERS_AutoGen_IAD_Home/01-L100.xml' => 'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/01-L100.xml',
    'RESNET_Tests/Other_HERS_AutoGen_IAD_Home/02-L100.xml' => 'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/02-L100.xml',
    'RESNET_Tests/Other_HERS_AutoGen_IAD_Home/03-L304.xml' => 'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/03-L304.xml',
    'RESNET_Tests/Other_HERS_AutoGen_IAD_Home/04-L324.xml' => 'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/04-L324.xml',
    'RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2019_PreAddendumA/01-L100.xml' => 'RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/01-L100.xml',
    'RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2019_PreAddendumA/02-L100.xml' => 'RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/02-L100.xml',
    'RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2019_PreAddendumA/03-L304.xml' => 'RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/03-L304.xml',
    'RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2019_PreAddendumA/04-L324.xml' => 'RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/04-L324.xml',
    'RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/01-L100.xml' => 'RESNET_Tests/4.1_Standard_140/L100AC.xml',
    'RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/02-L100.xml' => 'RESNET_Tests/4.1_Standard_140/L100AC.xml',
    'RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/03-L304.xml' => 'RESNET_Tests/4.1_Standard_140/L304XC.xml',
    'RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/04-L324.xml' => 'RESNET_Tests/4.1_Standard_140/L324XC.xml',
    'RESNET_Tests/Other_HERS_Method_301_2014_PreAddendumE/L100A-01.xml' => 'RESNET_Tests/4.3_HERS_Method/L100A-01.xml',
    'RESNET_Tests/Other_HERS_Method_301_2014_PreAddendumE/L100A-02.xml' => 'RESNET_Tests/4.3_HERS_Method/L100A-02.xml',
    'RESNET_Tests/Other_HERS_Method_301_2014_PreAddendumE/L100A-03.xml' => 'RESNET_Tests/4.3_HERS_Method/L100A-03.xml',
    'RESNET_Tests/Other_HERS_Method_301_2014_PreAddendumE/L100A-04.xml' => 'RESNET_Tests/4.3_HERS_Method/L100A-04.xml',
    'RESNET_Tests/Other_HERS_Method_301_2014_PreAddendumE/L100A-05.xml' => 'RESNET_Tests/4.3_HERS_Method/L100A-05.xml',
    'RESNET_Tests/Other_HERS_Method_301_2019_PreAddendumA/L100A-01.xml' => 'RESNET_Tests/4.3_HERS_Method/L100A-01.xml',
    'RESNET_Tests/Other_HERS_Method_301_2019_PreAddendumA/L100A-02.xml' => 'RESNET_Tests/4.3_HERS_Method/L100A-02.xml',
    'RESNET_Tests/Other_HERS_Method_301_2019_PreAddendumA/L100A-03.xml' => 'RESNET_Tests/4.3_HERS_Method/L100A-03.xml',
    'RESNET_Tests/Other_HERS_Method_301_2019_PreAddendumA/L100A-04.xml' => 'RESNET_Tests/4.3_HERS_Method/L100A-04.xml',
    'RESNET_Tests/Other_HERS_Method_301_2019_PreAddendumA/L100A-05.xml' => 'RESNET_Tests/4.3_HERS_Method/L100A-05.xml',
    'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AD-HW-01.xml' => 'RESNET_Tests/4.1_Standard_140/L100AC.xml',
    'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AD-HW-02.xml' => 'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AD-HW-01.xml',
    'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AD-HW-03.xml' => 'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AD-HW-01.xml',
    'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AD-HW-04.xml' => 'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AD-HW-02.xml',
    'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AD-HW-05.xml' => 'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AD-HW-02.xml',
    'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AD-HW-06.xml' => 'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AD-HW-05.xml',
    'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AD-HW-07.xml' => 'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AD-HW-02.xml',
    'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AM-HW-01.xml' => 'RESNET_Tests/4.1_Standard_140/L100AC.xml',
    'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AM-HW-02.xml' => 'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AM-HW-01.xml',
    'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AM-HW-03.xml' => 'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AM-HW-01.xml',
    'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AM-HW-04.xml' => 'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AM-HW-02.xml',
    'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AM-HW-05.xml' => 'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AM-HW-02.xml',
    'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AM-HW-06.xml' => 'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AM-HW-05.xml',
    'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AM-HW-07.xml' => 'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AM-HW-02.xml',
    'RESNET_Tests/Other_Hot_Water_301_2014_PreAddendumA/L100AD-HW-01.xml' => 'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AD-HW-01.xml',
    'RESNET_Tests/Other_Hot_Water_301_2014_PreAddendumA/L100AD-HW-02.xml' => 'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AD-HW-02.xml',
    'RESNET_Tests/Other_Hot_Water_301_2014_PreAddendumA/L100AD-HW-03.xml' => 'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AD-HW-03.xml',
    'RESNET_Tests/Other_Hot_Water_301_2014_PreAddendumA/L100AM-HW-01.xml' => 'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AM-HW-01.xml',
    'RESNET_Tests/Other_Hot_Water_301_2014_PreAddendumA/L100AM-HW-02.xml' => 'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AM-HW-02.xml',
    'RESNET_Tests/Other_Hot_Water_301_2014_PreAddendumA/L100AM-HW-03.xml' => 'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AM-HW-03.xml',
  }

  puts "Generating #{hpxmls_files.size} HPXML files..."

  hpxmls_files.each do |derivative, orig_parent|
    print '.'

    begin
      hpxml_files = [derivative]
      parent = orig_parent
      unless parent.nil?
        hpxml_files.unshift(parent)
      end
      while not parent.nil?
        next unless hpxmls_files.keys.include? parent

        unless hpxmls_files[parent].nil?
          hpxml_files.unshift(hpxmls_files[parent])
        end
        parent = hpxmls_files[parent]
      end

      hpxml = HPXML.new
      hpxml_files.each do |hpxml_file|
        if hpxml_file.include? 'RESNET_Tests/4.1_Standard_140'
          hpxml = HPXML.new(hpxml_path: File.join(tests_dir, hpxml_file), collapse_enclosure: false)
          next
        end
        set_hpxml_header(hpxml_file, hpxml, orig_parent)
        set_hpxml_site(hpxml_file, hpxml)
        set_hpxml_building_construction(hpxml_file, hpxml)
        set_hpxml_building_occupancy(hpxml_file, hpxml)
        set_hpxml_climate_and_risk_zones(hpxml_file, hpxml)
        set_hpxml_attics(hpxml_file, hpxml)
        set_hpxml_foundations(hpxml_file, hpxml)
        set_hpxml_roofs(hpxml_file, hpxml)
        set_hpxml_rim_joists(hpxml_file, hpxml)
        set_hpxml_walls(hpxml_file, hpxml)
        set_hpxml_foundation_walls(hpxml_file, hpxml)
        set_hpxml_floors(hpxml_file, hpxml)
        set_hpxml_slabs(hpxml_file, hpxml)
        set_hpxml_windows(hpxml_file, hpxml)
        set_hpxml_doors(hpxml_file, hpxml)
        set_hpxml_air_infiltration_measurements(hpxml_file, hpxml)
        set_hpxml_heating_systems(hpxml_file, hpxml)
        set_hpxml_cooling_systems(hpxml_file, hpxml)
        set_hpxml_heat_pumps(hpxml_file, hpxml)
        set_hpxml_hvac_controls(hpxml_file, hpxml)
        set_hpxml_hvac_distributions(hpxml_file, hpxml)
        set_hpxml_ventilation_fans(hpxml_file, hpxml)
        set_hpxml_water_heating_systems(hpxml_file, hpxml)
        set_hpxml_hot_water_distribution(hpxml_file, hpxml)
        set_hpxml_water_fixtures(hpxml_file, hpxml)
        set_hpxml_clothes_washer(hpxml_file, hpxml)
        set_hpxml_clothes_dryer(hpxml_file, hpxml)
        set_hpxml_dishwasher(hpxml_file, hpxml)
        set_hpxml_refrigerator(hpxml_file, hpxml)
        set_hpxml_cooking_range(hpxml_file, hpxml)
        set_hpxml_oven(hpxml_file, hpxml)
        set_hpxml_lighting(hpxml_file, hpxml)
        set_hpxml_plug_loads(hpxml_file, hpxml)
      end

      next if derivative.include? 'RESNET_Tests/4.1_Standard_140'

      hpxml_doc = hpxml.to_oga()

      hpxml_path = File.join(tests_dir, derivative)

      FileUtils.mkdir_p(File.dirname(hpxml_path))
      XMLHelper.write_file(hpxml_doc, hpxml_path)

      # Validate file against HPXML schema
      xsd_path = File.join(File.dirname(__FILE__), 'hpxml-measures', 'HPXMLtoOpenStudio', 'resources', 'hpxml_schema', 'HPXML.xsd')
      errors, _ = XMLValidator.validate_against_schema(hpxml_path, xsd_path)
      if errors.size > 0
        fail errors.to_s
      end

      # Check for additional errors
      errors = hpxml.check_for_errors()
      if errors.size > 0
        fail "ERRORS: #{errors}"
      end
    rescue Exception => e
      puts "\n#{e}\n#{e.backtrace.join('\n')}"
      puts "\nError: Did not successfully generate #{derivative}."
      exit!
    end
  end

  puts "\n"

  # Print warnings about extra files
  abs_hpxml_files = []
  dirs = [nil]
  hpxmls_files.keys.each do |hpxml_file|
    abs_hpxml_files << File.absolute_path(File.join(tests_dir, hpxml_file))
    next unless hpxml_file.include? '/'

    dirs << hpxml_file.split('/')[0] + '/'
  end
  dirs.uniq.each do |dir|
    Dir["#{tests_dir}/#{dir}*.xml"].each do |xml|
      next if abs_hpxml_files.include? File.absolute_path(xml)

      puts "Warning: Extra HPXML file found at #{File.absolute_path(xml)}"
    end
  end
end

def get_standard_140_hpxml(hpxml_path)
  hpxml = HPXML.new(hpxml_path: hpxml_path, collapse_enclosure: false)

  return hpxml
end

def set_hpxml_header(hpxml_file, hpxml, orig_parent)
  if hpxml_file.include?('HERS_AutoGen') || hpxml_file.include?('HERS_Method') || hpxml_file.include?('Hot_Water')
    hpxml.header.apply_ashrae140_assumptions = nil
  end
  if hpxml_file.include?('RESNET_Tests/Other_Hot_Water_301_2014_PreAddendumA')
    hpxml.header.eri_calculation_version = '2014'
  elsif hpxml_file.include?('RESNET_Tests/Other_HERS_Method_301_2014_PreAddendumE') ||
        hpxml_file.include?('RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014')
    hpxml.header.eri_calculation_version = '2014A'
  elsif hpxml_file.include?('RESNET_Tests/Other_HERS_Method_301_2019_PreAddendumA') ||
        hpxml_file.include?('RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2019_PreAddendumA') ||
        hpxml_file.include?('RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA')
    hpxml.header.eri_calculation_version = '2019'
  elsif hpxml_file.include?('HERS_AutoGen') || hpxml_file.include?('HERS_Method') || hpxml_file.include?('Hot_Water')
    hpxml.header.eri_calculation_version = 'latest'
  elsif hpxml_file.include?('EPA_Tests')
    hpxml.header.xml_type = 'HPXML'
    hpxml.header.xml_generated_by = 'tasks.rb'
    hpxml.header.transaction = 'create'
    hpxml.header.building_id = 'MyBuilding'
    hpxml.header.event_type = 'proposed workscope'
    hpxml.header.created_date_and_time = Time.new(2000, 1, 1, 0, 0, 0, '-07:00').strftime('%Y-%m-%dT%H:%M:%S%:z') # Hard-code to prevent diffs
    if hpxml_file.include?('SF_National_3.2')
      hpxml.header.energystar_calculation_version = ESConstants.SFNationalVer3_2
    elsif hpxml_file.include?('SF_National_3.1')
      hpxml.header.energystar_calculation_version = ESConstants.SFNationalVer3_1
    elsif hpxml_file.include?('SF_National_3.0')
      hpxml.header.energystar_calculation_version = ESConstants.SFNationalVer3_0
    elsif hpxml_file.include?('MF_National_1.2')
      hpxml.header.energystar_calculation_version = ESConstants.MFNationalVer1_2
    elsif hpxml_file.include?('MF_National_1.1')
      hpxml.header.energystar_calculation_version = ESConstants.MFNationalVer1_1
    elsif hpxml_file.include?('MF_National_1.0')
      hpxml.header.energystar_calculation_version = ESConstants.MFNationalVer1_0
    end
    hpxml.header.state_code = File.basename(hpxml_file)[11..12]
  end
  hpxml.header.zip_code = '00000'
  if not orig_parent.nil?
    hpxml.header.extension_properties['ParentHPXMLFile'] = File.basename(orig_parent)
  end
end

def set_hpxml_site(hpxml_file, hpxml)
  if hpxml_file.include?('EPA_Tests')
    if hpxml_file.include?('elec')
      hpxml.site.fuels = [HPXML::FuelTypeElectricity]
    else
      hpxml.site.fuels = [HPXML::FuelTypeElectricity, HPXML::FuelTypeNaturalGas]
    end
  elsif hpxml_file.include?('HERS_AutoGen') || hpxml_file.include?('HERS_Method') || hpxml_file.include?('Hot_Water')
    hpxml.site.fuels = [HPXML::FuelTypeElectricity, HPXML::FuelTypeNaturalGas]
  end
end

def set_hpxml_building_construction(hpxml_file, hpxml)
  hpxml.building_construction.conditioned_building_volume = nil
  if ['RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/03-L304.xml',
      'RESNET_Tests/4.3_HERS_Method/L100A-03.xml',
      'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AD-HW-01.xml',
      'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AM-HW-01.xml'].include? hpxml_file
    # 2 bedrooms
    hpxml.building_construction.number_of_bedrooms = 2
  elsif ['RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/04-L324.xml',
         'RESNET_Tests/4.3_HERS_Method/L100A-04.xml',
         'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AD-HW-02.xml',
         'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AM-HW-02.xml'].include? hpxml_file
    # 4 bedrooms
    hpxml.building_construction.number_of_bedrooms = 4
  elsif ['RESNET_Tests/4.5_DSE/HVAC3a.xml'].include? hpxml_file
    # Unconditioned basement
    hpxml.building_construction.number_of_conditioned_floors = 1
    hpxml.building_construction.conditioned_floor_area = 1539
  elsif hpxml_file.include?('EPA_Tests')
    if hpxml_file.include?('SF')
      hpxml.building_construction.residential_facility_type = HPXML::ResidentialTypeSFD
      hpxml.building_construction.number_of_conditioned_floors = 2
      hpxml.building_construction.number_of_conditioned_floors_above_grade = 2
      hpxml.building_construction.number_of_bedrooms = 3
      hpxml.building_construction.conditioned_floor_area = 2376
    elsif hpxml_file.include?('MF')
      hpxml.building_construction.residential_facility_type = HPXML::ResidentialTypeApartment
      hpxml.building_construction.number_of_conditioned_floors = 1
      hpxml.building_construction.number_of_conditioned_floors_above_grade = 1
      hpxml.building_construction.number_of_bedrooms = 2
      hpxml.building_construction.conditioned_floor_area = 1200
    end
    if hpxml_file.include?('cond_bsmt')
      footprint_area = (hpxml.building_construction.conditioned_floor_area / hpxml.building_construction.number_of_conditioned_floors)
      hpxml.building_construction.number_of_conditioned_floors += 1
      hpxml.building_construction.conditioned_floor_area += footprint_area
    end
  end
end

def set_hpxml_building_occupancy(hpxml_file, hpxml)
  if hpxml_file.include?('HERS_AutoGen') || hpxml_file.include?('HERS_Method') || hpxml_file.include?('Hot_Water')
    hpxml.building_occupancy.number_of_residents = nil
  end
end

def set_hpxml_climate_and_risk_zones(hpxml_file, hpxml)
  if ['RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/01-L100.xml'].include? hpxml_file
    # Baltimore
    hpxml.climate_and_risk_zones.climate_zone_ieccs.clear
    hpxml.climate_and_risk_zones.climate_zone_ieccs.add(year: 2006,
                                                        zone: '4A')
    hpxml.climate_and_risk_zones.weather_station_id = 'WeatherStation'
    hpxml.climate_and_risk_zones.weather_station_name = 'Baltimore, MD'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_MD_Baltimore-Washington.Intl.AP.724060_TMY3.epw'
    hpxml.header.state_code = 'MD'
  elsif ['RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/02-L100.xml'].include? hpxml_file
    # Dallas
    hpxml.climate_and_risk_zones.climate_zone_ieccs.clear
    hpxml.climate_and_risk_zones.climate_zone_ieccs.add(year: 2006,
                                                        zone: '3A')
    hpxml.climate_and_risk_zones.weather_station_id = 'WeatherStation'
    hpxml.climate_and_risk_zones.weather_station_name = 'Dallas, TX'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_TX_Dallas-Fort.Worth.Intl.AP.722590_TMY3.epw'
    hpxml.header.state_code = 'TX'
  elsif ['RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/03-L304.xml',
         'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AM-HW-01.xml'].include? hpxml_file
    # Miami
    hpxml.climate_and_risk_zones.climate_zone_ieccs.clear
    hpxml.climate_and_risk_zones.climate_zone_ieccs.add(year: 2006,
                                                        zone: '1A')
    hpxml.climate_and_risk_zones.weather_station_id = 'WeatherStation'
    hpxml.climate_and_risk_zones.weather_station_name = 'Miami, FL'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_FL_Miami.Intl.AP.722020_TMY3.epw'
    hpxml.header.state_code = 'FL'
  elsif ['RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AD-HW-01.xml'].include? hpxml_file
    # Duluth
    hpxml.climate_and_risk_zones.climate_zone_ieccs.clear
    hpxml.climate_and_risk_zones.climate_zone_ieccs.add(year: 2006,
                                                        zone: '7')
    hpxml.climate_and_risk_zones.weather_station_id = 'WeatherStation'
    hpxml.climate_and_risk_zones.weather_station_name = 'Duluth, MN'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_MN_Duluth.Intl.AP.727450_TMY3.epw'
    hpxml.header.state_code = 'MN'
  elsif hpxml_file.include?('HERS_AutoGen') || hpxml_file.include?('HERS_Method') || hpxml_file.include?('Hot_Water')
    if hpxml.climate_and_risk_zones.weather_station_epw_filepath == 'USA_CO_Colorado.Springs-Peterson.Field.724660_TMY3.epw'
      hpxml.climate_and_risk_zones.climate_zone_ieccs.clear
      hpxml.climate_and_risk_zones.climate_zone_ieccs.add(year: 2006,
                                                          zone: '5B')
      hpxml.header.state_code = 'CO'
    end
  elsif hpxml_file.include?('EPA_Tests')
    hpxml.climate_and_risk_zones.weather_station_id = 'WeatherStation'
    years = [2006]
    if hpxml_file.include?('SF_National_3.2') || hpxml_file.include?('MF_National_1.2')
      years << 2021
    end
    if hpxml_file.include?('CZ2')
      hpxml.climate_and_risk_zones.climate_zone_ieccs.clear
      years.each do |year|
        hpxml.climate_and_risk_zones.climate_zone_ieccs.add(year: year,
                                                            zone: '2A')
      end
      hpxml.climate_and_risk_zones.weather_station_name = 'Tampa, FL'
      hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_FL_Tampa.Intl.AP.722110_TMY3.epw'
      hpxml.header.state_code = 'FL'
    elsif hpxml_file.include?('CZ4')
      hpxml.climate_and_risk_zones.climate_zone_ieccs.clear
      years.each do |year|
        hpxml.climate_and_risk_zones.climate_zone_ieccs.add(year: year,
                                                            zone: '4A')
      end
      hpxml.climate_and_risk_zones.weather_station_name = 'St Louis, MO'
      hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_MO_St.Louis-Lambert.Intl.AP.724340_TMY3.epw'
      hpxml.header.state_code = 'MO'
    elsif hpxml_file.include?('CZ6')
      hpxml.climate_and_risk_zones.climate_zone_ieccs.clear
      years.each do |year|
        hpxml.climate_and_risk_zones.climate_zone_ieccs.add(year: year,
                                                            zone: '6A')
      end
      hpxml.climate_and_risk_zones.weather_station_name = 'Burlington, VT'
      hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_VT_Burlington.Intl.AP.726170_TMY3.epw'
      hpxml.header.state_code = 'VT'
    end
  end
end

def set_hpxml_air_infiltration_measurements(hpxml_file, hpxml)
  if hpxml_file.include?('Hot_Water') ||
     ['RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2019_PreAddendumA/01-L100.xml',
      'RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2019_PreAddendumA/02-L100.xml',
      'RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2019_PreAddendumA/04-L324.xml'].include?(hpxml_file)
    # 3 ACH50
    hpxml.air_infiltration_measurements.clear
    hpxml.air_infiltration_measurements.add(id: "AirInfiltrationMeasurement#{hpxml.air_infiltration_measurements.size + 1}",
                                            house_pressure: 50,
                                            unit_of_measure: HPXML::UnitsACH,
                                            air_leakage: 3,
                                            infiltration_volume: hpxml.building_construction.conditioned_floor_area * 8.0)
  elsif ['RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2019_PreAddendumA/03-L304.xml'].include? hpxml_file
    # 5 ACH50
    hpxml.air_infiltration_measurements.clear
    hpxml.air_infiltration_measurements.add(id: "AirInfiltrationMeasurement#{hpxml.air_infiltration_measurements.size + 1}",
                                            unit_of_measure: HPXML::UnitsACH,
                                            house_pressure: 50,
                                            air_leakage: 5,
                                            infiltration_volume: hpxml.building_construction.conditioned_floor_area * 8.0)
  elsif ['RESNET_Tests/4.5_DSE/HVAC3a.xml'].include? hpxml_file
    hpxml.air_infiltration_measurements[0].infiltration_volume = 12312
    hpxml.air_infiltration_measurements[0].air_leakage = 0.67
  elsif hpxml_file.include?('EPA_Tests/SF')
    if ['EPA_Tests/SF_National_3.0/SFNHv3_CZ4_MO_gas_vented_crawl.xml'].include? hpxml_file
      ach50 = 5
    elsif ['EPA_Tests/SF_National_3.0/SFNHv3_CZ2_FL_gas_slab.xml'].include? hpxml_file
      ach50 = 6
    elsif ['EPA_Tests/SF_National_3.1/SFNHv31_CZ2_FL_elec_slab.xml',
           'EPA_Tests/SF_National_3.0/SFNHv3_CZ6_VT_elec_cond_bsmt.xml'].include? hpxml_file
      ach50 = 4
    elsif ['EPA_Tests/SF_National_3.1/SFNHv31_CZ4_MO_elec_vented_crawl.xml',
           'EPA_Tests/SF_National_3.1/SFNHv31_CZ6_VT_gas_cond_bsmt.xml',
           'EPA_Tests/SF_National_3.2/SFNHv32_CZ2_FL_gas_slab.xml',
           'EPA_Tests/SF_National_3.2/SFNHv32_CZ4_MO_gas_vented_crawl.xml',
           'EPA_Tests/SF_National_3.2/SFNHv32_CZ6_VT_elec_cond_bsmt.xml',].include? hpxml_file
      ach50 = 3
    end
    hpxml.air_infiltration_measurements.clear
    hpxml.air_infiltration_measurements.add(id: "AirInfiltrationMeasurement#{hpxml.air_infiltration_measurements.size + 1}",
                                            unit_of_measure: HPXML::UnitsACH,
                                            house_pressure: 50,
                                            air_leakage: ach50,
                                            infiltration_volume: hpxml.building_construction.conditioned_floor_area * 8.5)
  elsif hpxml_file.include?('EPA_Tests/MF')
    tot_cb_area, _ext_cb_area = hpxml.compartmentalization_boundary_areas()
    hpxml.air_infiltration_measurements.clear
    hpxml.air_infiltration_measurements.add(id: "AirInfiltrationMeasurement#{hpxml.air_infiltration_measurements.size + 1}",
                                            unit_of_measure: HPXML::UnitsCFM,
                                            house_pressure: 50,
                                            air_leakage: (0.3 * tot_cb_area).round(3),
                                            infiltration_volume: hpxml.building_construction.conditioned_floor_area * 8.5)
  end
end

def set_hpxml_attics(hpxml_file, hpxml)
  if hpxml_file.include?('EPA_Tests/SF') || hpxml_file.include?('top_corner')
    hpxml.attics.clear
    hpxml.attics.add(id: "Attic#{hpxml.attics.size + 1}",
                     attic_type: HPXML::AtticTypeVented,
                     vented_attic_sla: (1.0 / 300.0).round(6))
  elsif hpxml_file.include?('HERS_AutoGen') || hpxml_file.include?('HERS_Method') || hpxml_file.include?('Hot_Water')
    hpxml.attics.clear
    hpxml.attics.add(id: "Attic#{hpxml.attics.size + 1}",
                     attic_type: HPXML::AtticTypeVented,
                     vented_attic_sla: (1.0 / 300.0).round(6))
  end
end

def set_hpxml_foundations(hpxml_file, hpxml)
  if ['RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/02-L100.xml'].include? hpxml_file
    hpxml.foundations.clear
    hpxml.foundations.add(id: "Foundation#{hpxml.foundations.size + 1}",
                          foundation_type: HPXML::FoundationTypeCrawlspaceUnvented,
                          within_infiltration_volume: false)
  elsif hpxml_file.include?('vented_crawl')
    hpxml.foundations.clear
    hpxml.foundations.add(id: "Foundation#{hpxml.foundations.size + 1}",
                          foundation_type: HPXML::FoundationTypeCrawlspaceVented,
                          vented_crawlspace_sla: (1.0 / 150.0).round(6))
  end
end

def set_hpxml_roofs(hpxml_file, hpxml)
  if hpxml_file.include?('EPA_Tests')
    rb_grade = nil
    if ['EPA_Tests/SF_National_3.0/SFNHv3_CZ2_FL_gas_slab.xml'].include? hpxml_file
      rb_grade = 1
    elsif hpxml_file.include?('ground_corner') || hpxml_file.include?('middle_interior')
      return
    end
    if hpxml_file.include?('EPA_Tests/SF')
      area = 1485
    elsif hpxml_file.include?('EPA_Tests/MF')
      area = 1500
    end
    hpxml.roofs.clear
    hpxml.roofs.add(id: "Roof#{hpxml.roofs.size + 1}",
                    interior_adjacent_to: HPXML::LocationAtticVented,
                    area: area,
                    solar_absorptance: 0.92,
                    emittance: 0.9,
                    pitch: 9,
                    radiant_barrier: !rb_grade.nil?,
                    radiant_barrier_grade: rb_grade,
                    insulation_assembly_r_value: 1.99)
  end
end

def set_hpxml_rim_joists(hpxml_file, hpxml)
  if ['RESNET_Tests/4.5_DSE/HVAC3a.xml'].include? hpxml_file
    for i in 0..hpxml.rim_joists.size - 1
      hpxml.rim_joists[i].interior_adjacent_to = HPXML::LocationBasementUnconditioned
    end
  elsif hpxml_file.include?('EPA_Tests/SF')
    if ['EPA_Tests/SF_National_3.1/SFNHv31_CZ2_FL_elec_slab.xml',
        'EPA_Tests/SF_National_3.0/SFNHv3_CZ2_FL_gas_slab.xml',
        'EPA_Tests/SF_National_3.0/SFNHv3_CZ4_MO_gas_vented_crawl.xml'].include? hpxml_file
      assembly_r = (1.0 / 0.082).round(3)
    elsif ['EPA_Tests/SF_National_3.1/SFNHv31_CZ4_MO_elec_vented_crawl.xml',
           'EPA_Tests/SF_National_3.0/SFNHv3_CZ6_VT_elec_cond_bsmt.xml'].include? hpxml_file
      assembly_r = (1.0 / 0.057).round(3)
    elsif ['EPA_Tests/SF_National_3.1/SFNHv31_CZ6_VT_gas_cond_bsmt.xml'].include? hpxml_file
      assembly_r = (1.0 / 0.048).round(3)
    elsif ['EPA_Tests/SF_National_3.2/SFNHv32_CZ2_FL_gas_slab.xml'].include? hpxml_file
      assembly_r = (1.0 / 0.084).round(3)
    elsif ['EPA_Tests/SF_National_3.2/SFNHv32_CZ4_MO_gas_vented_crawl.xml',
           'EPA_Tests/SF_National_3.2/SFNHv32_CZ6_VT_elec_cond_bsmt.xml'].include? hpxml_file
      assembly_r = (1.0 / 0.045).round(3)
    end
    hpxml.rim_joists.clear
    hpxml.rim_joists.add(id: "RimJoist#{hpxml.rim_joists.size + 1}",
                         exterior_adjacent_to: HPXML::LocationOutside,
                         interior_adjacent_to: HPXML::LocationLivingSpace,
                         area: 152,
                         solar_absorptance: 0.75,
                         emittance: 0.9,
                         insulation_assembly_r_value: assembly_r)
    if hpxml_file.include?('cond_bsmt')
      interior_adjacent_to = HPXML::LocationBasementConditioned
    elsif hpxml_file.include?('vented_crawl')
      interior_adjacent_to = HPXML::LocationCrawlspaceVented
      assembly_r = 4.0
    elsif hpxml_file.include?('slab')
      interior_adjacent_to = nil
    end
    if not interior_adjacent_to.nil?
      hpxml.rim_joists.add(id: "RimJoist#{hpxml.rim_joists.size + 1}",
                           exterior_adjacent_to: HPXML::LocationOutside,
                           interior_adjacent_to: interior_adjacent_to,
                           area: 152,
                           solar_absorptance: 0.75,
                           emittance: 0.9,
                           insulation_assembly_r_value: assembly_r)
    end
  elsif hpxml_file.include?('EPA_Tests/MF')
    if ['EPA_Tests/MF_National_1.0/MFNCv1_CZ2_FL_gas_ground_corner_slab.xml',
        'EPA_Tests/MF_National_1.0/MFNCv1_CZ4_MO_gas_top_corner.xml'].include? hpxml_file
      assembly_r = (1.0 / 0.089).round(3)
    elsif ['EPA_Tests/MF_National_1.1/MFNCv11_CZ4_MO_elec_ground_corner_vented_crawl.xml',
           'EPA_Tests/MF_National_1.1/MFNCv11_CZ2_FL_elec_top_corner.xml'].include? hpxml_file
      assembly_r = (1.0 / 0.064).round(3)
    elsif ['EPA_Tests/MF_National_1.1/MFNCv11_CZ6_VT_gas_ground_corner_cond_bsmt.xml',
           'EPA_Tests/MF_National_1.0/MFNCv1_CZ6_VT_elec_middle_interior.xml'].include? hpxml_file
      assembly_r = (1.0 / 0.051).round(3)
    elsif ['EPA_Tests/MF_National_1.2/MFNCv12_CZ2_FL_gas_ground_corner_slab.xml'].include? hpxml_file
      assembly_r = (1.0 / 0.084).round(3)
    elsif ['EPA_Tests/MF_National_1.2/MFNCv12_CZ4_MO_gas_top_corner.xml',
           'EPA_Tests/MF_National_1.2/MFNCv12_CZ6_VT_elec_middle_interior.xml'].include? hpxml_file
      assembly_r = (1.0 / 0.045).round(3)
    end
    if hpxml_file.include?('ground_corner') || hpxml_file.include?('top_corner')
      exterior_area = 110
      common_area = 30
    elsif hpxml_file.include?('middle_interior')
      exterior_area = 80
      common_area = 60
    end
    hpxml.rim_joists.clear
    hpxml.rim_joists.add(id: "RimJoist#{hpxml.rim_joists.size + 1}",
                         exterior_adjacent_to: HPXML::LocationOutside,
                         interior_adjacent_to: HPXML::LocationLivingSpace,
                         area: exterior_area,
                         solar_absorptance: 0.75,
                         emittance: 0.9,
                         insulation_assembly_r_value: assembly_r)
    hpxml.rim_joists.add(id: "RimJoist#{hpxml.rim_joists.size + 1}",
                         exterior_adjacent_to: HPXML::LocationOtherHousingUnit,
                         interior_adjacent_to: HPXML::LocationLivingSpace,
                         area: common_area,
                         solar_absorptance: 0.75,
                         emittance: 0.9,
                         insulation_assembly_r_value: 3.75)
    if hpxml_file.include?('cond_bsmt')
      interior_adjacent_to = HPXML::LocationBasementConditioned
    elsif hpxml_file.include?('vented_crawl')
      interior_adjacent_to = HPXML::LocationCrawlspaceVented
      assembly_r = 4.0
    elsif hpxml_file.include?('slab')
      interior_adjacent_to = nil
    end
    if not interior_adjacent_to.nil?
      hpxml.rim_joists.add(id: "RimJoist#{hpxml.rim_joists.size + 1}",
                           exterior_adjacent_to: HPXML::LocationOutside,
                           interior_adjacent_to: interior_adjacent_to,
                           area: exterior_area,
                           solar_absorptance: 0.75,
                           emittance: 0.9,
                           insulation_assembly_r_value: assembly_r)
      hpxml.rim_joists.add(id: "RimJoist#{hpxml.rim_joists.size + 1}",
                           exterior_adjacent_to: interior_adjacent_to,
                           interior_adjacent_to: interior_adjacent_to,
                           area: common_area,
                           solar_absorptance: 0.75,
                           emittance: 0.9,
                           insulation_assembly_r_value: 3.75)
    end
  end
end

def set_hpxml_walls(hpxml_file, hpxml)
  if hpxml_file.include?('EPA_Tests/SF')
    if ['EPA_Tests/SF_National_3.1/SFNHv31_CZ2_FL_elec_slab.xml',
        'EPA_Tests/SF_National_3.0/SFNHv3_CZ2_FL_gas_slab.xml',
        'EPA_Tests/SF_National_3.0/SFNHv3_CZ4_MO_gas_vented_crawl.xml'].include? hpxml_file
      assembly_r = (1.0 / 0.082).round(3)
    elsif ['EPA_Tests/SF_National_3.1/SFNHv31_CZ4_MO_elec_vented_crawl.xml',
           'EPA_Tests/SF_National_3.0/SFNHv3_CZ6_VT_elec_cond_bsmt.xml'].include? hpxml_file
      assembly_r = (1.0 / 0.057).round(3)
    elsif ['EPA_Tests/SF_National_3.1/SFNHv31_CZ6_VT_gas_cond_bsmt.xml'].include? hpxml_file
      assembly_r = (1.0 / 0.048).round(3)
    elsif ['EPA_Tests/SF_National_3.2/SFNHv32_CZ2_FL_gas_slab.xml'].include? hpxml_file
      assembly_r = (1.0 / 0.084).round(3)
    elsif ['EPA_Tests/SF_National_3.2/SFNHv32_CZ4_MO_gas_vented_crawl.xml',
           'EPA_Tests/SF_National_3.2/SFNHv32_CZ6_VT_elec_cond_bsmt.xml'].include? hpxml_file
      assembly_r = (1.0 / 0.045).round(3)
    end
    hpxml.walls.clear
    hpxml.walls.add(id: "Wall#{hpxml.walls.size + 1}",
                    exterior_adjacent_to: HPXML::LocationOutside,
                    interior_adjacent_to: HPXML::LocationLivingSpace,
                    wall_type: HPXML::WallTypeWoodStud,
                    area: 2584,
                    solar_absorptance: 0.75,
                    emittance: 0.9,
                    insulation_assembly_r_value: assembly_r)
  elsif hpxml_file.include?('EPA_Tests/MF')
    if ['EPA_Tests/MF_National_1.0/MFNCv1_CZ2_FL_gas_ground_corner_slab.xml',
        'EPA_Tests/MF_National_1.0/MFNCv1_CZ4_MO_gas_top_corner.xml'].include? hpxml_file
      assembly_r = (1.0 / 0.089).round(3)
    elsif ['EPA_Tests/MF_National_1.1/MFNCv11_CZ4_MO_elec_ground_corner_vented_crawl.xml',
           'EPA_Tests/MF_National_1.1/MFNCv11_CZ2_FL_elec_top_corner.xml'].include? hpxml_file
      assembly_r = (1.0 / 0.064).round(3)
    elsif ['EPA_Tests/MF_National_1.1/MFNCv11_CZ6_VT_gas_ground_corner_cond_bsmt.xml',
           'EPA_Tests/MF_National_1.0/MFNCv1_CZ6_VT_elec_middle_interior.xml'].include? hpxml_file
      assembly_r = (1.0 / 0.051).round(3)
    elsif ['EPA_Tests/MF_National_1.2/MFNCv12_CZ2_FL_gas_ground_corner_slab.xml'].include? hpxml_file
      assembly_r = (1.0 / 0.084).round(3)
    elsif ['EPA_Tests/MF_National_1.2/MFNCv12_CZ4_MO_gas_top_corner.xml',
           'EPA_Tests/MF_National_1.2/MFNCv12_CZ6_VT_elec_middle_interior.xml'].include? hpxml_file
      assembly_r = (1.0 / 0.045).round(3)
    end
    if hpxml_file.include?('ground_corner') || hpxml_file.include?('top_corner')
      exterior_area = 935
      common_area = 255
    elsif hpxml_file.include?('middle_interior')
      exterior_area = 680
      common_area = 510
    end
    hpxml.walls.clear
    hpxml.walls.add(id: "Wall#{hpxml.walls.size + 1}",
                    exterior_adjacent_to: HPXML::LocationOutside,
                    interior_adjacent_to: HPXML::LocationLivingSpace,
                    wall_type: HPXML::WallTypeWoodStud,
                    area: exterior_area,
                    solar_absorptance: 0.75,
                    emittance: 0.9,
                    insulation_assembly_r_value: assembly_r)
    hpxml.walls.add(id: "Wall#{hpxml.walls.size + 1}",
                    exterior_adjacent_to: HPXML::LocationOtherHousingUnit,
                    interior_adjacent_to: HPXML::LocationLivingSpace,
                    wall_type: HPXML::WallTypeWoodStud,
                    area: common_area,
                    solar_absorptance: 0.75,
                    emittance: 0.9,
                    insulation_assembly_r_value: 3.75)
  end
end

def set_hpxml_foundation_walls(hpxml_file, hpxml)
  if ['RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/02-L100.xml'].include? hpxml_file
    # Unvented crawlspace with R-7 crawlspace wall insulation
    hpxml.foundation_walls.add(id: "FoundationWall#{hpxml.foundation_walls.size + 1}",
                               exterior_adjacent_to: HPXML::LocationGround,
                               interior_adjacent_to: HPXML::LocationCrawlspaceUnvented,
                               height: 4,
                               area: 228,
                               azimuth: 0,
                               thickness: 8,
                               depth_below_grade: 3,
                               insulation_interior_r_value: 7,
                               insulation_interior_distance_to_top: 0,
                               insulation_interior_distance_to_bottom: 4,
                               insulation_exterior_r_value: 0,
                               insulation_exterior_distance_to_top: 0,
                               insulation_exterior_distance_to_bottom: 0)
    hpxml.foundation_walls.add(id: "FoundationWall#{hpxml.foundation_walls.size + 1}",
                               exterior_adjacent_to: HPXML::LocationGround,
                               interior_adjacent_to: HPXML::LocationCrawlspaceUnvented,
                               height: 4,
                               area: 108,
                               azimuth: 90,
                               thickness: 8,
                               depth_below_grade: 3,
                               insulation_interior_r_value: 7,
                               insulation_interior_distance_to_top: 0,
                               insulation_interior_distance_to_bottom: 4,
                               insulation_exterior_r_value: 0,
                               insulation_exterior_distance_to_top: 0,
                               insulation_exterior_distance_to_bottom: 0)
    hpxml.foundation_walls.add(id: "FoundationWall#{hpxml.foundation_walls.size + 1}",
                               exterior_adjacent_to: HPXML::LocationGround,
                               interior_adjacent_to: HPXML::LocationCrawlspaceUnvented,
                               height: 4,
                               area: 228,
                               azimuth: 180,
                               thickness: 8,
                               depth_below_grade: 3,
                               insulation_interior_r_value: 7,
                               insulation_interior_distance_to_top: 0,
                               insulation_interior_distance_to_bottom: 4,
                               insulation_exterior_r_value: 0,
                               insulation_exterior_distance_to_top: 0,
                               insulation_exterior_distance_to_bottom: 0)
    hpxml.foundation_walls.add(id: "FoundationWall#{hpxml.foundation_walls.size + 1}",
                               exterior_adjacent_to: HPXML::LocationGround,
                               interior_adjacent_to: HPXML::LocationCrawlspaceUnvented,
                               height: 4,
                               area: 108,
                               azimuth: 270,
                               thickness: 8,
                               depth_below_grade: 3,
                               insulation_interior_r_value: 7,
                               insulation_interior_distance_to_top: 0,
                               insulation_interior_distance_to_bottom: 4,
                               insulation_exterior_r_value: 0,
                               insulation_exterior_distance_to_top: 0,
                               insulation_exterior_distance_to_bottom: 0)
  elsif ['RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/04-L324.xml'].include? hpxml_file
    hpxml.foundation_walls.each do |fwall|
      fwall.insulation_interior_distance_to_top = 0 if fwall.insulation_interior_distance_to_top.nil?
      if fwall.insulation_interior_distance_to_bottom.nil?
        if fwall.insulation_interior_r_value.to_f > 0
          fwall.insulation_interior_distance_to_bottom = fwall.height
        else
          fwall.insulation_interior_distance_to_bottom = 0
        end
      end
      fwall.insulation_exterior_distance_to_top = 0 if fwall.insulation_exterior_distance_to_top.nil?
      if fwall.insulation_exterior_distance_to_bottom.nil?
        if fwall.insulation_exterior_r_value.to_f > 0
          fwall.insulation_exterior_distance_to_bottom = fwall.height
        else
          fwall.insulation_exterior_distance_to_bottom = 0
        end
      end
    end
  elsif ['RESNET_Tests/4.5_DSE/HVAC3a.xml'].include? hpxml_file
    for i in 0..hpxml.foundation_walls.size - 1
      hpxml.foundation_walls[i].interior_adjacent_to = HPXML::LocationBasementUnconditioned
    end
  elsif hpxml_file.include?('EPA_Tests')
    if hpxml_file.include?('EPA_Tests/SF')
      exterior_perimeter = 152
      common_perimeter = 0
    elsif hpxml_file.include?('EPA_Tests/MF')
      exterior_perimeter = 110
      common_perimeter = 30
    end
    if hpxml_file.include?('vented_crawl')
      hpxml.foundation_walls.clear
      hpxml.foundation_walls.add(id: "FoundationWall#{hpxml.foundation_walls.size + 1}",
                                 exterior_adjacent_to: HPXML::LocationGround,
                                 interior_adjacent_to: HPXML::LocationCrawlspaceVented,
                                 height: 4.0,
                                 area: exterior_perimeter * 4.0,
                                 thickness: 8,
                                 depth_below_grade: 2.0,
                                 insulation_interior_r_value: 0,
                                 insulation_interior_distance_to_top: 0,
                                 insulation_interior_distance_to_bottom: 0,
                                 insulation_exterior_r_value: 0,
                                 insulation_exterior_distance_to_top: 0,
                                 insulation_exterior_distance_to_bottom: 0)
      if common_perimeter > 0
        hpxml.foundation_walls.add(id: "FoundationWall#{hpxml.foundation_walls.size + 1}",
                                   exterior_adjacent_to: HPXML::LocationCrawlspaceVented,
                                   interior_adjacent_to: HPXML::LocationCrawlspaceVented,
                                   height: 4.0,
                                   area: common_perimeter * 4.0,
                                   thickness: 8,
                                   depth_below_grade: 2.0,
                                   insulation_interior_r_value: 0,
                                   insulation_interior_distance_to_top: 0,
                                   insulation_interior_distance_to_bottom: 0,
                                   insulation_exterior_r_value: 0,
                                   insulation_exterior_distance_to_top: 0,
                                   insulation_exterior_distance_to_bottom: 0)
      end
    elsif hpxml_file.include?('cond_bsmt')
      if hpxml_file.include?('MF') && hpxml_file.include?('CZ6')
        insulation_interior_r_value = 7.5
        insulation_interior_distance_to_top = 0
        insulation_interior_distance_to_bottom = 8.5
        insulation_exterior_r_value = 0
        insulation_exterior_distance_to_top = 0
        insulation_exterior_distance_to_bottom = 0
      else
        assembly_r = (1.0 / 0.05).round(3)
      end
      hpxml.foundation_walls.clear
      hpxml.foundation_walls.add(id: "FoundationWall#{hpxml.foundation_walls.size + 1}",
                                 exterior_adjacent_to: HPXML::LocationGround,
                                 interior_adjacent_to: HPXML::LocationBasementConditioned,
                                 height: 8.5,
                                 area: exterior_perimeter * 8.5,
                                 thickness: 8,
                                 depth_below_grade: 6.0,
                                 insulation_interior_r_value: insulation_interior_r_value,
                                 insulation_interior_distance_to_top: insulation_interior_distance_to_top,
                                 insulation_interior_distance_to_bottom: insulation_interior_distance_to_bottom,
                                 insulation_exterior_r_value: insulation_exterior_r_value,
                                 insulation_exterior_distance_to_top: insulation_exterior_distance_to_top,
                                 insulation_exterior_distance_to_bottom: insulation_exterior_distance_to_bottom,
                                 insulation_assembly_r_value: assembly_r)
      if common_perimeter > 0
        hpxml.foundation_walls.add(id: "FoundationWall#{hpxml.foundation_walls.size + 1}",
                                   exterior_adjacent_to: HPXML::LocationBasementConditioned,
                                   interior_adjacent_to: HPXML::LocationBasementConditioned,
                                   height: 8.5,
                                   area: common_perimeter * 8.5,
                                   thickness: 8,
                                   depth_below_grade: 6.0,
                                   insulation_interior_r_value: 0,
                                   insulation_interior_distance_to_top: 0,
                                   insulation_interior_distance_to_bottom: 0,
                                   insulation_exterior_r_value: 0,
                                   insulation_exterior_distance_to_top: 0,
                                   insulation_exterior_distance_to_bottom: 0)
      end
    end
  end
end

def set_hpxml_floors(hpxml_file, hpxml)
  if ['RESNET_Tests/4.5_DSE/HVAC3a.xml'].include? hpxml_file
    # R-11 floor from ASHRAE 140 but with 13% framing factor instead of 10%
    hpxml.floors.add(id: "Floor#{hpxml.floors.size + 1}",
                     exterior_adjacent_to: HPXML::LocationBasementUnconditioned,
                     interior_adjacent_to: HPXML::LocationLivingSpace,
                     floor_type: HPXML::FloorTypeWoodFrame,
                     area: 1539,
                     insulation_assembly_r_value: 13.85)
  elsif ['RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/02-L100.xml'].include? hpxml_file
    # Uninsulated
    hpxml.floors[0].insulation_assembly_r_value = 4.24
    hpxml.floors[0].exterior_adjacent_to = HPXML::LocationCrawlspaceUnvented
  elsif ['RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/04-L324.xml'].include? hpxml_file
    hpxml.floors.delete_at(1)
  elsif hpxml_file.include?('EPA_Tests')
    # Ceiling
    if hpxml_file.include?('EPA_Tests/SF')
      area = 1188
    elsif hpxml_file.include?('EPA_Tests/MF')
      area = 1200
    end
    if hpxml_file.include?('ground_corner') || hpxml_file.include?('middle_interior')
      exterior_adjacent_to = HPXML::LocationOtherHousingUnit
      floor_or_ceiling = HPXML::FloorOrCeilingCeiling
      ceiling_assembly_r = 1.67
    else
      exterior_adjacent_to = HPXML::LocationAtticVented
      if ['EPA_Tests/SF_National_3.0/SFNHv3_CZ2_FL_gas_slab.xml'].include? hpxml_file
        ceiling_assembly_r = (1.0 / 0.035).round(3)
      elsif ['EPA_Tests/SF_National_3.1/SFNHv31_CZ2_FL_elec_slab.xml',
             'EPA_Tests/SF_National_3.0/SFNHv3_CZ4_MO_gas_vented_crawl.xml'].include? hpxml_file
        ceiling_assembly_r = (1.0 / 0.030).round(3)
      elsif ['EPA_Tests/MF_National_1.1/MFNCv11_CZ2_FL_elec_top_corner.xml',
             'EPA_Tests/MF_National_1.0/MFNCv1_CZ4_MO_gas_top_corner.xml'].include? hpxml_file
        ceiling_assembly_r = (1.0 / 0.027).round(3)
      elsif ['EPA_Tests/SF_National_3.2/SFNHv32_CZ2_FL_gas_slab.xml',
             'EPA_Tests/SF_National_3.1/SFNHv31_CZ4_MO_elec_vented_crawl.xml',
             'EPA_Tests/SF_National_3.1/SFNHv31_CZ6_VT_gas_cond_bsmt.xml',
             'EPA_Tests/SF_National_3.0/SFNHv3_CZ6_VT_elec_cond_bsmt.xml',
             'EPA_Tests/MF_National_1.2/MFNCv12_CZ2_FL_gas_ground_corner_slab.xml'].include? hpxml_file
        ceiling_assembly_r = (1.0 / 0.026).round(3)
      elsif ['EPA_Tests/SF_National_3.2/SFNHv32_CZ4_MO_gas_vented_crawl.xml',
             'EPA_Tests/SF_National_3.2/SFNHv32_CZ6_VT_elec_cond_bsmt.xml',
             'EPA_Tests/MF_National_1.2/MFNCv12_CZ4_MO_gas_top_corner.xml'].include? hpxml_file
        ceiling_assembly_r = (1.0 / 0.024).round(3)
      end
    end
    hpxml.floors.add(id: "Floor#{hpxml.floors.size + 1}",
                     exterior_adjacent_to: exterior_adjacent_to,
                     interior_adjacent_to: HPXML::LocationLivingSpace,
                     floor_type: HPXML::FloorTypeWoodFrame,
                     floor_or_ceiling: floor_or_ceiling,
                     area: area,
                     insulation_assembly_r_value: ceiling_assembly_r)
    # Floor
    if hpxml_file.include?('vented_crawl')
      if hpxml_file.include?('EPA_Tests/SF')
        floor_assembly_r = (1.0 / 0.047).round(3)
      elsif hpxml_file.include?('EPA_Tests/MF')
        floor_assembly_r = (1.0 / 0.033).round(3)
      end
      hpxml.floors.add(id: "Floor#{hpxml.floors.size + 1}",
                       exterior_adjacent_to: HPXML::LocationCrawlspaceVented,
                       interior_adjacent_to: HPXML::LocationLivingSpace,
                       floor_type: HPXML::FloorTypeWoodFrame,
                       area: area,
                       insulation_assembly_r_value: floor_assembly_r)
    elsif hpxml_file.include?('top_corner') || hpxml_file.include?('middle_interior')
      hpxml.floors.add(id: "Floor#{hpxml.floors.size + 1}",
                       exterior_adjacent_to: HPXML::LocationOtherHousingUnit,
                       interior_adjacent_to: HPXML::LocationLivingSpace,
                       floor_type: HPXML::FloorTypeWoodFrame,
                       floor_or_ceiling: HPXML::FloorOrCeilingFloor,
                       area: area,
                       insulation_assembly_r_value: 3.1)
    end
  end
end

def set_hpxml_slabs(hpxml_file, hpxml)
  if ['RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/02-L100.xml'].include? hpxml_file
    # Unvented crawlspace
    hpxml.slabs.add(id: "Slab#{hpxml.slabs.size + 1}",
                    interior_adjacent_to: HPXML::LocationCrawlspaceUnvented,
                    area: 1539,
                    thickness: 0,
                    exposed_perimeter: 168,
                    perimeter_insulation_depth: 0,
                    under_slab_insulation_width: 0,
                    under_slab_insulation_spans_entire_slab: nil,
                    perimeter_insulation_r_value: 0,
                    under_slab_insulation_r_value: 0,
                    carpet_fraction: 0,
                    carpet_r_value: 2.5)
  elsif ['RESNET_Tests/4.5_DSE/HVAC3a.xml'].include? hpxml_file
    hpxml.slabs[0].interior_adjacent_to = HPXML::LocationBasementUnconditioned
  elsif hpxml_file.include?('EPA_Tests')
    if hpxml_file.include?('slab')
      interior_adjacent_to = HPXML::LocationLivingSpace
      depth_below_grade = 0
      carpet_fraction = 0.8
      thickness = 4
    elsif hpxml_file.include?('vented_crawl')
      interior_adjacent_to = HPXML::LocationCrawlspaceVented
      depth_below_grade = nil
      carpet_fraction = 0.0
      thickness = 0
    elsif hpxml_file.include?('cond_bsmt')
      interior_adjacent_to = HPXML::LocationBasementConditioned
      depth_below_grade = nil
      carpet_fraction = 0.8
      thickness = 4
    else
      return
    end
    if hpxml_file.include?('EPA_Tests/SF')
      exposed_perimeter = 152
      area = 1188
    elsif hpxml_file.include?('EPA_Tests/MF')
      exposed_perimeter = 110
      area = 1200
    end
    hpxml.slabs.clear
    hpxml.slabs.add(id: "Slab#{hpxml.slabs.size + 1}",
                    interior_adjacent_to: interior_adjacent_to,
                    depth_below_grade: depth_below_grade,
                    area: area,
                    thickness: thickness,
                    exposed_perimeter: exposed_perimeter,
                    perimeter_insulation_depth: 0,
                    under_slab_insulation_width: 0,
                    under_slab_insulation_spans_entire_slab: nil,
                    perimeter_insulation_r_value: 0,
                    under_slab_insulation_r_value: 0,
                    carpet_fraction: carpet_fraction,
                    carpet_r_value: 2.0)
  end
end

def set_hpxml_windows(hpxml_file, hpxml)
  if hpxml_file.include?('HERS_AutoGen') || hpxml_file.include?('HERS_Method') || hpxml_file.include?('Hot_Water')
    hpxml.windows.each do |window|
      window.interior_shading_factor_summer = nil
      window.interior_shading_factor_winter = nil
      window.performance_class = HPXML::WindowClassResidential
    end
  elsif hpxml_file.include?('EPA_Tests')
    if ['EPA_Tests/SF_National_3.0/SFNHv3_CZ2_FL_gas_slab.xml',
        'EPA_Tests/MF_National_1.0/MFNCv1_CZ2_FL_gas_ground_corner_slab.xml'].include? hpxml_file
      ufactor = 0.60
      shgc = 0.27
    elsif ['EPA_Tests/SF_National_3.2/SFNHv32_CZ2_FL_gas_slab.xml',
           'EPA_Tests/SF_National_3.1/SFNHv31_CZ2_FL_elec_slab.xml',
           'EPA_Tests/MF_National_1.1/MFNCv11_CZ2_FL_elec_top_corner.xml',
           'EPA_Tests/MF_National_1.2/MFNCv12_CZ2_FL_gas_ground_corner_slab.xml'].include? hpxml_file
      ufactor = 0.40
      shgc = 0.25
    elsif ['EPA_Tests/SF_National_3.0/SFNHv3_CZ4_MO_gas_vented_crawl.xml',
           'EPA_Tests/MF_National_1.0/MFNCv1_CZ4_MO_gas_top_corner.xml'].include? hpxml_file
      ufactor = 0.32
      shgc = 0.40
    elsif ['EPA_Tests/SF_National_3.2/SFNHv32_CZ4_MO_gas_vented_crawl.xml',
           'EPA_Tests/SF_National_3.1/SFNHv31_CZ4_MO_elec_vented_crawl.xml',
           'EPA_Tests/SF_National_3.0/SFNHv3_CZ6_VT_elec_cond_bsmt.xml',
           'EPA_Tests/MF_National_1.2/MFNCv12_CZ4_MO_gas_top_corner.xml',
           'EPA_Tests/MF_National_1.1/MFNCv11_CZ4_MO_elec_ground_corner_vented_crawl.xml',
           'EPA_Tests/MF_National_1.0/MFNCv1_CZ6_VT_elec_middle_interior.xml'].include? hpxml_file
      ufactor = 0.30
      shgc = 0.40
    elsif ['EPA_Tests/SF_National_3.2/SFNHv32_CZ6_VT_elec_cond_bsmt.xml',
           'EPA_Tests/SF_National_3.1/SFNHv31_CZ6_VT_gas_cond_bsmt.xml',
           'EPA_Tests/MF_National_1.2/MFNCv12_CZ6_VT_elec_middle_interior.xml',
           'EPA_Tests/MF_National_1.1/MFNCv11_CZ6_VT_gas_ground_corner_cond_bsmt.xml'].include? hpxml_file
      ufactor = 0.27
      shgc = 0.40
    end

    cfa = hpxml.building_construction.conditioned_floor_area
    ag_bndry_wall_area, bg_bndry_wall_area = hpxml.thermal_boundary_wall_areas()
    common_wall_area = hpxml.common_wall_area()
    fa = ag_bndry_wall_area / (ag_bndry_wall_area + 0.5 * bg_bndry_wall_area)
    f = 1.0 - 0.44 * common_wall_area / (ag_bndry_wall_area + common_wall_area)
    tot_window_area = 0.15 * cfa * fa * f

    if hpxml_file.include?('EPA_Tests/SF')
      windows = [[0, (tot_window_area / 4.0).round(2), 'Wall1'],
                 [90, (tot_window_area / 4.0).round(2), 'Wall1'],
                 [180, (tot_window_area / 4.0).round(2), 'Wall1'],
                 [270, (tot_window_area / 4.0).round(2), 'Wall1']]
    elsif hpxml_file.include?('EPA_Tests/MF')
      if hpxml_file.include?('ground_corner') || hpxml_file.include?('top_corner')
        windows = [[90, (40 / 70.0 * tot_window_area).round(2), 'Wall1'],
                   [180, (30 / 70.0 * tot_window_area).round(2), 'Wall1']]
      elsif hpxml_file.include?('middle_interior')
        windows = [[90, tot_window_area.round(2), 'Wall1']]
      end
    end

    hpxml.windows.clear
    windows.each do |window_values|
      azimuth, area, wall = window_values
      hpxml.windows.add(id: "Window#{hpxml.windows.size + 1}",
                        area: area,
                        azimuth: azimuth,
                        ufactor: ufactor,
                        shgc: shgc,
                        fraction_operable: 0.67,
                        wall_idref: wall,
                        performance_class: HPXML::WindowClassResidential)
    end
  end
end

def set_hpxml_skylights(hpxml_file, hpxml)
end

def set_hpxml_doors(hpxml_file, hpxml)
  if hpxml_file.include?('EPA_Tests/SF')
    if hpxml_file.include?('SF_National_3.2') || hpxml_file.include?('SF_National_3.1')
      r_value = (1.0 / 0.17).round(3)
    elsif hpxml_file.include?('SF_National_3.0')
      r_value = (1.0 / 0.21).round(3)
    end
    doors = [[0, 21, 'Wall1'],
             [0, 21, 'Wall1']]
    hpxml.doors.clear
    doors.each do |door_values|
      azimuth, area, wall = door_values
      hpxml.doors.add(id: "Door#{hpxml.doors.size + 1}",
                      wall_idref: wall,
                      area: area,
                      azimuth: azimuth,
                      r_value: r_value)
    end
  elsif hpxml_file.include?('EPA_Tests/MF')
    if hpxml_file.include?('MF_National_1.0')
      r_value = (1.0 / 0.21).round(3)
    elsif hpxml_file.include?('MF_National_1.1') || hpxml_file.include?('MF_National_1.2')
      r_value = (1.0 / 0.17).round(3)
    end
    doors = [[0, 21, 'Wall1']]
    hpxml.doors.clear
    doors.each do |door_values|
      azimuth, area, wall = door_values
      hpxml.doors.add(id: "Door#{hpxml.doors.size + 1}",
                      wall_idref: wall,
                      area: area,
                      azimuth: azimuth,
                      r_value: r_value)
    end
  end
end

def set_hpxml_heating_systems(hpxml_file, hpxml)
  if ['RESNET_Tests/4.4_HVAC/HVAC2c.xml',
      'RESNET_Tests/4.4_HVAC/HVAC2d.xml'].include?(hpxml_file)
    hpxml.heating_systems.clear
  elsif ['RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/01-L100.xml'].include? hpxml_file
    # Gas furnace with AFUE = 82%
    hpxml.heating_systems.clear
    hpxml.heating_systems.add(id: "HeatingSystem#{hpxml.heating_systems.size + 1}",
                              distribution_system_idref: 'HVACDistribution1',
                              heating_system_type: HPXML::HVACTypeFurnace,
                              heating_system_fuel: HPXML::FuelTypeNaturalGas,
                              heating_capacity: -1,
                              heating_efficiency_afue: 0.82,
                              fraction_heat_load_served: 1,
                              fan_watts_per_cfm: 0.58,
                              airflow_defect_ratio: -0.25)
  elsif ['RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/03-L304.xml'].include? hpxml_file
    # Electric strip heating with COP = 1.0
    hpxml.heating_systems.clear
    hpxml.heating_systems.add(id: "HeatingSystem#{hpxml.heating_systems.size + 1}",
                              heating_system_type: HPXML::HVACTypeElectricResistance,
                              heating_system_fuel: HPXML::FuelTypeElectricity,
                              heating_capacity: -1,
                              heating_efficiency_percent: 1,
                              fraction_heat_load_served: 1)
  elsif ['RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/04-L324.xml'].include? hpxml_file
    # Gas furnace with AFUE = 95%
    hpxml.heating_systems.clear
    hpxml.heating_systems.add(id: "HeatingSystem#{hpxml.heating_systems.size + 1}",
                              distribution_system_idref: 'HVACDistribution1',
                              heating_system_type: HPXML::HVACTypeFurnace,
                              heating_system_fuel: HPXML::FuelTypeNaturalGas,
                              heating_capacity: -1,
                              heating_efficiency_afue: 0.95,
                              fraction_heat_load_served: 1,
                              fan_watts_per_cfm: 0.58,
                              airflow_defect_ratio: -0.25)
  elsif ['RESNET_Tests/4.3_HERS_Method/L100A-03.xml'].include? hpxml_file
    # Natural gas furnace with AFUE = 78%
    hpxml.heating_systems.clear
    hpxml.heating_systems.add(id: "HeatingSystem#{hpxml.heating_systems.size + 1}",
                              distribution_system_idref: 'HVACDistribution1',
                              heating_system_type: HPXML::HVACTypeFurnace,
                              heating_system_fuel: HPXML::FuelTypeNaturalGas,
                              heating_capacity: -1,
                              heating_efficiency_afue: 0.78,
                              fraction_heat_load_served: 1,
                              fan_watts_per_cfm: 0.58,
                              airflow_defect_ratio: -0.25)
  elsif ['RESNET_Tests/4.3_HERS_Method/L100A-05.xml'].include? hpxml_file
    # Natural gas furnace with AFUE = 96%
    hpxml.heating_systems.clear
    hpxml.heating_systems.add(id: "HeatingSystem#{hpxml.heating_systems.size + 1}",
                              distribution_system_idref: 'HVACDistribution1',
                              heating_system_type: HPXML::HVACTypeFurnace,
                              heating_system_fuel: HPXML::FuelTypeNaturalGas,
                              heating_capacity: -1,
                              heating_efficiency_afue: 0.96,
                              fraction_heat_load_served: 1,
                              fan_watts_per_cfm: 0.58,
                              airflow_defect_ratio: -0.25)
  elsif ['RESNET_Tests/4.4_HVAC/HVAC2a.xml',
         'RESNET_Tests/4.4_HVAC/HVAC1a.xml'].include? hpxml_file
    # Gas Furnace; 56.1 kBtu/h; AFUE = 78%; 0.0005 kW/cfm
    hpxml.heating_systems.clear
    hpxml.heating_systems.add(id: "HeatingSystem#{hpxml.heating_systems.size + 1}",
                              distribution_system_idref: 'HVACDistribution1',
                              heating_system_type: HPXML::HVACTypeFurnace,
                              heating_system_fuel: HPXML::FuelTypeNaturalGas,
                              heating_capacity: 56100,
                              heating_efficiency_afue: 0.78,
                              fraction_heat_load_served: 1,
                              fan_watts_per_cfm: 0.5)
  elsif ['RESNET_Tests/4.4_HVAC/HVAC2b.xml'].include? hpxml_file
    # Gas Furnace; 56.1 kBtu/h; AFUE = 90%; 0.000375 kW/cfm
    hpxml.heating_systems.clear
    hpxml.heating_systems.add(id: "HeatingSystem#{hpxml.heating_systems.size + 1}",
                              distribution_system_idref: 'HVACDistribution1',
                              heating_system_type: HPXML::HVACTypeFurnace,
                              heating_system_fuel: HPXML::FuelTypeNaturalGas,
                              heating_capacity: 56100,
                              heating_efficiency_afue: 0.9,
                              fraction_heat_load_served: 1,
                              fan_watts_per_cfm: 0.5)
  elsif ['RESNET_Tests/4.4_HVAC/HVAC2e.xml'].include? hpxml_file
    # Electric Furnace; 56.1 kBtu/h; COP =1.0
    hpxml.heating_systems.clear
    hpxml.heating_systems.add(id: "HeatingSystem#{hpxml.heating_systems.size + 1}",
                              distribution_system_idref: 'HVACDistribution1',
                              heating_system_type: HPXML::HVACTypeFurnace,
                              heating_system_fuel: HPXML::FuelTypeElectricity,
                              heating_capacity: 56100,
                              heating_efficiency_afue: 1,
                              fraction_heat_load_served: 1,
                              fan_watts_per_cfm: 0.5)
  elsif ['RESNET_Tests/4.5_DSE/HVAC3a.xml',
         'RESNET_Tests/4.5_DSE/HVAC3e.xml'].include? hpxml_file
    # Gas Furnace; 46.6 kBtu/h
    hpxml.heating_systems.clear
    hpxml.heating_systems.add(id: "HeatingSystem#{hpxml.heating_systems.size + 1}",
                              distribution_system_idref: 'HVACDistribution1',
                              heating_system_type: HPXML::HVACTypeFurnace,
                              heating_system_fuel: HPXML::FuelTypeNaturalGas,
                              heating_capacity: 46600,
                              heating_efficiency_afue: 0.78,
                              fraction_heat_load_served: 1,
                              fan_watts_per_cfm: 0.5)
  elsif ['RESNET_Tests/4.5_DSE/HVAC3b.xml'].include? hpxml_file
    # Change to 56.0 kBtu/h
    hpxml.heating_systems[0].heating_capacity = 56000
  elsif ['RESNET_Tests/4.5_DSE/HVAC3c.xml'].include? hpxml_file
    # Change to 49.0 kBtu/h
    hpxml.heating_systems[0].heating_capacity = 49000
  elsif ['RESNET_Tests/4.5_DSE/HVAC3d.xml'].include? hpxml_file
    # Change to 61.0 kBtu/h
    hpxml.heating_systems[0].heating_capacity = 61000
  elsif hpxml_file.include? 'Hot_Water'
    # Natural gas furnace with AFUE = 78%
    hpxml.heating_systems.clear
    hpxml.heating_systems.add(id: "HeatingSystem#{hpxml.heating_systems.size + 1}",
                              distribution_system_idref: 'HVACDistribution1',
                              heating_system_type: HPXML::HVACTypeFurnace,
                              heating_system_fuel: HPXML::FuelTypeNaturalGas,
                              heating_capacity: -1,
                              heating_efficiency_afue: 0.78,
                              fraction_heat_load_served: 1,
                              fan_watts_per_cfm: 0.58,
                              airflow_defect_ratio: -0.25)
  elsif hpxml_file.include?('EPA_Tests')
    if hpxml_file.include?('_elec_')
      return
    elsif hpxml_file.include?('CZ2')
      afue = 0.80
    elsif hpxml_file.include?('CZ4')
      afue = 0.90
    elsif hpxml_file.include?('CZ6')
      afue = 0.95
    end

    if hpxml_file.include?('SF_National_3.2') || hpxml_file.include?('MF_National_1.2')
      fan_watts_per_cfm = 0.52
      airflow_defect_ratio = -0.20
    else
      fan_watts_per_cfm = 0.58
      airflow_defect_ratio = -0.25
    end

    hpxml.heating_systems.clear
    hpxml.heating_systems.add(id: "HeatingSystem#{hpxml.heating_systems.size + 1}",
                              distribution_system_idref: 'HVACDistribution1',
                              heating_system_type: HPXML::HVACTypeFurnace,
                              heating_system_fuel: HPXML::FuelTypeNaturalGas,
                              heating_capacity: -1,
                              heating_efficiency_afue: afue,
                              fraction_heat_load_served: 1,
                              fan_watts_per_cfm: fan_watts_per_cfm,
                              airflow_defect_ratio: airflow_defect_ratio)
  end
end

def set_hpxml_cooling_systems(hpxml_file, hpxml)
  if ['RESNET_Tests/4.4_HVAC/HVAC2c.xml',
      'RESNET_Tests/4.4_HVAC/HVAC2d.xml'].include?(hpxml_file)
    hpxml.cooling_systems.clear
  elsif ['RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/01-L100.xml'].include? hpxml_file
    # Central air conditioner with SEER = 11.0
    hpxml.cooling_systems.clear
    hpxml.cooling_systems.add(id: "CoolingSystem#{hpxml.cooling_systems.size + 1}",
                              distribution_system_idref: 'HVACDistribution1',
                              cooling_system_type: HPXML::HVACTypeCentralAirConditioner,
                              cooling_system_fuel: HPXML::FuelTypeElectricity,
                              cooling_capacity: -1,
                              fraction_cool_load_served: 1,
                              cooling_efficiency_seer: 11,
                              fan_watts_per_cfm: 0.58,
                              airflow_defect_ratio: -0.25,
                              charge_defect_ratio: -0.25)
  elsif ['RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/03-L304.xml'].include? hpxml_file
    # Central air conditioner with SEER = 15.0
    hpxml.cooling_systems.clear
    hpxml.cooling_systems.add(id: "CoolingSystem#{hpxml.cooling_systems.size + 1}",
                              distribution_system_idref: 'HVACDistribution1',
                              cooling_system_type: HPXML::HVACTypeCentralAirConditioner,
                              cooling_system_fuel: HPXML::FuelTypeElectricity,
                              cooling_capacity: -1,
                              fraction_cool_load_served: 1,
                              cooling_efficiency_seer: 15,
                              fan_watts_per_cfm: 0.58,
                              airflow_defect_ratio: -0.25,
                              charge_defect_ratio: -0.25)
  elsif ['RESNET_Tests/4.3_HERS_Method/L100A-03.xml',
         'RESNET_Tests/4.3_HERS_Method/L100A-05.xml'].include? hpxml_file
    # Cooling system – electric A/C with SEER = 10.0
    hpxml.cooling_systems.clear
    hpxml.cooling_systems.add(id: "CoolingSystem#{hpxml.cooling_systems.size + 1}",
                              distribution_system_idref: 'HVACDistribution1',
                              cooling_system_type: HPXML::HVACTypeCentralAirConditioner,
                              cooling_system_fuel: HPXML::FuelTypeElectricity,
                              cooling_capacity: -1,
                              fraction_cool_load_served: 1,
                              cooling_efficiency_seer: 10,
                              fan_watts_per_cfm: 0.58,
                              airflow_defect_ratio: -0.25,
                              charge_defect_ratio: -0.25)
  elsif ['RESNET_Tests/4.4_HVAC/HVAC1a.xml',
         'RESNET_Tests/4.4_HVAC/HVAC2a.xml'].include? hpxml_file
    # Air cooled air conditioner; 38.3 kBtu/h; SEER = 10
    hpxml.cooling_systems.clear
    hpxml.cooling_systems.add(id: "CoolingSystem#{hpxml.cooling_systems.size + 1}",
                              distribution_system_idref: 'HVACDistribution1',
                              cooling_system_type: HPXML::HVACTypeCentralAirConditioner,
                              cooling_system_fuel: HPXML::FuelTypeElectricity,
                              cooling_capacity: 38300,
                              fraction_cool_load_served: 1,
                              cooling_efficiency_seer: 10,
                              fan_watts_per_cfm: 0.5)
  elsif ['RESNET_Tests/4.4_HVAC/HVAC1b.xml'].include? hpxml_file
    # Change to SEER = 13
    hpxml.cooling_systems[0].cooling_efficiency_seer = 13
  elsif ['RESNET_Tests/4.5_DSE/HVAC3e.xml',
         'RESNET_Tests/4.5_DSE/HVAC3a.xml'].include? hpxml_file
    # Air Conditioner; 38.4 kBtu/h; SEER 10
    hpxml.cooling_systems.clear
    hpxml.cooling_systems.add(id: "CoolingSystem#{hpxml.cooling_systems.size + 1}",
                              distribution_system_idref: 'HVACDistribution1',
                              cooling_system_type: HPXML::HVACTypeCentralAirConditioner,
                              cooling_system_fuel: HPXML::FuelTypeElectricity,
                              cooling_capacity: 38400,
                              fraction_cool_load_served: 1,
                              cooling_efficiency_seer: 10,
                              fan_watts_per_cfm: 0.5)
  elsif ['RESNET_Tests/4.5_DSE/HVAC3f.xml'].include? hpxml_file
    # Change to 49.9 kBtu/h
    hpxml.cooling_systems[0].cooling_capacity = 49900
  elsif ['RESNET_Tests/4.5_DSE/HVAC3g.xml'].include? hpxml_file
    # Change to 42.2 kBtu/h
    hpxml.cooling_systems[0].cooling_capacity = 42200
  elsif ['RESNET_Tests/4.5_DSE/HVAC3h.xml'].include? hpxml_file
    # Change to 55.0 kBtu/h
    hpxml.cooling_systems[0].cooling_capacity = 55000
  elsif hpxml_file.include? 'Hot_Water'
    # Central air conditioner with SEER = 13.0
    hpxml.cooling_systems.clear
    hpxml.cooling_systems.add(id: "CoolingSystem#{hpxml.cooling_systems.size + 1}",
                              distribution_system_idref: 'HVACDistribution1',
                              cooling_system_type: HPXML::HVACTypeCentralAirConditioner,
                              cooling_system_fuel: HPXML::FuelTypeElectricity,
                              cooling_capacity: -1,
                              fraction_cool_load_served: 1,
                              cooling_efficiency_seer: 13,
                              fan_watts_per_cfm: 0.58,
                              airflow_defect_ratio: -0.25,
                              charge_defect_ratio: -0.25)
  elsif hpxml_file.include?('EPA_Tests')
    if hpxml_file.include?('_elec_')
      return
    elsif hpxml_file.include?('CZ2')
      if hpxml_file.include?('SF_National_3.2') || hpxml_file.include?('MF_National_1.2')
        seer = 16
      else
        seer = 14.5
      end
    elsif hpxml_file.include?('CZ4')
      if hpxml_file.include?('SF_National_3.2') || hpxml_file.include?('MF_National_1.2')
        seer = 16
      else
        seer = 13
      end
    elsif hpxml_file.include?('CZ6')
      if hpxml_file.include?('SF_National_3.2') || hpxml_file.include?('MF_National_1.2')
        seer = 14
      else
        seer = 13
      end
    end

    if hpxml_file.include?('SF_National_3.2') || hpxml_file.include?('MF_National_1.2')
      fan_watts_per_cfm = 0.52
      airflow_defect_ratio = -0.20
      charge_defect_ratio = -0.25
    else
      fan_watts_per_cfm = 0.58
      airflow_defect_ratio = -0.25
      charge_defect_ratio = -0.25
    end

    hpxml.cooling_systems.clear
    hpxml.cooling_systems.add(id: "CoolingSystem#{hpxml.cooling_systems.size + 1}",
                              distribution_system_idref: 'HVACDistribution1',
                              cooling_system_type: HPXML::HVACTypeCentralAirConditioner,
                              cooling_system_fuel: HPXML::FuelTypeElectricity,
                              cooling_capacity: -1,
                              fraction_cool_load_served: 1,
                              cooling_efficiency_seer: seer,
                              fan_watts_per_cfm: fan_watts_per_cfm,
                              airflow_defect_ratio: airflow_defect_ratio,
                              charge_defect_ratio: charge_defect_ratio)
  end
end

def set_hpxml_heat_pumps(hpxml_file, hpxml)
  if ['RESNET_Tests/4.3_HERS_Method/L100A-03.xml',
      'RESNET_Tests/4.3_HERS_Method/L100A-05.xml'].include? hpxml_file
    hpxml.heat_pumps.clear
  elsif ['RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/02-L100.xml'].include? hpxml_file
    # Electric heat pump with HSPF = 7.5 and SEER = 12.0
    hpxml.heat_pumps.clear
    hpxml.heat_pumps.add(id: "HeatPump#{hpxml.heat_pumps.size + 1}",
                         distribution_system_idref: 'HVACDistribution1',
                         heat_pump_type: HPXML::HVACTypeHeatPumpAirToAir,
                         heat_pump_fuel: HPXML::FuelTypeElectricity,
                         cooling_capacity: -1,
                         heating_capacity: -1,
                         backup_type: HPXML::HeatPumpBackupTypeIntegrated,
                         backup_heating_fuel: HPXML::FuelTypeElectricity,
                         backup_heating_capacity: -1,
                         backup_heating_efficiency_percent: 1.0,
                         fraction_heat_load_served: 1,
                         fraction_cool_load_served: 1,
                         heating_efficiency_hspf: 7.5,
                         cooling_efficiency_seer: 12,
                         fan_watts_per_cfm: 0.58,
                         airflow_defect_ratio: -0.25,
                         charge_defect_ratio: -0.25)
  elsif ['RESNET_Tests/4.3_HERS_Method/L100A-01.xml'].include? hpxml_file
    # Heating system – electric HP with HSPF = 6.8
    # Cooling system – electric A/C with SEER
    hpxml.heat_pumps.clear
    hpxml.heat_pumps.add(id: "HeatPump#{hpxml.heat_pumps.size + 1}",
                         distribution_system_idref: 'HVACDistribution1',
                         heat_pump_type: HPXML::HVACTypeHeatPumpAirToAir,
                         heat_pump_fuel: HPXML::FuelTypeElectricity,
                         cooling_capacity: -1,
                         heating_capacity: -1,
                         backup_type: HPXML::HeatPumpBackupTypeIntegrated,
                         backup_heating_fuel: HPXML::FuelTypeElectricity,
                         backup_heating_capacity: -1,
                         backup_heating_efficiency_percent: 1.0,
                         fraction_heat_load_served: 1,
                         fraction_cool_load_served: 1,
                         heating_efficiency_hspf: 6.8,
                         cooling_efficiency_seer: 10,
                         fan_watts_per_cfm: 0.58,
                         airflow_defect_ratio: -0.25,
                         charge_defect_ratio: -0.25)
  elsif ['RESNET_Tests/4.3_HERS_Method/L100A-04.xml'].include? hpxml_file
    # Change to a high efficiency HP with HSPF = 9.85
    hpxml.heat_pumps[0].heating_efficiency_hspf = 9.85
  elsif ['RESNET_Tests/4.4_HVAC/HVAC2c.xml'].include? hpxml_file
    # Air Source Heat Pump; 56.1 kBtu/h; HSPF = 6.8
    hpxml.heat_pumps.clear
    hpxml.heat_pumps.add(id: "HeatPump#{hpxml.heat_pumps.size + 1}",
                         distribution_system_idref: 'HVACDistribution1',
                         heat_pump_type: HPXML::HVACTypeHeatPumpAirToAir,
                         heat_pump_fuel: HPXML::FuelTypeElectricity,
                         cooling_capacity: 56100,
                         heating_capacity: 56100,
                         backup_type: HPXML::HeatPumpBackupTypeIntegrated,
                         backup_heating_fuel: HPXML::FuelTypeElectricity,
                         backup_heating_capacity: 34121,
                         backup_heating_efficiency_percent: 1.0,
                         fraction_heat_load_served: 1,
                         fraction_cool_load_served: 1,
                         heating_efficiency_hspf: 6.8,
                         cooling_efficiency_seer: 10,
                         fan_watts_per_cfm: 0.5)
  elsif ['RESNET_Tests/4.4_HVAC/HVAC2d.xml'].include? hpxml_file
    # Air Source Heat Pump; 56.1 kBtu/h; HSPF = 9.85
    hpxml.heat_pumps.clear
    hpxml.heat_pumps.add(id: "HeatPump#{hpxml.heat_pumps.size + 1}",
                         distribution_system_idref: 'HVACDistribution1',
                         heat_pump_type: HPXML::HVACTypeHeatPumpAirToAir,
                         heat_pump_fuel: HPXML::FuelTypeElectricity,
                         cooling_capacity: 56100,
                         heating_capacity: 56100,
                         backup_type: HPXML::HeatPumpBackupTypeIntegrated,
                         backup_heating_fuel: HPXML::FuelTypeElectricity,
                         backup_heating_capacity: 34121,
                         backup_heating_efficiency_percent: 1.0,
                         fraction_heat_load_served: 1,
                         fraction_cool_load_served: 1,
                         heating_efficiency_hspf: 9.85,
                         cooling_efficiency_seer: 13,
                         fan_watts_per_cfm: 0.5)
  elsif hpxml_file.include?('EPA_Tests')
    if hpxml_file.include?('_gas_')
      return
    elsif hpxml_file.include?('CZ2')
      if hpxml_file.include?('SF_National_3.2') || hpxml_file.include?('MF_National_1.2')
        hspf = 9.2
        seer = 16
      else
        hspf = 8.2
        seer = 15
      end
    elsif hpxml_file.include?('CZ4')
      if hpxml_file.include?('SF_National_3.2') || hpxml_file.include?('MF_National_1.2')
        hspf = 9.2
        seer = 16
      else
        hspf = 8.5
        seer = 15
      end
    elsif hpxml_file.include?('CZ6')
      if hpxml_file.include?('SF_National_3.2') || hpxml_file.include?('MF_National_1.2')
        hspf = 9.2
        seer = 16
      else
        hspf = 9.5
        seer = 14.5
      end
    end

    if hpxml_file.include?('SF_National_3.2') || hpxml_file.include?('MF_National_1.2')
      fan_watts_per_cfm = 0.52
      airflow_defect_ratio = -0.20
      charge_defect_ratio = -0.25
    else
      fan_watts_per_cfm = 0.58
      airflow_defect_ratio = -0.25
      charge_defect_ratio = -0.25
    end

    hpxml.heat_pumps.clear
    hpxml.heat_pumps.add(id: "HeatPump#{hpxml.heat_pumps.size + 1}",
                         distribution_system_idref: 'HVACDistribution1',
                         heat_pump_type: HPXML::HVACTypeHeatPumpAirToAir,
                         heat_pump_fuel: HPXML::FuelTypeElectricity,
                         cooling_capacity: -1,
                         heating_capacity: -1,
                         backup_type: HPXML::HeatPumpBackupTypeIntegrated,
                         backup_heating_fuel: HPXML::FuelTypeElectricity,
                         backup_heating_capacity: -1,
                         backup_heating_efficiency_percent: 1.0,
                         fraction_heat_load_served: 1,
                         fraction_cool_load_served: 1,
                         heating_efficiency_hspf: hspf,
                         cooling_efficiency_seer: seer,
                         fan_watts_per_cfm: fan_watts_per_cfm,
                         airflow_defect_ratio: airflow_defect_ratio,
                         charge_defect_ratio: charge_defect_ratio)
  end
end

def set_hpxml_hvac_controls(hpxml_file, hpxml)
  if hpxml_file.include?('HERS_AutoGen') || hpxml_file.include?('HERS_Method') || hpxml_file.include?('Hot_Water')
    hpxml.hvac_controls.clear
    if hpxml.heating_systems.size + hpxml.cooling_systems.size + hpxml.heat_pumps.size > 0
      hpxml.hvac_controls.add(id: "HVACControl#{hpxml.hvac_controls.size + 1}",
                              control_type: HPXML::HVACControlTypeManual)
    end
  elsif hpxml_file.include?('EPA_Tests')
    hpxml.hvac_controls.clear
    hpxml.hvac_controls.add(id: "HVACControl#{hpxml.hvac_controls.size + 1}",
                            control_type: HPXML::HVACControlTypeProgrammable)
  end
end

def set_hpxml_hvac_distributions(hpxml_file, hpxml)
  # Type
  if ['RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/01-L100.xml',
      'RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/02-L100.xml',
      'RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/03-L304.xml',
      'RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/04-L324.xml',
      'RESNET_Tests/4.3_HERS_Method/L100A-01.xml',
      'RESNET_Tests/4.5_DSE/HVAC3a.xml',
      'RESNET_Tests/4.5_DSE/HVAC3e.xml'].include?(hpxml_file) ||
     hpxml_file.include?('Hot_Water') ||
     hpxml_file.include?('EPA_Tests')
    hpxml.hvac_distributions.clear
    hpxml.hvac_distributions.add(id: "HVACDistribution#{hpxml.hvac_distributions.size + 1}",
                                 distribution_system_type: HPXML::HVACDistributionTypeAir,
                                 air_type: HPXML::AirTypeRegularVelocity)
  elsif ['RESNET_Tests/4.4_HVAC/HVAC1a.xml',
         'RESNET_Tests/4.4_HVAC/HVAC2a.xml'].include? hpxml_file
    hpxml.hvac_distributions.clear
    hpxml.hvac_distributions.add(id: "HVACDistribution#{hpxml.hvac_distributions.size + 1}",
                                 distribution_system_type: HPXML::HVACDistributionTypeDSE,
                                 annual_heating_dse: 1,
                                 annual_cooling_dse: 1)
  end

  # Leakage
  if ['RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/01-L100.xml',
      'RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/02-L100.xml',
      'RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/03-L304.xml',
      'RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/04-L324.xml',
      'RESNET_Tests/4.3_HERS_Method/L100A-01.xml',
      'RESNET_Tests/4.5_DSE/HVAC3a.xml',
      'RESNET_Tests/4.5_DSE/HVAC3e.xml'].include?(hpxml_file) ||
     hpxml_file.include?('Hot_Water') ||
     hpxml_file.include?('EPA_Tests/SF_National_3.2') ||
     hpxml_file.include?('EPA_Tests/SF_National_3.1') ||
     hpxml_file.include?('EPA_Tests/MF_National_1.2') ||
     hpxml_file.include?('EPA_Tests/MF_National_1.1')
    # No leakage
    hpxml.hvac_distributions[0].duct_leakage_measurements.clear
    hpxml.hvac_distributions[0].duct_leakage_measurements.add(duct_type: HPXML::DuctTypeSupply,
                                                              duct_leakage_units: HPXML::UnitsCFM25,
                                                              duct_leakage_value: 0,
                                                              duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside)
    hpxml.hvac_distributions[0].duct_leakage_measurements.add(duct_type: HPXML::DuctTypeReturn,
                                                              duct_leakage_units: HPXML::UnitsCFM25,
                                                              duct_leakage_value: 0,
                                                              duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside)
  elsif ['RESNET_Tests/4.5_DSE/HVAC3d.xml',
         'RESNET_Tests/4.5_DSE/HVAC3h.xml'].include? hpxml_file
    # Supply and return duct leakage = 125 cfm each
    for i in 0..hpxml.hvac_distributions[0].duct_leakage_measurements.size - 1
      hpxml.hvac_distributions[0].duct_leakage_measurements[i].duct_leakage_value = 125
    end
  elsif hpxml_file.include?('EPA_Tests')
    tot_cfm25 = 4.0 * hpxml.building_construction.conditioned_floor_area / 100.0
    hpxml.hvac_distributions[0].duct_leakage_measurements.clear
    hpxml.hvac_distributions[0].duct_leakage_measurements.add(duct_type: HPXML::DuctTypeSupply,
                                                              duct_leakage_units: HPXML::UnitsCFM25,
                                                              duct_leakage_value: (tot_cfm25 * 0.5).round(2),
                                                              duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside)
    hpxml.hvac_distributions[0].duct_leakage_measurements.add(duct_type: HPXML::DuctTypeReturn,
                                                              duct_leakage_units: HPXML::UnitsCFM25,
                                                              duct_leakage_value: (tot_cfm25 * 0.5).round(2),
                                                              duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside)
  end

  # Ducts
  if ['RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/01-L100.xml',
      'RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/02-L100.xml',
      'RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/03-L304.xml',
      'RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/04-L324.xml',
      'RESNET_Tests/4.3_HERS_Method/L100A-01.xml',
      'RESNET_Tests/4.5_DSE/HVAC3a.xml',
      'RESNET_Tests/4.5_DSE/HVAC3e.xml'].include?(hpxml_file) ||
     hpxml_file.include?('Hot_Water')
    # Supply duct area = 308 ft2; Return duct area = 77 ft2
    # Duct R-val = 0
    # Duct Location = 100% conditioned
    hpxml.hvac_distributions[0].ducts.clear
    hpxml.hvac_distributions[0].ducts.add(id: "Duct#{hpxml.hvac_distributions[0].ducts.size + 1}",
                                          duct_type: HPXML::DuctTypeSupply,
                                          duct_insulation_r_value: 0,
                                          duct_location: HPXML::LocationLivingSpace,
                                          duct_surface_area: 308)
    hpxml.hvac_distributions[0].ducts.add(id: "Duct#{hpxml.hvac_distributions[0].ducts.size + 1}",
                                          duct_type: HPXML::DuctTypeReturn,
                                          duct_insulation_r_value: 0,
                                          duct_location: HPXML::LocationLivingSpace,
                                          duct_surface_area: 77)
  elsif ['RESNET_Tests/4.5_DSE/HVAC3b.xml'].include? hpxml_file
    # Change to Duct Location = 100% in basement
    for i in 0..hpxml.hvac_distributions[0].ducts.size - 1
      hpxml.hvac_distributions[0].ducts[i].duct_location = HPXML::LocationBasementUnconditioned
    end
  elsif ['RESNET_Tests/4.5_DSE/HVAC3f.xml'].include? hpxml_file
    # Change to Duct Location = 100% in attic
    for i in 0..hpxml.hvac_distributions[0].ducts.size - 1
      hpxml.hvac_distributions[0].ducts[i].duct_location = HPXML::LocationAtticVented
    end
  elsif ['RESNET_Tests/4.5_DSE/HVAC3c.xml',
         'RESNET_Tests/4.5_DSE/HVAC3g.xml'].include? hpxml_file
    # Change to Duct R-val = 6
    for i in 0..hpxml.hvac_distributions[0].ducts.size - 1
      hpxml.hvac_distributions[0].ducts[i].duct_insulation_r_value = 6
    end
  elsif hpxml_file.include?('EPA_Tests')
    supply_area = 0.27 * hpxml.building_construction.conditioned_floor_area
    return_area = 0.05 * hpxml.building_construction.conditioned_floor_area
    if hpxml_file.include?('SF_National_3.2') || hpxml_file.include?('SF_National_3.1') ||
       hpxml_file.include?('MF_National_1.2') || hpxml_file.include?('MF_National_1.1') || hpxml_file.include?('MF_National_1.0')
      if hpxml_file.include?('MF_National_1.0') && hpxml_file.include?('top_corner')
        location = HPXML::LocationAtticVented
        supply_r = 8
        return_r = 6
      else
        location = HPXML::LocationLivingSpace
        supply_r = 0
        return_r = 0
      end
      hpxml.hvac_distributions[0].ducts.clear
      hpxml.hvac_distributions[0].ducts.add(id: "Duct#{hpxml.hvac_distributions[0].ducts.size + 1}",
                                            duct_type: HPXML::DuctTypeSupply,
                                            duct_insulation_r_value: supply_r,
                                            duct_location: location,
                                            duct_surface_area: supply_area.round(2))
      hpxml.hvac_distributions[0].ducts.add(id: "Duct#{hpxml.hvac_distributions[0].ducts.size + 1}",
                                            duct_type: HPXML::DuctTypeReturn,
                                            duct_insulation_r_value: return_r,
                                            duct_location: location,
                                            duct_surface_area: return_area.round(2))
    elsif hpxml_file.include?('SF_National_3.0')
      if hpxml_file.include?('slab')
        non_attic_location = HPXML::LocationLivingSpace
        non_attic_frac = 0.25
      elsif hpxml_file.include?('vented_crawl')
        non_attic_location = HPXML::LocationCrawlspaceVented
        non_attic_frac = 0.5
      elsif hpxml_file.include?('cond_bsmt')
        non_attic_location = HPXML::LocationBasementConditioned
        non_attic_frac = 0.5
      end
      if non_attic_location == HPXML::LocationBasementConditioned
        non_attic_rvalue = 0
      else
        non_attic_rvalue = 6
      end
      hpxml.hvac_distributions[0].ducts.clear
      hpxml.hvac_distributions[0].ducts.add(id: "Duct#{hpxml.hvac_distributions[0].ducts.size + 1}",
                                            duct_type: HPXML::DuctTypeSupply,
                                            duct_insulation_r_value: 8,
                                            duct_location: HPXML::LocationAtticVented,
                                            duct_surface_area: (supply_area * (1.0 - non_attic_frac)).round(2))
      hpxml.hvac_distributions[0].ducts.add(id: "Duct#{hpxml.hvac_distributions[0].ducts.size + 1}",
                                            duct_type: HPXML::DuctTypeReturn,
                                            duct_insulation_r_value: 6,
                                            duct_location: HPXML::LocationAtticVented,
                                            duct_surface_area: (return_area * (1.0 - non_attic_frac)).round(2))
      hpxml.hvac_distributions[0].ducts.add(id: "Duct#{hpxml.hvac_distributions[0].ducts.size + 1}",
                                            duct_type: HPXML::DuctTypeSupply,
                                            duct_insulation_r_value: non_attic_rvalue,
                                            duct_location: non_attic_location,
                                            duct_surface_area: (supply_area * non_attic_frac).round(2))
      hpxml.hvac_distributions[0].ducts.add(id: "Duct#{hpxml.hvac_distributions[0].ducts.size + 1}",
                                            duct_type: HPXML::DuctTypeReturn,
                                            duct_insulation_r_value: non_attic_rvalue,
                                            duct_location: non_attic_location,
                                            duct_surface_area: (return_area * non_attic_frac).round(2))
    end
  end

  # CFA served
  if hpxml.hvac_distributions.size == 1
    hpxml.hvac_distributions[0].conditioned_floor_area_served = hpxml.building_construction.conditioned_floor_area
  end

  # Return registers
  if hpxml_file.include?('EPA_Tests')
    hpxml.hvac_distributions[0].number_of_return_registers = 1
  else
    hpxml.hvac_distributions.each do |hvac_distribution|
      next unless hvac_distribution.distribution_system_type == HPXML::HVACDistributionTypeAir

      hvac_distribution.number_of_return_registers = hpxml.building_construction.number_of_conditioned_floors
    end
  end
end

def set_hpxml_ventilation_fans(hpxml_file, hpxml)
  if ['RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/02-L100.xml'].include? hpxml_file
    # Exhaust-only whole-dwelling mechanical ventilation
    hpxml.ventilation_fans.clear
    hpxml.ventilation_fans.add(id: "VentilationFan#{hpxml.ventilation_fans.size + 1}",
                               fan_type: HPXML::MechVentTypeExhaust,
                               tested_flow_rate: 56.2,
                               hours_in_operation: 24,
                               fan_power: 14.7,
                               used_for_whole_building_ventilation: true,
                               is_shared_system: false)
  elsif ['RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/03-L304.xml'].include? hpxml_file
    # Balanced whole-dwelling mechanical ventilation without energy recovery
    hpxml.ventilation_fans.clear
    hpxml.ventilation_fans.add(id: "VentilationFan#{hpxml.ventilation_fans.size + 1}",
                               fan_type: HPXML::MechVentTypeBalanced,
                               tested_flow_rate: 56.2,
                               hours_in_operation: 24,
                               fan_power: 14.7,
                               used_for_whole_building_ventilation: true,
                               is_shared_system: false)
  elsif ['RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/04-L324.xml'].include? hpxml_file
    # Balanced whole-dwelling mechanical ventilation with a 60% energy recovery system
    hpxml.ventilation_fans.clear
    hpxml.ventilation_fans.add(id: "VentilationFan#{hpxml.ventilation_fans.size + 1}",
                               fan_type: HPXML::MechVentTypeERV,
                               tested_flow_rate: 56.2,
                               hours_in_operation: 24,
                               sensible_recovery_efficiency: 0.6,
                               total_recovery_efficiency: 0.4, # Unspecified
                               fan_power: 14.7,
                               used_for_whole_building_ventilation: true,
                               is_shared_system: false)
  elsif hpxml_file.include?('EPA_Tests')
    if hpxml_file.include?('CZ2') || hpxml_file.include?('CZ4')
      fan_type = HPXML::MechVentTypeSupply
    elsif hpxml_file.include?('CZ6')
      fan_type = HPXML::MechVentTypeExhaust
    end
    tested_flow_rate = (0.01 * hpxml.building_construction.conditioned_floor_area + 7.5 * (hpxml.building_construction.number_of_bedrooms + 1)).round(2)
    if hpxml_file.include?('SF_National_3.2') || hpxml_file.include?('SF_National_3.1') ||
       hpxml_file.include?('MF_National_1.2') || hpxml_file.include?('MF_National_1.1')
      cfm_per_w = 2.8
    elsif hpxml_file.include?('SF_National_3.0') || hpxml_file.include?('MF_National_1.0')
      cfm_per_w = 2.2
    end
    hpxml.ventilation_fans.clear
    hpxml.ventilation_fans.add(id: "VentilationFan#{hpxml.ventilation_fans.size + 1}",
                               fan_type: fan_type,
                               tested_flow_rate: tested_flow_rate,
                               hours_in_operation: 24,
                               fan_power: (tested_flow_rate / cfm_per_w).round(3),
                               used_for_whole_building_ventilation: true,
                               is_shared_system: false)
  end
end

def set_hpxml_water_heating_systems(hpxml_file, hpxml)
  if ['RESNET_Tests/4.3_HERS_Method/L100A-01.xml'].include? hpxml_file
    # 40 gal electric with EF = 0.88
    hpxml.water_heating_systems.clear
    hpxml.water_heating_systems.add(id: "WaterHeatingSystem#{hpxml.water_heating_systems.size + 1}",
                                    is_shared_system: false,
                                    fuel_type: HPXML::FuelTypeElectricity,
                                    water_heater_type: HPXML::WaterHeaterTypeStorage,
                                    location: HPXML::LocationLivingSpace,
                                    tank_volume: 40,
                                    fraction_dhw_load_served: 1,
                                    energy_factor: 0.88)
  elsif ['RESNET_Tests/4.3_HERS_Method/L100A-02.xml'].include? hpxml_file
    # Tankless natural gas with EF = 0.82
    hpxml.water_heating_systems.clear
    hpxml.water_heating_systems.add(id: "WaterHeatingSystem#{hpxml.water_heating_systems.size + 1}",
                                    is_shared_system: false,
                                    fuel_type: HPXML::FuelTypeNaturalGas,
                                    water_heater_type: HPXML::WaterHeaterTypeTankless,
                                    location: HPXML::LocationLivingSpace,
                                    fraction_dhw_load_served: 1,
                                    energy_factor: 0.82)
  elsif ['RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AD-HW-01.xml',
         'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AM-HW-01.xml'].include? hpxml_file
    # 40 gallon storage; gas; EF = 0.56; RE = 0.78; conditioned space
    hpxml.water_heating_systems.clear
    hpxml.water_heating_systems.add(id: "WaterHeatingSystem#{hpxml.water_heating_systems.size + 1}",
                                    is_shared_system: false,
                                    fuel_type: HPXML::FuelTypeNaturalGas,
                                    water_heater_type: HPXML::WaterHeaterTypeStorage,
                                    location: HPXML::LocationLivingSpace,
                                    tank_volume: 40,
                                    fraction_dhw_load_served: 1,
                                    energy_factor: 0.56,
                                    recovery_efficiency: 0.78)
  elsif ['RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AD-HW-03.xml',
         'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AM-HW-03.xml'].include? hpxml_file
    # 40 gallon storage; gas; EF = 0.62; RE = 0.78; conditioned space
    hpxml.water_heating_systems.clear
    hpxml.water_heating_systems.add(id: "WaterHeatingSystem#{hpxml.water_heating_systems.size + 1}",
                                    is_shared_system: false,
                                    fuel_type: HPXML::FuelTypeNaturalGas,
                                    water_heater_type: HPXML::WaterHeaterTypeStorage,
                                    location: HPXML::LocationLivingSpace,
                                    tank_volume: 40,
                                    fraction_dhw_load_served: 1,
                                    energy_factor: 0.62,
                                    recovery_efficiency: 0.78)
  elsif hpxml_file.include?('HERS_AutoGen')
    # 40 gal electric with EF = 0.92
    hpxml.water_heating_systems.clear
    hpxml.water_heating_systems.add(id: "WaterHeatingSystem#{hpxml.water_heating_systems.size + 1}",
                                    is_shared_system: false,
                                    fuel_type: HPXML::FuelTypeElectricity,
                                    water_heater_type: HPXML::WaterHeaterTypeStorage,
                                    location: HPXML::LocationLivingSpace,
                                    tank_volume: 40,
                                    fraction_dhw_load_served: 1,
                                    energy_factor: 0.92)
  elsif hpxml_file.include?('EPA_Tests')
    hpxml.water_heating_systems.clear
    if hpxml_file.include?('_gas_')
      if hpxml_file.include?('EPA_Tests/MF')
        if hpxml_file.include?('MF_National_1.2')
          water_heater_type = HPXML::WaterHeaterTypeTankless
          uniform_energy_factor = 0.9
        else
          water_heater_type = HPXML::WaterHeaterTypeStorage
          tank_volume = 40
          energy_factor = 0.67
        end
      else
        if hpxml_file.include?('SF_National_3.2')
          water_heater_type = HPXML::WaterHeaterTypeTankless
          uniform_energy_factor = 0.9
        else
          water_heater_type = HPXML::WaterHeaterTypeStorage
          tank_volume = 40
          energy_factor = 0.61
        end
      end
      hpxml.water_heating_systems.add(id: "WaterHeatingSystem#{hpxml.water_heating_systems.size + 1}",
                                      is_shared_system: false,
                                      fuel_type: HPXML::FuelTypeNaturalGas,
                                      water_heater_type: water_heater_type,
                                      location: HPXML::LocationLivingSpace,
                                      tank_volume: tank_volume,
                                      fraction_dhw_load_served: 1,
                                      energy_factor: energy_factor,
                                      uniform_energy_factor: uniform_energy_factor)
    elsif hpxml_file.include?('_elec_')
      if hpxml_file.include?('EPA_Tests/MF')
        if hpxml_file.include?('MF_National_1.2')
          water_heater_type = HPXML::WaterHeaterTypeHeatPump
          tank_volume = 60
          uniform_energy_factor = 1.49
          first_hour_rating = 40
        else
          water_heater_type = HPXML::WaterHeaterTypeStorage
          tank_volume = 40
          energy_factor = 0.95
        end
      else
        if hpxml_file.include?('SF_National_3.2')
          water_heater_type = HPXML::WaterHeaterTypeHeatPump
          tank_volume = 60
          uniform_energy_factor = 2.2
          first_hour_rating = 40
        else
          water_heater_type = HPXML::WaterHeaterTypeStorage
          tank_volume = 40
          energy_factor = 0.93
        end
      end
      hpxml.water_heating_systems.add(id: "WaterHeatingSystem#{hpxml.water_heating_systems.size + 1}",
                                      is_shared_system: false,
                                      fuel_type: HPXML::FuelTypeElectricity,
                                      water_heater_type: water_heater_type,
                                      location: HPXML::LocationLivingSpace,
                                      tank_volume: tank_volume,
                                      fraction_dhw_load_served: 1,
                                      energy_factor: energy_factor,
                                      uniform_energy_factor: uniform_energy_factor,
                                      first_hour_rating: first_hour_rating)
    end
  end
end

def set_hpxml_hot_water_distribution(hpxml_file, hpxml)
  if ['RESNET_Tests/4.3_HERS_Method/L100A-01.xml',
      'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AD-HW-01.xml',
      'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AM-HW-01.xml'].include?(hpxml_file) ||
     hpxml_file.include?('EPA_Tests')
    # Standard
    hpxml.hot_water_distributions.clear
    hpxml.hot_water_distributions.add(id: "HotWaterDstribution#{hpxml.hot_water_distributions.size + 1}",
                                      system_type: HPXML::DHWDistTypeStandard,
                                      pipe_r_value: 0.0)
  elsif ['RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AD-HW-05.xml',
         'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AM-HW-05.xml'].include? hpxml_file
    # Change to recirculation: Control = none; 50 W pump; Loop length is same as reference loop length; Branch length is 10 ft; All hot water pipes insulated to R-3
    hpxml.hot_water_distributions[0].system_type = HPXML::DHWDistTypeRecirc
    hpxml.hot_water_distributions[0].recirculation_control_type = HPXML::DHWRecirControlTypeNone
    hpxml.hot_water_distributions[0].recirculation_branch_piping_length = 10
    hpxml.hot_water_distributions[0].recirculation_pump_power = 50
    hpxml.hot_water_distributions[0].pipe_r_value = 3
  elsif ['RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AD-HW-06.xml',
         'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AM-HW-06.xml'].include? hpxml_file
    # Change to recirculation: Control = manual
    hpxml.hot_water_distributions[0].recirculation_control_type = HPXML::DHWRecirControlTypeManual
  elsif ['RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AD-HW-07.xml',
         'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AM-HW-07.xml'].include? hpxml_file
    # Change to drain Water Heat Recovery (DWHR) with all facilities connected; equal flow; DWHR eff = 54%
    hpxml.hot_water_distributions[0].dwhr_facilities_connected = HPXML::DWHRFacilitiesConnectedAll
    hpxml.hot_water_distributions[0].dwhr_equal_flow = true
    hpxml.hot_water_distributions[0].dwhr_efficiency = 0.54
  elsif hpxml_file.include?('HERS_AutoGen')
    # Standard
    hpxml.hot_water_distributions.clear
    hpxml.hot_water_distributions.add(id: "HotWaterDstribution#{hpxml.hot_water_distributions.size + 1}",
                                      system_type: HPXML::DHWDistTypeStandard,
                                      pipe_r_value: 0.0)
  end

  has_uncond_bsmnt = false
  hpxml.foundation_walls.each do |foundation_wall|
    next unless [foundation_wall.interior_adjacent_to, foundation_wall.exterior_adjacent_to].include? HPXML::LocationBasementUnconditioned

    has_uncond_bsmnt = true
  end
  cfa = hpxml.building_construction.conditioned_floor_area
  ncfl = hpxml.building_construction.number_of_conditioned_floors
  piping_length = HotWaterAndAppliances.get_default_std_pipe_length(has_uncond_bsmnt, cfa, ncfl)

  if hpxml.hot_water_distributions.size > 0
    if hpxml.hot_water_distributions[0].system_type == HPXML::DHWDistTypeStandard
      hpxml.hot_water_distributions[0].standard_piping_length = piping_length.round(3)
    elsif hpxml.hot_water_distributions[0].system_type == HPXML::DHWDistTypeRecirc
      hpxml.hot_water_distributions[0].recirculation_piping_length = HotWaterAndAppliances.get_default_recirc_loop_length(piping_length).round(3)
    end
  end
end

def set_hpxml_water_fixtures(hpxml_file, hpxml)
  if ['RESNET_Tests/4.3_HERS_Method/L100A-01.xml',
      'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AD-HW-01.xml',
      'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AM-HW-01.xml'].include?(hpxml_file) ||
     hpxml_file.include?('EPA_Tests/SF')
    # Standard
    hpxml.water_fixtures.clear
    hpxml.water_fixtures.add(id: "WaterFixture#{hpxml.water_fixtures.size + 1}",
                             water_fixture_type: HPXML::WaterFixtureTypeShowerhead,
                             low_flow: false)
    hpxml.water_fixtures.add(id: "WaterFixture#{hpxml.water_fixtures.size + 1}",
                             water_fixture_type: HPXML::WaterFixtureTypeFaucet,
                             low_flow: false)
  elsif ['RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AD-HW-04.xml',
         'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AM-HW-04.xml'].include?(hpxml_file) ||
        hpxml_file.include?('EPA_Tests/MF')
    # Low-flow
    hpxml.water_fixtures.clear
    hpxml.water_fixtures.add(id: "WaterFixture#{hpxml.water_fixtures.size + 1}",
                             water_fixture_type: HPXML::WaterFixtureTypeShowerhead,
                             low_flow: true)
    hpxml.water_fixtures.add(id: "WaterFixture#{hpxml.water_fixtures.size + 1}",
                             water_fixture_type: HPXML::WaterFixtureTypeFaucet,
                             low_flow: true)
  elsif hpxml_file.include?('HERS_AutoGen')
    # Standard
    hpxml.water_fixtures.clear
    hpxml.water_fixtures.add(id: "WaterFixture#{hpxml.water_fixtures.size + 1}",
                             water_fixture_type: HPXML::WaterFixtureTypeShowerhead,
                             low_flow: false)
    hpxml.water_fixtures.add(id: "WaterFixture#{hpxml.water_fixtures.size + 1}",
                             water_fixture_type: HPXML::WaterFixtureTypeFaucet,
                             low_flow: false)
  end
end

def set_hpxml_clothes_washer(hpxml_file, hpxml)
  return unless hpxml_file.include?('HERS_AutoGen') || hpxml_file.include?('HERS_Method') || hpxml_file.include?('Hot_Water') || hpxml_file.include?('EPA_Tests')

  if hpxml_file.include?('SF_National_3.2') || hpxml_file.include?('MF_National_1.2')
    default_values = { integrated_modified_energy_factor: 1.57, # ft3/(kWh/cyc)
                       rated_annual_kwh: 284.0, # kWh/yr
                       label_electric_rate: 0.12, # $/kWh
                       label_gas_rate: 1.09, # $/therm
                       label_annual_gas_cost: 18.0, # $
                       capacity: 4.2, # ft^3
                       label_usage: 6.0 } # cyc/week
  else
    default_values = HotWaterAndAppliances.get_clothes_washer_default_values(get_eri_version(hpxml))
  end

  hpxml.clothes_washers.clear
  hpxml.clothes_washers.add(id: "ClothesWasher#{hpxml.clothes_washers.size + 1}",
                            is_shared_appliance: false,
                            location: HPXML::LocationLivingSpace,
                            integrated_modified_energy_factor: default_values[:integrated_modified_energy_factor],
                            rated_annual_kwh: default_values[:rated_annual_kwh],
                            label_electric_rate: default_values[:label_electric_rate],
                            label_gas_rate: default_values[:label_gas_rate],
                            label_annual_gas_cost: default_values[:label_annual_gas_cost],
                            label_usage: default_values[:label_usage],
                            capacity: default_values[:capacity])
end

def set_hpxml_clothes_dryer(hpxml_file, hpxml)
  return unless hpxml_file.include?('HERS_AutoGen') || hpxml_file.include?('HERS_Method') || hpxml_file.include?('Hot_Water') || hpxml_file.include?('EPA_Tests')

  if ['RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/01-L100.xml',
      'RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/04-L324.xml',
      'RESNET_Tests/4.3_HERS_Method/L100A-02.xml',
      'RESNET_Tests/4.3_HERS_Method/L100A-03.xml',
      'RESNET_Tests/4.3_HERS_Method/L100A-05.xml',
      'RESNET_Tests/Other_HERS_Method_301_2014_PreAddendumE/L100A-02.xml',
      'RESNET_Tests/Other_HERS_Method_301_2014_PreAddendumE/L100A-03.xml',
      'RESNET_Tests/Other_HERS_Method_301_2014_PreAddendumE/L100A-05.xml',
      'RESNET_Tests/Other_HERS_Method_301_2019_PreAddendumA/L100A-02.xml',
      'RESNET_Tests/Other_HERS_Method_301_2019_PreAddendumA/L100A-03.xml',
      'RESNET_Tests/Other_HERS_Method_301_2019_PreAddendumA/L100A-05.xml'].include?(hpxml_file) ||
     (hpxml_file.include?('EPA_Tests') && hpxml_file.include?('_gas_'))
    # Standard gas
    default_values = HotWaterAndAppliances.get_clothes_dryer_default_values(get_eri_version(hpxml), HPXML::FuelTypeNaturalGas)
    hpxml.clothes_dryers.clear
    hpxml.clothes_dryers.add(id: "ClothesDryer#{hpxml.clothes_dryers.size + 1}",
                             is_shared_appliance: false,
                             location: HPXML::LocationLivingSpace,
                             fuel_type: HPXML::FuelTypeNaturalGas,
                             control_type: default_values[:control_type],
                             combined_energy_factor: default_values[:combined_energy_factor])
  elsif ['RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/02-L100.xml',
         'RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/03-L304.xml',
         'RESNET_Tests/4.3_HERS_Method/L100A-01.xml',
         'RESNET_Tests/Other_HERS_Method_301_2014_PreAddendumE/L100A-01.xml',
         'RESNET_Tests/Other_HERS_Method_301_2014_PreAddendumE/L100A-04.xml',
         'RESNET_Tests/Other_HERS_Method_301_2019_PreAddendumA/L100A-01.xml',
         'RESNET_Tests/Other_HERS_Method_301_2019_PreAddendumA/L100A-04.xml',
         'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AD-HW-01.xml',
         'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AM-HW-01.xml'].include?(hpxml_file) ||
        (hpxml_file.include?('EPA_Tests') && hpxml_file.include?('_elec_'))
    # Standard electric
    default_values = HotWaterAndAppliances.get_clothes_dryer_default_values(get_eri_version(hpxml), HPXML::FuelTypeElectricity)
    hpxml.clothes_dryers.clear
    hpxml.clothes_dryers.add(id: "ClothesDryer#{hpxml.clothes_dryers.size + 1}",
                             is_shared_appliance: false,
                             location: HPXML::LocationLivingSpace,
                             fuel_type: HPXML::FuelTypeElectricity,
                             control_type: default_values[:control_type],
                             combined_energy_factor: default_values[:combined_energy_factor])
  end
end

def set_hpxml_dishwasher(hpxml_file, hpxml)
  if hpxml_file.include?('EPA_Tests')
    hpxml.dishwashers.clear
    hpxml.dishwashers.add(id: "Dishwasher#{hpxml.dishwashers.size + 1}",
                          is_shared_appliance: false,
                          location: HPXML::LocationLivingSpace,
                          place_setting_capacity: 12,
                          rated_annual_kwh: 270,
                          label_electric_rate: 0.12,
                          label_gas_rate: 1.09,
                          label_annual_gas_cost: 22.23,
                          label_usage: 208 / 52)
  elsif hpxml_file.include?('HERS_AutoGen') || hpxml_file.include?('HERS_Method') || hpxml_file.include?('Hot_Water')
    default_values = HotWaterAndAppliances.get_dishwasher_default_values(get_eri_version(hpxml))
    hpxml.dishwashers.clear
    hpxml.dishwashers.add(id: "Dishwasher#{hpxml.dishwashers.size + 1}",
                          is_shared_appliance: false,
                          location: HPXML::LocationLivingSpace,
                          place_setting_capacity: default_values[:place_setting_capacity],
                          rated_annual_kwh: default_values[:rated_annual_kwh],
                          label_electric_rate: default_values[:label_electric_rate],
                          label_gas_rate: default_values[:label_gas_rate],
                          label_annual_gas_cost: default_values[:label_annual_gas_cost],
                          label_usage: default_values[:label_usage])
  end
end

def set_hpxml_refrigerator(hpxml_file, hpxml)
  if hpxml_file.include?('EPA_Tests')
    hpxml.refrigerators.clear

    if hpxml_file.include?('SF_National_3.2') || hpxml_file.include?('MF_National_1.2')
      rated_annual_kwh = 450.0
    else
      rated_annual_kwh = 423.0
    end

    hpxml.refrigerators.add(id: "Refrigerator#{hpxml.refrigerators.size + 1}",
                            location: HPXML::LocationLivingSpace,
                            rated_annual_kwh: rated_annual_kwh)
  elsif hpxml_file.include?('HERS_AutoGen') || hpxml_file.include?('HERS_Method') || hpxml_file.include?('Hot_Water')
    # Standard
    default_values = HotWaterAndAppliances.get_refrigerator_default_values(hpxml.building_construction.number_of_bedrooms)
    hpxml.refrigerators.clear
    hpxml.refrigerators.add(id: "Refrigerator#{hpxml.refrigerators.size + 1}",
                            location: HPXML::LocationLivingSpace,
                            rated_annual_kwh: default_values[:rated_annual_kwh])
  end
end

def set_hpxml_cooking_range(hpxml_file, hpxml)
  return unless hpxml_file.include?('HERS_AutoGen') || hpxml_file.include?('HERS_Method') || hpxml_file.include?('Hot_Water') || hpxml_file.include?('EPA_Tests')

  if ['RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/01-L100.xml',
      'RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/04-L324.xml',
      'RESNET_Tests/4.3_HERS_Method/L100A-02.xml',
      'RESNET_Tests/4.3_HERS_Method/L100A-03.xml',
      'RESNET_Tests/4.3_HERS_Method/L100A-05.xml',
      'RESNET_Tests/Other_HERS_Method_301_2014_PreAddendumE/L100A-02.xml',
      'RESNET_Tests/Other_HERS_Method_301_2014_PreAddendumE/L100A-03.xml',
      'RESNET_Tests/Other_HERS_Method_301_2014_PreAddendumE/L100A-05.xml',
      'RESNET_Tests/Other_HERS_Method_301_2019_PreAddendumA/L100A-02.xml',
      'RESNET_Tests/Other_HERS_Method_301_2019_PreAddendumA/L100A-03.xml',
      'RESNET_Tests/Other_HERS_Method_301_2019_PreAddendumA/L100A-05.xml'].include?(hpxml_file) ||
     (hpxml_file.include?('EPA_Tests') && hpxml_file.include?('_gas_'))
    # Standard gas
    default_values = HotWaterAndAppliances.get_range_oven_default_values()
    hpxml.cooking_ranges.clear
    hpxml.cooking_ranges.add(id: "CookingRange#{hpxml.cooking_ranges.size + 1}",
                             location: HPXML::LocationLivingSpace,
                             fuel_type: HPXML::FuelTypeNaturalGas,
                             is_induction: default_values[:is_induction])
  elsif ['RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/02-L100.xml',
         'RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/03-L304.xml',
         'RESNET_Tests/4.3_HERS_Method/L100A-01.xml',
         'RESNET_Tests/Other_HERS_Method_301_2014_PreAddendumE/L100A-01.xml',
         'RESNET_Tests/Other_HERS_Method_301_2019_PreAddendumA/L100A-01.xml',
         'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AD-HW-01.xml',
         'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AM-HW-01.xml'].include?(hpxml_file) ||
        (hpxml_file.include?('EPA_Tests') && hpxml_file.include?('_elec_'))
    # Standard electric
    default_values = HotWaterAndAppliances.get_range_oven_default_values()
    hpxml.cooking_ranges.clear
    hpxml.cooking_ranges.add(id: "CookingRange#{hpxml.cooking_ranges.size + 1}",
                             location: HPXML::LocationLivingSpace,
                             fuel_type: HPXML::FuelTypeElectricity,
                             is_induction: default_values[:is_induction])
  end
end

def set_hpxml_oven(hpxml_file, hpxml)
  return unless hpxml_file.include?('HERS_AutoGen') || hpxml_file.include?('HERS_Method') || hpxml_file.include?('Hot_Water') || hpxml_file.include?('EPA_Tests')

  default_values = HotWaterAndAppliances.get_range_oven_default_values()
  hpxml.ovens.clear
  hpxml.ovens.add(id: "Oven#{hpxml.ovens.size + 1}",
                  is_convection: default_values[:is_convection])
end

def set_hpxml_lighting(hpxml_file, hpxml)
  return unless hpxml_file.include?('HERS_AutoGen') || hpxml_file.include?('HERS_Method') || hpxml_file.include?('Hot_Water') || hpxml_file.include?('EPA_Tests')

  if hpxml_file.include?('EPA_Tests/SF_National_3.2')
    ltg_fracs = { [HPXML::LocationInterior, HPXML::LightingTypeLED] => 1.0,
                  [HPXML::LocationExterior, HPXML::LightingTypeLED] => 1.0,
                  [HPXML::LocationGarage, HPXML::LightingTypeLED] => 1.0,
                  [HPXML::LocationInterior, HPXML::LightingTypeCFL] => 0,
                  [HPXML::LocationExterior, HPXML::LightingTypeCFL] => 0,
                  [HPXML::LocationGarage, HPXML::LightingTypeCFL] => 0,
                  [HPXML::LocationInterior, HPXML::LightingTypeLFL] => 0,
                  [HPXML::LocationExterior, HPXML::LightingTypeLFL] => 0,
                  [HPXML::LocationGarage, HPXML::LightingTypeLFL] => 0 }
  elsif hpxml_file.include?('EPA_Tests/MF_National_1.2')
    ltg_fracs = { [HPXML::LocationInterior, HPXML::LightingTypeLED] => 0,
                  [HPXML::LocationExterior, HPXML::LightingTypeLED] => 0,
                  [HPXML::LocationGarage, HPXML::LightingTypeLED] => 0,
                  [HPXML::LocationInterior, HPXML::LightingTypeCFL] => 1.0,
                  [HPXML::LocationExterior, HPXML::LightingTypeCFL] => 1.0,
                  [HPXML::LocationGarage, HPXML::LightingTypeCFL] => 1.0,
                  [HPXML::LocationInterior, HPXML::LightingTypeLFL] => 0,
                  [HPXML::LocationExterior, HPXML::LightingTypeLFL] => 0,
                  [HPXML::LocationGarage, HPXML::LightingTypeLFL] => 0 }
  elsif hpxml_file.include?('EPA_Tests/SF_National_3.1') || hpxml_file.include?('EPA_Tests/MF_National_1.1') || hpxml_file.include?('EPA_Tests/MF_National_1.0')
    ltg_fracs = { [HPXML::LocationInterior, HPXML::LightingTypeLED] => 0,
                  [HPXML::LocationExterior, HPXML::LightingTypeLED] => 0,
                  [HPXML::LocationGarage, HPXML::LightingTypeLED] => 0,
                  [HPXML::LocationInterior, HPXML::LightingTypeCFL] => 0.9,
                  [HPXML::LocationExterior, HPXML::LightingTypeCFL] => 0,
                  [HPXML::LocationGarage, HPXML::LightingTypeCFL] => 0,
                  [HPXML::LocationInterior, HPXML::LightingTypeLFL] => 0,
                  [HPXML::LocationExterior, HPXML::LightingTypeLFL] => 0,
                  [HPXML::LocationGarage, HPXML::LightingTypeLFL] => 0 }
  elsif hpxml_file.include?('EPA_Tests/SF_National_3.0')
    ltg_fracs = { [HPXML::LocationInterior, HPXML::LightingTypeLED] => 0,
                  [HPXML::LocationExterior, HPXML::LightingTypeLED] => 0,
                  [HPXML::LocationGarage, HPXML::LightingTypeLED] => 0,
                  [HPXML::LocationInterior, HPXML::LightingTypeCFL] => 0.8,
                  [HPXML::LocationExterior, HPXML::LightingTypeCFL] => 0,
                  [HPXML::LocationGarage, HPXML::LightingTypeCFL] => 0,
                  [HPXML::LocationInterior, HPXML::LightingTypeLFL] => 0,
                  [HPXML::LocationExterior, HPXML::LightingTypeLFL] => 0,
                  [HPXML::LocationGarage, HPXML::LightingTypeLFL] => 0 }
  else
    ltg_fracs = Lighting.get_default_fractions()
  end

  hpxml.lighting_groups.clear
  ltg_fracs.each do |key, fraction|
    location, lighting_type = key
    hpxml.lighting_groups.add(id: "LightingGroup#{hpxml.lighting_groups.size + 1}",
                              location: location,
                              fraction_of_units_in_location: fraction,
                              lighting_type: lighting_type)
  end
end

def set_hpxml_plug_loads(hpxml_file, hpxml)
  return unless hpxml_file.include?('HERS_AutoGen') || hpxml_file.include?('HERS_Method') || hpxml_file.include?('Hot_Water') || hpxml_file.include?('EPA_Tests')

  hpxml.plug_loads.clear
end

def get_eri_version(hpxml)
  eri_version = hpxml.header.eri_calculation_version
  eri_version = Constants.ERIVersions[-1] if (eri_version == 'latest' || eri_version.nil?)
  return eri_version
end

def create_sample_hpxmls
  # Copy sample files from hpxml-measures subtree
  puts 'Copying sample files...'
  FileUtils.rm_f(Dir.glob('workflow/sample_files/*.xml'))

  # Copy files we're interested in
  include_list = ['base.xml',
                  'base-appliances-dehumidifier.xml',
                  'base-appliances-dehumidifier-ief-portable.xml',
                  'base-appliances-dehumidifier-ief-whole-home.xml',
                  'base-appliances-dehumidifier-multiple.xml',
                  'base-appliances-gas.xml',
                  'base-appliances-modified.xml',
                  'base-appliances-none.xml',
                  'base-appliances-oil.xml',
                  'base-appliances-propane.xml',
                  'base-appliances-wood.xml',
                  'base-atticroof-cathedral.xml',
                  'base-atticroof-conditioned.xml',
                  'base-atticroof-flat.xml',
                  'base-atticroof-radiant-barrier.xml',
                  'base-atticroof-unvented-insulated-roof.xml',
                  'base-atticroof-vented.xml',
                  # 'base-battery.xml',
                  'base-bldgtype-multifamily.xml',
                  'base-bldgtype-multifamily-adjacent-to-multiple.xml',
                  'base-bldgtype-multifamily-shared-boiler-only-baseboard.xml',
                  'base-bldgtype-multifamily-shared-boiler-only-fan-coil.xml',
                  'base-bldgtype-multifamily-shared-boiler-only-fan-coil-ducted.xml',
                  'base-bldgtype-multifamily-shared-boiler-only-water-loop-heat-pump.xml',
                  'base-bldgtype-multifamily-shared-chiller-only-baseboard.xml',
                  'base-bldgtype-multifamily-shared-chiller-only-fan-coil.xml',
                  'base-bldgtype-multifamily-shared-chiller-only-fan-coil-ducted.xml',
                  'base-bldgtype-multifamily-shared-chiller-only-water-loop-heat-pump.xml',
                  'base-bldgtype-multifamily-shared-cooling-tower-only-water-loop-heat-pump.xml',
                  'base-bldgtype-multifamily-shared-generator.xml',
                  'base-bldgtype-multifamily-shared-ground-loop-ground-to-air-heat-pump.xml',
                  'base-bldgtype-multifamily-shared-laundry-room.xml',
                  'base-bldgtype-multifamily-shared-laundry-room-multiple-water-heaters.xml',
                  'base-bldgtype-multifamily-shared-mechvent.xml',
                  'base-bldgtype-multifamily-shared-mechvent-preconditioning.xml',
                  'base-bldgtype-multifamily-shared-pv.xml',
                  'base-bldgtype-multifamily-shared-water-heater.xml',
                  'base-bldgtype-multifamily-shared-water-heater-recirc.xml',
                  'base-bldgtype-single-family-attached.xml',
                  'base-dhw-combi-tankless.xml',
                  'base-dhw-desuperheater.xml',
                  'base-dhw-dwhr.xml',
                  'base-dhw-indirect-standbyloss.xml',
                  'base-dhw-jacket-gas.xml',
                  'base-dhw-jacket-hpwh.xml',
                  'base-dhw-jacket-indirect.xml',
                  'base-dhw-low-flow-fixtures.xml',
                  'base-dhw-multiple.xml',
                  'base-dhw-none.xml',
                  'base-dhw-recirc-demand.xml',
                  'base-dhw-solar-fraction.xml',
                  'base-dhw-solar-indirect-flat-plate.xml',
                  'base-dhw-tank-elec-uef.xml',
                  'base-dhw-tank-gas-uef.xml',
                  'base-dhw-tank-heat-pump-uef.xml',
                  'base-dhw-tankless-electric-uef.xml',
                  'base-dhw-tankless-gas-uef.xml',
                  'base-dhw-tankless-propane.xml',
                  'base-dhw-tank-oil.xml',
                  'base-dhw-tank-wood.xml',
                  'base-enclosure-2stories.xml',
                  'base-enclosure-2stories-garage.xml',
                  'base-enclosure-beds-1.xml',
                  'base-enclosure-beds-2.xml',
                  'base-enclosure-beds-4.xml',
                  'base-enclosure-beds-5.xml',
                  'base-enclosure-garage.xml',
                  'base-enclosure-infil-cfm50.xml',
                  'base-enclosure-infil-natural-ach.xml',
                  'base-enclosure-overhangs.xml',
                  'base-enclosure-skylights.xml',
                  'base-foundation-ambient.xml',
                  'base-foundation-basement-garage.xml',
                  'base-foundation-conditioned-basement-slab-insulation.xml',
                  'base-foundation-conditioned-basement-wall-insulation.xml',
                  'base-foundation-multiple.xml',
                  'base-foundation-slab.xml',
                  'base-foundation-unconditioned-basement.xml',
                  'base-foundation-unconditioned-basement-assembly-r.xml',
                  'base-foundation-unconditioned-basement-wall-insulation.xml',
                  'base-foundation-unvented-crawlspace.xml',
                  'base-foundation-vented-crawlspace.xml',
                  'base-foundation-walkout-basement.xml',
                  'base-hvac-air-to-air-heat-pump-1-speed.xml',
                  'base-hvac-air-to-air-heat-pump-1-speed-cooling-only.xml',
                  'base-hvac-air-to-air-heat-pump-1-speed-heating-only.xml',
                  'base-hvac-air-to-air-heat-pump-1-speed-seer2-hspf2.xml',
                  'base-hvac-air-to-air-heat-pump-2-speed.xml',
                  'base-hvac-air-to-air-heat-pump-var-speed.xml',
                  'base-hvac-boiler-elec-only.xml',
                  'base-hvac-boiler-gas-only.xml',
                  'base-hvac-boiler-oil-only.xml',
                  'base-hvac-boiler-propane-only.xml',
                  'base-hvac-central-ac-only-1-speed.xml',
                  'base-hvac-central-ac-only-1-speed-seer2.xml',
                  'base-hvac-central-ac-only-2-speed.xml',
                  'base-hvac-central-ac-only-var-speed.xml',
                  'base-hvac-central-ac-plus-air-to-air-heat-pump-heating.xml',
                  'base-hvac-dse.xml',
                  'base-hvac-ducts-leakage-cfm50.xml',
                  'base-hvac-dual-fuel-air-to-air-heat-pump-1-speed.xml',
                  'base-hvac-elec-resistance-only.xml',
                  'base-hvac-evap-cooler-only.xml',
                  'base-hvac-evap-cooler-only-ducted.xml',
                  'base-hvac-fireplace-wood-only.xml',
                  'base-hvac-fixed-heater-gas-only.xml',
                  'base-hvac-floor-furnace-propane-only.xml',
                  'base-hvac-furnace-elec-only.xml',
                  'base-hvac-furnace-gas-only.xml',
                  'base-hvac-ground-to-air-heat-pump.xml',
                  'base-hvac-ground-to-air-heat-pump-cooling-only.xml',
                  'base-hvac-ground-to-air-heat-pump-heating-only.xml',
                  'base-hvac-install-quality-air-to-air-heat-pump-1-speed.xml',
                  'base-hvac-install-quality-furnace-gas-central-ac-1-speed.xml',
                  'base-hvac-install-quality-ground-to-air-heat-pump.xml',
                  'base-hvac-install-quality-mini-split-air-conditioner-only-ducted.xml',
                  'base-hvac-install-quality-mini-split-heat-pump-ducted.xml',
                  'base-hvac-mini-split-air-conditioner-only-ducted.xml',
                  'base-hvac-mini-split-air-conditioner-only-ductless.xml',
                  'base-hvac-mini-split-heat-pump-ducted.xml',
                  'base-hvac-mini-split-heat-pump-ducted-cooling-only.xml',
                  'base-hvac-mini-split-heat-pump-ducted-heating-only.xml',
                  'base-hvac-mini-split-heat-pump-ductless.xml',
                  'base-hvac-multiple.xml',
                  'base-hvac-none.xml',
                  'base-hvac-portable-heater-gas-only.xml',
                  'base-hvac-ptac.xml',
                  'base-hvac-ptac-with-heating-electricity.xml',
                  'base-hvac-ptac-with-heating-natural-gas.xml',
                  'base-hvac-pthp.xml',
                  'base-hvac-room-ac-only.xml',
                  'base-hvac-room-ac-only-ceer.xml',
                  'base-hvac-room-ac-with-heating.xml',
                  'base-hvac-room-ac-with-reverse-cycle.xml',
                  'base-hvac-stove-wood-pellets-only.xml',
                  'base-hvac-undersized.xml',
                  'base-hvac-wall-furnace-elec-only.xml',
                  'base-lighting-ceiling-fans.xml',
                  'base-location-baltimore-md.xml',
                  'base-location-capetown-zaf.xml',
                  'base-location-dallas-tx.xml',
                  'base-location-duluth-mn.xml',
                  'base-location-helena-mt.xml',
                  'base-location-honolulu-hi.xml',
                  'base-location-miami-fl.xml',
                  'base-location-phoenix-az.xml',
                  'base-location-portland-or.xml',
                  'base-mechvent-balanced.xml',
                  'base-mechvent-cfis.xml',
                  'base-mechvent-cfis-airflow-fraction-zero.xml',
                  'base-mechvent-cfis-supplemental-fan-exhaust.xml',
                  'base-mechvent-erv.xml',
                  'base-mechvent-erv-atre-asre.xml',
                  'base-mechvent-exhaust.xml',
                  'base-mechvent-hrv.xml',
                  'base-mechvent-hrv-asre.xml',
                  'base-mechvent-multiple.xml',
                  'base-mechvent-supply.xml',
                  'base-mechvent-whole-house-fan.xml',
                  'base-misc-generators.xml',
                  'base-pv.xml']
  # 'base-pv-battery.xml']
  include_list.each do |include_file|
    if File.exist? "hpxml-measures/workflow/sample_files/#{include_file}"
      FileUtils.cp("hpxml-measures/workflow/sample_files/#{include_file}", "workflow/sample_files/#{include_file}")
    else
      puts "Warning: Included file hpxml-measures/workflow/sample_files/#{include_file} not found."
    end
  end

  # Update HPXMLs as needed
  puts 'Updating HPXML inputs for ERI/ENERGY STAR...'
  hpxml_paths = []
  Dir['workflow/sample_files/*.xml'].each do |hpxml_path|
    hpxml_paths << hpxml_path
  end
  hpxml_paths.each do |hpxml_path|
    hpxml = HPXML.new(hpxml_path: hpxml_path)

    # Handle different inputs for ERI

    hpxml.header.eri_calculation_version = 'latest'
    hpxml.header.iecc_eri_calculation_version = IECCConstants.AllVersions[-1]
    hpxml.header.utility_bill_scenarios.clear
    hpxml.header.timestep = nil
    hpxml.site.site_type = nil
    hpxml.site.surroundings = nil
    hpxml.site.vertical_surroundings = nil
    hpxml.site.shielding_of_home = nil
    hpxml.site.orientation_of_front_of_home = nil
    hpxml.site.azimuth_of_front_of_home = nil
    hpxml.site.ground_conductivity = nil
    hpxml.building_occupancy.number_of_residents = nil
    hpxml.building_construction.number_of_bathrooms = nil
    hpxml.building_construction.conditioned_building_volume = nil
    hpxml.building_construction.average_ceiling_height = nil
    hpxml.attics.each do |attic|
      if [HPXML::AtticTypeVented,
          HPXML::AtticTypeUnvented].include? attic.attic_type
        attic.within_infiltration_volume = false if attic.within_infiltration_volume.nil?
      end
    end
    hpxml.foundations.each do |foundation|
      next unless [HPXML::FoundationTypeBasementUnconditioned,
                   HPXML::FoundationTypeCrawlspaceUnvented,
                   HPXML::FoundationTypeCrawlspaceVented].include? foundation.foundation_type

      foundation.within_infiltration_volume = false if foundation.within_infiltration_volume.nil?
    end
    hpxml.roofs.each do |roof|
      roof.roof_type = nil
    end
    hpxml.rim_joists.each do |rim_joist|
      rim_joist.siding = nil
    end
    hpxml.walls.each do |wall|
      wall.siding = nil
      wall.interior_finish_type = nil
      wall.interior_finish_thickness = nil
    end
    hpxml.floors.each do |floor|
      floor.interior_finish_type = nil
      floor.interior_finish_thickness = nil
      next if [HPXML::LocationOtherHousingUnit,
               HPXML::LocationOtherHeatedSpace,
               HPXML::LocationOtherMultifamilyBufferSpace,
               HPXML::LocationOtherNonFreezingSpace].include? floor.exterior_adjacent_to

      floor.floor_or_ceiling = nil
    end
    hpxml.foundation_walls.each do |fwall|
      fwall.interior_finish_type = nil
      fwall.interior_finish_thickness = nil
      fwall.insulation_interior_distance_to_top = 0 if fwall.insulation_interior_distance_to_top.nil?
      if fwall.insulation_interior_distance_to_bottom.nil?
        if fwall.insulation_interior_r_value.to_f > 0
          fwall.insulation_interior_distance_to_bottom = fwall.height
        else
          fwall.insulation_interior_distance_to_bottom = 0
        end
      end
      fwall.insulation_exterior_distance_to_top = 0 if fwall.insulation_exterior_distance_to_top.nil?
      if fwall.insulation_exterior_distance_to_bottom.nil?
        if fwall.insulation_exterior_r_value.to_f > 0
          fwall.insulation_exterior_distance_to_bottom = fwall.height
        else
          fwall.insulation_exterior_distance_to_bottom = 0
        end
      end
    end
    hpxml.windows.each do |window|
      window.interior_shading_factor_winter = nil
      window.interior_shading_factor_summer = nil
    end
    hpxml.cooling_systems.each do |cooling_system|
      cooling_system.primary_system = nil
    end
    hpxml.heating_systems.each do |heating_system|
      heating_system.primary_system = nil
      next unless heating_system.heating_system_type == HPXML::HVACTypeBoiler
      next unless heating_system.is_shared_system.nil?

      heating_system.is_shared_system = false
    end
    hpxml.heat_pumps.each do |heat_pump|
      heat_pump.primary_heating_system = nil
      heat_pump.primary_cooling_system = nil
      next unless heat_pump.heat_pump_type == HPXML::HVACTypeHeatPumpGroundToAir
      next unless heat_pump.is_shared_system.nil?

      heat_pump.is_shared_system = false
    end
    hpxml.water_heating_systems.each do |water_heating_system|
      water_heating_system.temperature = nil
      next unless water_heating_system.is_shared_system.nil?

      water_heating_system.is_shared_system = false
    end
    shared_water_heaters = hpxml.water_heating_systems.select { |wh| wh.is_shared_system }
    if not hpxml.clothes_washers.empty?
      if hpxml.clothes_washers[0].is_shared_appliance
        hpxml.clothes_washers[0].number_of_units_served = shared_water_heaters[0].number_of_units_served
        hpxml.clothes_washers[0].count = 2
      else
        hpxml.clothes_washers[0].is_shared_appliance = false
      end
    end
    if not hpxml.clothes_dryers.empty?
      if hpxml.clothes_dryers[0].is_shared_appliance
        hpxml.clothes_dryers[0].number_of_units_served = shared_water_heaters[0].number_of_units_served
        hpxml.clothes_dryers[0].count = 2
      else
        hpxml.clothes_dryers[0].is_shared_appliance = false
      end
    end
    if not hpxml.dishwashers.empty?
      if not hpxml.dishwashers[0].is_shared_appliance
        hpxml.dishwashers[0].is_shared_appliance = false
      end
    end
    hpxml.ventilation_fans.each do |ventilation_fan|
      ventilation_fan.count = nil
      next unless ventilation_fan.used_for_whole_building_ventilation

      ventilation_fan.is_shared_system = false if ventilation_fan.is_shared_system.nil?

      if ventilation_fan.is_shared_system
        ventilation_fan.rated_flow_rate = ventilation_fan.rated_flow_rate.to_f + ventilation_fan.delivered_ventilation.to_f if ventilation_fan.tested_flow_rate.nil?
        ventilation_fan.tested_flow_rate = nil
        ventilation_fan.delivered_ventilation = nil
      else
        ventilation_fan.tested_flow_rate = ventilation_fan.rated_flow_rate.to_f + ventilation_fan.delivered_ventilation.to_f if ventilation_fan.tested_flow_rate.nil?
        ventilation_fan.rated_flow_rate = nil
        ventilation_fan.delivered_ventilation = nil
      end
      ventilation_fan.cfis_vent_mode_airflow_fraction = 1.0 if ventilation_fan.cfis_vent_mode_airflow_fraction.nil? && ventilation_fan.fan_type == HPXML::MechVentTypeCFIS
      next if ventilation_fan.is_cfis_supplemental_fan?

      if ventilation_fan.hours_in_operation.nil?
        if ventilation_fan.fan_type == HPXML::MechVentTypeCFIS
          ventilation_fan.hours_in_operation = 8.0
        else
          ventilation_fan.hours_in_operation = 24.0
        end
      end
    end
    hpxml.ventilation_fans.reverse_each do |ventilation_fan|
      next if ventilation_fan.used_for_whole_building_ventilation
      next if ventilation_fan.used_for_seasonal_cooling_load_reduction

      ventilation_fan.delete
    end
    hpxml.plug_loads.clear
    hpxml.fuel_loads.clear
    hpxml.heating_systems.each do |heating_system|
      next unless [HPXML::HVACTypeFurnace].include? heating_system.heating_system_type

      if heating_system.fan_watts_per_cfm.nil?
        heating_system.fan_watts_per_cfm = 0.58
      end
      if heating_system.airflow_defect_ratio.nil?
        heating_system.airflow_defect_ratio = -0.25
      end
    end
    hpxml.cooling_systems.each do |cooling_system|
      next unless [HPXML::HVACTypeCentralAirConditioner,
                   HPXML::HVACTypeMiniSplitAirConditioner].include? cooling_system.cooling_system_type

      if cooling_system.fan_watts_per_cfm.nil?
        cooling_system.fan_watts_per_cfm = 0.58
      end
      if cooling_system.airflow_defect_ratio.nil?
        if not cooling_system.distribution_system_idref.nil?
          cooling_system.airflow_defect_ratio = -0.25
        else
          cooling_system.airflow_defect_ratio = 0.0
        end
      end
      if cooling_system.charge_defect_ratio.nil?
        cooling_system.charge_defect_ratio = -0.25
      end
    end
    hpxml.heat_pumps.each do |heat_pump|
      next unless [HPXML::HVACTypeHeatPumpAirToAir,
                   HPXML::HVACTypeHeatPumpGroundToAir,
                   HPXML::HVACTypeHeatPumpMiniSplit].include? heat_pump.heat_pump_type

      if heat_pump.fan_watts_per_cfm.nil?
        heat_pump.fan_watts_per_cfm = 0.58
      end
      if heat_pump.airflow_defect_ratio.nil?
        if not heat_pump.distribution_system_idref.nil?
          heat_pump.airflow_defect_ratio = -0.25
        else
          heat_pump.airflow_defect_ratio = 0.0
        end
      end
      if heat_pump.charge_defect_ratio.nil?
        heat_pump.charge_defect_ratio = -0.25
      end
    end
    hpxml.heating_systems.each do |heating_system|
      next unless heating_system.heating_system_type == HPXML::HVACTypeBoiler
      next unless heating_system.is_shared_system
      next unless heating_system.heating_capacity.nil?

      heating_system.heating_capacity = 300000
    end
    hpxml.pv_systems.each do |pv_system|
      next unless pv_system.is_shared_system.nil?

      pv_system.is_shared_system = false
    end
    hpxml.generators.each do |generator|
      next unless generator.is_shared_system.nil?

      generator.is_shared_system = false
    end
    n_htg_systems = (hpxml.heating_systems + hpxml.heat_pumps).select { |h| h.fraction_heat_load_served.to_f > 0 }.size
    n_clg_systems = (hpxml.cooling_systems + hpxml.heat_pumps).select { |h| h.fraction_cool_load_served.to_f > 0 }.size
    hpxml.hvac_distributions.each do |hvac_distribution|
      next unless hvac_distribution.conditioned_floor_area_served.nil?
      next unless hvac_distribution.distribution_system_type == HPXML::HVACDistributionTypeAir
      next unless hvac_distribution.ducts.size > 0

      n_hvac_systems = [n_htg_systems, n_clg_systems].max
      hvac_distribution.conditioned_floor_area_served = hpxml.building_construction.conditioned_floor_area / n_hvac_systems
    end

    hpxml.hvac_distributions.each do |hvac_distribution|
      next unless hvac_distribution.number_of_return_registers.nil?
      next unless hvac_distribution.distribution_system_type == HPXML::HVACDistributionTypeAir
      next unless hvac_distribution.ducts.select { |d| d.duct_type == HPXML::DuctTypeReturn }.size > 0

      hvac_distribution.number_of_return_registers = hpxml.building_construction.number_of_conditioned_floors.ceil
    end
    # TODO: Allow UsageBin in 301validator and remove code below
    hpxml.water_heating_systems.each do |dhw_system|
      next if dhw_system.uniform_energy_factor.nil?
      next unless [HPXML::WaterHeaterTypeStorage, HPXML::WaterHeaterTypeHeatPump].include? dhw_system.water_heater_type
      next unless dhw_system.first_hour_rating.nil?

      if dhw_system.usage_bin == HPXML::WaterHeaterUsageBinLow
        dhw_system.usage_bin = nil
        dhw_system.first_hour_rating = 46.0
      elsif dhw_system.usage_bin == HPXML::WaterHeaterUsageBinMedium
        dhw_system.usage_bin = nil
        dhw_system.first_hour_rating = 56.0
      else
        fail hpxml_path
      end
    end
    zip_map = { 'USA_CO_Denver.Intl.AP.725650_TMY3.epw' => '80206',
                'USA_OR_Portland.Intl.AP.726980_TMY3.epw' => '97214',
                'US_CO_Boulder_AMY_2012.epw' => '80305-3447',
                'USA_MD_Baltimore-Washington.Intl.AP.724060_TMY3.epw' => '21221',
                'USA_TX_Dallas-Fort.Worth.Intl.AP.722590_TMY3.epw' => '75229',
                'USA_MN_Duluth.Intl.AP.727450_TMY3.epw' => '55807',
                'USA_MT_Helena.Rgnl.AP.727720_TMY3.epw' => '59602',
                'USA_HI_Honolulu.Intl.AP.911820_TMY3.epw' => '96817',
                'USA_FL_Miami.Intl.AP.722020_TMY3.epw' => '33134',
                'USA_AZ_Phoenix-Sky.Harbor.Intl.AP.722780_TMY3.epw' => '85023',
                'ZAF_Cape.Town.688160_IWEC.epw' => '00000' }
    hpxml.header.zip_code = zip_map[hpxml.climate_and_risk_zones.weather_station_epw_filepath]
    if hpxml.header.zip_code.nil?
      fail "#{hpxml_path}: EPW location (#{hpxml.climate_and_risk_zones.weather_station_epw_filepath}) not handled. Need to update zip_map."
    end

    if hpxml.climate_and_risk_zones.weather_station_epw_filepath == 'ZAF_Cape.Town.688160_IWEC.epw'
      if hpxml.header.state_code.nil?
        hpxml.header.state_code = 'NA'
      end
      if hpxml.climate_and_risk_zones.climate_zone_ieccs.empty?
        hpxml.climate_and_risk_zones.climate_zone_ieccs.add(zone: '3A',
                                                            year: 2006)
      end
    end
    if hpxml.climate_and_risk_zones.climate_zone_ieccs.select { |z| z.year == Integer(hpxml.header.iecc_eri_calculation_version) }.size == 0
      hpxml.climate_and_risk_zones.climate_zone_ieccs.add(year: Integer(hpxml.header.iecc_eri_calculation_version),
                                                          zone: hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone)
    end

    # Handle different inputs for ENERGY STAR/ZERH

    if hpxml_path.include? 'base-bldgtype-multifamily'
      hpxml.header.zerh_calculation_version = ZERHConstants.Ver1
      if hpxml.climate_and_risk_zones.climate_zone_ieccs.select { |z| z.year == 2015 }.size == 0
        hpxml.climate_and_risk_zones.climate_zone_ieccs.add(year: 2015,
                                                            zone: hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone)
      end
    else
      hpxml.header.zerh_calculation_version = ZERHConstants.SFVer2
      if hpxml.climate_and_risk_zones.climate_zone_ieccs.select { |z| z.year == 2021 }.size == 0
        hpxml.climate_and_risk_zones.climate_zone_ieccs.add(year: 2021,
                                                            zone: hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone)
      end
    end
    if hpxml_path.include? 'base-bldgtype-multifamily'
      hpxml.header.energystar_calculation_version = ESConstants.MFNationalVer1_2
    elsif hpxml.header.state_code == 'FL'
      hpxml.header.energystar_calculation_version = ESConstants.SFFloridaVer3_1
    elsif hpxml.header.state_code == 'HI'
      hpxml.header.energystar_calculation_version = ESConstants.SFPacificVer3_0
    elsif hpxml.header.state_code == 'OR'
      hpxml.header.energystar_calculation_version = ESConstants.SFOregonWashingtonVer3_2
    else
      hpxml.header.energystar_calculation_version = ESConstants.SFNationalVer3_2
    end
    hpxml.windows.each do |window|
      window.performance_class = HPXML::WindowClassResidential
    end
    hpxml.hvac_systems.each do |hvac_system|
      next if hvac_system.shared_loop_watts.nil?

      hvac_system.shared_loop_motor_efficiency = 0.9
    end
    hpxml.hot_water_distributions.each do |dhw_dist|
      next if dhw_dist.shared_recirculation_pump_power.nil?

      dhw_dist.shared_recirculation_motor_efficiency = 0.9
    end
    hpxml.hvac_controls.each do |hvac_control|
      hvac_control.heating_setpoint_temp = nil
      hvac_control.cooling_setpoint_temp = nil
      next unless hvac_control.control_type.nil?

      hvac_control.control_type = HPXML::HVACControlTypeManual
    end

    XMLHelper.write_file(hpxml.to_oga, hpxml_path)
  end

  # Create additional files
  puts 'Creating additional HPXML files for ERI...'

  # base-hvac-programmable-thermostat.xml
  hpxml = HPXML.new(hpxml_path: 'workflow/sample_files/base.xml')
  hpxml.hvac_controls[0].control_type = HPXML::HVACControlTypeProgrammable
  XMLHelper.write_file(hpxml.to_oga, 'workflow/sample_files/base-hvac-programmable-thermostat.xml')

  # Older ERI versions
  Constants.ERIVersions.each do |eri_version|
    hpxml = HPXML.new(hpxml_path: 'workflow/sample_files/base.xml')
    hpxml.header.eri_calculation_version = eri_version
    hpxml.header.iecc_eri_calculation_version = nil
    hpxml.header.energystar_calculation_version = nil
    hpxml.header.zerh_calculation_version = nil

    if Constants.ERIVersions.index(eri_version) < Constants.ERIVersions.index('2019A')
      # Need old input for clothes dryers
      hpxml.clothes_dryers[0].control_type = HPXML::ClothesDryerControlTypeTimer
    end

    XMLHelper.write_file(hpxml.to_oga, "workflow/sample_files/base-version-eri-#{eri_version}.xml")
  end

  # All IECC versions
  IECCConstants.AllVersions.each do |iecc_version|
    hpxml = HPXML.new(hpxml_path: 'workflow/sample_files/base.xml')
    hpxml.header.iecc_eri_calculation_version = iecc_version
    hpxml.header.eri_calculation_version = nil
    hpxml.header.energystar_calculation_version = nil
    hpxml.header.zerh_calculation_version = nil
    zone = hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone
    if hpxml.climate_and_risk_zones.climate_zone_ieccs.select { |z| z.year == Integer(iecc_version) }.size == 0
      hpxml.climate_and_risk_zones.climate_zone_ieccs.add(year: Integer(iecc_version),
                                                          zone: zone)
    end

    XMLHelper.write_file(hpxml.to_oga, "workflow/sample_files/base-version-iecc-eri-#{iecc_version}.xml")
  end

  # Additional ENERGY STAR files
  hpxml = HPXML.new(hpxml_path: 'workflow/sample_files/base-bldgtype-multifamily.xml')
  hpxml.header.energystar_calculation_version = ESConstants.MFOregonWashingtonVer1_2
  hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '4C'
  hpxml.climate_and_risk_zones.weather_station_name = 'Portland, OR'
  hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_OR_Portland.Intl.AP.726980_TMY3.epw'
  hpxml.header.state_code = 'OR'
  XMLHelper.write_file(hpxml.to_oga, 'workflow/sample_files/base-bldgtype-multifamily-location-portland-or.xml')
end

command_list = [:update_measures, :create_release_zips]

def display_usage(command_list)
  puts "Usage: openstudio #{File.basename(__FILE__)} [COMMAND]\nCommands:\n  " + command_list.join("\n  ")
end

if ARGV.size == 0
  puts 'ERROR: Missing command.'
  display_usage(command_list)
  exit!
elsif ARGV.size > 1
  puts 'ERROR: Too many commands.'
  display_usage(command_list)
  exit!
elsif not command_list.include? ARGV[0].to_sym
  puts "ERROR: Invalid command '#{ARGV[0]}'."
  display_usage(command_list)
  exit!
end

if ARGV[0].to_sym == :update_measures
  require 'oga'
  require_relative 'rulesets/resources/constants'

  # Prevent NREL error regarding U: drive when not VPNed in
  ENV['HOME'] = 'C:' if !ENV['HOME'].nil? && ENV['HOME'].start_with?('U:')
  ENV['HOMEDRIVE'] = 'C:\\' if !ENV['HOMEDRIVE'].nil? && ENV['HOMEDRIVE'].start_with?('U:')

  create_test_hpxmls
  create_sample_hpxmls

  # Apply rubocop
  cops = ['Layout',
          'Lint/DeprecatedClassMethods',
          'Lint/DuplicateElsifCondition',
          'Lint/DuplicateHashKey',
          'Lint/DuplicateMethods',
          'Lint/InterpolationCheck',
          'Lint/LiteralAsCondition',
          'Lint/RedundantStringCoercion',
          'Lint/SelfAssignment',
          'Lint/UnderscorePrefixedVariableName',
          'Lint/UnusedBlockArgument',
          'Lint/UnusedMethodArgument',
          'Lint/UselessAssignment',
          'Style/AndOr',
          'Style/FrozenStringLiteralComment',
          'Style/HashSyntax',
          'Style/Next',
          'Style/NilComparison',
          'Style/RedundantParentheses',
          'Style/RedundantSelf',
          'Style/ReturnNil',
          'Style/SelfAssignment',
          'Style/StringLiterals',
          'Style/StringLiteralsInInterpolation']
  commands = ["\"require 'rubocop/rake_task'\"",
              "\"RuboCop::RakeTask.new(:rubocop) do |t| t.options = ['--auto-correct', '--format', 'simple', '--only', '#{cops.join(',')}'] end\"",
              '"Rake.application[:rubocop].invoke"']
  command = "#{OpenStudio.getOpenStudioCLI} -e #{commands.join(' -e ')}"
  puts 'Applying rubocop auto-correct to measures...'
  system(command)

  puts 'Done.'
end

if ARGV[0].to_sym == :create_release_zips
  require_relative 'workflow/version'

  if ENV['CI']
    # CI doesn't have git, so default to everything
    git_files = Dir['**/*.*']
  else
    # Only include files under git version control
    command = 'git ls-files'
    begin
      git_files = `#{command}`
    rescue
      puts "Command failed: '#{command}'. Perhaps git needs to be installed?"
      exit!
    end
  end
  files = ['Changelog.md',
           'LICENSE.md',
           'hpxml-measures/HPXMLtoOpenStudio/measure.*',
           'hpxml-measures/HPXMLtoOpenStudio/resources/**/*.*',
           'hpxml-measures/ReportSimulationOutput/measure.*',
           'hpxml-measures/ReportSimulationOutput/resources/**/*.*',
           'rulesets/**/*.*',
           'weather/*.*',
           'workflow/*.*',
           'workflow/real_homes/*.*',
           'workflow/sample_files/*.*',
           'workflow/tests/*.rb',
           'workflow/tests/**/*.csv',
           'workflow/tests/**/*.xml',
           'documentation/index.html',
           'documentation/_static/**/*.*']

  if not ENV['CI']
    # Generate documentation
    puts 'Generating documentation...'
    command = 'sphinx-build -b singlehtml docs/source documentation'
    begin
      `#{command}`
      if not File.exist? File.join(File.dirname(__FILE__), 'documentation', 'index.html')
        puts 'Documentation was not successfully generated. Aborting...'
        exit!
      end
    rescue
      puts "Command failed: '#{command}'. Perhaps sphinx needs to be installed?"
      exit!
    end

    fonts_dir = File.join(File.dirname(__FILE__), 'documentation', '_static', 'fonts')
    if Dir.exist? fonts_dir
      FileUtils.rm_r(fonts_dir)
    end
  end

  # Create zip files
  require 'zip'
  zip_path = File.join(File.dirname(__FILE__), "OpenStudio-ERI-v#{Version::OS_ERI_Version}.zip")
  File.delete(zip_path) if File.exist? zip_path
  puts "Creating #{zip_path}..."
  Zip::File.open(zip_path, create: true) do |zipfile|
    files.each do |f|
      Dir[f].each do |file|
        if file.start_with? 'documentation'
          # always include
        else
          if not git_files.include? file
            next
          end
        end
        zipfile.add(File.join('OpenStudio-ERI', file), file)
      end
    end
    puts "Wrote file at #{zip_path}."
  end

  # Cleanup
  if not ENV['CI']
    FileUtils.rm_r(File.join(File.dirname(__FILE__), 'documentation'))
  end

  puts 'Done.'
end
