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
    'RESNET_Tests/Other_Hot_Water_301_2014_PreAddendumA/L100AM-HW-03.xml' => 'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AM-HW-03.xml'
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
        set_hpxml_air_infiltration_measurements(hpxml_file, hpxml)
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
  end
end

def set_hpxml_site(hpxml_file, hpxml)
  return unless hpxml_file.include?('HERS_AutoGen') || hpxml_file.include?('HERS_Method') || hpxml_file.include?('Hot_Water')

  hpxml.site.fuels = [HPXML::FuelTypeElectricity, HPXML::FuelTypeNaturalGas]
end

def set_hpxml_building_construction(hpxml_file, hpxml)
  hpxml.building_construction.use_only_ideal_air_system = nil
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
  elsif ['RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/02-L100.xml'].include? hpxml_file
    # Dallas
    hpxml.climate_and_risk_zones.iecc_zone = '3A'
    hpxml.climate_and_risk_zones.weather_station_id = 'WeatherStation'
    hpxml.climate_and_risk_zones.weather_station_name = 'Dallas, TX'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_TX_Dallas-Fort.Worth.Intl.AP.722590_TMY3.epw'
  elsif ['RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/03-L304.xml',
         'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AM-HW-01.xml'].include? hpxml_file
    # Miami
    hpxml.climate_and_risk_zones.iecc_zone = '1A'
    hpxml.climate_and_risk_zones.weather_station_id = 'WeatherStation'
    hpxml.climate_and_risk_zones.weather_station_name = 'Miami, FL'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_FL_Miami.Intl.AP.722020_TMY3.epw'
  elsif ['RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AD-HW-01.xml'].include? hpxml_file
    # Duluth
    hpxml.climate_and_risk_zones.iecc_zone = '7'
    hpxml.climate_and_risk_zones.weather_station_id = 'WeatherStation'
    hpxml.climate_and_risk_zones.weather_station_name = 'Duluth, MN'
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'USA_MN_Duluth.Intl.AP.727450_TMY3.epw'
  elsif hpxml_file.include?('HERS_AutoGen') || hpxml_file.include?('HERS_Method') || hpxml_file.include?('Hot_Water')
    if hpxml.climate_and_risk_zones.weather_station_epw_filepath == 'USA_CO_Colorado.Springs-Peterson.Field.724660_TMY3.epw'
      hpxml.climate_and_risk_zones.iecc_zone = '5B'
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
  end
end

def set_hpxml_attics(hpxml_file, hpxml)
  return unless hpxml_file.include?('HERS_AutoGen') || hpxml_file.include?('HERS_Method') || hpxml_file.include?('Hot_Water')

  hpxml.attics.clear
  hpxml.attics.add(id: 'VentedAttic',
                   attic_type: HPXML::AtticTypeVented,
                   vented_attic_sla: (1.0 / 300.0).round(5))
end

def set_hpxml_foundations(hpxml_file, hpxml)
  if ['RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/02-L100.xml'].include? hpxml_file
    hpxml.foundations.clear
    hpxml.foundations.add(id: 'UnventedCrawlspace',
                          foundation_type: HPXML::FoundationTypeCrawlspaceUnvented,
                          within_infiltration_volume: false)
  end
end

def set_hpxml_roofs(hpxml_file, hpxml)
end

def set_hpxml_rim_joists(hpxml_file, hpxml)
  if ['RESNET_Tests/4.5_DSE/HVAC3a.xml'].include? hpxml_file
    for i in 0..hpxml.rim_joists.size - 1
      hpxml.rim_joists[i].interior_adjacent_to = HPXML::LocationBasementUnconditioned
    end
  end
end

def set_hpxml_walls(hpxml_file, hpxml)
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
  end
end

def set_hpxml_windows(hpxml_file, hpxml)
  if hpxml_file.include?('HERS_AutoGen') || hpxml_file.include?('HERS_Method') || hpxml_file.include?('Hot_Water')
    hpxml.windows.each do |window|
      window.interior_shading_factor_summer = nil
      window.interior_shading_factor_winter = nil
    end
  end
end

def set_hpxml_skylights(hpxml_file, hpxml)
end

def set_hpxml_doors(hpxml_file, hpxml)
end

def set_hpxml_heating_systems(hpxml_file, hpxml)
  if ['RESNET_Tests/4.4_HVAC/HVAC2c.xml',
      'RESNET_Tests/4.4_HVAC/HVAC2d.xml'].include? hpxml_file
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
                              fraction_heat_load_served: 1)
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
                              fraction_heat_load_served: 1)
  elsif ['RESNET_Tests/4.3_HERS_Method/L100A-03.xml'].include? hpxml_file
    # Natural gas furnace with AFUE = 78%
    hpxml.heating_systems.clear
    hpxml.heating_systems.add(id: 'HeatingSystem',
                              distribution_system_idref: 'HVACDistribution',
                              heating_system_type: HPXML::HVACTypeFurnace,
                              heating_system_fuel: HPXML::FuelTypeNaturalGas,
                              heating_capacity: -1,
                              heating_efficiency_afue: 0.78,
                              fraction_heat_load_served: 1)
  elsif ['RESNET_Tests/4.3_HERS_Method/L100A-05.xml'].include? hpxml_file
    # Natural gas furnace with AFUE = 96%
    hpxml.heating_systems.clear
    hpxml.heating_systems.add(id: 'HeatingSystem',
                              distribution_system_idref: 'HVACDistribution',
                              heating_system_type: HPXML::HVACTypeFurnace,
                              heating_system_fuel: HPXML::FuelTypeNaturalGas,
                              heating_capacity: -1,
                              heating_efficiency_afue: 0.96,
                              fraction_heat_load_served: 1)
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
                              fraction_heat_load_served: 1)
  elsif ['RESNET_Tests/4.4_HVAC/HVAC2b.xml'].include? hpxml_file
    # Gas Furnace; 56.1 kBtu/h; AFUE = 90%; 0.000375 kW/cfm
    hpxml.heating_systems.clear
    hpxml.heating_systems.add(id: 'HeatingSystem',
                              distribution_system_idref: 'HVACDistribution',
                              heating_system_type: HPXML::HVACTypeFurnace,
                              heating_system_fuel: HPXML::FuelTypeNaturalGas,
                              heating_capacity: 56100,
                              heating_efficiency_afue: 0.9,
                              fraction_heat_load_served: 1)
  elsif ['RESNET_Tests/4.4_HVAC/HVAC2e.xml'].include? hpxml_file
    # Electric Furnace; 56.1 kBtu/h; COP =1.0
    hpxml.heating_systems.clear
    hpxml.heating_systems.add(id: 'HeatingSystem',
                              distribution_system_idref: 'HVACDistribution',
                              heating_system_type: HPXML::HVACTypeFurnace,
                              heating_system_fuel: HPXML::FuelTypeElectricity,
                              heating_capacity: 56100,
                              heating_efficiency_afue: 1,
                              fraction_heat_load_served: 1)
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
                              fraction_heat_load_served: 1)

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
                              fraction_heat_load_served: 1)
  end
end

def set_hpxml_cooling_systems(hpxml_file, hpxml)
  if ['RESNET_Tests/4.4_HVAC/HVAC2c.xml',
      'RESNET_Tests/4.4_HVAC/HVAC2d.xml'].include? hpxml_file
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
                              cooling_efficiency_seer: 11)
  elsif ['RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/03-L304.xml'].include? hpxml_file
    # Central air conditioner with SEER = 15.0
    hpxml.cooling_systems.clear
    hpxml.cooling_systems.add(id: 'CoolingSystem',
                              distribution_system_idref: 'HVACDistribution',
                              cooling_system_type: HPXML::HVACTypeCentralAirConditioner,
                              cooling_system_fuel: HPXML::FuelTypeElectricity,
                              cooling_capacity: -1,
                              fraction_cool_load_served: 1,
                              cooling_efficiency_seer: 15)
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
                              cooling_efficiency_seer: 10)
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
                              cooling_efficiency_seer: 10)
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
                              cooling_efficiency_seer: 10)

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
                              cooling_efficiency_seer: 13)
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
                         cooling_efficiency_seer: 12)
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
                         cooling_efficiency_seer: 10)
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
                         cooling_efficiency_seer: 10)
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
                         cooling_efficiency_seer: 13)
  end
end

def set_hpxml_hvac_controls(hpxml_file, hpxml)
  if hpxml_file.include?('HERS_AutoGen') || hpxml_file.include?('HERS_Method') || hpxml_file.include?('Hot_Water')
    hpxml.hvac_controls.clear
    if hpxml.heating_systems.size + hpxml.cooling_systems.size + hpxml.heat_pumps.size > 0
      hpxml.hvac_controls.add(id: 'HVACControl',
                              control_type: HPXML::HVACControlTypeManual,
                              heating_setpoint_temp: 68,
                              cooling_setpoint_temp: 78)
    end
  end
end

def set_hpxml_hvac_distributions(hpxml_file, hpxml)
  if ['RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/01-L100.xml',
      'RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/02-L100.xml',
      'RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/03-L304.xml',
      'RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/04-L324.xml',
      'RESNET_Tests/4.3_HERS_Method/L100A-01.xml',
      'RESNET_Tests/4.5_DSE/HVAC3a.xml',
      'RESNET_Tests/4.5_DSE/HVAC3e.xml'].include? hpxml_file
    hpxml.hvac_distributions.clear
    hpxml.hvac_distributions.add(id: 'HVACDistribution',
                                 distribution_system_type: HPXML::HVACDistributionTypeAir)
  elsif ['RESNET_Tests/4.4_HVAC/HVAC1a.xml',
         'RESNET_Tests/4.4_HVAC/HVAC2a.xml'].include? hpxml_file
    hpxml.hvac_distributions.clear
    hpxml.hvac_distributions.add(id: 'HVACDistribution',
                                 distribution_system_type: HPXML::HVACDistributionTypeDSE,
                                 annual_heating_dse: 1,
                                 annual_cooling_dse: 1)
  elsif hpxml_file.include? 'Hot_Water'
    hpxml.hvac_distributions.clear
    hpxml.hvac_distributions.add(id: 'HVACDistribution',
                                 distribution_system_type: HPXML::HVACDistributionTypeAir)
  end
  if ['RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/01-L100.xml',
      'RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/02-L100.xml',
      'RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/03-L304.xml',
      'RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/04-L324.xml',
      'RESNET_Tests/4.3_HERS_Method/L100A-01.xml',
      'RESNET_Tests/4.5_DSE/HVAC3a.xml',
      'RESNET_Tests/4.5_DSE/HVAC3e.xml'].include?(hpxml_file) ||
     hpxml_file.include?('Hot_Water')
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
  end
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
  end
  if hpxml.hvac_distributions.size == 1
    hpxml.hvac_distributions[0].conditioned_floor_area_served = hpxml.building_construction.conditioned_floor_area
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
    # 40 gal electric with EF = 0.88
    hpxml.water_heating_systems.clear
    hpxml.water_heating_systems.add(id: 'WaterHeater',
                                    is_shared_system: false,
                                    fuel_type: HPXML::FuelTypeElectricity,
                                    water_heater_type: HPXML::WaterHeaterTypeStorage,
                                    location: HPXML::LocationLivingSpace,
                                    tank_volume: 40,
                                    fraction_dhw_load_served: 1,
                                    energy_factor: 0.92)
  end
end

def set_hpxml_hot_water_distribution(hpxml_file, hpxml)
  if ['RESNET_Tests/4.3_HERS_Method/L100A-01.xml',
      'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AD-HW-01.xml',
      'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AM-HW-01.xml'].include? hpxml_file
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
    if (hpxml.hot_water_distributions[0].system_type == HPXML::DHWDistTypeStandard) && hpxml.hot_water_distributions[0].standard_piping_length.nil?
      hpxml.hot_water_distributions[0].standard_piping_length = piping_length.round(2)
    elsif (hpxml.hot_water_distributions[0].system_type == HPXML::DHWDistTypeRecirc) && hpxml.hot_water_distributions[0].recirculation_piping_length.nil?
      hpxml.hot_water_distributions[0].recirculation_piping_length = HotWaterAndAppliances.get_default_recirc_loop_length(piping_length).round(2)
    end
  end
end

def set_hpxml_water_fixtures(hpxml_file, hpxml)
  if ['RESNET_Tests/4.3_HERS_Method/L100A-01.xml',
      'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AD-HW-01.xml',
      'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AM-HW-01.xml'].include? hpxml_file
    # Standard
    hpxml.water_fixtures.clear
    hpxml.water_fixtures.add(id: 'WaterFixture',
                             water_fixture_type: HPXML::WaterFixtureTypeShowerhead,
                             low_flow: false)
    hpxml.water_fixtures.add(id: 'WaterFixture2',
                             water_fixture_type: HPXML::WaterFixtureTypeFaucet,
                             low_flow: false)
  elsif ['RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AD-HW-04.xml',
         'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AM-HW-04.xml'].include? hpxml_file
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
  return unless hpxml_file.include?('HERS_AutoGen') || hpxml_file.include?('HERS_Method') || hpxml_file.include?('Hot_Water')

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
  return unless hpxml_file.include?('HERS_AutoGen') || hpxml_file.include?('HERS_Method') || hpxml_file.include?('Hot_Water')

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
      'RESNET_Tests/Other_HERS_Method_301_2019_PreAddendumA/L100A-05.xml'].include?(hpxml_file)
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
         'RESNET_Tests/Other_HERS_Method_301_2019_PreAddendumA/L100A-01.xml',
         'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AD-HW-01.xml',
         'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AM-HW-01.xml'].include? hpxml_file
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
  return unless hpxml_file.include?('HERS_AutoGen') || hpxml_file.include?('HERS_Method') || hpxml_file.include?('Hot_Water')

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

def set_hpxml_refrigerator(hpxml_file, hpxml)
  return unless hpxml_file.include?('HERS_AutoGen') || hpxml_file.include?('HERS_Method') || hpxml_file.include?('Hot_Water')

  # Standard
  default_values = HotWaterAndAppliances.get_refrigerator_default_values(hpxml.building_construction.number_of_bedrooms)
  hpxml.refrigerators.clear
  hpxml.refrigerators.add(id: 'Refrigerator',
                          location: HPXML::LocationLivingSpace,
                          rated_annual_kwh: default_values[:rated_annual_kwh])
end

def set_hpxml_cooking_range(hpxml_file, hpxml)
  return unless hpxml_file.include?('HERS_AutoGen') || hpxml_file.include?('HERS_Method') || hpxml_file.include?('Hot_Water')

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
      'RESNET_Tests/Other_HERS_Method_301_2019_PreAddendumA/L100A-05.xml'].include?(hpxml_file)
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
         'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AM-HW-01.xml'].include? hpxml_file
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
  return unless hpxml_file.include?('HERS_AutoGen') || hpxml_file.include?('HERS_Method') || hpxml_file.include?('Hot_Water')

  default_values = HotWaterAndAppliances.get_range_oven_default_values()
  hpxml.ovens.clear
  hpxml.ovens.add(id: 'Oven',
                  is_convection: default_values[:is_convection])
end

def set_hpxml_lighting(hpxml_file, hpxml)
  return unless hpxml_file.include?('HERS_AutoGen') || hpxml_file.include?('HERS_Method') || hpxml_file.include?('Hot_Water')

  hpxml.lighting_groups.clear
  ltg_fracs = Lighting.get_default_fractions()
  ltg_fracs.each_with_index do |(key, fraction), i|
    location, lighting_type = key
    hpxml.lighting_groups.add(id: "LightingGroup#{i + 1}",
                              location: location,
                              fraction_of_units_in_location: fraction,
                              lighting_type: lighting_type)
  end
end

def set_hpxml_plug_loads(hpxml_file, hpxml)
  return unless hpxml_file.include?('HERS_AutoGen') || hpxml_file.include?('HERS_Method') || hpxml_file.include?('Hot_Water')

  hpxml.plug_loads.clear
end

def get_eri_version(hpxml)
  eri_version = hpxml.header.eri_calculation_version
  eri_version = Constants.ERIVersions[-1] if eri_version == 'latest'
  return eri_version
end

def create_sample_hpxmls
  # Copy sample files from hpxml-measures subtree
  puts 'Copying sample files...'
  FileUtils.rm_f(Dir.glob('workflow/sample_files/*.xml'))
  FileUtils.rm_f(Dir.glob('workflow/sample_files/invalid_files/*.xml'))
  FileUtils.cp(Dir.glob('hpxml-measures/workflow/sample_files/*.xml'), 'workflow/sample_files')
  FileUtils.cp(Dir.glob('hpxml-measures/workflow/sample_files/invalid_files/*.xml'), 'workflow/sample_files/invalid_files')
  FileUtils.rm_f(Dir.glob('workflow/sample_files/base-hvac-autosize*.xml'))

  # Remove files we're not interested in
  exclude_list = ['invalid_files/cfis-with-hydronic-distribution.xml',
                  'invalid_files/clothes-washer-location.xml',
                  'invalid_files/clothes-dryer-location.xml',
                  'invalid_files/cooking-range-location.xml',
                  'invalid_files/dhw-invalid-ef-tank.xml',
                  'invalid_files/dhw-invalid-uef-tank-heat-pump.xml',
                  'invalid_files/dishwasher-location.xml',
                  'invalid_files/duct-location.xml',
                  'invalid_files/duct-location-unconditioned-space.xml',
                  'invalid_files/duplicate-id.xml',
                  'invalid_files/enclosure-attic-missing-roof.xml',
                  'invalid_files/enclosure-basement-missing-exterior-foundation-wall.xml',
                  'invalid_files/enclosure-basement-missing-slab.xml',
                  'invalid_files/enclosure-garage-missing-exterior-wall.xml',
                  'invalid_files/enclosure-garage-missing-roof-ceiling.xml',
                  'invalid_files/enclosure-garage-missing-slab.xml',
                  'invalid_files/enclosure-living-missing-ceiling-roof.xml',
                  'invalid_files/enclosure-living-missing-exterior-wall.xml',
                  'invalid_files/enclosure-living-missing-floor-slab.xml',
                  'invalid_files/heat-pump-mixed-fixed-and-autosize-capacities.xml',
                  'invalid_files/heat-pump-mixed-fixed-and-autosize-capacities2.xml',
                  'invalid_files/hvac-distribution-multiple-attached-cooling.xml',
                  'invalid_files/hvac-distribution-multiple-attached-heating.xml',
                  'invalid_files/hvac-distribution-return-duct-leakage-missing.xml',
                  'invalid_files/hvac-dse-multiple-attached-cooling.xml',
                  'invalid_files/hvac-dse-multiple-attached-heating.xml',
                  'invalid_files/hvac-inconsistent-fan-powers.xml',
                  'invalid_files/hvac-invalid-distribution-system-type.xml',
                  'invalid_files/invalid-assembly-effective-rvalue.xml',
                  'invalid_files/invalid-datatype-boolean.xml',
                  'invalid_files/invalid-datatype-float.xml',
                  'invalid_files/invalid-datatype-integer.xml',
                  'invalid_files/invalid-daylight-saving.xml',
                  'invalid_files/invalid-distribution-cfa-served.xml',
                  'invalid_files/invalid-facility-type-equipment.xml',
                  'invalid_files/invalid-facility-type-surfaces.xml',
                  'invalid_files/invalid-foundation-wall-properties.xml',
                  'invalid_files/invalid-id.xml',
                  'invalid_files/invalid-infiltration-volume.xml',
                  'invalid_files/invalid-input-parameters.xml',
                  'invalid_files/invalid-neighbor-shading-azimuth.xml',
                  'invalid_files/invalid-number-of-bedrooms-served.xml',
                  'invalid_files/invalid-number-of-conditioned-floors.xml',
                  'invalid_files/invalid-number-of-units-served.xml',
                  'invalid_files/invalid-relatedhvac-desuperheater.xml',
                  'invalid_files/invalid-relatedhvac-dhw-indirect.xml',
                  'invalid_files/invalid-schema-version.xml',
                  'invalid_files/invalid-shared-vent-in-unit-flowrate.xml',
                  'invalid_files/invalid-timestep.xml',
                  'invalid_files/invalid-window-height.xml',
                  'invalid_files/lighting-fractions.xml',
                  'invalid_files/missing-duct-location.xml',
                  'invalid_files/multifamily-reference-appliance.xml',
                  'invalid_files/multifamily-reference-duct.xml',
                  'invalid_files/multifamily-reference-surface.xml',
                  'invalid_files/multifamily-reference-water-heater.xml',
                  'invalid_files/net-area-negative-roof.xml',
                  'invalid_files/net-area-negative-wall.xml',
                  'invalid_files/orphaned-hvac-distribution.xml',
                  'invalid_files/slab-zero-exposed-perimeter.xml',
                  'invalid_files/solar-thermal-system-with-combi-tankless.xml',
                  'invalid_files/solar-thermal-system-with-desuperheater.xml',
                  'invalid_files/solar-thermal-system-with-dhw-indirect.xml',
                  'invalid_files/refrigerator-location.xml',
                  'invalid_files/refrigerators-multiple-primary.xml',
                  'invalid_files/refrigerators-no-primary.xml',
                  'invalid_files/repeated-relatedhvac-desuperheater.xml',
                  'invalid_files/repeated-relatedhvac-dhw-indirect.xml',
                  'invalid_files/invalid-runperiod.xml',
                  'invalid_files/unattached-cfis.xml',
                  'invalid_files/unattached-door.xml',
                  'invalid_files/unattached-hvac-distribution.xml',
                  'invalid_files/unattached-skylight.xml',
                  'invalid_files/unattached-solar-thermal-system.xml',
                  'invalid_files/unattached-shared-clothes-washer-water-heater.xml',
                  'invalid_files/unattached-shared-dishwasher-water-heater.xml',
                  'invalid_files/unattached-window.xml',
                  'invalid_files/water-heater-location.xml',
                  'invalid_files/water-heater-location-other.xml',
                  'base-appliances-coal.xml',
                  'base-dhw-combi-tankless-outside.xml',
                  'base-dhw-desuperheater-var-speed.xml',
                  'base-dhw-desuperheater-2-speed.xml',
                  'base-dhw-desuperheater-gshp.xml',
                  'base-dhw-desuperheater-tankless.xml',
                  'base-dhw-indirect-outside.xml',
                  'base-dhw-indirect-with-solar-fraction.xml',
                  'base-dhw-jacket-electric.xml',
                  'base-dhw-tank-coal.xml',
                  'base-dhw-tank-gas-outside.xml',
                  'base-dhw-tank-heat-pump-outside.xml',
                  'base-dhw-tank-heat-pump-with-solar.xml',
                  'base-dhw-tank-heat-pump-with-solar-fraction.xml',
                  'base-dhw-tankless-electric-outside.xml',
                  'base-dhw-tankless-gas-with-solar.xml',
                  'base-dhw-tankless-gas-with-solar-fraction.xml',
                  'base-enclosure-infil-ach-house-pressure.xml',
                  'base-enclosure-infil-cfm-house-pressure.xml',
                  'base-enclosure-infil-flue.xml',
                  'base-enclosure-rooftypes.xml',
                  'base-enclosure-split-surfaces2.xml',
                  'base-enclosure-walltypes.xml',
                  'base-enclosure-windows-interior-shading.xml',
                  'base-enclosure-windows-none.xml',
                  'base-foundation-complex.xml',
                  'base-hvac-boiler-coal-only.xml',
                  'base-hvac-central-ac-plus-air-to-air-heat-pump-heating.xml',
                  'base-hvac-dual-fuel-air-to-air-heat-pump-2-speed.xml',
                  'base-hvac-dual-fuel-air-to-air-heat-pump-var-speed.xml',
                  'base-hvac-dual-fuel-mini-split-heat-pump-ducted.xml',
                  'base-hvac-ducts-leakage-percent.xml',
                  'base-hvac-furnace-coal-only.xml',
                  'base-hvac-furnace-x3-dse.xml',
                  'base-hvac-ideal-air.xml',
                  'base-hvac-programmable-thermostat-detailed.xml',
                  'base-hvac-undersized-allow-increased-fixed-capacities.xml',
                  'base-lighting-detailed.xml',
                  'base-lighting-none.xml',
                  'base-location-AMY-2012.xml',
                  'base-mechvent-bath-kitchen-fans.xml',
                  'base-mechvent-cfis-dse.xml',
                  'base-mechvent-cfis-evap-cooler-only-ducted.xml',
                  'base-mechvent-exhaust-rated-flow-rate.xml',
                  'base-misc-defaults.xml',
                  'base-misc-loads-large-uncommon.xml',
                  'base-misc-loads-large-uncommon2.xml',
                  'base-misc-loads-none.xml',
                  'base-misc-neighbor-shading.xml',
                  'base-misc-shelter-coefficient.xml',
                  'base-misc-usage-multiplier.xml',
                  'base-simcontrol-calendar-year-custom.xml',
                  'base-simcontrol-daylight-saving-custom.xml',
                  'base-simcontrol-daylight-saving-disabled.xml',
                  'base-simcontrol-runperiod-1-month.xml',
                  'base-simcontrol-timestep-10-mins.xml']
  exclude_list.each do |exclude_file|
    if File.exist? "workflow/sample_files/#{exclude_file}"
      FileUtils.rm_f("workflow/sample_files/#{exclude_file}")
    else
      puts "Warning: Excluded file workflow/sample_files/#{exclude_file} not found."
    end
  end

  # Update HPXMLs as needed
  puts 'Updating HPXML inputs for ERI...'
  hpxml_paths = []
  Dir['workflow/sample_files/*.xml'].each do |hpxml_path|
    hpxml_paths << hpxml_path
  end
  Dir['workflow/sample_files/invalid_files/*.xml'].each do |hpxml_path|
    hpxml_paths << hpxml_path
  end
  hpxml_paths.each do |hpxml_path|
    hpxml = HPXML.new(hpxml_path: hpxml_path)

    # Add ERI version
    hpxml.header.eri_calculation_version = 'latest'

    hpxml.building_construction.number_of_bathrooms = nil

    # Handle extra inputs for ERI
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
    hpxml.pv_systems.each do |pv_system|
      next unless pv_system.is_shared_system.nil?

      pv_system.is_shared_system = false
    end
    hpxml.generators.each do |generator|
      next unless generator.is_shared_system.nil?

      generator.is_shared_system = false
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
  XMLHelper.write_file(hpxml.to_oga, 'workflow/sample_files/invalid_files/hvac-ducts-leakage-total-pre-addendum-l.xml')

  # Older versions
  Constants.ERIVersions.each do |eri_version|
    hpxml = HPXML.new(hpxml_path: 'workflow/sample_files/base.xml')
    hpxml.header.eri_calculation_version = eri_version

    if Constants.ERIVersions.index(eri_version) < Constants.ERIVersions.index('2019A')
      # Arbitrary appliance inputs new as of 301-2019 Addendum A
      hpxml.clothes_washers[0].label_usage = 999
      hpxml.dishwashers[0].label_electric_rate = 999
      hpxml.dishwashers[0].label_gas_rate = 999
      hpxml.dishwashers[0].label_annual_gas_cost = 999
      hpxml.dishwashers[0].label_usage = 999
    end

    XMLHelper.write_file(hpxml.to_oga, "workflow/sample_files/base-version-#{eri_version}.xml")
  end
end

command_list = [:generate_sample_outputs, :update_version, :update_measures, :create_release_zips]

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

  FileUtils.rm_rf('sample_results/.', secure: true)
  sleep 1
  FileUtils.mkdir_p('sample_results')

  cli_path = OpenStudio.getOpenStudioCLI
  command = "\"#{cli_path}\" energy_rating_index.rb -x sample_files/base.xml --hourly ALL"
  system(command)

  dirs = ['ERIRatedHome',
          'ERIReferenceHome',
          'ERIIndexAdjustmentDesign',
          'ERIIndexAdjustmentReferenceHome',
          'results']
  dirs.each do |dir|
    FileUtils.copy_entry dir, "sample_results/#{dir}"
  end
end

if ARGV[0].to_sym == :update_version
  eri_version_change = { from: '0.10.0',
                         to: '0.11.0' }

  file_names = ['workflow/energy_rating_index.rb', 'docs/source/getting_started.rst']

  file_names.each do |file_name|
    text = File.read(file_name)
    new_contents = text.gsub(eri_version_change[:from], eri_version_change[:to])

    # To write changes to the file, use:
    File.open(file_name, 'w') { |file| file.puts new_contents }
    puts "Updated from version #{eri_version_change[:from]} to version #{eri_version_change[:to]} in #{file_name}."
  end

  puts 'Done. Now check all changed files before committing.'
end

if ARGV[0].to_sym == :update_measures
  require 'oga'
  require_relative 'hpxml-measures/HPXMLtoOpenStudio/resources/constants'
  require_relative 'hpxml-measures/HPXMLtoOpenStudio/resources/hotwater_appliances'
  require_relative 'hpxml-measures/HPXMLtoOpenStudio/resources/hpxml'
  require_relative 'hpxml-measures/HPXMLtoOpenStudio/resources/lighting'
  require_relative 'hpxml-measures/HPXMLtoOpenStudio/resources/xmlhelper'

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
           'weather/*.*',
           'workflow/*.*',
           'workflow/sample_files/*.*',
           'workflow/tests/*.rb',
           'workflow/tests/RESNET_Tests/4.*/*.xml',
           'documentation/index.html',
           'documentation/_static/**/*.*']

  if not ENV['CI']
    # Run RESNET tests
    puts 'Running RESNET tests (this will take a few minutes)...'
    results_dir = File.join('workflow', 'tests', 'test_results')
    tests = { 'test_resnet_ashrae_140' => File.join(results_dir, 'RESNET_Test_4.1_Standard_140.csv'),
              'test_resnet_hers_reference_home_auto_generation' => File.join(results_dir, 'RESNET_Test_4.2_HERS_AutoGen_Reference_Home.csv'),
              'test_resnet_hers_method' => File.join(results_dir, 'RESNET_Test_4.3_HERS_Method.csv'),
              'test_resnet_hvac' => File.join(results_dir, 'RESNET_Test_4.4_HVAC.csv'),
              'test_resnet_dse' => File.join(results_dir, 'RESNET_Test_4.5_DSE.csv'),
              'test_resnet_hot_water' => File.join(results_dir, 'RESNET_Test_4.6_Hot_Water.csv') }
    tests.each do |test_name, results_csv|
      command = "\"#{OpenStudio.getOpenStudioCLI}\" workflow/tests/energy_rating_index_test.rb --name=#{test_name} > log.txt"
      system(command)
      if not File.exist? results_csv
        puts "#{results_csv} not generated. Aborting..."
        exit!
      end
      File.delete('log.txt')
    end

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
    if not ENV['CI']
      tests.values.each do |results_csv|
        zip.addFile(results_csv, File.join('OpenStudio-ERI', results_csv))
      end
    end
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
