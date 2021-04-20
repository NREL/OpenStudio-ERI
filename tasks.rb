# frozen_string_literal: true

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
    'EPA_Tests/SFv3_1/SFv3_1_CZ2_FL_elec_slab.xml' => nil,
    'EPA_Tests/SFv3_1/SFv3_1_CZ4_MO_elec_vented_crawl.xml' => nil,
    'EPA_Tests/SFv3_1/SFv3_1_CZ6_VT_gas_cond_bsmt.xml' => nil,
    'EPA_Tests/SFv3_0/SFv3_0_CZ2_FL_gas_slab.xml' => nil,
    'EPA_Tests/SFv3_0/SFv3_0_CZ4_MO_gas_vented_crawl.xml' => nil,
    'EPA_Tests/SFv3_0/SFv3_0_CZ6_VT_elec_cond_bsmt.xml' => nil,
    'EPA_Tests/MFv1_1/MFv1_1_CZ2_FL_elec_top_corner.xml' => nil,
    'EPA_Tests/MFv1_1/MFv1_1_CZ4_MO_elec_ground_corner_vented_crawl.xml' => nil,
    'EPA_Tests/MFv1_1/MFv1_1_CZ6_VT_gas_ground_corner_cond_bsmt.xml' => nil,
    'EPA_Tests/MFv1_0/MFv1_0_CZ2_FL_gas_ground_corner_slab.xml' => nil,
    'EPA_Tests/MFv1_0/MFv1_0_CZ4_MO_gas_top_corner.xml' => nil,
    'EPA_Tests/MFv1_0/MFv1_0_CZ6_VT_elec_middle_interior.xml' => nil,
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

  hpxmls_files.each do |derivative, parent|
    print '.'

    begin
      hpxml_files = [derivative]
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
        set_hpxml_header(hpxml_file, hpxml)
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
        set_hpxml_frame_floors(hpxml_file, hpxml)
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
      schemas_dir = File.absolute_path(File.join(File.dirname(__FILE__), 'hpxml-measures', 'HPXMLtoOpenStudio', 'resources'))
      errors = XMLHelper.validate(hpxml_doc.to_s, File.join(schemas_dir, 'HPXML.xsd'), nil)
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

def set_hpxml_header(hpxml_file, hpxml)
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
    hpxml.header.created_date_and_time = Time.new(2000, 1, 1).strftime('%Y-%m-%dT%H:%M:%S%:z') # Hard-code to prevent diffs
    if hpxml_file.include?('SFv3_1')
      hpxml.header.energystar_calculation_version = ESConstants.SFNationalVer3_1
    elsif hpxml_file.include?('SFv3_0')
      hpxml.header.energystar_calculation_version = ESConstants.SFNationalVer3
    elsif hpxml_file.include?('MFv1_1')
      hpxml.header.energystar_calculation_version = ESConstants.MFNationalVer1_1_2019
    elsif hpxml_file.include?('MFv1_0')
      hpxml.header.energystar_calculation_version = ESConstants.MFNationalVer1_2019
    end
    hpxml.header.state_code = File.basename(hpxml_file)[11..12]
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
    hpxml.building_construction.conditioned_building_volume = 12312
  elsif hpxml_file.include?('EPA_Tests')
    if hpxml_file.include?('SF')
      hpxml.building_construction.residential_facility_type = HPXML::ResidentialTypeSFD
      hpxml.building_construction.number_of_conditioned_floors = 2
      hpxml.building_construction.number_of_conditioned_floors_above_grade = 2
      hpxml.building_construction.number_of_bedrooms = 3
      hpxml.building_construction.conditioned_floor_area = 2400
      hpxml.building_construction.conditioned_building_volume = 20400
    elsif hpxml_file.include?('MF')
      hpxml.building_construction.residential_facility_type = HPXML::ResidentialTypeApartment
      hpxml.building_construction.number_of_conditioned_floors = 1
      hpxml.building_construction.number_of_conditioned_floors_above_grade = 1
      hpxml.building_construction.number_of_bedrooms = 2
      hpxml.building_construction.conditioned_floor_area = 1200
      hpxml.building_construction.conditioned_building_volume = 10200
    end
    if hpxml_file.include?('cond_bsmt')
      hpxml.building_construction.number_of_conditioned_floors += 1
      hpxml.building_construction.conditioned_floor_area += 1200
      hpxml.building_construction.conditioned_building_volume += 5100
    end
  end
end

def set_hpxml_building_occupancy(hpxml_file, hpxml)
  if hpxml_file.include?('HERS_AutoGen') || hpxml_file.include?('HERS_Method') || hpxml_file.include?('Hot_Water')
    hpxml.building_occupancy.number_of_residents = nil
  end
end

def set_hpxml_climate_and_risk_zones(hpxml_file, hpxml)
  hpxml.climate_and_risk_zones.iecc_year = 2006
  if ['RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/01-L100.xml'].include? hpxml_file
    # Baltimore
    hpxml.climate_and_risk_zones.iecc_zone = '4A'
    hpxml.climate_and_risk_zones.weather_station_id = 'WeatherStation'
    hpxml.climate_and_risk_zones.weather_station_name = 'Baltimore, MD'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_MD_Baltimore-Washington.Intl.AP.724060_TMY3.epw'
    hpxml.header.state_code = 'MD'
  elsif ['RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/02-L100.xml'].include? hpxml_file
    # Dallas
    hpxml.climate_and_risk_zones.iecc_zone = '3A'
    hpxml.climate_and_risk_zones.weather_station_id = 'WeatherStation'
    hpxml.climate_and_risk_zones.weather_station_name = 'Dallas, TX'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_TX_Dallas-Fort.Worth.Intl.AP.722590_TMY3.epw'
    hpxml.header.state_code = 'TX'
  elsif ['RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/03-L304.xml',
         'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AM-HW-01.xml'].include? hpxml_file
    # Miami
    hpxml.climate_and_risk_zones.iecc_zone = '1A'
    hpxml.climate_and_risk_zones.weather_station_id = 'WeatherStation'
    hpxml.climate_and_risk_zones.weather_station_name = 'Miami, FL'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_FL_Miami.Intl.AP.722020_TMY3.epw'
    hpxml.header.state_code = 'FL'
  elsif ['RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AD-HW-01.xml'].include? hpxml_file
    # Duluth
    hpxml.climate_and_risk_zones.iecc_zone = '7'
    hpxml.climate_and_risk_zones.weather_station_id = 'WeatherStation'
    hpxml.climate_and_risk_zones.weather_station_name = 'Duluth, MN'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_MN_Duluth.Intl.AP.727450_TMY3.epw'
    hpxml.header.state_code = 'MN'
  elsif hpxml_file.include?('HERS_AutoGen') || hpxml_file.include?('HERS_Method') || hpxml_file.include?('Hot_Water')
    if hpxml.climate_and_risk_zones.weather_station_epw_filepath == 'USA_CO_Colorado.Springs-Peterson.Field.724660_TMY3.epw'
      hpxml.climate_and_risk_zones.iecc_zone = '5B'
      hpxml.header.state_code = 'CO'
    end
  elsif hpxml_file.include?('EPA_Tests')
    hpxml.climate_and_risk_zones.weather_station_id = 'WeatherStation'
    if hpxml_file.include?('CZ2')
      hpxml.climate_and_risk_zones.iecc_zone = '2A'
      hpxml.climate_and_risk_zones.weather_station_name = 'Tampa, FL'
      hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_FL_Tampa.Intl.AP.722110_TMY3.epw'
      hpxml.header.state_code = 'FL'
    elsif hpxml_file.include?('CZ4')
      hpxml.climate_and_risk_zones.iecc_zone = '4A'
      hpxml.climate_and_risk_zones.weather_station_name = 'St Louis, MO'
      hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_MO_St.Louis-Lambert.Intl.AP.724340_TMY3.epw'
      hpxml.header.state_code = 'MO'
    elsif hpxml_file.include?('CZ6')
      hpxml.climate_and_risk_zones.iecc_zone = '6A'
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
    hpxml.air_infiltration_measurements.add(id: 'InfiltrationMeasurement',
                                            house_pressure: 50,
                                            unit_of_measure: HPXML::UnitsACH,
                                            air_leakage: 3,
                                            infiltration_volume: hpxml.building_construction.conditioned_building_volume)
  elsif ['RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2019_PreAddendumA/03-L304.xml'].include? hpxml_file
    # 5 ACH50
    hpxml.air_infiltration_measurements.clear
    hpxml.air_infiltration_measurements.add(id: 'InfiltrationMeasurement',
                                            unit_of_measure: HPXML::UnitsACH,
                                            house_pressure: 50,
                                            air_leakage: 5,
                                            infiltration_volume: hpxml.building_construction.conditioned_building_volume)
  elsif ['RESNET_Tests/4.5_DSE/HVAC3a.xml'].include? hpxml_file
    hpxml.air_infiltration_measurements[0].infiltration_volume = 12312
    hpxml.air_infiltration_measurements[0].air_leakage = 0.67
  elsif hpxml_file.include?('EPA_Tests/SF')
    if ['EPA_Tests/SFv3_0/SFv3_0_CZ4_MO_gas_vented_crawl.xml'].include? hpxml_file
      ach50 = 5
    elsif ['EPA_Tests/SFv3_0/SFv3_0_CZ2_FL_gas_slab.xml'].include? hpxml_file
      ach50 = 6
    elsif ['EPA_Tests/SFv3_1/SFv3_1_CZ2_FL_elec_slab.xml',
           'EPA_Tests/SFv3_0/SFv3_0_CZ6_VT_elec_cond_bsmt.xml'].include? hpxml_file
      ach50 = 4
    elsif ['EPA_Tests/SFv3_1/SFv3_1_CZ4_MO_elec_vented_crawl.xml',
           'EPA_Tests/SFv3_1/SFv3_1_CZ6_VT_gas_cond_bsmt.xml'].include? hpxml_file
      ach50 = 3
    end
    hpxml.air_infiltration_measurements.clear
    hpxml.air_infiltration_measurements.add(id: 'InfiltrationMeasurement',
                                            unit_of_measure: HPXML::UnitsACH,
                                            house_pressure: 50,
                                            air_leakage: ach50,
                                            infiltration_volume: hpxml.building_construction.conditioned_building_volume)
  elsif hpxml_file.include?('EPA_Tests/MF')
    tot_cb_area, ext_cb_area = hpxml.compartmentalization_boundary_areas()
    hpxml.air_infiltration_measurements.clear
    hpxml.air_infiltration_measurements.add(id: 'InfiltrationMeasurement',
                                            unit_of_measure: HPXML::UnitsCFM,
                                            house_pressure: 50,
                                            air_leakage: 0.3 * tot_cb_area,
                                            infiltration_volume: hpxml.building_construction.conditioned_building_volume)
  end
end

def set_hpxml_attics(hpxml_file, hpxml)
  if hpxml_file.include?('EPA_Tests/SF') || hpxml_file.include?('top_corner')
    hpxml.attics.clear
    hpxml.attics.add(id: 'VentedAttic',
                     attic_type: HPXML::AtticTypeVented,
                     vented_attic_sla: (1.0 / 300.0).round(6))
  elsif hpxml_file.include?('HERS_AutoGen') || hpxml_file.include?('HERS_Method') || hpxml_file.include?('Hot_Water')
    hpxml.attics.clear
    hpxml.attics.add(id: 'VentedAttic',
                     attic_type: HPXML::AtticTypeVented,
                     vented_attic_sla: (1.0 / 300.0).round(6))
  end
end

def set_hpxml_foundations(hpxml_file, hpxml)
  if ['RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/02-L100.xml'].include? hpxml_file
    hpxml.foundations.clear
    hpxml.foundations.add(id: 'UnventedCrawlspace',
                          foundation_type: HPXML::FoundationTypeCrawlspaceUnvented,
                          within_infiltration_volume: false)
  elsif hpxml_file.include?('vented_crawl')
    hpxml.foundations.clear
    hpxml.foundations.add(id: 'VentedCrawlspace',
                          foundation_type: HPXML::FoundationTypeCrawlspaceVented,
                          vented_crawlspace_sla: (1.0 / 150.0).round(6))
  end
end

def set_hpxml_roofs(hpxml_file, hpxml)
  if hpxml_file.include?('EPA_Tests')
    rb_grade = nil
    if ['EPA_Tests/SFv3_0/SFv3_0_CZ2_FL_gas_slab.xml'].include? hpxml_file
      rb_grade = 1
    elsif hpxml_file.include?('ground_corner') || hpxml_file.include?('middle_interior')
      return
    end
    hpxml.roofs.clear
    hpxml.roofs.add(id: 'Roof',
                    interior_adjacent_to: HPXML::LocationAtticVented,
                    area: 1500,
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
    if ['EPA_Tests/SFv3_1/SFv3_1_CZ2_FL_elec_slab.xml',
        'EPA_Tests/SFv3_0/SFv3_0_CZ2_FL_gas_slab.xml',
        'EPA_Tests/SFv3_0/SFv3_0_CZ4_MO_gas_vented_crawl.xml'].include? hpxml_file
      assembly_r = (1.0 / 0.082).round(3)
    elsif ['EPA_Tests/SFv3_1/SFv3_1_CZ4_MO_elec_vented_crawl.xml',
           'EPA_Tests/SFv3_0/SFv3_0_CZ6_VT_elec_cond_bsmt.xml'].include? hpxml_file
      assembly_r = (1.0 / 0.057).round(3)
    elsif ['EPA_Tests/SFv3_1/SFv3_1_CZ6_VT_gas_cond_bsmt.xml'].include? hpxml_file
      assembly_r = (1.0 / 0.048).round(3)
    end
    hpxml.rim_joists.clear
    hpxml.rim_joists.add(id: 'RimJoist',
                         exterior_adjacent_to: HPXML::LocationOutside,
                         interior_adjacent_to: HPXML::LocationLivingSpace,
                         area: 140,
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
      hpxml.rim_joists.add(id: 'RimJoistFoundation',
                           exterior_adjacent_to: HPXML::LocationOutside,
                           interior_adjacent_to: interior_adjacent_to,
                           area: 140,
                           solar_absorptance: 0.75,
                           emittance: 0.9,
                           insulation_assembly_r_value: assembly_r)
    end
  elsif hpxml_file.include?('EPA_Tests/MF')
    if ['EPA_Tests/MFv1_0/MFv1_0_CZ2_FL_gas_ground_corner_slab.xml',
        'EPA_Tests/MFv1_0/MFv1_0_CZ4_MO_gas_top_corner.xml'].include? hpxml_file
      assembly_r = (1.0 / 0.089).round(3)
    elsif ['EPA_Tests/MFv1_1/MFv1_1_CZ4_MO_elec_ground_corner_vented_crawl.xml',
           'EPA_Tests/MFv1_1/MFv1_1_CZ2_FL_elec_top_corner.xml'].include? hpxml_file
      assembly_r = (1.0 / 0.064).round(3)
    elsif ['EPA_Tests/MFv1_1/MFv1_1_CZ6_VT_gas_ground_corner_cond_bsmt.xml',
           'EPA_Tests/MFv1_0/MFv1_0_CZ6_VT_elec_middle_interior.xml'].include? hpxml_file
      assembly_r = (1.0 / 0.051).round(3)
    end
    if hpxml_file.include?('ground_corner') || hpxml_file.include?('top_corner')
      exterior_area = 110
    elsif hpxml_file.include?('middle_interior')
      exterior_area = 80
    end
    hpxml.rim_joists.clear
    hpxml.rim_joists.add(id: 'RimJoist',
                         exterior_adjacent_to: HPXML::LocationOutside,
                         interior_adjacent_to: HPXML::LocationLivingSpace,
                         area: exterior_area,
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
      hpxml.rim_joists.add(id: 'RimJoistFoundation',
                           exterior_adjacent_to: HPXML::LocationOutside,
                           interior_adjacent_to: interior_adjacent_to,
                           area: exterior_area,
                           solar_absorptance: 0.75,
                           emittance: 0.9,
                           insulation_assembly_r_value: assembly_r)
    end
  end
end

def set_hpxml_walls(hpxml_file, hpxml)
  if hpxml_file.include?('EPA_Tests/SF')
    if ['EPA_Tests/SFv3_1/SFv3_1_CZ2_FL_elec_slab.xml',
        'EPA_Tests/SFv3_0/SFv3_0_CZ2_FL_gas_slab.xml',
        'EPA_Tests/SFv3_0/SFv3_0_CZ4_MO_gas_vented_crawl.xml'].include? hpxml_file
      assembly_r = (1.0 / 0.082).round(3)
    elsif ['EPA_Tests/SFv3_1/SFv3_1_CZ4_MO_elec_vented_crawl.xml',
           'EPA_Tests/SFv3_0/SFv3_0_CZ6_VT_elec_cond_bsmt.xml'].include? hpxml_file
      assembly_r = (1.0 / 0.057).round(3)
    elsif ['EPA_Tests/SFv3_1/SFv3_1_CZ6_VT_gas_cond_bsmt.xml'].include? hpxml_file
      assembly_r = (1.0 / 0.048).round(3)
    end
    hpxml.walls.clear
    hpxml.walls.add(id: 'Wall',
                    exterior_adjacent_to: HPXML::LocationOutside,
                    interior_adjacent_to: HPXML::LocationLivingSpace,
                    wall_type: HPXML::WallTypeWoodStud,
                    area: 2380,
                    solar_absorptance: 0.75,
                    emittance: 0.9,
                    insulation_assembly_r_value: assembly_r)
  elsif hpxml_file.include?('EPA_Tests/MF')
    if ['EPA_Tests/MFv1_0/MFv1_0_CZ2_FL_gas_ground_corner_slab.xml',
        'EPA_Tests/MFv1_0/MFv1_0_CZ4_MO_gas_top_corner.xml'].include? hpxml_file
      assembly_r = (1.0 / 0.089).round(3)
    elsif ['EPA_Tests/MFv1_1/MFv1_1_CZ4_MO_elec_ground_corner_vented_crawl.xml',
           'EPA_Tests/MFv1_1/MFv1_1_CZ2_FL_elec_top_corner.xml'].include? hpxml_file
      assembly_r = (1.0 / 0.064).round(3)
    elsif ['EPA_Tests/MFv1_1/MFv1_1_CZ6_VT_gas_ground_corner_cond_bsmt.xml',
           'EPA_Tests/MFv1_0/MFv1_0_CZ6_VT_elec_middle_interior.xml'].include? hpxml_file
      assembly_r = (1.0 / 0.051).round(3)
    end
    if hpxml_file.include?('ground_corner') || hpxml_file.include?('top_corner')
      exterior_area = 935
      common_area = 255
    elsif hpxml_file.include?('middle_interior')
      exterior_area = 680
      common_area = 510
    end
    hpxml.walls.clear
    hpxml.walls.add(id: 'Wall',
                    exterior_adjacent_to: HPXML::LocationOutside,
                    interior_adjacent_to: HPXML::LocationLivingSpace,
                    wall_type: HPXML::WallTypeWoodStud,
                    area: exterior_area,
                    solar_absorptance: 0.75,
                    emittance: 0.9,
                    insulation_assembly_r_value: assembly_r)
    hpxml.walls.add(id: 'WallAdiabatic',
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
    hpxml.foundation_walls.add(id: 'FoundationWallNorth',
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
    hpxml.foundation_walls.add(id: 'FoundationWallEast',
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
    hpxml.foundation_walls.add(id: 'FoundationWallSouth',
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
    hpxml.foundation_walls.add(id: 'FoundationWallWest',
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
  elsif ['RESNET_Tests/4.5_DSE/HVAC3a.xml'].include? hpxml_file
    for i in 0..hpxml.foundation_walls.size - 1
      hpxml.foundation_walls[i].interior_adjacent_to = HPXML::LocationBasementUnconditioned
    end
  elsif hpxml_file.include?('EPA_Tests') && hpxml_file.include?('vented_crawl')
    hpxml.foundation_walls.clear
    hpxml.foundation_walls.add(id: 'FoundationWall',
                               exterior_adjacent_to: HPXML::LocationGround,
                               interior_adjacent_to: HPXML::LocationCrawlspaceVented,
                               height: 4.0,
                               area: 552,
                               thickness: 8,
                               depth_below_grade: 2.0,
                               insulation_interior_r_value: 0,
                               insulation_interior_distance_to_top: 0,
                               insulation_interior_distance_to_bottom: 0,
                               insulation_exterior_r_value: 0,
                               insulation_exterior_distance_to_top: 0,
                               insulation_exterior_distance_to_bottom: 0)
  elsif hpxml_file.include?('EPA_Tests') && hpxml_file.include?('cond_bsmt')
    if hpxml_file.include?('MF') && hpxml_file.include?('CZ6')
      insulation_interior_r_value = 7.5
      insulation_interior_distance_to_top = 0
      insulation_interior_distance_to_bottom = 8
      insulation_exterior_r_value = 0
      insulation_exterior_distance_to_top = 0
      insulation_exterior_distance_to_bottom = 0
    else
      assembly_r = (1.0 / 0.05).round(3)
    end
    hpxml.foundation_walls.clear
    hpxml.foundation_walls.add(id: 'FoundationWall',
                               exterior_adjacent_to: HPXML::LocationGround,
                               interior_adjacent_to: HPXML::LocationBasementConditioned,
                               height: 8.0,
                               area: 1104,
                               thickness: 8,
                               depth_below_grade: 6.0,
                               insulation_interior_r_value: insulation_interior_r_value,
                               insulation_interior_distance_to_top: insulation_interior_distance_to_top,
                               insulation_interior_distance_to_bottom: insulation_interior_distance_to_bottom,
                               insulation_exterior_r_value: insulation_exterior_r_value,
                               insulation_exterior_distance_to_top: insulation_exterior_distance_to_top,
                               insulation_exterior_distance_to_bottom: insulation_exterior_distance_to_bottom,
                               insulation_assembly_r_value: assembly_r)
  end
end

def set_hpxml_frame_floors(hpxml_file, hpxml)
  if ['RESNET_Tests/4.5_DSE/HVAC3a.xml'].include? hpxml_file
    # R-11 floor from ASHRAE 140 but with 13% framing factor instead of 10%
    hpxml.frame_floors.add(id: 'FloorOverFoundation',
                           exterior_adjacent_to: HPXML::LocationBasementUnconditioned,
                           interior_adjacent_to: HPXML::LocationLivingSpace,
                           area: 1539,
                           insulation_assembly_r_value: 13.85)
  elsif ['RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/02-L100.xml'].include? hpxml_file
    # Uninsulated
    hpxml.frame_floors[1].insulation_assembly_r_value = 4.24
    hpxml.frame_floors[1].exterior_adjacent_to = HPXML::LocationCrawlspaceUnvented
  elsif ['RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/04-L324.xml'].include? hpxml_file
    hpxml.frame_floors.delete_at(1)
  elsif hpxml_file.include?('EPA_Tests')
    # Ceiling
    if hpxml_file.include?('ground_corner') || hpxml_file.include?('middle_interior')
      exterior_adjacent_to = HPXML::LocationOtherHousingUnit
      other_space_above_or_below = HPXML::FrameFloorOtherSpaceAbove
      ceiling_assembly_r = 1.67
    else
      exterior_adjacent_to = HPXML::LocationAtticVented
      if ['EPA_Tests/SFv3_0/SFv3_0_CZ2_FL_gas_slab.xml'].include? hpxml_file
        ceiling_assembly_r = (1.0 / 0.035).round(3)
      elsif ['EPA_Tests/SFv3_1/SFv3_1_CZ2_FL_elec_slab.xml',
             'EPA_Tests/SFv3_0/SFv3_0_CZ4_MO_gas_vented_crawl.xml'].include? hpxml_file
        ceiling_assembly_r = (1.0 / 0.030).round(3)
      elsif ['EPA_Tests/MFv1_1/MFv1_1_CZ2_FL_elec_top_corner.xml',
             'EPA_Tests/MFv1_0/MFv1_0_CZ4_MO_gas_top_corner.xml'].include? hpxml_file
        ceiling_assembly_r = (1.0 / 0.027).round(3)
      elsif ['EPA_Tests/SFv3_1/SFv3_1_CZ4_MO_elec_vented_crawl.xml',
             'EPA_Tests/SFv3_1/SFv3_1_CZ6_VT_gas_cond_bsmt.xml',
             'EPA_Tests/SFv3_0/SFv3_0_CZ6_VT_elec_cond_bsmt.xml'].include? hpxml_file
        ceiling_assembly_r = (1.0 / 0.026).round(3)
      end
    end
    hpxml.frame_floors.add(id: 'Ceiling',
                           exterior_adjacent_to: exterior_adjacent_to,
                           interior_adjacent_to: HPXML::LocationLivingSpace,
                           area: 1200,
                           insulation_assembly_r_value: ceiling_assembly_r,
                           other_space_above_or_below: other_space_above_or_below)
    # Floor
    if hpxml_file.include?('vented_crawl')
      if hpxml_file.include?('EPA_Tests/SF')
        floor_assembly_r = (1.0 / 0.047).round(3)
      elsif hpxml_file.include?('EPA_Tests/MF')
        floor_assembly_r = (1.0 / 0.033).round(3)
      end
      hpxml.frame_floors.add(id: 'Floor',
                             exterior_adjacent_to: HPXML::LocationCrawlspaceVented,
                             interior_adjacent_to: HPXML::LocationLivingSpace,
                             area: 1200,
                             insulation_assembly_r_value: floor_assembly_r)
    elsif hpxml_file.include?('top_corner') || hpxml_file.include?('middle_interior')
      hpxml.frame_floors.add(id: 'Floor',
                             exterior_adjacent_to: HPXML::LocationOtherHousingUnit,
                             interior_adjacent_to: HPXML::LocationLivingSpace,
                             area: 1200,
                             insulation_assembly_r_value: 3.1,
                             other_space_above_or_below: HPXML::FrameFloorOtherSpaceBelow)
    end
  end
end

def set_hpxml_slabs(hpxml_file, hpxml)
  if ['RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/02-L100.xml'].include? hpxml_file
    # Unvented crawlspace
    hpxml.slabs.add(id: 'Slab',
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
      name = 'Slab'
    elsif hpxml_file.include?('vented_crawl')
      interior_adjacent_to = HPXML::LocationCrawlspaceVented
      depth_below_grade = nil
      carpet_fraction = 0.0
      thickness = 0
      name = 'DirtFloor'
    elsif hpxml_file.include?('cond_bsmt')
      interior_adjacent_to = HPXML::LocationBasementConditioned
      depth_below_grade = nil
      carpet_fraction = 0.8
      thickness = 4
      name = 'Slab'
    else
      return
    end
    if hpxml_file.include?('EPA_Tests/SF')
      exposed_perimeter = 138
    elsif hpxml_file.include?('EPA_Tests/MF')
      exposed_perimeter = 110
    end
    hpxml.slabs.clear
    hpxml.slabs.add(id: name,
                    interior_adjacent_to: interior_adjacent_to,
                    depth_below_grade: depth_below_grade,
                    area: 1200,
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
    if ['EPA_Tests/SFv3_0/SFv3_0_CZ2_FL_gas_slab.xml',
        'EPA_Tests/MFv1_0/MFv1_0_CZ2_FL_gas_ground_corner_slab.xml'].include? hpxml_file
      ufactor = 0.60
      shgc = 0.27
    elsif ['EPA_Tests/SFv3_1/SFv3_1_CZ2_FL_elec_slab.xml',
           'EPA_Tests/MFv1_1/MFv1_1_CZ2_FL_elec_top_corner.xml'].include? hpxml_file
      ufactor = 0.40
      shgc = 0.25
    elsif ['EPA_Tests/SFv3_0/SFv3_0_CZ4_MO_gas_vented_crawl.xml',
           'EPA_Tests/MFv1_0/MFv1_0_CZ4_MO_gas_top_corner.xml'].include? hpxml_file
      ufactor = 0.32
      shgc = 0.40
    elsif ['EPA_Tests/SFv3_1/SFv3_1_CZ4_MO_elec_vented_crawl.xml',
           'EPA_Tests/SFv3_0/SFv3_0_CZ6_VT_elec_cond_bsmt.xml',
           'EPA_Tests/MFv1_1/MFv1_1_CZ4_MO_elec_ground_corner_vented_crawl.xml',
           'EPA_Tests/MFv1_0/MFv1_0_CZ6_VT_elec_middle_interior.xml'].include? hpxml_file
      ufactor = 0.30
      shgc = 0.40
    elsif ['EPA_Tests/SFv3_1/SFv3_1_CZ6_VT_gas_cond_bsmt.xml',
           'EPA_Tests/MFv1_1/MFv1_1_CZ6_VT_gas_ground_corner_cond_bsmt.xml'].include? hpxml_file
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
      windows = { 'WindowsNorth' => [0, (tot_window_area / 4.0).round(2), 'Wall'],
                  'WindowsEast' => [90, (tot_window_area / 4.0).round(2), 'Wall'],
                  'WindowsSouth' => [180, (tot_window_area / 4.0).round(2), 'Wall'],
                  'WindowsWest' => [270, (tot_window_area / 4.0).round(2), 'Wall'] }
    elsif hpxml_file.include?('EPA_Tests/MF')
      if hpxml_file.include?('ground_corner') || hpxml_file.include?('top_corner')
        windows = { 'WindowsEast' => [90, (0.571 * tot_window_area).round(2), 'Wall'],
                    'WindowsSouth' => [180, (0.429 * tot_window_area).round(2), 'Wall'] }
      elsif hpxml_file.include?('middle_interior')
        windows = { 'WindowsEast' => [90, tot_window_area.round(2), 'Wall'] }
      end
    end

    hpxml.windows.clear
    windows.each do |window_name, window_values|
      azimuth, area, wall = window_values
      hpxml.windows.add(id: window_name,
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
    if hpxml_file.include?('SFv3_1')
      r_value = (1.0 / 0.17).round(3)
    elsif hpxml_file.include?('SFv3_0')
      r_value = (1.0 / 0.21).round(3)
    end
    doors = { 'Door1' => [0, 21, 'Wall'],
              'Door2' => [0, 21, 'Wall'] }
    hpxml.doors.clear
    doors.each do |door_name, door_values|
      azimuth, area, wall = door_values
      hpxml.doors.add(id: door_name,
                      wall_idref: wall,
                      area: area,
                      azimuth: azimuth,
                      r_value: r_value)
    end
  elsif hpxml_file.include?('EPA_Tests/MF')
    if hpxml_file.include?('MFv1_0')
      r_value = (1.0 / 0.21).round(3)
    elsif hpxml_file.include?('MFv1_1')
      r_value = (1.0 / 0.17).round(3)
    end
    doors = { 'Door1' => [0, 21, 'Wall'] }
    hpxml.doors.clear
    doors.each do |door_name, door_values|
      azimuth, area, wall = door_values
      hpxml.doors.add(id: door_name,
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
    hpxml.heating_systems.add(id: 'HeatingSystem',
                              distribution_system_idref: 'HVACDistribution',
                              heating_system_type: HPXML::HVACTypeFurnace,
                              heating_system_fuel: HPXML::FuelTypeNaturalGas,
                              heating_capacity: -1,
                              heating_efficiency_afue: 0.82,
                              fraction_heat_load_served: 1,
                              fan_power_not_tested: true,
                              airflow_not_tested: true)
  elsif ['RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/03-L304.xml'].include? hpxml_file
    # Electric strip heating with COP = 1.0
    hpxml.heating_systems.clear
    hpxml.heating_systems.add(id: 'HeatingSystem',
                              heating_system_type: HPXML::HVACTypeElectricResistance,
                              heating_system_fuel: HPXML::FuelTypeElectricity,
                              heating_capacity: -1,
                              heating_efficiency_percent: 1,
                              fraction_heat_load_served: 1)
  elsif ['RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/04-L324.xml'].include? hpxml_file
    # Gas furnace with AFUE = 95%
    hpxml.heating_systems.clear
    hpxml.heating_systems.add(id: 'HeatingSystem',
                              distribution_system_idref: 'HVACDistribution',
                              heating_system_type: HPXML::HVACTypeFurnace,
                              heating_system_fuel: HPXML::FuelTypeNaturalGas,
                              heating_capacity: -1,
                              heating_efficiency_afue: 0.95,
                              fraction_heat_load_served: 1,
                              fan_power_not_tested: true,
                              airflow_not_tested: true)
  elsif ['RESNET_Tests/4.3_HERS_Method/L100A-03.xml'].include? hpxml_file
    # Natural gas furnace with AFUE = 78%
    hpxml.heating_systems.clear
    hpxml.heating_systems.add(id: 'HeatingSystem',
                              distribution_system_idref: 'HVACDistribution',
                              heating_system_type: HPXML::HVACTypeFurnace,
                              heating_system_fuel: HPXML::FuelTypeNaturalGas,
                              heating_capacity: -1,
                              heating_efficiency_afue: 0.78,
                              fraction_heat_load_served: 1,
                              fan_power_not_tested: true,
                              airflow_not_tested: true)
  elsif ['RESNET_Tests/4.3_HERS_Method/L100A-05.xml'].include? hpxml_file
    # Natural gas furnace with AFUE = 96%
    hpxml.heating_systems.clear
    hpxml.heating_systems.add(id: 'HeatingSystem',
                              distribution_system_idref: 'HVACDistribution',
                              heating_system_type: HPXML::HVACTypeFurnace,
                              heating_system_fuel: HPXML::FuelTypeNaturalGas,
                              heating_capacity: -1,
                              heating_efficiency_afue: 0.96,
                              fraction_heat_load_served: 1,
                              fan_power_not_tested: true,
                              airflow_not_tested: true)
  elsif ['RESNET_Tests/4.4_HVAC/HVAC2a.xml',
         'RESNET_Tests/4.4_HVAC/HVAC1a.xml'].include? hpxml_file
    # Gas Furnace; 56.1 kBtu/h; AFUE = 78%; 0.0005 kW/cfm
    hpxml.heating_systems.clear
    hpxml.heating_systems.add(id: 'HeatingSystem',
                              distribution_system_idref: 'HVACDistribution',
                              heating_system_type: HPXML::HVACTypeFurnace,
                              heating_system_fuel: HPXML::FuelTypeNaturalGas,
                              heating_capacity: 56100,
                              heating_efficiency_afue: 0.78,
                              fraction_heat_load_served: 1,
                              fan_watts_per_cfm: 0.5)
  elsif ['RESNET_Tests/4.4_HVAC/HVAC2b.xml'].include? hpxml_file
    # Gas Furnace; 56.1 kBtu/h; AFUE = 90%; 0.000375 kW/cfm
    hpxml.heating_systems.clear
    hpxml.heating_systems.add(id: 'HeatingSystem',
                              distribution_system_idref: 'HVACDistribution',
                              heating_system_type: HPXML::HVACTypeFurnace,
                              heating_system_fuel: HPXML::FuelTypeNaturalGas,
                              heating_capacity: 56100,
                              heating_efficiency_afue: 0.9,
                              fraction_heat_load_served: 1,
                              fan_watts_per_cfm: 0.5)
  elsif ['RESNET_Tests/4.4_HVAC/HVAC2e.xml'].include? hpxml_file
    # Electric Furnace; 56.1 kBtu/h; COP =1.0
    hpxml.heating_systems.clear
    hpxml.heating_systems.add(id: 'HeatingSystem',
                              distribution_system_idref: 'HVACDistribution',
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
    hpxml.heating_systems.add(id: 'HeatingSystem',
                              distribution_system_idref: 'HVACDistribution',
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
    hpxml.heating_systems.add(id: 'HeatingSystem',
                              distribution_system_idref: 'HVACDistribution',
                              heating_system_type: HPXML::HVACTypeFurnace,
                              heating_system_fuel: HPXML::FuelTypeNaturalGas,
                              heating_capacity: -1,
                              heating_efficiency_afue: 0.78,
                              fraction_heat_load_served: 1,
                              fan_power_not_tested: true,
                              airflow_not_tested: true)
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
    hpxml.heating_systems.clear
    hpxml.heating_systems.add(id: 'HeatingSystem',
                              distribution_system_idref: 'HVACDistribution',
                              heating_system_type: HPXML::HVACTypeFurnace,
                              heating_system_fuel: HPXML::FuelTypeNaturalGas,
                              heating_capacity: -1,
                              heating_efficiency_afue: afue,
                              fraction_heat_load_served: 1,
                              fan_watts_per_cfm: 0.58,
                              airflow_defect_ratio: -0.25)
  end
end

def set_hpxml_cooling_systems(hpxml_file, hpxml)
  if ['RESNET_Tests/4.4_HVAC/HVAC2c.xml',
      'RESNET_Tests/4.4_HVAC/HVAC2d.xml'].include?(hpxml_file)
    hpxml.cooling_systems.clear
  elsif ['RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/01-L100.xml'].include? hpxml_file
    # Central air conditioner with SEER = 11.0
    hpxml.cooling_systems.clear
    hpxml.cooling_systems.add(id: 'CoolingSystem',
                              distribution_system_idref: 'HVACDistribution',
                              cooling_system_type: HPXML::HVACTypeCentralAirConditioner,
                              cooling_system_fuel: HPXML::FuelTypeElectricity,
                              cooling_capacity: -1,
                              fraction_cool_load_served: 1,
                              cooling_efficiency_seer: 11,
                              fan_power_not_tested: true,
                              airflow_not_tested: true,
                              charge_not_tested: true)
  elsif ['RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/03-L304.xml'].include? hpxml_file
    # Central air conditioner with SEER = 15.0
    hpxml.cooling_systems.clear
    hpxml.cooling_systems.add(id: 'CoolingSystem',
                              distribution_system_idref: 'HVACDistribution',
                              cooling_system_type: HPXML::HVACTypeCentralAirConditioner,
                              cooling_system_fuel: HPXML::FuelTypeElectricity,
                              cooling_capacity: -1,
                              fraction_cool_load_served: 1,
                              cooling_efficiency_seer: 15,
                              fan_power_not_tested: true,
                              airflow_not_tested: true,
                              charge_not_tested: true)
  elsif ['RESNET_Tests/4.3_HERS_Method/L100A-03.xml',
         'RESNET_Tests/4.3_HERS_Method/L100A-05.xml'].include? hpxml_file
    # Cooling system – electric A/C with SEER = 10.0
    hpxml.cooling_systems.clear
    hpxml.cooling_systems.add(id: 'CoolingSystem',
                              distribution_system_idref: 'HVACDistribution',
                              cooling_system_type: HPXML::HVACTypeCentralAirConditioner,
                              cooling_system_fuel: HPXML::FuelTypeElectricity,
                              cooling_capacity: -1,
                              fraction_cool_load_served: 1,
                              cooling_efficiency_seer: 10,
                              fan_power_not_tested: true,
                              airflow_not_tested: true,
                              charge_not_tested: true)
  elsif ['RESNET_Tests/4.4_HVAC/HVAC1a.xml',
         'RESNET_Tests/4.4_HVAC/HVAC2a.xml'].include? hpxml_file
    # Air cooled air conditioner; 38.3 kBtu/h; SEER = 10
    hpxml.cooling_systems.clear
    hpxml.cooling_systems.add(id: 'CoolingSystem',
                              distribution_system_idref: 'HVACDistribution',
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
    hpxml.cooling_systems.add(id: 'CoolingSystem',
                              distribution_system_idref: 'HVACDistribution',
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
    hpxml.cooling_systems.add(id: 'CoolingSystem',
                              distribution_system_idref: 'HVACDistribution',
                              cooling_system_type: HPXML::HVACTypeCentralAirConditioner,
                              cooling_system_fuel: HPXML::FuelTypeElectricity,
                              cooling_capacity: -1,
                              fraction_cool_load_served: 1,
                              cooling_efficiency_seer: 13,
                              fan_power_not_tested: true,
                              airflow_not_tested: true,
                              charge_not_tested: true)
  elsif hpxml_file.include?('EPA_Tests')
    if hpxml_file.include?('_elec_')
      return
    elsif hpxml_file.include?('CZ4') || hpxml_file.include?('CZ6')
      seer = 13
    elsif hpxml_file.include?('CZ2')
      seer = 14.5
    end
    hpxml.cooling_systems.clear
    hpxml.cooling_systems.add(id: 'CoolingSystem',
                              distribution_system_idref: 'HVACDistribution',
                              cooling_system_type: HPXML::HVACTypeCentralAirConditioner,
                              cooling_system_fuel: HPXML::FuelTypeElectricity,
                              cooling_capacity: -1,
                              fraction_cool_load_served: 1,
                              cooling_efficiency_seer: seer,
                              fan_watts_per_cfm: 0.58,
                              airflow_defect_ratio: -0.25,
                              charge_defect_ratio: -0.25)
  end
end

def set_hpxml_heat_pumps(hpxml_file, hpxml)
  if ['RESNET_Tests/4.3_HERS_Method/L100A-03.xml',
      'RESNET_Tests/4.3_HERS_Method/L100A-05.xml'].include? hpxml_file
    hpxml.heat_pumps.clear
  elsif ['RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/02-L100.xml'].include? hpxml_file
    # Electric heat pump with HSPF = 7.5 and SEER = 12.0
    hpxml.heat_pumps.clear
    hpxml.heat_pumps.add(id: 'HeatPump',
                         distribution_system_idref: 'HVACDistribution',
                         heat_pump_type: HPXML::HVACTypeHeatPumpAirToAir,
                         heat_pump_fuel: HPXML::FuelTypeElectricity,
                         cooling_capacity: -1,
                         heating_capacity: -1,
                         backup_heating_fuel: HPXML::FuelTypeElectricity,
                         backup_heating_capacity: -1,
                         backup_heating_efficiency_percent: 1.0,
                         fraction_heat_load_served: 1,
                         fraction_cool_load_served: 1,
                         heating_efficiency_hspf: 7.5,
                         cooling_efficiency_seer: 12,
                         fan_power_not_tested: true,
                         airflow_not_tested: true,
                         charge_not_tested: true)
  elsif ['RESNET_Tests/4.3_HERS_Method/L100A-01.xml'].include? hpxml_file
    # Heating system – electric HP with HSPF = 6.8
    # Cooling system – electric A/C with SEER
    hpxml.heat_pumps.clear
    hpxml.heat_pumps.add(id: 'HeatPump',
                         distribution_system_idref: 'HVACDistribution',
                         heat_pump_type: HPXML::HVACTypeHeatPumpAirToAir,
                         heat_pump_fuel: HPXML::FuelTypeElectricity,
                         cooling_capacity: -1,
                         heating_capacity: -1,
                         backup_heating_fuel: HPXML::FuelTypeElectricity,
                         backup_heating_capacity: -1,
                         backup_heating_efficiency_percent: 1.0,
                         fraction_heat_load_served: 1,
                         fraction_cool_load_served: 1,
                         heating_efficiency_hspf: 6.8,
                         cooling_efficiency_seer: 10,
                         fan_power_not_tested: true,
                         airflow_not_tested: true,
                         charge_not_tested: true)
  elsif ['RESNET_Tests/4.3_HERS_Method/L100A-04.xml'].include? hpxml_file
    # Change to a high efficiency HP with HSPF = 9.85
    hpxml.heat_pumps[0].heating_efficiency_hspf = 9.85
  elsif ['RESNET_Tests/4.4_HVAC/HVAC2c.xml'].include? hpxml_file
    # Air Source Heat Pump; 56.1 kBtu/h; HSPF = 6.8
    hpxml.heat_pumps.clear
    hpxml.heat_pumps.add(id: 'HeatPump',
                         distribution_system_idref: 'HVACDistribution',
                         heat_pump_type: HPXML::HVACTypeHeatPumpAirToAir,
                         heat_pump_fuel: HPXML::FuelTypeElectricity,
                         cooling_capacity: 56100,
                         heating_capacity: 56100,
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
    hpxml.heat_pumps.add(id: 'HeatPump',
                         distribution_system_idref: 'HVACDistribution',
                         heat_pump_type: HPXML::HVACTypeHeatPumpAirToAir,
                         heat_pump_fuel: HPXML::FuelTypeElectricity,
                         cooling_capacity: 56100,
                         heating_capacity: 56100,
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
      hspf = 8.2
      seer = 15
    elsif hpxml_file.include?('CZ4')
      hspf = 8.5
      seer = 15
    elsif hpxml_file.include?('CZ6')
      hspf = 9.5
      seer = 14.5
    end
    hpxml.heat_pumps.clear
    hpxml.heat_pumps.add(id: 'HeatPump',
                         distribution_system_idref: 'HVACDistribution',
                         heat_pump_type: HPXML::HVACTypeHeatPumpAirToAir,
                         heat_pump_fuel: HPXML::FuelTypeElectricity,
                         cooling_capacity: -1,
                         heating_capacity: -1,
                         backup_heating_fuel: HPXML::FuelTypeElectricity,
                         backup_heating_capacity: -1,
                         backup_heating_efficiency_percent: 1.0,
                         fraction_heat_load_served: 1,
                         fraction_cool_load_served: 1,
                         heating_efficiency_hspf: hspf,
                         cooling_efficiency_seer: seer,
                         fan_watts_per_cfm: 0.58,
                         airflow_defect_ratio: -0.25,
                         charge_defect_ratio: -0.25)
  end
end

def set_hpxml_hvac_controls(hpxml_file, hpxml)
  if hpxml_file.include?('HERS_AutoGen') || hpxml_file.include?('HERS_Method') || hpxml_file.include?('Hot_Water')
    hpxml.hvac_controls.clear
    if hpxml.heating_systems.size + hpxml.cooling_systems.size + hpxml.heat_pumps.size > 0
      hpxml.hvac_controls.add(id: 'HVACControl',
                              control_type: HPXML::HVACControlTypeManual)
    end
  elsif hpxml_file.include?('EPA_Tests')
    hpxml.hvac_controls.clear
    hpxml.hvac_controls.add(id: 'HVACControl',
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
    hpxml.hvac_distributions.add(id: 'HVACDistribution',
                                 distribution_system_type: HPXML::HVACDistributionTypeAir,
                                 air_type: HPXML::AirTypeRegularVelocity)
  elsif ['RESNET_Tests/4.4_HVAC/HVAC1a.xml',
         'RESNET_Tests/4.4_HVAC/HVAC2a.xml'].include? hpxml_file
    hpxml.hvac_distributions.clear
    hpxml.hvac_distributions.add(id: 'HVACDistribution',
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
     hpxml_file.include?('EPA_Tests/SFv3_1') ||
     hpxml_file.include?('EPA_Tests/MFv1_1')
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
                                                              duct_leakage_value: tot_cfm25 * 0.5,
                                                              duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside)
    hpxml.hvac_distributions[0].duct_leakage_measurements.add(duct_type: HPXML::DuctTypeReturn,
                                                              duct_leakage_units: HPXML::UnitsCFM25,
                                                              duct_leakage_value: tot_cfm25 * 0.5,
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
    hpxml.hvac_distributions[0].ducts.add(duct_type: HPXML::DuctTypeSupply,
                                          duct_insulation_r_value: 0,
                                          duct_location: HPXML::LocationLivingSpace,
                                          duct_surface_area: 308)
    hpxml.hvac_distributions[0].ducts.add(duct_type: HPXML::DuctTypeReturn,
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
    if hpxml_file.include?('SFv3_1') || hpxml_file.include?('MFv1_1') || hpxml_file.include?('MFv1_0')
      if hpxml_file.include?('MFv1_0') && hpxml_file.include?('top_corner')
        location = HPXML::LocationAtticVented
        supply_r = 8
        return_r = 6
      else
        location = HPXML::LocationLivingSpace
        supply_r = 0
        return_r = 0
      end
      hpxml.hvac_distributions[0].ducts.clear
      hpxml.hvac_distributions[0].ducts.add(duct_type: HPXML::DuctTypeSupply,
                                            duct_insulation_r_value: supply_r,
                                            duct_location: location,
                                            duct_surface_area: supply_area)
      hpxml.hvac_distributions[0].ducts.add(duct_type: HPXML::DuctTypeReturn,
                                            duct_insulation_r_value: return_r,
                                            duct_location: location,
                                            duct_surface_area: return_area)
    elsif hpxml_file.include?('SFv3_0')
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
      hpxml.hvac_distributions[0].ducts.add(duct_type: HPXML::DuctTypeSupply,
                                            duct_insulation_r_value: 8,
                                            duct_location: HPXML::LocationAtticVented,
                                            duct_surface_area: supply_area * (1.0 - non_attic_frac))
      hpxml.hvac_distributions[0].ducts.add(duct_type: HPXML::DuctTypeReturn,
                                            duct_insulation_r_value: 6,
                                            duct_location: HPXML::LocationAtticVented,
                                            duct_surface_area: return_area * (1.0 - non_attic_frac))
      hpxml.hvac_distributions[0].ducts.add(duct_type: HPXML::DuctTypeSupply,
                                            duct_insulation_r_value: non_attic_rvalue,
                                            duct_location: non_attic_location,
                                            duct_surface_area: supply_area * non_attic_frac)
      hpxml.hvac_distributions[0].ducts.add(duct_type: HPXML::DuctTypeReturn,
                                            duct_insulation_r_value: non_attic_rvalue,
                                            duct_location: non_attic_location,
                                            duct_surface_area: return_area * non_attic_frac)
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
    hpxml.ventilation_fans.add(id: 'MechanicalVentilation',
                               fan_type: HPXML::MechVentTypeExhaust,
                               tested_flow_rate: 56.2,
                               hours_in_operation: 24,
                               fan_power: 14.7,
                               used_for_whole_building_ventilation: true,
                               is_shared_system: false)
  elsif ['RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/03-L304.xml'].include? hpxml_file
    # Balanced whole-dwelling mechanical ventilation without energy recovery
    hpxml.ventilation_fans.clear
    hpxml.ventilation_fans.add(id: 'MechanicalVentilation',
                               fan_type: HPXML::MechVentTypeBalanced,
                               tested_flow_rate: 56.2,
                               hours_in_operation: 24,
                               fan_power: 14.7,
                               used_for_whole_building_ventilation: true,
                               is_shared_system: false)
  elsif ['RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/04-L324.xml'].include? hpxml_file
    # Balanced whole-dwelling mechanical ventilation with a 60% energy recovery system
    hpxml.ventilation_fans.clear
    hpxml.ventilation_fans.add(id: 'MechanicalVentilation',
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
    if hpxml_file.include?('SFv3_1') || hpxml_file.include?('MFv1_1')
      cfm_per_w = 2.8
    elsif hpxml_file.include?('SFv3_0') || hpxml_file.include?('MFv1_0')
      cfm_per_w = 2.2
    end
    hpxml.ventilation_fans.clear
    hpxml.ventilation_fans.add(id: 'MechanicalVentilation',
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
    hpxml.water_heating_systems.add(id: 'WaterHeater',
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
    hpxml.water_heating_systems.add(id: 'WaterHeater',
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
    hpxml.water_heating_systems.add(id: 'WaterHeater',
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
    hpxml.water_heating_systems.add(id: 'WaterHeater',
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
    hpxml.water_heating_systems.add(id: 'WaterHeater',
                                    is_shared_system: false,
                                    fuel_type: HPXML::FuelTypeElectricity,
                                    water_heater_type: HPXML::WaterHeaterTypeStorage,
                                    location: HPXML::LocationLivingSpace,
                                    tank_volume: 40,
                                    fraction_dhw_load_served: 1,
                                    energy_factor: 0.92)
  elsif hpxml_file.include?('EPA_Tests')
    if hpxml_file.include?('EPA_Tests/MF')
      location = HPXML::LocationLivingSpace
    elsif hpxml_file.include?('slab')
      location = HPXML::LocationAtticVented
    elsif hpxml_file.include?('vented_crawl')
      location = HPXML::LocationCrawlspaceVented
    elsif hpxml_file.include?('cond_bsmt')
      location = HPXML::LocationBasementConditioned
    end
    hpxml.water_heating_systems.clear
    if hpxml_file.include?('_gas_')
      if hpxml_file.include?('EPA_Tests/MF')
        energy_factor = 0.67
      else
        energy_factor = 0.61
      end
      hpxml.water_heating_systems.add(id: 'WaterHeater',
                                      is_shared_system: false,
                                      fuel_type: HPXML::FuelTypeNaturalGas,
                                      water_heater_type: HPXML::WaterHeaterTypeStorage,
                                      location: location,
                                      tank_volume: 40,
                                      fraction_dhw_load_served: 1,
                                      energy_factor: energy_factor,
                                      recovery_efficiency: 0.8)
    elsif hpxml_file.include?('_elec_')
      if hpxml_file.include?('EPA_Tests/MF')
        energy_factor = 0.95
      else
        energy_factor = 0.93
      end
      hpxml.water_heating_systems.add(id: 'WaterHeater',
                                      is_shared_system: false,
                                      fuel_type: HPXML::FuelTypeElectricity,
                                      water_heater_type: HPXML::WaterHeaterTypeStorage,
                                      location: location,
                                      tank_volume: 40,
                                      fraction_dhw_load_served: 1,
                                      energy_factor: energy_factor)
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
    hpxml.hot_water_distributions.add(id: 'HotWaterDstribution',
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
    hpxml.hot_water_distributions.add(id: 'HotWaterDstribution',
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
    hpxml.water_fixtures.add(id: 'WaterFixture',
                             water_fixture_type: HPXML::WaterFixtureTypeShowerhead,
                             low_flow: false)
    hpxml.water_fixtures.add(id: 'WaterFixture2',
                             water_fixture_type: HPXML::WaterFixtureTypeFaucet,
                             low_flow: false)
  elsif ['RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AD-HW-04.xml',
         'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AM-HW-04.xml'].include?(hpxml_file) ||
        hpxml_file.include?('EPA_Tests/MF')
    # Low-flow
    hpxml.water_fixtures.clear
    hpxml.water_fixtures.add(id: 'WaterFixture',
                             water_fixture_type: HPXML::WaterFixtureTypeShowerhead,
                             low_flow: true)
    hpxml.water_fixtures.add(id: 'WaterFixture2',
                             water_fixture_type: HPXML::WaterFixtureTypeFaucet,
                             low_flow: true)
  elsif hpxml_file.include?('HERS_AutoGen')
    # Standard
    hpxml.water_fixtures.clear
    hpxml.water_fixtures.add(id: 'WaterFixture',
                             water_fixture_type: HPXML::WaterFixtureTypeShowerhead,
                             low_flow: false)
    hpxml.water_fixtures.add(id: 'WaterFixture2',
                             water_fixture_type: HPXML::WaterFixtureTypeFaucet,
                             low_flow: false)
  end
end

def set_hpxml_clothes_washer(hpxml_file, hpxml)
  return unless hpxml_file.include?('HERS_AutoGen') || hpxml_file.include?('HERS_Method') || hpxml_file.include?('Hot_Water') || hpxml_file.include?('EPA_Tests')

  default_values = HotWaterAndAppliances.get_clothes_washer_default_values(get_eri_version(hpxml))
  hpxml.clothes_washers.clear
  hpxml.clothes_washers.add(id: 'ClothesWasher',
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
    hpxml.clothes_dryers.add(id: 'ClothesDryer',
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
    hpxml.clothes_dryers.add(id: 'ClothesDryer',
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
    hpxml.dishwashers.add(id: 'Dishwasher',
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
    hpxml.dishwashers.add(id: 'Dishwasher',
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
    hpxml.refrigerators.add(id: 'Refrigerator',
                            location: HPXML::LocationLivingSpace,
                            rated_annual_kwh: 423.0)
  elsif hpxml_file.include?('HERS_AutoGen') || hpxml_file.include?('HERS_Method') || hpxml_file.include?('Hot_Water')
    # Standard
    default_values = HotWaterAndAppliances.get_refrigerator_default_values(hpxml.building_construction.number_of_bedrooms)
    hpxml.refrigerators.clear
    hpxml.refrigerators.add(id: 'Refrigerator',
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
    hpxml.cooking_ranges.add(id: 'Range',
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
    hpxml.cooking_ranges.add(id: 'Range',
                             location: HPXML::LocationLivingSpace,
                             fuel_type: HPXML::FuelTypeElectricity,
                             is_induction: default_values[:is_induction])
  end
end

def set_hpxml_oven(hpxml_file, hpxml)
  return unless hpxml_file.include?('HERS_AutoGen') || hpxml_file.include?('HERS_Method') || hpxml_file.include?('Hot_Water') || hpxml_file.include?('EPA_Tests')

  default_values = HotWaterAndAppliances.get_range_oven_default_values()
  hpxml.ovens.clear
  hpxml.ovens.add(id: 'Oven',
                  is_convection: default_values[:is_convection])
end

def set_hpxml_lighting(hpxml_file, hpxml)
  return unless hpxml_file.include?('HERS_AutoGen') || hpxml_file.include?('HERS_Method') || hpxml_file.include?('Hot_Water') || hpxml_file.include?('EPA_Tests')

  if hpxml_file.include?('EPA_Tests/SFv3_1') || hpxml_file.include?('EPA_Tests/MFv1_1') || hpxml_file.include?('EPA_Tests/MFv1_0')
    ltg_fracs = { [HPXML::LocationInterior, HPXML::LightingTypeLED] => 0,
                  [HPXML::LocationExterior, HPXML::LightingTypeLED] => 0,
                  [HPXML::LocationGarage, HPXML::LightingTypeLED] => 0,
                  [HPXML::LocationInterior, HPXML::LightingTypeCFL] => 0.9,
                  [HPXML::LocationExterior, HPXML::LightingTypeCFL] => 0,
                  [HPXML::LocationGarage, HPXML::LightingTypeCFL] => 0,
                  [HPXML::LocationInterior, HPXML::LightingTypeLFL] => 0,
                  [HPXML::LocationExterior, HPXML::LightingTypeLFL] => 0,
                  [HPXML::LocationGarage, HPXML::LightingTypeLFL] => 0 }
  elsif hpxml_file.include?('EPA_Tests/SFv3_0')
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
  ltg_fracs.each_with_index do |(key, fraction), i|
    location, lighting_type = key
    hpxml.lighting_groups.add(id: "LightingGroup#{i + 1}",
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
  FileUtils.rm_f(Dir.glob('workflow/sample_files/invalid_files/*.xml'))

  # Copy files we're interested in
  include_list = ['invalid_files/dhw-frac-load-served.xml',
                  'invalid_files/enclosure-floor-area-exceeds-cfa.xml',
                  'invalid_files/hvac-frac-load-served.xml',
                  'invalid_files/invalid-epw-filepath.xml',
                  'invalid_files/missing-elements.xml',
                  'invalid_files/num-bedrooms-exceeds-limit.xml',
                  'base.xml',
                  'base-appliances-dehumidifier.xml',
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
                  'base-foundation-conditioned-basement-wall-interior-insulation.xml',
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
                  'base-hvac-boiler-elec-only.xml',
                  'base-hvac-boiler-gas-only.xml',
                  'base-hvac-boiler-oil-only.xml',
                  'base-hvac-boiler-propane-only.xml',
                  'base-hvac-central-ac-only-1-speed.xml',
                  'base-hvac-dse.xml',
                  'base-hvac-dual-fuel-air-to-air-heat-pump-1-speed.xml',
                  'base-hvac-dual-fuel-air-to-air-heat-pump-1-speed-electric.xml',
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
                  'base-hvac-install-quality-all-air-to-air-heat-pump-1-speed.xml',
                  'base-hvac-install-quality-all-furnace-gas-central-ac-1-speed.xml',
                  'base-hvac-install-quality-all-ground-to-air-heat-pump.xml',
                  'base-hvac-install-quality-all-mini-split-air-conditioner-only-ducted.xml',
                  'base-hvac-install-quality-all-mini-split-heat-pump-ducted.xml',
                  'base-hvac-mini-split-air-conditioner-only-ducted.xml',
                  'base-hvac-mini-split-air-conditioner-only-ductless.xml',
                  'base-hvac-mini-split-heat-pump-ducted.xml',
                  'base-hvac-mini-split-heat-pump-ducted-cooling-only.xml',
                  'base-hvac-mini-split-heat-pump-ducted-heating-only.xml',
                  'base-hvac-mini-split-heat-pump-ductless.xml',
                  'base-hvac-multiple.xml',
                  'base-hvac-none.xml',
                  'base-hvac-portable-heater-gas-only.xml',
                  'base-hvac-programmable-thermostat.xml',
                  'base-hvac-room-ac-only.xml',
                  'base-hvac-stove-wood-pellets-only.xml',
                  'base-hvac-undersized.xml',
                  'base-hvac-wall-furnace-elec-only.xml',
                  'base-lighting-ceiling-fans.xml',
                  'base-location-baltimore-md.xml',
                  'base-location-dallas-tx.xml',
                  'base-location-duluth-mn.xml',
                  'base-location-helena-mt.xml',
                  'base-location-honolulu-hi.xml',
                  'base-location-miami-fl.xml',
                  'base-location-phoenix-az.xml',
                  'base-location-portland-or.xml',
                  'base-mechvent-balanced.xml',
                  'base-mechvent-cfis.xml',
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
  Dir['workflow/sample_files/invalid_files/*.xml'].each do |hpxml_path|
    hpxml_paths << hpxml_path
  end
  hpxml_paths.each do |hpxml_path|
    hpxml = HPXML.new(hpxml_path: hpxml_path)

    # Handle extra inputs for ERI
    hpxml.header.eri_calculation_version = 'latest'
    hpxml.building_construction.number_of_bathrooms = nil
    hpxml.heating_systems.each do |heating_system|
      next unless heating_system.heating_system_type == HPXML::HVACTypeBoiler
      next unless heating_system.is_shared_system.nil?

      heating_system.is_shared_system = false
    end
    hpxml.heat_pumps.each do |heat_pump|
      next unless heat_pump.heat_pump_type == HPXML::HVACTypeHeatPumpGroundToAir
      next unless heat_pump.is_shared_system.nil?

      heat_pump.is_shared_system = false
    end
    hpxml.water_heating_systems.each do |water_heating_system|
      next unless water_heating_system.is_shared_system.nil?

      water_heating_system.is_shared_system = false
    end
    shared_water_heaters = hpxml.water_heating_systems.select { |wh| wh.is_shared_system }
    if not hpxml.clothes_washers.empty?
      if hpxml.clothes_washers[0].is_shared_appliance
        hpxml.clothes_washers[0].number_of_units_served = shared_water_heaters[0].number_of_units_served
        hpxml.clothes_washers[0].number_of_units = 2
      else
        hpxml.clothes_washers[0].is_shared_appliance = false
      end
    end
    if not hpxml.clothes_dryers.empty?
      if hpxml.clothes_dryers[0].is_shared_appliance
        hpxml.clothes_dryers[0].number_of_units_served = shared_water_heaters[0].number_of_units_served
        hpxml.clothes_dryers[0].number_of_units = 2
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
      next unless ventilation_fan.used_for_whole_building_ventilation
      next unless ventilation_fan.is_shared_system.nil?

      ventilation_fan.is_shared_system = false
    end
    hpxml.heating_systems.each do |heating_system|
      next unless [HPXML::HVACTypeFurnace].include? heating_system.heating_system_type

      if heating_system.fan_watts_per_cfm.nil?
        heating_system.fan_power_not_tested = true
      end
      if heating_system.airflow_defect_ratio.nil?
        heating_system.airflow_not_tested = true
      end
    end
    hpxml.cooling_systems.each do |cooling_system|
      next unless [HPXML::HVACTypeCentralAirConditioner,
                   HPXML::HVACTypeMiniSplitAirConditioner].include? cooling_system.cooling_system_type

      if cooling_system.fan_watts_per_cfm.nil?
        cooling_system.fan_power_not_tested = true
      end
      if cooling_system.airflow_defect_ratio.nil?
        cooling_system.airflow_not_tested = true
      end
      if cooling_system.charge_defect_ratio.nil?
        cooling_system.charge_not_tested = true
      end
    end
    hpxml.heat_pumps.each do |heat_pump|
      next unless [HPXML::HVACTypeHeatPumpAirToAir,
                   HPXML::HVACTypeHeatPumpGroundToAir,
                   HPXML::HVACTypeHeatPumpMiniSplit].include? heat_pump.heat_pump_type

      if not heat_pump.distribution_system_idref.nil? # Ducted, these inputs apply
        if heat_pump.fan_watts_per_cfm.nil?
          heat_pump.fan_power_not_tested = true
        end
        if heat_pump.airflow_defect_ratio.nil?
          heat_pump.airflow_not_tested = true
        end
      end
      if heat_pump.charge_defect_ratio.nil?
        if heat_pump.heat_pump_type == HPXML::HVACTypeHeatPumpGroundToAir
          # TODO: GSHP can't be untested, since that ends up grade 3 and is currently unsupported by E+
          heat_pump.charge_defect_ratio = 0.0
        else
          heat_pump.charge_not_tested = true
        end
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
    hpxml.heating_systems.each do |heating_system|
      next unless heating_system.heating_system_type == HPXML::HVACTypeBoiler
      next if heating_system.is_shared_system
      next unless heating_system.electric_auxiliary_energy.nil?

      if heating_system.heating_system_fuel == HPXML::FuelTypeOil
        heating_system.electric_auxiliary_energy = 330.0
      else
        heating_system.electric_auxiliary_energy = 170.0
      end
    end

    # Handle extra inputs for ENERGY STAR

    if hpxml_path.include? 'base-bldgtype-multifamily'
      hpxml.header.energystar_calculation_version = ESConstants.MFNationalVer1_1_2019
    elsif hpxml.header.state_code == 'FL'
      hpxml.header.energystar_calculation_version = ESConstants.SFFloridaVer3_1
    elsif hpxml.header.state_code == 'HI'
      hpxml.header.energystar_calculation_version = ESConstants.SFPacificVer3
    elsif hpxml.header.state_code == 'OR'
      hpxml.header.energystar_calculation_version = ESConstants.SFOregonWashingtonVer3_2
    else
      hpxml.header.energystar_calculation_version = ESConstants.SFNationalVer3_1
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

    XMLHelper.write_file(hpxml.to_oga, hpxml_path)
  end

  # Create additional files
  puts 'Creating additional HPXML files for ERI...'

  # Duct leakage exemption
  hpxml = HPXML.new(hpxml_path: 'workflow/sample_files/base.xml')
  hpxml.hvac_distributions[0].duct_leakage_measurements.clear
  hpxml.hvac_distributions[0].duct_leakage_to_outside_testing_exemption = true
  XMLHelper.write_file(hpxml.to_oga, 'workflow/sample_files/base-hvac-ducts-leakage-to-outside-exemption.xml')

  # ... and invalid test file (pre-Addendum L)
  hpxml = HPXML.new(hpxml_path: 'workflow/sample_files/base-hvac-ducts-leakage-to-outside-exemption.xml')
  hpxml.header.eri_calculation_version = '2014A'
  hpxml.clothes_dryers[0].control_type = HPXML::ClothesDryerControlTypeTimer
  XMLHelper.write_file(hpxml.to_oga, 'workflow/sample_files/invalid_files/hvac-ducts-leakage-to-outside-exemption-pre-addendum-d.xml')

  # Duct leakage total
  hpxml = HPXML.new(hpxml_path: 'workflow/sample_files/base.xml')
  # Add total duct leakage
  hpxml.hvac_distributions[0].duct_leakage_measurements.clear
  hpxml.hvac_distributions[0].duct_leakage_measurements.add(duct_leakage_units: HPXML::UnitsCFM25,
                                                            duct_leakage_value: 150,
                                                            duct_leakage_total_or_to_outside: HPXML::DuctLeakageTotal)
  # Add supply duct in conditioned space
  hpxml.hvac_distributions[0].ducts.add(duct_type: HPXML::DuctTypeSupply,
                                        duct_insulation_r_value: 4,
                                        duct_location: HPXML::LocationLivingSpace,
                                        duct_surface_area: 105)
  # Add return duct in conditioned space
  hpxml.hvac_distributions[0].ducts.add(duct_type: HPXML::DuctTypeReturn,
                                        duct_insulation_r_value: 4,
                                        duct_location: HPXML::LocationLivingSpace,
                                        duct_surface_area: 35)
  XMLHelper.write_file(hpxml.to_oga, 'workflow/sample_files/base-hvac-ducts-leakage-total.xml')

  # ... and invalid test file (pre-Addendum L)
  hpxml = HPXML.new(hpxml_path: 'workflow/sample_files/base-hvac-ducts-leakage-total.xml')
  hpxml.header.eri_calculation_version = '2014ADEG'
  hpxml.clothes_dryers[0].control_type = HPXML::ClothesDryerControlTypeTimer
  XMLHelper.write_file(hpxml.to_oga, 'workflow/sample_files/invalid_files/hvac-ducts-leakage-total-pre-addendum-l.xml')

  # Older versions
  Constants.ERIVersions.each do |eri_version|
    hpxml = HPXML.new(hpxml_path: 'workflow/sample_files/base.xml')
    hpxml.header.eri_calculation_version = eri_version
    hpxml.header.energystar_calculation_version = nil

    if Constants.ERIVersions.index(eri_version) < Constants.ERIVersions.index('2019A')
      # Need old input for clothes dryers
      hpxml.clothes_dryers[0].control_type = HPXML::ClothesDryerControlTypeTimer
    end

    XMLHelper.write_file(hpxml.to_oga, "workflow/sample_files/base-version-#{eri_version}.xml")
  end

  # Invalid ENERGY STAR version test files
  es_files = { ESConstants.SFNationalVer3 => HPXML::ResidentialTypeApartment,
               ESConstants.MFNationalVer1_2019 => HPXML::ResidentialTypeSFD,
               ESConstants.SFFloridaVer3_1 => HPXML::ResidentialTypeSFD,
               ESConstants.SFOregonWashingtonVer3_2 => HPXML::ResidentialTypeSFD,
               ESConstants.SFPacificVer3 => HPXML::ResidentialTypeSFD }
  es_files.each do |es_version, bldg_type|
    hpxml = HPXML.new(hpxml_path: 'workflow/sample_files/base.xml')
    hpxml.header.energystar_calculation_version = es_version
    hpxml.building_construction.residential_facility_type = bldg_type
    hpxml.header.state_code = 'CO'
    XMLHelper.write_file(hpxml.to_oga, "workflow/sample_files/invalid_files/energy-star-#{es_version.gsub(' ', '_').gsub(',', '')}.xml")
  end

  # ENERGY STAR Oregon/Washington MF file
  hpxml = HPXML.new(hpxml_path: 'workflow/sample_files/base-bldgtype-multifamily.xml')
  hpxml.header.energystar_calculation_version = ESConstants.MFOregonWashingtonVer1_2_2019
  hpxml.climate_and_risk_zones.iecc_zone = '4C'
  hpxml.climate_and_risk_zones.weather_station_name = 'Portland, OR'
  hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_OR_Portland.Intl.AP.726980_TMY3.epw'
  hpxml.header.state_code = 'OR'
  XMLHelper.write_file(hpxml.to_oga, 'workflow/sample_files/base-bldgtype-multifamily-location-portland-or.xml')
end

command_list = [:generate_sample_outputs, :update_measures, :create_release_zips]

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

if ARGV[0].to_sym == :generate_sample_outputs
  Dir.chdir('workflow')

  # Update ERI sample files
  FileUtils.rm_rf('sample_results_eri/.', secure: true)
  sleep 1
  FileUtils.mkdir_p('sample_results_eri')

  cli_path = OpenStudio.getOpenStudioCLI
  command = "\"#{cli_path}\" energy_rating_index.rb -x sample_files/base.xml --hourly ALL"
  system(command)

  dirs = ['ERIRatedHome',
          'ERIReferenceHome',
          'ERIIndexAdjustmentDesign',
          'ERIIndexAdjustmentReferenceHome',
          'results']
  dirs.each do |dir|
    FileUtils.copy_entry dir, "sample_results_eri/#{dir}"
  end

  # Update ENERGY STAR sample files
  FileUtils.rm_rf('sample_results_energystar/.', secure: true)
  sleep 1
  FileUtils.mkdir_p('sample_results_energystar')

  cli_path = OpenStudio.getOpenStudioCLI
  command = "\"#{cli_path}\" energy_star.rb -x sample_files/base.xml --hourly ALL"
  system(command)

  dirs = ['ESRated',
          'ESReference',
          'results']
  dirs.each do |dir|
    FileUtils.copy_entry dir, "sample_results_energystar/#{dir}"
  end
end

if ARGV[0].to_sym == :update_measures
  require 'oga'
  require_relative 'hpxml-measures/HPXMLtoOpenStudio/resources/constants'
  require_relative 'hpxml-measures/HPXMLtoOpenStudio/resources/hotwater_appliances'
  require_relative 'hpxml-measures/HPXMLtoOpenStudio/resources/hpxml'
  require_relative 'hpxml-measures/HPXMLtoOpenStudio/resources/lighting'
  require_relative 'hpxml-measures/HPXMLtoOpenStudio/resources/xmlhelper'
  require_relative 'rulesets/EnergyStarRuleset/resources/constants'

  # Prevent NREL error regarding U: drive when not VPNed in
  ENV['HOME'] = 'C:' if !ENV['HOME'].nil? && ENV['HOME'].start_with?('U:')
  ENV['HOMEDRIVE'] = 'C:\\' if !ENV['HOMEDRIVE'].nil? && ENV['HOMEDRIVE'].start_with?('U:')

  create_test_hpxmls
  create_sample_hpxmls

  # Apply rubocop
  cops = ['Layout',
          'Lint/DeprecatedClassMethods',
          # 'Lint/RedundantStringCoercion', # Enable when rubocop is upgraded
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

  # Update measures XMLs
  command = "#{OpenStudio.getOpenStudioCLI} measure -t '#{File.join(File.dirname(__FILE__), 'rulesets')}'"
  puts 'Updating measure.xmls...'
  system(command, [:out, :err] => File::NULL)

  puts 'Done.'
end

if ARGV[0].to_sym == :create_release_zips
  require_relative 'hpxml-measures/HPXMLtoOpenStudio/resources/version'

  release_map = { File.join(File.dirname(__FILE__), "OpenStudio-ERI-v#{Version::OS_HPXML_Version}-minimal.zip") => false,
                  File.join(File.dirname(__FILE__), "OpenStudio-ERI-v#{Version::OS_HPXML_Version}-full.zip") => true }

  release_map.keys.each do |zip_path|
    File.delete(zip_path) if File.exist? zip_path
  end

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
  files = ['hpxml-measures/HPXMLtoOpenStudio/measure.*',
           'hpxml-measures/HPXMLtoOpenStudio/resources/*.*',
           'hpxml-measures/SimulationOutputReport/measure.*',
           'hpxml-measures/SimulationOutputReport/resources/*.*',
           'rulesets/301EnergyRatingIndexRuleset/measure.*',
           'rulesets/301EnergyRatingIndexRuleset/resources/*.*',
           'rulesets/EnergyStarRuleset/measure.*',
           'rulesets/EnergyStarRuleset/resources/*.*',
           'weather/*.*',
           'workflow/*.*',
           'workflow/sample_files/*.*',
           'workflow/tests/*.rb',
           'workflow/tests/base_results/*_4.*.csv',
           'workflow/tests/RESNET_Tests/4.*/*.xml',
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
    FileUtils.rm_r(File.join(File.dirname(__FILE__), 'documentation', '_static', 'fonts'))

    # Check if we need to download weather files for the full release zip
    num_epws_expected = 1011
    num_epws_local = 0
    files.each do |f|
      Dir[f].each do |file|
        next unless file.end_with? '.epw'

        num_epws_local += 1
      end
    end

    # Make sure we have the full set of weather files
    if num_epws_local < num_epws_expected
      puts 'Fetching all weather files...'
      command = "#{OpenStudio.getOpenStudioCLI} workflow/energy_rating_index.rb --download-weather"
      log = `#{command}`
    end
  end

  # Create zip files
  release_map.each do |zip_path, include_all_epws|
    puts "Creating #{zip_path}..."
    zip = OpenStudio::ZipFile.new(zip_path, false)
    files.each do |f|
      Dir[f].each do |file|
        if file.start_with? 'documentation'
          # always include
        elsif include_all_epws
          if (not git_files.include? file) && (not file.start_with? 'weather')
            next
          end
        else
          if not git_files.include? file
            next
          end
        end

        zip.addFile(file, File.join('OpenStudio-ERI', file))
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
