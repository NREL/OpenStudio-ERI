def create_test_hpxmls
  require_relative 'hpxml-measures/HPXMLtoOpenStudio/resources/hpxml'
  require_relative 'hpxml-measures/HPXMLtoOpenStudio/resources/hotwater_appliances'
  require_relative 'hpxml-measures/HPXMLtoOpenStudio/resources/lighting'

  this_dir = File.dirname(__FILE__)
  tests_dir = File.join(this_dir, 'workflow/tests')

  # Hash of HPXML -> Parent HPXML
  hpxmls_files = {
    'RESNET_Tests/4.1_Standard_140/L100AC.xml' => nil,
    'RESNET_Tests/4.1_Standard_140/L100AL.xml' => nil,
    'RESNET_Tests/4.1_Standard_140/L110AC.xml' => 'RESNET_Tests/4.1_Standard_140/L100AC.xml',
    'RESNET_Tests/4.1_Standard_140/L110AL.xml' => 'RESNET_Tests/4.1_Standard_140/L100AL.xml',
    'RESNET_Tests/4.1_Standard_140/L120AC.xml' => 'RESNET_Tests/4.1_Standard_140/L100AC.xml',
    'RESNET_Tests/4.1_Standard_140/L120AL.xml' => 'RESNET_Tests/4.1_Standard_140/L100AL.xml',
    'RESNET_Tests/4.1_Standard_140/L130AC.xml' => 'RESNET_Tests/4.1_Standard_140/L100AC.xml',
    'RESNET_Tests/4.1_Standard_140/L130AL.xml' => 'RESNET_Tests/4.1_Standard_140/L100AL.xml',
    'RESNET_Tests/4.1_Standard_140/L140AC.xml' => 'RESNET_Tests/4.1_Standard_140/L100AC.xml',
    'RESNET_Tests/4.1_Standard_140/L140AL.xml' => 'RESNET_Tests/4.1_Standard_140/L100AL.xml',
    'RESNET_Tests/4.1_Standard_140/L150AC.xml' => 'RESNET_Tests/4.1_Standard_140/L100AC.xml',
    'RESNET_Tests/4.1_Standard_140/L150AL.xml' => 'RESNET_Tests/4.1_Standard_140/L100AL.xml',
    'RESNET_Tests/4.1_Standard_140/L160AC.xml' => 'RESNET_Tests/4.1_Standard_140/L100AC.xml',
    'RESNET_Tests/4.1_Standard_140/L160AL.xml' => 'RESNET_Tests/4.1_Standard_140/L100AL.xml',
    'RESNET_Tests/4.1_Standard_140/L170AC.xml' => 'RESNET_Tests/4.1_Standard_140/L100AC.xml',
    'RESNET_Tests/4.1_Standard_140/L170AL.xml' => 'RESNET_Tests/4.1_Standard_140/L100AL.xml',
    'RESNET_Tests/4.1_Standard_140/L200AC.xml' => 'RESNET_Tests/4.1_Standard_140/L100AC.xml',
    'RESNET_Tests/4.1_Standard_140/L200AL.xml' => 'RESNET_Tests/4.1_Standard_140/L100AL.xml',
    'RESNET_Tests/4.1_Standard_140/L302XC.xml' => 'RESNET_Tests/4.1_Standard_140/L100AC.xml',
    'RESNET_Tests/4.1_Standard_140/L322XC.xml' => 'RESNET_Tests/4.1_Standard_140/L100AC.xml',
    'RESNET_Tests/4.1_Standard_140/L155AC.xml' => 'RESNET_Tests/4.1_Standard_140/L150AC.xml',
    'RESNET_Tests/4.1_Standard_140/L155AL.xml' => 'RESNET_Tests/4.1_Standard_140/L150AL.xml',
    'RESNET_Tests/4.1_Standard_140/L202AC.xml' => 'RESNET_Tests/4.1_Standard_140/L200AC.xml',
    'RESNET_Tests/4.1_Standard_140/L202AL.xml' => 'RESNET_Tests/4.1_Standard_140/L200AL.xml',
    'RESNET_Tests/4.1_Standard_140/L304XC.xml' => 'RESNET_Tests/4.1_Standard_140/L302XC.xml',
    'RESNET_Tests/4.1_Standard_140/L324XC.xml' => 'RESNET_Tests/4.1_Standard_140/L322XC.xml',
    'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/01-L100.xml' => 'RESNET_Tests/4.1_Standard_140/L100AC.xml',
    'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/02-L100.xml' => 'RESNET_Tests/4.1_Standard_140/L100AC.xml',
    'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/03-L304.xml' => 'RESNET_Tests/4.1_Standard_140/L304XC.xml',
    'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/04-L324.xml' => 'RESNET_Tests/4.1_Standard_140/L324XC.xml',
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
    'RESNET_Tests/4.6_Hot_Water/L100AD-HW-01.xml' => 'RESNET_Tests/4.1_Standard_140/L100AC.xml',
    'RESNET_Tests/4.6_Hot_Water/L100AD-HW-02.xml' => 'RESNET_Tests/4.6_Hot_Water/L100AD-HW-01.xml',
    'RESNET_Tests/4.6_Hot_Water/L100AD-HW-03.xml' => 'RESNET_Tests/4.6_Hot_Water/L100AD-HW-01.xml',
    'RESNET_Tests/4.6_Hot_Water/L100AD-HW-04.xml' => 'RESNET_Tests/4.6_Hot_Water/L100AD-HW-02.xml',
    'RESNET_Tests/4.6_Hot_Water/L100AD-HW-05.xml' => 'RESNET_Tests/4.6_Hot_Water/L100AD-HW-02.xml',
    'RESNET_Tests/4.6_Hot_Water/L100AD-HW-06.xml' => 'RESNET_Tests/4.6_Hot_Water/L100AD-HW-05.xml',
    'RESNET_Tests/4.6_Hot_Water/L100AD-HW-07.xml' => 'RESNET_Tests/4.6_Hot_Water/L100AD-HW-02.xml',
    'RESNET_Tests/4.6_Hot_Water/L100AM-HW-01.xml' => 'RESNET_Tests/4.1_Standard_140/L100AC.xml',
    'RESNET_Tests/4.6_Hot_Water/L100AM-HW-02.xml' => 'RESNET_Tests/4.6_Hot_Water/L100AM-HW-01.xml',
    'RESNET_Tests/4.6_Hot_Water/L100AM-HW-03.xml' => 'RESNET_Tests/4.6_Hot_Water/L100AM-HW-01.xml',
    'RESNET_Tests/4.6_Hot_Water/L100AM-HW-04.xml' => 'RESNET_Tests/4.6_Hot_Water/L100AM-HW-02.xml',
    'RESNET_Tests/4.6_Hot_Water/L100AM-HW-05.xml' => 'RESNET_Tests/4.6_Hot_Water/L100AM-HW-02.xml',
    'RESNET_Tests/4.6_Hot_Water/L100AM-HW-06.xml' => 'RESNET_Tests/4.6_Hot_Water/L100AM-HW-05.xml',
    'RESNET_Tests/4.6_Hot_Water/L100AM-HW-07.xml' => 'RESNET_Tests/4.6_Hot_Water/L100AM-HW-02.xml',
    'RESNET_Tests/Other_HERS_AutoGen_IAD_Home/01-L100.xml' => 'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/01-L100.xml',
    'RESNET_Tests/Other_HERS_AutoGen_IAD_Home/02-L100.xml' => 'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/02-L100.xml',
    'RESNET_Tests/Other_HERS_AutoGen_IAD_Home/03-L304.xml' => 'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/03-L304.xml',
    'RESNET_Tests/Other_HERS_AutoGen_IAD_Home/04-L324.xml' => 'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/04-L324.xml',
    'RESNET_Tests/Other_HERS_Method_PreAddendumE/L100A-01.xml' => 'RESNET_Tests/4.3_HERS_Method/L100A-01.xml',
    'RESNET_Tests/Other_HERS_Method_PreAddendumE/L100A-02.xml' => 'RESNET_Tests/4.3_HERS_Method/L100A-02.xml',
    'RESNET_Tests/Other_HERS_Method_PreAddendumE/L100A-03.xml' => 'RESNET_Tests/4.3_HERS_Method/L100A-03.xml',
    'RESNET_Tests/Other_HERS_Method_PreAddendumE/L100A-04.xml' => 'RESNET_Tests/4.3_HERS_Method/L100A-04.xml',
    'RESNET_Tests/Other_HERS_Method_PreAddendumE/L100A-05.xml' => 'RESNET_Tests/4.3_HERS_Method/L100A-05.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml' => 'RESNET_Tests/4.1_Standard_140/L100AC.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-07.xml' => 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-08.xml' => 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-09.xml' => 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-10.xml' => 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-11.xml' => 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-12.xml' => 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-13.xml' => 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-14.xml' => 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-15.xml' => 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-16.xml' => 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-17.xml' => 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-16.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-18.xml' => 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-19.xml' => 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-20.xml' => 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-21.xml' => 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-22.xml' => 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml' => 'RESNET_Tests/4.1_Standard_140/L100AL.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-07.xml' => 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-08.xml' => 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-09.xml' => 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-10.xml' => 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-11.xml' => 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-12.xml' => 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-13.xml' => 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-14.xml' => 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-15.xml' => 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-16.xml' => 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-17.xml' => 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-16.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-18.xml' => 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-19.xml' => 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-20.xml' => 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-21.xml' => 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-22.xml' => 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml',
    'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-01.xml' => 'RESNET_Tests/4.1_Standard_140/L100AC.xml',
    'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-02.xml' => 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-01.xml',
    'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-03.xml' => 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-01.xml',
    'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-04.xml' => 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-01.xml',
    'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-05.xml' => 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-01.xml',
    'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-06.xml' => 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-01.xml',
    'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-07.xml' => 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-01.xml',
    'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-08.xml' => 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-07.xml',
    'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-09.xml' => 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-01.xml',
    'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-10.xml' => 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-08.xml',
    'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-11.xml' => 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-01.xml',
    'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-12.xml' => 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-07.xml',
    'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-01.xml' => 'RESNET_Tests/4.1_Standard_140/L100AL.xml',
    'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-02.xml' => 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-01.xml',
    'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-03.xml' => 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-01.xml',
    'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-04.xml' => 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-01.xml',
    'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-05.xml' => 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-01.xml',
    'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-06.xml' => 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-01.xml',
    'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-07.xml' => 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-01.xml',
    'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-08.xml' => 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-07.xml',
    'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-09.xml' => 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-01.xml',
    'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-10.xml' => 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-08.xml',
    'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-11.xml' => 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-01.xml',
    'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-12.xml' => 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-07.xml',
    'RESNET_Tests/Other_Hot_Water_PreAddendumA/L100AD-HW-01.xml' => 'RESNET_Tests/4.6_Hot_Water/L100AD-HW-01.xml',
    'RESNET_Tests/Other_Hot_Water_PreAddendumA/L100AD-HW-02.xml' => 'RESNET_Tests/4.6_Hot_Water/L100AD-HW-02.xml',
    'RESNET_Tests/Other_Hot_Water_PreAddendumA/L100AD-HW-03.xml' => 'RESNET_Tests/4.6_Hot_Water/L100AD-HW-03.xml',
    'RESNET_Tests/Other_Hot_Water_PreAddendumA/L100AM-HW-01.xml' => 'RESNET_Tests/4.6_Hot_Water/L100AM-HW-01.xml',
    'RESNET_Tests/Other_Hot_Water_PreAddendumA/L100AM-HW-02.xml' => 'RESNET_Tests/4.6_Hot_Water/L100AM-HW-02.xml',
    'RESNET_Tests/Other_Hot_Water_PreAddendumA/L100AM-HW-03.xml' => 'RESNET_Tests/4.6_Hot_Water/L100AM-HW-03.xml'
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
        set_hpxml_header(hpxml_file, hpxml)
        set_hpxml_site(hpxml_file, hpxml)
        set_hpxml_building_occupancy(hpxml_file, hpxml)
        set_hpxml_building_construction(hpxml_file, hpxml)
        set_hpxml_climate_and_risk_zones(hpxml_file, hpxml)
        set_hpxml_air_infiltration_measurements(hpxml_file, hpxml)
        set_hpxml_attics(hpxml_file, hpxml)
        set_hpxml_foundations(hpxml_file, hpxml)
        set_hpxml_roofs(hpxml_file, hpxml)
        set_hpxml_rim_joists(hpxml_file, hpxml)
        set_hpxml_walls(hpxml_file, hpxml)
        set_hpxml_foundations_walls(hpxml_file, hpxml)
        set_hpxml_frame_floors(hpxml_file, hpxml)
        set_hpxml_slabs(hpxml_file, hpxml)
        set_hpxml_windows(hpxml_file, hpxml)
        set_hpxml_skylights(hpxml_file, hpxml)
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
        set_hpxml_pv_systems(hpxml_file, hpxml)
        set_hpxml_clothes_washer(hpxml_file, hpxml)
        set_hpxml_clothes_dryer(hpxml_file, hpxml)
        set_hpxml_dishwasher(hpxml_file, hpxml)
        set_hpxml_refrigerator(hpxml_file, hpxml)
        set_hpxml_cooking_range(hpxml_file, hpxml)
        set_hpxml_oven(hpxml_file, hpxml)
        set_hpxml_lighting(hpxml_file, hpxml)
        set_hpxml_ceiling_fans(hpxml_file, hpxml)
        set_hpxml_plug_loads(hpxml_file, hpxml)
        set_hpxml_misc_load_schedule(hpxml_file, hpxml)
      end

      hpxml_doc = hpxml.to_rexml()

      hpxml_path = File.join(tests_dir, derivative)

      # Validate file against HPXML schema
      schemas_dir = File.absolute_path(File.join(File.dirname(__FILE__), 'hpxml-measures', 'HPXMLtoOpenStudio', 'resources'))
      errors = XMLHelper.validate(hpxml_doc.to_s, File.join(schemas_dir, 'HPXML.xsd'), nil)
      if errors.size > 0
        fail errors.to_s
      end

      XMLHelper.write_file(hpxml_doc, hpxml_path)
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

def set_hpxml_header(hpxml_file, hpxml)
  if ['RESNET_Tests/4.1_Standard_140/L100AC.xml',
      'RESNET_Tests/4.1_Standard_140/L100AL.xml'].include? hpxml_file
    # Base configuration w/ all Addenda
    hpxml.set_header(xml_type: 'HPXML',
                     xml_generated_by: 'Rakefile',
                     transaction: 'create',
                     software_program_used: nil,
                     software_program_version: nil,
                     eri_calculation_version: '2014AEG',
                     building_id: 'MyBuilding',
                     event_type: 'proposed workscope',
                     created_date_and_time: Time.new(2000, 1, 1).strftime('%Y-%m-%dT%H:%M:%S%:z')) # Hard-code to prevent diffs
  elsif hpxml_file.include? 'RESNET_Tests/Other_Hot_Water_PreAddendumA'
    # Pre-Addendum A
    hpxml.header.eri_calculation_version = '2014'
  elsif hpxml_file.include?('RESNET_Tests/Other_HERS_Method_PreAddendumE') ||
        hpxml_file.include?('RESNET_Tests/Other_HERS_Method_Proposed') ||
        hpxml_file.include?('RESNET_Tests/Other_HERS_Method_Task_Group')
    # Pre-Addendum E
    hpxml.header.eri_calculation_version = '2014A'
  end
end

def set_hpxml_site(hpxml_file, hpxml)
  if hpxml_file.include?('RESNET_Tests/4.1_Standard_140') ||
     hpxml_file.include?('RESNET_Tests/4.4_HVAC') ||
     hpxml_file.include?('RESNET_Tests/4.5_DSE')
    # Base configuration
    hpxml.set_site(fuels: [HPXML::FuelTypeElectricity, HPXML::FuelTypeNaturalGas])
  end
end

def set_hpxml_building_occupancy(hpxml_file, hpxml)
  if hpxml_file.include?('RESNET_Tests/4.1_Standard_140') ||
     hpxml_file.include?('RESNET_Tests/4.4_HVAC') ||
     hpxml_file.include?('RESNET_Tests/4.5_DSE')
    # Base configuration
    hpxml.set_building_occupancy(number_of_residents: 0)
  else
    hpxml.set_building_occupancy()
  end
end

def set_hpxml_building_construction(hpxml_file, hpxml)
  if ['RESNET_Tests/4.1_Standard_140/L100AC.xml',
      'RESNET_Tests/4.1_Standard_140/L100AL.xml'].include? hpxml_file
    # Base configuration
    hpxml.set_building_construction(number_of_conditioned_floors: 1,
                                    number_of_conditioned_floors_above_grade: 1,
                                    number_of_bedrooms: 3,
                                    conditioned_floor_area: 1539,
                                    conditioned_building_volume: 12312)
  elsif ['RESNET_Tests/4.1_Standard_140/L322XC.xml'].include? hpxml_file
    # Conditioned basement
    hpxml.building_construction.number_of_conditioned_floors = 2
    hpxml.building_construction.conditioned_floor_area = 3078
    hpxml.building_construction.conditioned_building_volume = 24624
  elsif ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/03-L304.xml',
         'RESNET_Tests/4.3_HERS_Method/L100A-03.xml',
         'RESNET_Tests/4.6_Hot_Water/L100AD-HW-01.xml',
         'RESNET_Tests/4.6_Hot_Water/L100AM-HW-01.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-09.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-09.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-03.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-03.xml'].include? hpxml_file
    # 2 bedrooms
    hpxml.building_construction.number_of_bedrooms = 2
  elsif ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/04-L324.xml',
         'RESNET_Tests/4.3_HERS_Method/L100A-04.xml',
         'RESNET_Tests/4.6_Hot_Water/L100AD-HW-02.xml',
         'RESNET_Tests/4.6_Hot_Water/L100AM-HW-02.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-10.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-10.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-04.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-04.xml'].include? hpxml_file
    # 4 bedrooms
    hpxml.building_construction.number_of_bedrooms = 4
  elsif ['RESNET_Tests/4.5_DSE/HVAC3a.xml'].include? hpxml_file
    # Unconditioned basement
    hpxml.building_construction.number_of_conditioned_floors = 1
    hpxml.building_construction.conditioned_floor_area = 1539
    hpxml.building_construction.conditioned_building_volume = 12312
  end
  if hpxml_file.include? 'RESNET_Tests/4.1_Standard_140'
    hpxml.building_construction.use_only_ideal_air_system = true
  else
    hpxml.building_construction.use_only_ideal_air_system = nil
  end
end

def set_hpxml_climate_and_risk_zones(hpxml_file, hpxml)
  if hpxml_file == 'RESNET_Tests/4.1_Standard_140/L100AC.xml'
    # Colorado Springs
    hpxml.set_climate_and_risk_zones(iecc2006: '5B',
                                     weather_station_id: 'WeatherStation',
                                     weather_station_name: 'Colorado Springs, CO',
                                     weather_station_wmo: '724660')
  elsif hpxml_file == 'RESNET_Tests/4.1_Standard_140/L100AL.xml'
    # Las Vegas
    hpxml.set_climate_and_risk_zones(iecc2006: '3B',
                                     weather_station_id: 'WeatherStation',
                                     weather_station_name: 'Las Vegas, NV',
                                     weather_station_wmo: '723860')
  elsif ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/01-L100.xml'].include? hpxml_file
    # Baltimore
    hpxml.set_climate_and_risk_zones(iecc2006: '4A',
                                     weather_station_id: 'WeatherStation',
                                     weather_station_name: 'Baltimore, MD',
                                     weather_station_wmo: '724060')
  elsif ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/02-L100.xml'].include? hpxml_file
    # Dallas
    hpxml.set_climate_and_risk_zones(iecc2006: '3A',
                                     weather_station_id: 'WeatherStation',
                                     weather_station_name: 'Dallas, TX',
                                     weather_station_wmo: '722590')
  elsif ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/03-L304.xml',
         'RESNET_Tests/4.6_Hot_Water/L100AM-HW-01.xml'].include? hpxml_file
    # Miami
    hpxml.set_climate_and_risk_zones(iecc2006: '1A',
                                     weather_station_id: 'WeatherStation',
                                     weather_station_name: 'Miami, FL',
                                     weather_station_wmo: '722020')
  elsif ['RESNET_Tests/4.6_Hot_Water/L100AD-HW-01.xml'].include? hpxml_file
    # Duluth
    hpxml.set_climate_and_risk_zones(iecc2006: '7',
                                     weather_station_id: 'WeatherStation',
                                     weather_station_name: 'Duluth, MN',
                                     weather_station_wmo: '727450')
  end
end

def set_hpxml_air_infiltration_measurements(hpxml_file, hpxml)
  if ['RESNET_Tests/4.1_Standard_140/L100AC.xml',
      'RESNET_Tests/4.1_Standard_140/L100AL.xml',
      'RESNET_Tests/4.5_DSE/HVAC3a.xml'].include? hpxml_file
    # Base configuration
    hpxml.air_infiltration_measurements.clear()
    hpxml.air_infiltration_measurements.add(id: 'InfiltrationMeasurement',
                                            constant_ach_natural: 0.67)
  elsif ['RESNET_Tests/4.1_Standard_140/L322XC.xml'].include? hpxml_file
    hpxml.air_infiltration_measurements.clear()
    hpxml.air_infiltration_measurements.add(id: 'InfiltrationMeasurement',
                                            constant_ach_natural: 0.335)
  elsif ['RESNET_Tests/4.1_Standard_140/L110AC.xml',
         'RESNET_Tests/4.1_Standard_140/L110AL.xml',
         'RESNET_Tests/4.1_Standard_140/L200AC.xml',
         'RESNET_Tests/4.1_Standard_140/L200AL.xml'].include? hpxml_file
    # High Infiltration
    hpxml.air_infiltration_measurements.clear()
    hpxml.air_infiltration_measurements.add(id: 'InfiltrationMeasurement',
                                            constant_ach_natural: 1.5)
  elsif ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/01-L100.xml',
         'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/02-L100.xml',
         'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/03-L304.xml',
         'RESNET_Tests/4.3_HERS_Method/L100A-01.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-01.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-01.xml',
         'RESNET_Tests/4.6_Hot_Water/L100AD-HW-01.xml',
         'RESNET_Tests/4.6_Hot_Water/L100AM-HW-01.xml'].include? hpxml_file
    hpxml.air_infiltration_measurements.clear()
    hpxml.air_infiltration_measurements.add(id: 'InfiltrationMeasurement',
                                            unit_of_measure: HPXML::UnitsACHNatural,
                                            air_leakage: 0.67)
  elsif ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/04-L324.xml'].include? hpxml_file
    hpxml.air_infiltration_measurements.clear()
    hpxml.air_infiltration_measurements.add(id: 'InfiltrationMeasurement',
                                            unit_of_measure: HPXML::UnitsACHNatural,
                                            air_leakage: 0.335)
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml'].include? hpxml_file
    # 3 ACH50
    hpxml.air_infiltration_measurements.clear()
    hpxml.air_infiltration_measurements.add(id: 'InfiltrationMeasurement',
                                            house_pressure: 50,
                                            unit_of_measure: HPXML::UnitsACH,
                                            air_leakage: 3)
  end
  hpxml.air_infiltration_measurements[0].infiltration_volume = hpxml.building_construction.conditioned_building_volume
end

def set_hpxml_attics(hpxml_file, hpxml)
  if hpxml_file.include?('RESNET_Tests/4.1_Standard_140') ||
     hpxml_file.include?('RESNET_Tests/4.4_HVAC') ||
     hpxml_file.include?('RESNET_Tests/4.5_DSE')
    # Base configuration
    hpxml.attics.clear()
    hpxml.attics.add(id: 'VentedAttic',
                     attic_type: HPXML::AtticTypeVented,
                     vented_attic_constant_ach: 2.4,
                     vented_attic_sla: nil)
  else
    # Reference home
    hpxml.attics.clear()
    hpxml.attics.add(id: 'VentedAttic',
                     attic_type: HPXML::AtticTypeVented,
                     vented_attic_constant_ach: nil,
                     vented_attic_sla: (1.0 / 300.0).round(5))
  end
end

def set_hpxml_foundations(hpxml_file, hpxml)
  if hpxml_file.include? 'RESNET_Tests/Other_HERS_Method_Proposed'
    # Vented crawlspace
    hpxml.foundations.clear()
    hpxml.foundations.add(id: 'VentedCrawlspace',
                          foundation_type: HPXML::FoundationTypeCrawlspaceVented,
                          vented_crawlspace_sla: (1.0 / 150.0).round(5))
  elsif ['RESNET_Tests/4.5_DSE/HVAC3a.xml',
         'RESNET_Tests/4.5_DSE/HVAC3b.xml',
         'RESNET_Tests/4.5_DSE/HVAC3c.xml',
         'RESNET_Tests/4.5_DSE/HVAC3d.xml'].include? hpxml_file
    hpxml.foundations.clear()
    hpxml.foundations.add(id: 'UnconditionedBasement',
                          foundation_type: HPXML::FoundationTypeBasementUnconditioned,
                          unconditioned_basement_thermal_boundary: HPXML::FoundationThermalBoundaryFloor)
  else
    hpxml.foundations.clear()
  end
end

def set_hpxml_roofs(hpxml_file, hpxml)
  if ['RESNET_Tests/4.1_Standard_140/L100AC.xml',
      'RESNET_Tests/4.1_Standard_140/L100AL.xml'].include? hpxml_file
    # Base configuration
    hpxml.roofs.add(id: 'AtticRoofNorth',
                    interior_adjacent_to: HPXML::LocationAtticVented,
                    area: 811.1,
                    azimuth: 0,
                    solar_absorptance: 0.6,
                    emittance: 0.9,
                    pitch: 4,
                    radiant_barrier: false,
                    insulation_assembly_r_value: 1.99)
    hpxml.roofs.add(id: 'AtticRoofSouth',
                    interior_adjacent_to: HPXML::LocationAtticVented,
                    area: 811.1,
                    azimuth: 180,
                    solar_absorptance: 0.6,
                    emittance: 0.9,
                    pitch: 4,
                    radiant_barrier: false,
                    insulation_assembly_r_value: 1.99)
  elsif ['RESNET_Tests/4.1_Standard_140/L202AC.xml',
         'RESNET_Tests/4.1_Standard_140/L202AL.xml'].include? hpxml_file
    # Low Exterior Solar Absorptance
    for i in 0..hpxml.roofs.size - 1
      hpxml.roofs[i].solar_absorptance = 0.2
    end
  elsif ['RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-09.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-10.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-09.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-10.xml'].include? hpxml_file
    # Radiant barrier
    for i in 0..hpxml.roofs.size - 1
      hpxml.roofs[i].radiant_barrier = true
    end
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml'].include? hpxml_file
    # Solar absorptance = 0.75; Emittance = 0.90; Slope = 18.4 degrees (pitch = 4/12)
    for i in 0..hpxml.roofs.size - 1
      hpxml.roofs[i].solar_absorptance = 0.75
    end
  end
end

def set_hpxml_rim_joists(hpxml_file, hpxml)
  if ['RESNET_Tests/4.1_Standard_140/L322XC.xml'].include? hpxml_file
    # Uninsulated ASHRAE Conditioned Basement
    hpxml.rim_joists.add(id: 'RimJoistNorth',
                         exterior_adjacent_to: HPXML::LocationOutside,
                         interior_adjacent_to: HPXML::LocationBasementConditioned,
                         area: 42.75,
                         azimuth: 0,
                         solar_absorptance: 0.6,
                         emittance: 0.9,
                         insulation_assembly_r_value: 5.01)
    hpxml.rim_joists.add(id: 'RimJoistEast',
                         exterior_adjacent_to: HPXML::LocationOutside,
                         interior_adjacent_to: HPXML::LocationBasementConditioned,
                         area: 20.25,
                         azimuth: 90,
                         solar_absorptance: 0.6,
                         emittance: 0.9,
                         insulation_assembly_r_value: 5.01)
    hpxml.rim_joists.add(id: 'RimJoistSouth',
                         exterior_adjacent_to: HPXML::LocationOutside,
                         interior_adjacent_to: HPXML::LocationBasementConditioned,
                         area: 42.75,
                         azimuth: 180,
                         solar_absorptance: 0.6,
                         emittance: 0.9,
                         insulation_assembly_r_value: 5.01)
    hpxml.rim_joists.add(id: 'RimJoistWest',
                         exterior_adjacent_to: HPXML::LocationOutside,
                         interior_adjacent_to: HPXML::LocationBasementConditioned,
                         area: 20.25,
                         azimuth: 270,
                         solar_absorptance: 0.6,
                         emittance: 0.9,
                         insulation_assembly_r_value: 5.01)
  elsif ['RESNET_Tests/4.1_Standard_140/L324XC.xml'].include? hpxml_file
    # Interior Insulation Applied to Uninsulated ASHRAE Conditioned Basement Wall
    for i in 0..hpxml.rim_joists.size - 1
      hpxml.rim_joists[i].insulation_assembly_r_value = 13.14
    end
  elsif ['RESNET_Tests/4.5_DSE/HVAC3a.xml'].include? hpxml_file
    for i in 0..hpxml.rim_joists.size - 1
      hpxml.rim_joists[i].interior_adjacent_to = HPXML::LocationBasementUnconditioned
    end
  end
end

def set_hpxml_walls(hpxml_file, hpxml)
  if ['RESNET_Tests/4.1_Standard_140/L100AC.xml',
      'RESNET_Tests/4.1_Standard_140/L100AL.xml'].include? hpxml_file
    # Base configuration
    hpxml.walls.add(id: 'WallNorth',
                    exterior_adjacent_to: HPXML::LocationOutside,
                    interior_adjacent_to: HPXML::LocationLivingSpace,
                    wall_type: HPXML::WallTypeWoodStud,
                    area: 456,
                    azimuth: 0,
                    solar_absorptance: 0.6,
                    emittance: 0.9,
                    insulation_assembly_r_value: 11.76)
    hpxml.walls.add(id: 'WallEast',
                    exterior_adjacent_to: HPXML::LocationOutside,
                    interior_adjacent_to: HPXML::LocationLivingSpace,
                    wall_type: HPXML::WallTypeWoodStud,
                    area: 216,
                    azimuth: 90,
                    solar_absorptance: 0.6,
                    emittance: 0.9,
                    insulation_assembly_r_value: 11.76)
    hpxml.walls.add(id: 'WallSouth',
                    exterior_adjacent_to: HPXML::LocationOutside,
                    interior_adjacent_to: HPXML::LocationLivingSpace,
                    wall_type: HPXML::WallTypeWoodStud,
                    area: 456,
                    azimuth: 180,
                    solar_absorptance: 0.6,
                    emittance: 0.9,
                    insulation_assembly_r_value: 11.76)
    hpxml.walls.add(id: 'WallWest',
                    exterior_adjacent_to: HPXML::LocationOutside,
                    interior_adjacent_to: HPXML::LocationLivingSpace,
                    wall_type: HPXML::WallTypeWoodStud,
                    area: 216,
                    azimuth: 270,
                    solar_absorptance: 0.6,
                    emittance: 0.9,
                    insulation_assembly_r_value: 11.76)
    hpxml.walls.add(id: 'WallAtticGableEast',
                    exterior_adjacent_to: HPXML::LocationOutside,
                    interior_adjacent_to: HPXML::LocationAtticVented,
                    wall_type: HPXML::WallTypeWoodStud,
                    area: 60.75,
                    azimuth: 90,
                    solar_absorptance: 0.6,
                    emittance: 0.9,
                    insulation_assembly_r_value: 2.15)
    hpxml.walls.add(id: 'WallAtticGableWest',
                    exterior_adjacent_to: HPXML::LocationOutside,
                    interior_adjacent_to: HPXML::LocationAtticVented,
                    wall_type: HPXML::WallTypeWoodStud,
                    area: 60.75,
                    azimuth: 270,
                    solar_absorptance: 0.6,
                    emittance: 0.9,
                    insulation_assembly_r_value: 2.15)
  elsif ['RESNET_Tests/4.1_Standard_140/L120AC.xml',
         'RESNET_Tests/4.1_Standard_140/L120AL.xml'].include? hpxml_file
    # Well-Insulated Walls
    for i in 0..hpxml.walls.size - 3
      hpxml.walls[i].insulation_assembly_r_value = 23.58
    end
  elsif ['RESNET_Tests/4.1_Standard_140/L200AC.xml',
         'RESNET_Tests/4.1_Standard_140/L200AL.xml'].include? hpxml_file
    # Uninsulated
    for i in 0..hpxml.walls.size - 3
      hpxml.walls[i].insulation_assembly_r_value = 4.84
    end
  elsif ['RESNET_Tests/4.1_Standard_140/L202AC.xml',
         'RESNET_Tests/4.1_Standard_140/L202AL.xml'].include? hpxml_file
    # Low Exterior Solar Absorptance
    for i in 0..hpxml.walls.size - 1
      hpxml.walls[i].solar_absorptance = 0.2
    end
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml'].include? hpxml_file
    # Cavity insulation = R-13, grade I; Continuous sheathing insulation = R-5; Framing fraction = 0.25; Solar absorptance = 0.75
    for i in 0..hpxml.walls.size - 3
      hpxml.walls[i].insulation_assembly_r_value = 17.07
      hpxml.walls[i].solar_absorptance = 0.75
    end
  end
end

def set_hpxml_foundations_walls(hpxml_file, hpxml)
  if ['RESNET_Tests/4.1_Standard_140/L100AC.xml',
      'RESNET_Tests/4.1_Standard_140/L100AL.xml'].include? hpxml_file
    hpxml.foundation_walls.clear()
  elsif ['RESNET_Tests/4.1_Standard_140/L322XC.xml'].include? hpxml_file
    # Uninsulated ASHRAE Conditioned Basement
    hpxml.foundation_walls.add(id: 'FoundationWallNorth',
                               exterior_adjacent_to: 'ground',
                               interior_adjacent_to: HPXML::LocationBasementConditioned,
                               height: 7.25,
                               area: 413.25,
                               azimuth: 0,
                               thickness: 6,
                               depth_below_grade: 6.583,
                               insulation_interior_r_value: 0,
                               insulation_interior_distance_to_top: 0,
                               insulation_interior_distance_to_bottom: 0,
                               insulation_exterior_r_value: 0,
                               insulation_exterior_distance_to_top: 0,
                               insulation_exterior_distance_to_bottom: 0)
    hpxml.foundation_walls.add(id: 'FoundationWallEast',
                               exterior_adjacent_to: 'ground',
                               interior_adjacent_to: HPXML::LocationBasementConditioned,
                               height: 7.25,
                               area: 195.75,
                               azimuth: 90,
                               thickness: 6,
                               depth_below_grade: 6.583,
                               insulation_interior_r_value: 0,
                               insulation_interior_distance_to_top: 0,
                               insulation_interior_distance_to_bottom: 0,
                               insulation_exterior_r_value: 0,
                               insulation_exterior_distance_to_top: 0,
                               insulation_exterior_distance_to_bottom: 0)
    hpxml.foundation_walls.add(id: 'FoundationWallSouth',
                               exterior_adjacent_to: 'ground',
                               interior_adjacent_to: HPXML::LocationBasementConditioned,
                               height: 7.25,
                               area: 413.25,
                               azimuth: 180,
                               thickness: 6,
                               depth_below_grade: 6.583,
                               insulation_interior_r_value: 0,
                               insulation_interior_distance_to_top: 0,
                               insulation_interior_distance_to_bottom: 0,
                               insulation_exterior_r_value: 0,
                               insulation_exterior_distance_to_top: 0,
                               insulation_exterior_distance_to_bottom: 0)
    hpxml.foundation_walls.add(id: 'FoundationWallWest',
                               exterior_adjacent_to: 'ground',
                               interior_adjacent_to: HPXML::LocationBasementConditioned,
                               height: 7.25,
                               area: 195.75,
                               azimuth: 270,
                               thickness: 6,
                               depth_below_grade: 6.583,
                               insulation_interior_r_value: 0,
                               insulation_interior_distance_to_top: 0,
                               insulation_interior_distance_to_bottom: 0,
                               insulation_exterior_r_value: 0,
                               insulation_exterior_distance_to_top: 0,
                               insulation_exterior_distance_to_bottom: 0)
  elsif ['RESNET_Tests/4.1_Standard_140/L324XC.xml'].include? hpxml_file
    # Interior Insulation Applied to Uninsulated ASHRAE Conditioned Basement Wall
    for i in 0..hpxml.foundation_walls.size - 1
      hpxml.foundation_walls[i].insulation_interior_r_value = 10.2
      hpxml.foundation_walls[i].insulation_interior_distance_to_top = 0.0
      hpxml.foundation_walls[i].insulation_interior_distance_to_bottom = 7.25
    end
  elsif ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/02-L100.xml'].include? hpxml_file
    # Un-vented crawlspace with R-7 crawlspace wall insulation
    hpxml.foundation_walls.add(id: 'FoundationWallNorth',
                               exterior_adjacent_to: 'ground',
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
                               exterior_adjacent_to: 'ground',
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
                               exterior_adjacent_to: 'ground',
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
                               exterior_adjacent_to: 'ground',
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
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml'].include? hpxml_file
    # 2 ft. high crawlspace above grade
    hpxml.foundation_walls.add(id: 'FoundationWallNorth',
                               exterior_adjacent_to: 'ground',
                               interior_adjacent_to: HPXML::LocationCrawlspaceVented,
                               height: 2,
                               area: 114,
                               azimuth: 0,
                               thickness: 6,
                               depth_below_grade: 0,
                               insulation_interior_r_value: 0,
                               insulation_interior_distance_to_top: 0,
                               insulation_interior_distance_to_bottom: 0,
                               insulation_exterior_r_value: 0,
                               insulation_exterior_distance_to_top: 0,
                               insulation_exterior_distance_to_bottom: 0)
    hpxml.foundation_walls.add(id: 'FoundationWallEast',
                               exterior_adjacent_to: 'ground',
                               interior_adjacent_to: HPXML::LocationCrawlspaceVented,
                               height: 2,
                               area: 54,
                               azimuth: 90,
                               thickness: 6,
                               depth_below_grade: 0,
                               insulation_interior_r_value: 0,
                               insulation_interior_distance_to_top: 0,
                               insulation_interior_distance_to_bottom: 0,
                               insulation_exterior_r_value: 0,
                               insulation_exterior_distance_to_top: 0,
                               insulation_exterior_distance_to_bottom: 0)
    hpxml.foundation_walls.add(id: 'FoundationWallSouth',
                               exterior_adjacent_to: 'ground',
                               interior_adjacent_to: HPXML::LocationCrawlspaceVented,
                               height: 2,
                               area: 114,
                               azimuth: 180,
                               thickness: 6,
                               depth_below_grade: 0,
                               insulation_interior_r_value: 0,
                               insulation_interior_distance_to_top: 0,
                               insulation_interior_distance_to_bottom: 0,
                               insulation_exterior_r_value: 0,
                               insulation_exterior_distance_to_top: 0,
                               insulation_exterior_distance_to_bottom: 0)
    hpxml.foundation_walls.add(id: 'FoundationWallWest',
                               exterior_adjacent_to: 'ground',
                               interior_adjacent_to: HPXML::LocationCrawlspaceVented,
                               height: 2,
                               area: 54,
                               azimuth: 270,
                               thickness: 6,
                               depth_below_grade: 0,
                               insulation_interior_r_value: 0,
                               insulation_interior_distance_to_top: 0,
                               insulation_interior_distance_to_bottom: 0,
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
  if ['RESNET_Tests/4.1_Standard_140/L100AC.xml',
      'RESNET_Tests/4.1_Standard_140/L100AL.xml',
      'RESNET_Tests/4.5_DSE/HVAC3a.xml'].include? hpxml_file
    # Base configuration
    hpxml.frame_floors.clear()
    hpxml.frame_floors.add(id: 'FloorUnderAttic',
                           exterior_adjacent_to: HPXML::LocationAtticVented,
                           interior_adjacent_to: HPXML::LocationLivingSpace,
                           area: 1539,
                           insulation_assembly_r_value: 18.45)
    hpxml.frame_floors.add(id: 'FloorOverFoundation',
                           exterior_adjacent_to: HPXML::LocationOutside,
                           interior_adjacent_to: HPXML::LocationLivingSpace,
                           area: 1539,
                           insulation_assembly_r_value: 14.15)
    if ['RESNET_Tests/4.5_DSE/HVAC3a.xml'].include? hpxml_file
      hpxml.frame_floors[1].exterior_adjacent_to = HPXML::LocationBasementUnconditioned
    end
  elsif ['RESNET_Tests/4.1_Standard_140/L120AC.xml',
         'RESNET_Tests/4.1_Standard_140/L120AL.xml'].include? hpxml_file
    # Well-Insulated Walls and Roof
    hpxml.frame_floors[0].insulation_assembly_r_value = 57.49
  elsif ['RESNET_Tests/4.1_Standard_140/L200AC.xml',
         'RESNET_Tests/4.1_Standard_140/L200AL.xml'].include? hpxml_file
    # Energy Inefficient
    hpxml.frame_floors[0].insulation_assembly_r_value = 11.75
    hpxml.frame_floors[1].insulation_assembly_r_value = 4.24
  elsif ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/02-L100.xml'].include? hpxml_file
    # Uninsulated
    hpxml.frame_floors[1].insulation_assembly_r_value = 4.24
    hpxml.frame_floors[1].exterior_adjacent_to = HPXML::LocationCrawlspaceUnvented
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml'].include? hpxml_file
    # Blown insulation = R-49, grade I; Framing fraction = 0.11
    hpxml.frame_floors[0].insulation_assembly_r_value = 48.72
    # Cavity insulation = R-30, grade I; Framing fraction = 0.13; Covering = 100% carpet and pad
    hpxml.frame_floors[1].insulation_assembly_r_value = 28.66
    hpxml.frame_floors[1].exterior_adjacent_to = HPXML::LocationCrawlspaceVented
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml'].include? hpxml_file
    # Blown insulation = R-38, grade I; Framing fraction = 0.11
    hpxml.frame_floors[0].insulation_assembly_r_value = 37.53
    # Cavity insulation = R-19, grade I; Framing fraction = 0.13; Covering = 100% carpet and pad
    hpxml.frame_floors[1].insulation_assembly_r_value = 19.45
    hpxml.frame_floors[1].exterior_adjacent_to = HPXML::LocationCrawlspaceVented
  elsif ['RESNET_Tests/4.1_Standard_140/L302XC.xml',
         'RESNET_Tests/4.1_Standard_140/L322XC.xml',
         'RESNET_Tests/4.1_Standard_140/L324XC.xml',
         'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/04-L324.xml'].include? hpxml_file
    hpxml.frame_floors.delete_at(1)
  end
end

def set_hpxml_slabs(hpxml_file, hpxml)
  if ['RESNET_Tests/4.1_Standard_140/L100AC.xml',
      'RESNET_Tests/4.1_Standard_140/L100AL.xml'].include? hpxml_file
    hpxml.slabs.clear()
  elsif ['RESNET_Tests/4.1_Standard_140/L302XC.xml'].include? hpxml_file
    # Slab-on-Grade, Uninsulated ASHRAE Slab
    hpxml.slabs.add(id: 'Slab',
                    interior_adjacent_to: HPXML::LocationLivingSpace,
                    area: 1539,
                    thickness: 4,
                    exposed_perimeter: 168,
                    perimeter_insulation_depth: 0,
                    under_slab_insulation_width: 0,
                    under_slab_insulation_spans_entire_slab: nil,
                    depth_below_grade: 0,
                    perimeter_insulation_r_value: 0,
                    under_slab_insulation_r_value: 0,
                    carpet_fraction: 1,
                    carpet_r_value: 2.08)
  elsif ['RESNET_Tests/4.1_Standard_140/L304XC.xml'].include? hpxml_file
    # Slab-on-Grade, Insulated ASHRAE Slab
    hpxml.slabs[0].perimeter_insulation_depth = 2.5
    hpxml.slabs[0].perimeter_insulation_r_value = 5.4
  elsif ['RESNET_Tests/4.1_Standard_140/L322XC.xml'].include? hpxml_file
    # Uninsulated ASHRAE Conditioned Basement
    hpxml.slabs.add(id: 'Slab',
                    interior_adjacent_to: HPXML::LocationBasementConditioned,
                    area: 1539,
                    thickness: 4,
                    exposed_perimeter: 168,
                    perimeter_insulation_depth: 0,
                    under_slab_insulation_width: 0,
                    under_slab_insulation_spans_entire_slab: nil,
                    perimeter_insulation_r_value: 0,
                    under_slab_insulation_r_value: 0,
                    carpet_fraction: 0,
                    carpet_r_value: 0)
  elsif ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/02-L100.xml'].include? hpxml_file
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
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml'].include? hpxml_file
    # 2 ft. high crawlspace above grade
    hpxml.slabs.add(id: 'Slab',
                    interior_adjacent_to: HPXML::LocationCrawlspaceVented,
                    area: 1539,
                    thickness: 0,
                    exposed_perimeter: 168,
                    perimeter_insulation_depth: 0,
                    under_slab_insulation_width: 0,
                    under_slab_insulation_spans_entire_slab: nil,
                    perimeter_insulation_r_value: 0,
                    under_slab_insulation_r_value: 0,
                    carpet_fraction: 0,
                    carpet_r_value: 0)
  elsif ['RESNET_Tests/4.5_DSE/HVAC3a.xml'].include? hpxml_file
    hpxml.slabs[0].interior_adjacent_to = HPXML::LocationBasementUnconditioned
  end
end

def set_hpxml_windows(hpxml_file, hpxml)
  if ['RESNET_Tests/4.1_Standard_140/L100AC.xml',
      'RESNET_Tests/4.1_Standard_140/L100AL.xml'].include? hpxml_file
    # Base configuration
    hpxml.windows.clear()
    windows = { 'WindowNorth' => [0, 90, 'WallNorth'],
                'WindowEast' => [90, 45, 'WallEast'],
                'WindowSouth' => [180, 90, 'WallSouth'],
                'WindowWest' => [270, 45, 'WallWest'] }
    windows.each do |window_name, window_values|
      azimuth, area, wall = window_values
      hpxml.windows.add(id: window_name,
                        area: area,
                        azimuth: azimuth,
                        ufactor: 1.039,
                        shgc: 0.67,
                        operable: false,
                        wall_idref: wall)
    end
  elsif ['RESNET_Tests/4.1_Standard_140/L130AC.xml',
         'RESNET_Tests/4.1_Standard_140/L130AL.xml'].include? hpxml_file
    # Double-pane low-emissivity window with wood frame
    for i in 0..hpxml.windows.size - 1
      hpxml.windows[i].ufactor = 0.3
      hpxml.windows[i].shgc = 0.335
    end
  elsif ['RESNET_Tests/4.1_Standard_140/L140AC.xml',
         'RESNET_Tests/4.1_Standard_140/L140AL.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-06.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-06.xml'].include? hpxml_file
    # No windows
    hpxml.windows.clear()
  elsif ['RESNET_Tests/4.1_Standard_140/L150AC.xml',
         'RESNET_Tests/4.1_Standard_140/L150AL.xml'].include? hpxml_file
    # South windows only
    hpxml.windows.clear()
    hpxml.windows.add(id: 'WindowSouth',
                      area: 270,
                      azimuth: 180,
                      ufactor: 1.039,
                      shgc: 0.67,
                      operable: false,
                      wall_idref: 'WallSouth')
  elsif ['RESNET_Tests/4.1_Standard_140/L155AC.xml',
         'RESNET_Tests/4.1_Standard_140/L155AL.xml'].include? hpxml_file
    # South windows with overhangs
    hpxml.windows[0].overhangs_depth = 2.5
    hpxml.windows[0].overhangs_distance_to_top_of_window = 1
    hpxml.windows[0].overhangs_distance_to_bottom_of_window = 6
  elsif ['RESNET_Tests/4.1_Standard_140/L160AC.xml',
         'RESNET_Tests/4.1_Standard_140/L160AL.xml'].include? hpxml_file
    # East and West windows only
    hpxml.windows.clear()
    windows = { 'WindowEast' => [90, 135, 'WallEast'],
                'WindowWest' => [270, 135, 'WallWest'] }
    windows.each do |window_name, window_values|
      azimuth, area, wall = window_values
      hpxml.windows.add(id: window_name,
                        area: area,
                        azimuth: azimuth,
                        ufactor: 1.039,
                        shgc: 0.67,
                        operable: false,
                        wall_idref: wall)
    end
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml'].include? hpxml_file
    # Base configuration
    for i in 0..hpxml.windows.size - 1
      hpxml.windows[i].ufactor = 0.32
      hpxml.windows[i].shgc = 0.4
    end
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml'].include? hpxml_file
    # Base configuration
    for i in 0..hpxml.windows.size - 1
      hpxml.windows[i].ufactor = 0.35
      hpxml.windows[i].shgc = 0.25
    end
  elsif ['RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-11.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-11.xml'].include? hpxml_file
    # Window SHGC set to 0.01
    for i in 0..hpxml.windows.size - 1
      hpxml.windows[i].shgc = 0.01
    end
  end
  if hpxml_file.include?('RESNET_Tests/4.1_Standard_140') ||
     hpxml_file.include?('RESNET_Tests/4.4_HVAC') ||
     hpxml_file.include?('RESNET_Tests/4.5_DSE')
    # No interior shading
    for i in 0..hpxml.windows.size - 1
      hpxml.windows[i].interior_shading_factor_summer = 1
      hpxml.windows[i].interior_shading_factor_winter = 1
    end
  else
    # Default interior shading
    for i in 0..hpxml.windows.size - 1
      hpxml.windows[i].interior_shading_factor_summer = nil
      hpxml.windows[i].interior_shading_factor_winter = nil
    end
  end
end

def set_hpxml_skylights(hpxml_file, hpxml)
end

def set_hpxml_doors(hpxml_file, hpxml)
  if ['RESNET_Tests/4.1_Standard_140/L100AC.xml',
      'RESNET_Tests/4.1_Standard_140/L100AL.xml'].include? hpxml_file
    # Base configuration
    hpxml.doors.clear()
    doors = { 'DoorSouth' => [180, 20, 'WallSouth'],
              'DoorNorth' => [0, 20, 'WallNorth'] }
    doors.each do |door_name, door_values|
      azimuth, area, wall = door_values
      hpxml.doors.add(id: door_name,
                      wall_idref: wall,
                      area: area,
                      azimuth: azimuth,
                      r_value: 3.04)
    end
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml'].include? hpxml_file
    # U-factor = 0.35
    for i in 0..hpxml.doors.size - 1
      hpxml.doors[i].r_value = (1.0 / 0.35).round(2)
    end
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml'].include? hpxml_file
    # U-factor = 0.32
    for i in 0..hpxml.doors.size - 1
      hpxml.doors[i].r_value = (1.0 / 0.32).round(2)
    end
  end
end

def set_hpxml_heating_systems(hpxml_file, hpxml)
  if ['RESNET_Tests/4.4_HVAC/HVAC2c.xml',
      'RESNET_Tests/4.4_HVAC/HVAC2d.xml',
      'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-19.xml',
      'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-20.xml',
      'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-19.xml',
      'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-20.xml'].include? hpxml_file
    hpxml.heating_systems.clear()
  elsif ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/01-L100.xml'].include? hpxml_file
    # Gas furnace with AFUE = 82%
    hpxml.heating_systems.clear()
    hpxml.heating_systems.add(id: 'HeatingSystem',
                              distribution_system_idref: 'HVACDistribution',
                              heating_system_type: HPXML::HVACTypeFurnace,
                              heating_system_fuel: HPXML::FuelTypeNaturalGas,
                              heating_capacity: -1,
                              heating_efficiency_afue: 0.82,
                              fraction_heat_load_served: 1)
  elsif ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/03-L304.xml'].include? hpxml_file
    # Electric strip heating with COP = 1.0
    hpxml.heating_systems.clear()
    hpxml.heating_systems.add(id: 'HeatingSystem',
                              heating_system_type: HPXML::HVACTypeElectricResistance,
                              heating_system_fuel: HPXML::FuelTypeElectricity,
                              heating_capacity: -1,
                              heating_efficiency_percent: 1,
                              fraction_heat_load_served: 1)
  elsif ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/04-L324.xml'].include? hpxml_file
    # Gas furnace with AFUE = 95%
    hpxml.heating_systems.clear()
    hpxml.heating_systems.add(id: 'HeatingSystem',
                              distribution_system_idref: 'HVACDistribution',
                              heating_system_type: HPXML::HVACTypeFurnace,
                              heating_system_fuel: HPXML::FuelTypeNaturalGas,
                              heating_capacity: -1,
                              heating_efficiency_afue: 0.95,
                              fraction_heat_load_served: 1)
  elsif ['RESNET_Tests/4.3_HERS_Method/L100A-03.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-03.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-03.xml'].include? hpxml_file
    # Natural gas furnace with AFUE = 78%
    hpxml.heating_systems.clear()
    hpxml.heating_systems.add(id: 'HeatingSystem',
                              distribution_system_idref: 'HVACDistribution',
                              heating_system_type: HPXML::HVACTypeFurnace,
                              heating_system_fuel: HPXML::FuelTypeNaturalGas,
                              heating_capacity: -1,
                              heating_efficiency_afue: 0.78,
                              fraction_heat_load_served: 1)
  elsif ['RESNET_Tests/4.3_HERS_Method/L100A-05.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-05.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-05.xml'].include? hpxml_file
    # Natural gas furnace with AFUE = 96%
    hpxml.heating_systems.clear()
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
    hpxml.heating_systems.clear()
    hpxml.heating_systems.add(id: 'HeatingSystem',
                              distribution_system_idref: 'HVACDistribution',
                              heating_system_type: HPXML::HVACTypeFurnace,
                              heating_system_fuel: HPXML::FuelTypeNaturalGas,
                              heating_capacity: 56100,
                              heating_efficiency_afue: 0.78,
                              fraction_heat_load_served: 1,
                              electric_auxiliary_energy: 1040)
  elsif ['RESNET_Tests/4.4_HVAC/HVAC2b.xml'].include? hpxml_file
    # Gas Furnace; 56.1 kBtu/h; AFUE = 90%; 0.000375 kW/cfm
    hpxml.heating_systems.clear()
    hpxml.heating_systems.add(id: 'HeatingSystem',
                              distribution_system_idref: 'HVACDistribution',
                              heating_system_type: HPXML::HVACTypeFurnace,
                              heating_system_fuel: HPXML::FuelTypeNaturalGas,
                              heating_capacity: 56100,
                              heating_efficiency_afue: 0.9,
                              fraction_heat_load_served: 1,
                              electric_auxiliary_energy: 780)
  elsif ['RESNET_Tests/4.4_HVAC/HVAC2e.xml'].include? hpxml_file
    # Electric Furnace; 56.1 kBtu/h; COP =1.0
    hpxml.heating_systems.clear()
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
    hpxml.heating_systems.clear()
    hpxml.heating_systems.add(id: 'HeatingSystem',
                              distribution_system_idref: 'HVACDistribution',
                              heating_system_type: HPXML::HVACTypeFurnace,
                              heating_system_fuel: HPXML::FuelTypeNaturalGas,
                              heating_capacity: 46600,
                              heating_efficiency_afue: 0.78,
                              fraction_heat_load_served: 1)
    hpxml.heating_systems[0].heating_cfm = hpxml.heating_systems[0].heating_capacity * 360.0 / 12000.0
  elsif ['RESNET_Tests/4.5_DSE/HVAC3b.xml'].include? hpxml_file
    # Change to 56.0 kBtu/h
    hpxml.heating_systems[0].heating_capacity = 56000
    hpxml.heating_systems[0].heating_cfm = hpxml.heating_systems[0].heating_capacity * 360.0 / 12000.0
  elsif ['RESNET_Tests/4.5_DSE/HVAC3c.xml'].include? hpxml_file
    # Change to 49.0 kBtu/h
    hpxml.heating_systems[0].heating_capacity = 49000
    hpxml.heating_systems[0].heating_cfm = hpxml.heating_systems[0].heating_capacity * 360.0 / 12000.0
  elsif ['RESNET_Tests/4.5_DSE/HVAC3d.xml'].include? hpxml_file
    # Change to 61.0 kBtu/h
    hpxml.heating_systems[0].heating_capacity = 61000
    hpxml.heating_systems[0].heating_cfm = hpxml.heating_systems[0].heating_capacity * 360.0 / 12000.0
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml'].include? hpxml_file
    # Heating: gas furnace AFUE = 80%
    hpxml.heating_systems.clear()
    hpxml.heating_systems.add(id: 'HeatingSystem',
                              distribution_system_idref: 'HVACDistribution',
                              heating_system_type: HPXML::HVACTypeFurnace,
                              heating_system_fuel: HPXML::FuelTypeNaturalGas,
                              heating_capacity: -1,
                              heating_efficiency_afue: 0.8,
                              fraction_heat_load_served: 1)
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-07.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-07.xml'].include? hpxml_file
    # High-efficiency gas furnace with AFUE = 96%
    hpxml.heating_systems[0].heating_efficiency_afue = 0.96
  end
end

def set_hpxml_cooling_systems(hpxml_file, hpxml)
  if ['RESNET_Tests/4.4_HVAC/HVAC2c.xml',
      'RESNET_Tests/4.4_HVAC/HVAC2d.xml',
      'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-19.xml',
      'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-20.xml',
      'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-19.xml',
      'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-20.xml'].include? hpxml_file
    hpxml.cooling_systems.clear()
  elsif ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/01-L100.xml'].include? hpxml_file
    # central air conditioner with SEER = 11.0
    hpxml.cooling_systems.clear()
    hpxml.cooling_systems.add(id: 'CoolingSystem',
                              distribution_system_idref: 'HVACDistribution',
                              cooling_system_type: HPXML::HVACTypeCentralAirConditioner,
                              cooling_system_fuel: HPXML::FuelTypeElectricity,
                              cooling_capacity: -1,
                              fraction_cool_load_served: 1,
                              cooling_efficiency_seer: 11)
  elsif ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/03-L304.xml'].include? hpxml_file
    # Central air conditioner with SEER = 15.0
    hpxml.cooling_systems.clear()
    hpxml.cooling_systems.add(id: 'CoolingSystem',
                              distribution_system_idref: 'HVACDistribution',
                              cooling_system_type: HPXML::HVACTypeCentralAirConditioner,
                              cooling_system_fuel: HPXML::FuelTypeElectricity,
                              cooling_capacity: -1,
                              fraction_cool_load_served: 1,
                              cooling_efficiency_seer: 15)
  elsif ['RESNET_Tests/4.3_HERS_Method/L100A-03.xml',
         'RESNET_Tests/4.3_HERS_Method/L100A-05.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-03.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-05.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-03.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-05.xml'].include? hpxml_file
    # Cooling system – electric A/C with SEER = 10.0
    hpxml.cooling_systems.clear()
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
    hpxml.cooling_systems.clear()
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
    hpxml.cooling_systems.clear()
    hpxml.cooling_systems.add(id: 'CoolingSystem',
                              distribution_system_idref: 'HVACDistribution',
                              cooling_system_type: HPXML::HVACTypeCentralAirConditioner,
                              cooling_system_fuel: HPXML::FuelTypeElectricity,
                              cooling_capacity: 38400,
                              fraction_cool_load_served: 1,
                              cooling_efficiency_seer: 10)
    hpxml.cooling_systems[0].cooling_cfm = hpxml.cooling_systems[0].cooling_capacity * 360.0 / 12000.0
  elsif ['RESNET_Tests/4.5_DSE/HVAC3f.xml'].include? hpxml_file
    # Change to 49.9 kBtu/h
    hpxml.cooling_systems[0].cooling_capacity = 49900
    hpxml.cooling_systems[0].cooling_cfm = hpxml.cooling_systems[0].cooling_capacity * 360.0 / 12000.0
  elsif ['RESNET_Tests/4.5_DSE/HVAC3g.xml'].include? hpxml_file
    # Change to 42.2 kBtu/h
    hpxml.cooling_systems[0].cooling_capacity = 42200
    hpxml.cooling_systems[0].cooling_cfm = hpxml.cooling_systems[0].cooling_capacity * 360.0 / 12000.0
  elsif ['RESNET_Tests/4.5_DSE/HVAC3h.xml'].include? hpxml_file
    # Change to 55.0 kBtu/h
    hpxml.cooling_systems[0].cooling_capacity = 55000
    hpxml.cooling_systems[0].cooling_cfm = hpxml.cooling_systems[0].cooling_capacity * 360.0 / 12000.0
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml'].include? hpxml_file
    # Cooling: Air conditioner SEER = 14
    hpxml.cooling_systems.clear()
    hpxml.cooling_systems.add(id: 'CoolingSystem',
                              distribution_system_idref: 'HVACDistribution',
                              cooling_system_type: HPXML::HVACTypeCentralAirConditioner,
                              cooling_system_fuel: HPXML::FuelTypeElectricity,
                              cooling_capacity: -1,
                              fraction_cool_load_served: 1,
                              cooling_efficiency_seer: 14)
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml'].include? hpxml_file
    # Cooling: Air conditioner SEER = 13
    hpxml.cooling_systems.clear()
    hpxml.cooling_systems.add(id: 'CoolingSystem',
                              distribution_system_idref: 'HVACDistribution',
                              cooling_system_type: HPXML::HVACTypeCentralAirConditioner,
                              cooling_system_fuel: HPXML::FuelTypeElectricity,
                              cooling_capacity: -1,
                              fraction_cool_load_served: 1,
                              cooling_efficiency_seer: 13)
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-14.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-14.xml'].include? hpxml_file
    # Change to high efficiency air conditioner SEER = 21
    hpxml.cooling_systems[0].cooling_efficiency_seer = 21
  end
end

def set_hpxml_heat_pumps(hpxml_file, hpxml)
  if ['RESNET_Tests/4.3_HERS_Method/L100A-03.xml',
      'RESNET_Tests/4.3_HERS_Method/L100A-05.xml',
      'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-03.xml',
      'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-05.xml',
      'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-03.xml',
      'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-05.xml'].include? hpxml_file
    hpxml.heat_pumps.clear()
  elsif ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/02-L100.xml'].include? hpxml_file
    # Electric heat pump with HSPF = 7.5 and SEER = 12.0
    hpxml.heat_pumps.clear()
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
  elsif ['RESNET_Tests/4.3_HERS_Method/L100A-01.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-01.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-01.xml'].include? hpxml_file
    # Heating system – electric HP with HSPF = 6.8
    # Cooling system – electric A/C with SEER
    hpxml.heat_pumps.clear()
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
  elsif ['RESNET_Tests/4.3_HERS_Method/L100A-04.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-04.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-04.xml'].include? hpxml_file
    # Change to a high efficiency HP with HSPF = 9.85
    hpxml.heat_pumps[0].heating_efficiency_hspf = 9.85
  elsif ['RESNET_Tests/4.4_HVAC/HVAC2c.xml'].include? hpxml_file
    # Air Source Heat Pump; 56.1 kBtu/h; HSPF = 6.8
    hpxml.heat_pumps.clear()
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
    hpxml.heat_pumps.clear()
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
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-19.xml'].include? hpxml_file
    # Heat pump HVAC system with SEER=14, HSPF = 8.2
    hpxml.heat_pumps.clear()
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
                         heating_efficiency_hspf: 8.2,
                         cooling_efficiency_seer: 14)
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-20.xml'].include? hpxml_file
    # Heat pump HVAC system with SEER=14, HSPF = 12.0
    hpxml.heat_pumps.clear()
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
                         heating_efficiency_hspf: 12,
                         cooling_efficiency_seer: 14)
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-19.xml'].include? hpxml_file
    # Heat pump HVAC system with SEER=13, HSPF = 8.2
    hpxml.heat_pumps.clear()
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
                         heating_efficiency_hspf: 8.2,
                         cooling_efficiency_seer: 13)
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-20.xml'].include? hpxml_file
    # Heat pump HVAC system with SEER=13, HSPF = 12.0
    hpxml.heat_pumps.clear()
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
                         heating_efficiency_hspf: 12,
                         cooling_efficiency_seer: 13)
  end
end

def set_hpxml_hvac_controls(hpxml_file, hpxml)
  if hpxml_file.include?('RESNET_Tests/4.1_Standard_140') ||
     hpxml_file.include?('RESNET_Tests/4.4_HVAC') ||
     hpxml_file.include?('RESNET_Tests/4.5_DSE')
    # Base configuration
    hpxml.hvac_controls.clear()
    hpxml.hvac_controls.add(id: 'HVACControl',
                            control_type: HPXML::HVACControlTypeManual,
                            heating_setpoint_temp: 68,
                            cooling_setpoint_temp: 78)
  elsif ['RESNET_Tests/4.6_Hot_Water/L100AD-HW-01.xml',
         'RESNET_Tests/4.6_Hot_Water/L100AM-HW-01.xml'].include? hpxml_file
    hpxml.hvac_controls.clear()
  end
end

def set_hpxml_hvac_distributions(hpxml_file, hpxml)
  if ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/01-L100.xml',
      'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/02-L100.xml',
      'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/03-L304.xml',
      'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/04-L324.xml',
      'RESNET_Tests/4.3_HERS_Method/L100A-01.xml',
      'RESNET_Tests/4.5_DSE/HVAC3a.xml',
      'RESNET_Tests/4.5_DSE/HVAC3e.xml',
      'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml',
      'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml',
      'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-01.xml',
      'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-01.xml'].include? hpxml_file
    hpxml.hvac_distributions.clear()
    hpxml.hvac_distributions.add(id: 'HVACDistribution',
                                 distribution_system_type: HPXML::HVACDistributionTypeAir)
  elsif ['RESNET_Tests/4.4_HVAC/HVAC1a.xml'].include? hpxml_file
    hpxml.hvac_distributions.clear()
    hpxml.hvac_distributions.add(id: 'HVACDistribution',
                                 distribution_system_type: HPXML::HVACDistributionTypeDSE,
                                 annual_cooling_dse: 1)
  elsif ['RESNET_Tests/4.4_HVAC/HVAC2a.xml'].include? hpxml_file
    hpxml.hvac_distributions.clear()
    hpxml.hvac_distributions.add(id: 'HVACDistribution',
                                 distribution_system_type: HPXML::HVACDistributionTypeDSE,
                                 annual_heating_dse: 1)
  elsif ['RESNET_Tests/4.4_HVAC/HVAC2c.xml',
         'RESNET_Tests/4.4_HVAC/HVAC2d.xml',
         'RESNET_Tests/4.4_HVAC/HVAC2e.xml'].include? hpxml_file
    hpxml.hvac_distributions.clear()
    hpxml.hvac_distributions.add(id: 'HVACDistribution',
                                 distribution_system_type: HPXML::HVACDistributionTypeDSE,
                                 annual_heating_dse: 1,
                                 annual_cooling_dse: 1)
  end
  if ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/01-L100.xml',
      'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/02-L100.xml',
      'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/03-L304.xml',
      'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/04-L324.xml',
      'RESNET_Tests/4.3_HERS_Method/L100A-01.xml',
      'RESNET_Tests/4.5_DSE/HVAC3a.xml',
      'RESNET_Tests/4.5_DSE/HVAC3e.xml',
      'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml',
      'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml',
      'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-01.xml',
      'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-08.xml',
      'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-12.xml',
      'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-01.xml',
      'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-08.xml',
      'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-12.xml'].include? hpxml_file
    # No leakage
    hpxml.hvac_distributions[0].duct_leakage_measurements.clear()
    hpxml.hvac_distributions[0].duct_leakage_measurements.add(duct_type: HPXML::DuctTypeSupply,
                                                              duct_leakage_units: HPXML::UnitsCFM25,
                                                              duct_leakage_value: 0)
    hpxml.hvac_distributions[0].duct_leakage_measurements.add(duct_type: HPXML::DuctTypeReturn,
                                                              duct_leakage_units: HPXML::UnitsCFM25,
                                                              duct_leakage_value: 0)
  elsif ['RESNET_Tests/4.5_DSE/HVAC3d.xml',
         'RESNET_Tests/4.5_DSE/HVAC3h.xml'].include? hpxml_file
    # Supply and return duct leakage = 125 cfm each
    for i in 0..hpxml.hvac_distributions[0].duct_leakage_measurements.size - 1
      hpxml.hvac_distributions[0].duct_leakage_measurements[i].duct_leakage_value = 125
    end
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-22.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-22.xml'].include? hpxml_file
    # 4 cfm25 per 100 ft2 CFA with 50% return side and 50% supply side leakage
    for i in 0..hpxml.hvac_distributions[0].duct_leakage_measurements.size - 1
      hpxml.hvac_distributions[0].duct_leakage_measurements[i].duct_leakage_value = 30.78
    end
  elsif ['RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-07.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-07.xml'].include? hpxml_file
    # 123 cfm duct leakage with 50% in supply and 50% in return
    for i in 0..hpxml.hvac_distributions[0].duct_leakage_measurements.size - 1
      hpxml.hvac_distributions[0].duct_leakage_measurements[i].duct_leakage_value = 61.5
    end
  end
  if ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/01-L100.xml',
      'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/02-L100.xml',
      'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/03-L304.xml',
      'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/04-L324.xml',
      'RESNET_Tests/4.3_HERS_Method/L100A-01.xml',
      'RESNET_Tests/4.5_DSE/HVAC3a.xml',
      'RESNET_Tests/4.5_DSE/HVAC3e.xml',
      'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-01.xml',
      'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-01.xml'].include? hpxml_file
    # Supply duct area = 308 ft2; Return duct area = 77 ft2
    # Duct R-val = 0
    # Duct Location = 100% conditioned
    hpxml.hvac_distributions[0].ducts.clear()
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
  elsif ['RESNET_Tests/4.5_DSE/HVAC3f.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-08.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-08.xml'].include? hpxml_file
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
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml'].include? hpxml_file
    # 100% in conditioned space, including air handler; R-6 duct insulation
    hpxml.hvac_distributions[0].ducts.clear()
    hpxml.hvac_distributions[0].ducts.add(duct_type: HPXML::DuctTypeSupply,
                                          duct_insulation_r_value: 6,
                                          duct_location: HPXML::LocationLivingSpace,
                                          duct_surface_area: 415.5)
    hpxml.hvac_distributions[0].ducts.add(duct_type: HPXML::DuctTypeReturn,
                                          duct_insulation_r_value: 6,
                                          duct_location: HPXML::LocationLivingSpace,
                                          duct_surface_area: 77)
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-22.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-22.xml'].include? hpxml_file
    # Change to crawlspace
    for i in 0..hpxml.hvac_distributions[0].ducts.size - 1
      hpxml.hvac_distributions[0].ducts[i].duct_location = HPXML::LocationCrawlspaceVented
    end
  elsif ['RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-07.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-07.xml'].include? hpxml_file
    # Change to 385 ft2 supply ducts and 77 ft2 return ducts in ambient temperature environment with no solar radiation
    for i in 0..hpxml.hvac_distributions[0].ducts.size - 1
      hpxml.hvac_distributions[0].ducts[i].duct_insulation_r_value = 6
      hpxml.hvac_distributions[0].ducts[i].duct_location = HPXML::LocationOutside
    end
    hpxml.hvac_distributions[0].ducts[0].duct_surface_area = 385
    hpxml.hvac_distributions[0].ducts[1].duct_surface_area = 77
  end
end

def set_hpxml_ventilation_fans(hpxml_file, hpxml)
  if hpxml_file.include?('RESNET_Tests/4.1_Standard_140') ||
     hpxml_file.include?('RESNET_Tests/4.4_HVAC') ||
     hpxml_file.include?('RESNET_Tests/4.5_DSE')
    # Base configuration
    hpxml.ventilation_fans.clear()
  elsif ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/02-L100.xml'].include? hpxml_file
    # Exhaust-only whole-dwelling mechanical ventilation
    hpxml.ventilation_fans.clear()
    hpxml.ventilation_fans.add(id: 'MechanicalVentilation',
                               fan_type: HPXML::MechVentTypeExhaust,
                               tested_flow_rate: 56.2,
                               hours_in_operation: 24,
                               fan_power: 14.7,
                               used_for_whole_building_ventilation: true)
  elsif ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/03-L304.xml'].include? hpxml_file
    # Balanced whole-dwelling mechanical ventilation without energy recovery
    hpxml.ventilation_fans.clear()
    hpxml.ventilation_fans.add(id: 'MechanicalVentilation',
                               fan_type: HPXML::MechVentTypeBalanced,
                               tested_flow_rate: 56.2,
                               hours_in_operation: 24,
                               fan_power: 14.7,
                               used_for_whole_building_ventilation: true)
  elsif ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/04-L324.xml'].include? hpxml_file
    # Balanced whole-dwelling mechanical ventilation with a 60% heat recovery system
    hpxml.ventilation_fans.clear()
    hpxml.ventilation_fans.add(id: 'MechanicalVentilation',
                               fan_type: HPXML::MechVentTypeHRV,
                               tested_flow_rate: 56.2,
                               hours_in_operation: 24,
                               sensible_recovery_efficiency: 0.6,
                               fan_power: 14.7,
                               used_for_whole_building_ventilation: true)
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml'].include? hpxml_file
    # Exhaust fan = 58.7 cfm, continuous; Fan power = 14.7 watts
    hpxml.ventilation_fans.clear()
    hpxml.ventilation_fans.add(id: 'MechanicalVentilation',
                               fan_type: HPXML::MechVentTypeExhaust,
                               tested_flow_rate: 58.7,
                               hours_in_operation: 24,
                               fan_power: 14.7,
                               used_for_whole_building_ventilation: true)
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-09.xml'].include? hpxml_file
    # Change to exhaust mechanical ventilation = 51.2 cfm continuous with fan power = 12.8 watts
    hpxml.ventilation_fans[0].tested_flow_rate = 51.2
    hpxml.ventilation_fans[0].fan_power = 12.8
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-10.xml'].include? hpxml_file
    # Change to exhaust mechanical ventilation = 66.2 cfm continuous with fan power = 16.6 watts
    hpxml.ventilation_fans[0].tested_flow_rate = 66.2
    hpxml.ventilation_fans[0].fan_power = 16.6
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-15.xml'].include? hpxml_file
    # Change to CFIS system at flow rate of 176.1 cfm and 33.33% duty cycle (8 hours per day)
    hpxml.ventilation_fans.clear()
    hpxml.ventilation_fans.add(id: 'MechanicalVentilation',
                               fan_type: HPXML::MechVentTypeCFIS,
                               tested_flow_rate: 176.1,
                               hours_in_operation: 8,
                               fan_power: 14.7,
                               used_for_whole_building_ventilation: true,
                               distribution_system_idref: 'HVACDistribution')
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml'].include? hpxml_file
    # Exhaust fan = 56.2 cfm, continuous; Fan power = 14.0 watts
    hpxml.ventilation_fans.clear()
    hpxml.ventilation_fans.add(id: 'MechanicalVentilation',
                               fan_type: HPXML::MechVentTypeExhaust,
                               tested_flow_rate: 56.2,
                               hours_in_operation: 24,
                               fan_power: 14,
                               used_for_whole_building_ventilation: true)
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-09.xml'].include? hpxml_file
    # Change to exhaust mechanical ventilation = 48.7 cfm continuous with fan power = 12.2 watts
    hpxml.ventilation_fans[0].tested_flow_rate = 48.7
    hpxml.ventilation_fans[0].fan_power = 12.2
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-10.xml'].include? hpxml_file
    # Change to exhaust mechanical ventilation = 63.7 cfm continuous with fan power = 15.9 watts
    hpxml.ventilation_fans[0].tested_flow_rate = 63.7
    hpxml.ventilation_fans[0].fan_power = 15.9
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-15.xml'].include? hpxml_file
    # Change to CFIS system at flow rate of 168.6 cfm and 33.33% duty cycle (8 hours per day)
    hpxml.ventilation_fans.clear()
    hpxml.ventilation_fans.add(id: 'MechanicalVentilation',
                               fan_type: HPXML::MechVentTypeCFIS,
                               tested_flow_rate: 168.6,
                               hours_in_operation: 8,
                               fan_power: 373,
                               used_for_whole_building_ventilation: true,
                               distribution_system_idref: 'HVACDistribution')
  end
end

def set_hpxml_water_heating_systems(hpxml_file, hpxml)
  if hpxml_file.include?('RESNET_Tests/4.1_Standard_140') ||
     hpxml_file.include?('RESNET_Tests/4.4_HVAC') ||
     hpxml_file.include?('RESNET_Tests/4.5_DSE')
    # Base configuration
    hpxml.water_heating_systems.clear()
  elsif ['RESNET_Tests/4.3_HERS_Method/L100A-01.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-01.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-01.xml'].include? hpxml_file
    # 40 gal electric with EF = 0.88
    hpxml.water_heating_systems.clear()
    hpxml.water_heating_systems.add(id: 'WaterHeater',
                                    fuel_type: HPXML::FuelTypeElectricity,
                                    water_heater_type: HPXML::WaterHeaterTypeStorage,
                                    location: HPXML::LocationLivingSpace,
                                    tank_volume: 40,
                                    fraction_dhw_load_served: 1,
                                    energy_factor: 0.88)
  elsif ['RESNET_Tests/4.3_HERS_Method/L100A-02.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-02.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-02.xml'].include? hpxml_file
    # Tankless natural gas with EF = 0.82
    hpxml.water_heating_systems.clear()
    hpxml.water_heating_systems.add(id: 'WaterHeater',
                                    fuel_type: HPXML::FuelTypeNaturalGas,
                                    water_heater_type: HPXML::WaterHeaterTypeTankless,
                                    location: HPXML::LocationLivingSpace,
                                    fraction_dhw_load_served: 1,
                                    energy_factor: 0.82)
  elsif ['RESNET_Tests/4.6_Hot_Water/L100AD-HW-01.xml',
         'RESNET_Tests/4.6_Hot_Water/L100AM-HW-01.xml'].include? hpxml_file
    # 40 gallon storage; gas; EF = 0.56; RE = 0.78; conditioned space
    hpxml.water_heating_systems.clear()
    hpxml.water_heating_systems.add(id: 'WaterHeater',
                                    fuel_type: HPXML::FuelTypeNaturalGas,
                                    water_heater_type: HPXML::WaterHeaterTypeStorage,
                                    location: HPXML::LocationLivingSpace,
                                    tank_volume: 40,
                                    fraction_dhw_load_served: 1,
                                    energy_factor: 0.56,
                                    recovery_efficiency: 0.78)
  elsif ['RESNET_Tests/4.6_Hot_Water/L100AD-HW-03.xml',
         'RESNET_Tests/4.6_Hot_Water/L100AM-HW-03.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml'].include? hpxml_file
    # 40 gallon storage; gas; EF = 0.62; RE = 0.78; conditioned space
    hpxml.water_heating_systems.clear()
    hpxml.water_heating_systems.add(id: 'WaterHeater',
                                    fuel_type: HPXML::FuelTypeNaturalGas,
                                    water_heater_type: HPXML::WaterHeaterTypeStorage,
                                    location: HPXML::LocationLivingSpace,
                                    tank_volume: 40,
                                    fraction_dhw_load_served: 1,
                                    energy_factor: 0.62,
                                    recovery_efficiency: 0.78)
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-08.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-08.xml'].include? hpxml_file
    # Tankless gas water heater with EF=0.83
    hpxml.water_heating_systems.clear()
    hpxml.water_heating_systems.add(id: 'WaterHeater',
                                    fuel_type: HPXML::FuelTypeNaturalGas,
                                    water_heater_type: HPXML::WaterHeaterTypeTankless,
                                    location: HPXML::LocationLivingSpace,
                                    fraction_dhw_load_served: 1,
                                    energy_factor: 0.83)
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-12.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-12.xml'].include? hpxml_file
    # Standard electric water heater EF = 0.95, RE = 0.98
    hpxml.water_heating_systems.clear()
    hpxml.water_heating_systems.add(id: 'WaterHeater',
                                    fuel_type: HPXML::FuelTypeElectricity,
                                    water_heater_type: HPXML::WaterHeaterTypeStorage,
                                    location: HPXML::LocationLivingSpace,
                                    tank_volume: 40,
                                    fraction_dhw_load_served: 1,
                                    energy_factor: 0.95,
                                    recovery_efficiency: 0.98)
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-13.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-13.xml'].include? hpxml_file
    # Electric heat pump water heater EF = 2.5
    hpxml.water_heating_systems.clear()
    hpxml.water_heating_systems.add(id: 'WaterHeater',
                                    fuel_type: HPXML::FuelTypeElectricity,
                                    water_heater_type: HPXML::WaterHeaterTypeHeatPump,
                                    location: HPXML::LocationLivingSpace,
                                    tank_volume: 40,
                                    fraction_dhw_load_served: 1,
                                    energy_factor: 2.5)
  end
end

def set_hpxml_hot_water_distribution(hpxml_file, hpxml)
  if hpxml_file.include?('RESNET_Tests/4.1_Standard_140') ||
     hpxml_file.include?('RESNET_Tests/4.4_HVAC') ||
     hpxml_file.include?('RESNET_Tests/4.5_DSE')
    # Base configuration
    hpxml.hot_water_distributions.clear()
  elsif ['RESNET_Tests/4.3_HERS_Method/L100A-01.xml',
         'RESNET_Tests/4.6_Hot_Water/L100AD-HW-01.xml',
         'RESNET_Tests/4.6_Hot_Water/L100AM-HW-01.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-01.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-01.xml'].include? hpxml_file
    # Standard
    hpxml.hot_water_distributions.clear()
    hpxml.hot_water_distributions.add(id: 'HotWaterDstribution',
                                      system_type: HPXML::DHWDistTypeStandard,
                                      pipe_r_value: 0.0)
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-16.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-16.xml'].include? hpxml_file
    # Change to recirculation: loop length = 156.92 ft.; branch piping length = 10 ft.; pump power = 50 watts; R-3 piping insulation; and control = none
    hpxml.hot_water_distributions[0].system_type = HPXML::DHWDistTypeRecirc
    hpxml.hot_water_distributions[0].recirculation_control_type = HPXML::DHWRecirControlTypeNone
    hpxml.hot_water_distributions[0].recirculation_piping_length = 156.92
    hpxml.hot_water_distributions[0].recirculation_branch_piping_length = 10
    hpxml.hot_water_distributions[0].recirculation_pump_power = 50
    hpxml.hot_water_distributions[0].pipe_r_value = 3
  elsif ['RESNET_Tests/4.6_Hot_Water/L100AD-HW-05.xml',
         'RESNET_Tests/4.6_Hot_Water/L100AM-HW-05.xml'].include? hpxml_file
    # Change to recirculation: Control = none; 50 W pump; Loop length is same as reference loop length; Branch length is 10 ft; All hot water pipes insulated to R-3
    hpxml.hot_water_distributions[0].system_type = HPXML::DHWDistTypeRecirc
    hpxml.hot_water_distributions[0].recirculation_control_type = HPXML::DHWRecirControlTypeNone
    hpxml.hot_water_distributions[0].recirculation_branch_piping_length = 10
    hpxml.hot_water_distributions[0].recirculation_pump_power = 50
    hpxml.hot_water_distributions[0].pipe_r_value = 3
  elsif ['RESNET_Tests/4.6_Hot_Water/L100AD-HW-06.xml',
         'RESNET_Tests/4.6_Hot_Water/L100AM-HW-06.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-17.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-17.xml'].include? hpxml_file
    # Change to recirculation: Control = manual
    hpxml.hot_water_distributions[0].recirculation_control_type = HPXML::DHWRecirControlTypeManual
  elsif ['RESNET_Tests/4.6_Hot_Water/L100AD-HW-07.xml',
         'RESNET_Tests/4.6_Hot_Water/L100AM-HW-07.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-18.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-18.xml'].include? hpxml_file
    # Change to drain Water Heat Recovery (DWHR) with all facilities connected; equal flow; DWHR eff = 54%
    hpxml.hot_water_distributions[0].dwhr_facilities_connected = HPXML::DWHRFacilitiesConnectedAll
    hpxml.hot_water_distributions[0].dwhr_equal_flow = true
    hpxml.hot_water_distributions[0].dwhr_efficiency = 0.54
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
  if hpxml_file.include?('RESNET_Tests/4.1_Standard_140') ||
     hpxml_file.include?('RESNET_Tests/4.4_HVAC') ||
     hpxml_file.include?('RESNET_Tests/4.5_DSE')
    # Base configuration
    hpxml.water_fixtures.clear()
  elsif ['RESNET_Tests/4.3_HERS_Method/L100A-01.xml',
         'RESNET_Tests/4.6_Hot_Water/L100AD-HW-01.xml',
         'RESNET_Tests/4.6_Hot_Water/L100AM-HW-01.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-01.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-01.xml'].include? hpxml_file
    # Standard
    hpxml.water_fixtures.clear()
    hpxml.water_fixtures.add(id: 'WaterFixture',
                             water_fixture_type: HPXML::WaterFixtureTypeShowerhead,
                             low_flow: false)
    hpxml.water_fixtures.add(id: 'WaterFixture2',
                             water_fixture_type: HPXML::WaterFixtureTypeFaucet,
                             low_flow: false)
  elsif ['RESNET_Tests/4.6_Hot_Water/L100AD-HW-04.xml',
         'RESNET_Tests/4.6_Hot_Water/L100AM-HW-04.xml'].include? hpxml_file
    # Low-flow
    hpxml.water_fixtures.clear()
    hpxml.water_fixtures.add(id: 'WaterFixture',
                             water_fixture_type: HPXML::WaterFixtureTypeShowerhead,
                             low_flow: true)
    hpxml.water_fixtures.add(id: 'WaterFixture2',
                             water_fixture_type: HPXML::WaterFixtureTypeFaucet,
                             low_flow: true)
  end
end

def set_hpxml_pv_systems(hpxml_file, hpxml)
end

def set_hpxml_clothes_washer(hpxml_file, hpxml)
  if hpxml_file.include?('RESNET_Tests/4.1_Standard_140') ||
     hpxml_file.include?('RESNET_Tests/4.4_HVAC') ||
     hpxml_file.include?('RESNET_Tests/4.5_DSE')
    # Base configuration
    hpxml.clothes_washers.add()
  else
    # Standard
    hpxml.clothes_washers.clear()
    hpxml.clothes_washers.add(id: 'ClothesWasher',
                              location: HPXML::LocationLivingSpace,
                              integrated_modified_energy_factor: HotWaterAndAppliances.get_clothes_washer_reference_imef(),
                              rated_annual_kwh: HotWaterAndAppliances.get_clothes_washer_reference_ler(),
                              label_electric_rate: HotWaterAndAppliances.get_clothes_washer_reference_elec_rate(),
                              label_gas_rate: HotWaterAndAppliances.get_clothes_washer_reference_gas_rate(),
                              label_annual_gas_cost: HotWaterAndAppliances.get_clothes_washer_reference_agc(),
                              capacity: HotWaterAndAppliances.get_clothes_washer_reference_cap())
  end
end

def set_hpxml_clothes_dryer(hpxml_file, hpxml)
  if hpxml_file.include?('RESNET_Tests/4.1_Standard_140') ||
     hpxml_file.include?('RESNET_Tests/4.4_HVAC') ||
     hpxml_file.include?('RESNET_Tests/4.5_DSE')
    # Base configuration
    hpxml.clothes_dryers.clear()
  elsif ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/01-L100.xml',
         'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/04-L324.xml',
         'RESNET_Tests/4.3_HERS_Method/L100A-02.xml',
         'RESNET_Tests/4.3_HERS_Method/L100A-03.xml',
         'RESNET_Tests/4.3_HERS_Method/L100A-05.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-11.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-11.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-02.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-03.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-05.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-02.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-03.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-05.xml'].include? hpxml_file
    # Standard gas
    hpxml.clothes_dryers.clear()
    hpxml.clothes_dryers.add(id: 'ClothesDryer',
                             location: HPXML::LocationLivingSpace,
                             fuel_type: HPXML::FuelTypeNaturalGas,
                             control_type: HotWaterAndAppliances.get_clothes_dryer_reference_control(),
                             combined_energy_factor: HotWaterAndAppliances.get_clothes_dryer_reference_cef(HPXML::FuelTypeNaturalGas))
  elsif ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/02-L100.xml',
         'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/03-L304.xml',
         'RESNET_Tests/4.3_HERS_Method/L100A-01.xml',
         'RESNET_Tests/4.6_Hot_Water/L100AD-HW-01.xml',
         'RESNET_Tests/4.6_Hot_Water/L100AM-HW-01.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-01.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-01.xml'].include? hpxml_file
    # Standard electric
    hpxml.clothes_dryers.clear()
    hpxml.clothes_dryers.add(id: 'ClothesDryer',
                             location: HPXML::LocationLivingSpace,
                             fuel_type: HPXML::FuelTypeElectricity,
                             control_type: HotWaterAndAppliances.get_clothes_dryer_reference_control(),
                             combined_energy_factor: HotWaterAndAppliances.get_clothes_dryer_reference_cef(HPXML::FuelTypeElectricity))
  end
end

def set_hpxml_dishwasher(hpxml_file, hpxml)
  if hpxml_file.include?('RESNET_Tests/4.1_Standard_140') ||
     hpxml_file.include?('RESNET_Tests/4.4_HVAC') ||
     hpxml_file.include?('RESNET_Tests/4.5_DSE')
    # Base configuration
    hpxml.dishwashers.clear()
  else
    # Standard
    hpxml.dishwashers.clear()
    hpxml.dishwashers.add(id: 'Dishwasher',
                          place_setting_capacity: 12,
                          energy_factor: HotWaterAndAppliances.get_dishwasher_reference_ef())
  end
end

def set_hpxml_refrigerator(hpxml_file, hpxml)
  if hpxml_file.include?('RESNET_Tests/4.1_Standard_140') ||
     hpxml_file.include?('RESNET_Tests/4.4_HVAC') ||
     hpxml_file.include?('RESNET_Tests/4.5_DSE')
    # Base configuration
    hpxml.refrigerators.clear()
  else
    # Standard
    rated_annual_kwh = HotWaterAndAppliances.get_refrigerator_reference_annual_kwh(hpxml.building_construction.number_of_bedrooms)
    hpxml.refrigerators.clear()
    hpxml.refrigerators.add(id: 'Refrigerator',
                            location: HPXML::LocationLivingSpace,
                            rated_annual_kwh: rated_annual_kwh)
  end
end

def set_hpxml_cooking_range(hpxml_file, hpxml)
  if hpxml_file.include?('RESNET_Tests/4.1_Standard_140') ||
     hpxml_file.include?('RESNET_Tests/4.4_HVAC') ||
     hpxml_file.include?('RESNET_Tests/4.5_DSE')
    # Base configuration
    hpxml.cooking_ranges.clear()
  elsif ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/01-L100.xml',
         'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/04-L324.xml',
         'RESNET_Tests/4.3_HERS_Method/L100A-02.xml',
         'RESNET_Tests/4.3_HERS_Method/L100A-03.xml',
         'RESNET_Tests/4.3_HERS_Method/L100A-05.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-11.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-11.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-02.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-03.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-05.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-02.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-03.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-05.xml'].include? hpxml_file
    # Standard gas
    hpxml.cooking_ranges.clear()
    hpxml.cooking_ranges.add(id: 'Range',
                             fuel_type: HPXML::FuelTypeNaturalGas,
                             is_induction: HotWaterAndAppliances.get_range_oven_reference_is_convection())
  elsif ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/02-L100.xml',
         'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/03-L304.xml',
         'RESNET_Tests/4.3_HERS_Method/L100A-01.xml',
         'RESNET_Tests/4.6_Hot_Water/L100AD-HW-01.xml',
         'RESNET_Tests/4.6_Hot_Water/L100AM-HW-01.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-01.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-01.xml'].include? hpxml_file
    # Standard electric
    hpxml.cooking_ranges.clear()
    hpxml.cooking_ranges.add(id: 'Range',
                             fuel_type: HPXML::FuelTypeElectricity,
                             is_induction: HotWaterAndAppliances.get_range_oven_reference_is_convection())
  end
end

def set_hpxml_oven(hpxml_file, hpxml)
  if hpxml_file.include?('RESNET_Tests/4.1_Standard_140') ||
     hpxml_file.include?('RESNET_Tests/4.4_HVAC') ||
     hpxml_file.include?('RESNET_Tests/4.5_DSE')
    # Base configuration
    hpxml.ovens.clear()
  else
    # Standard
    hpxml.ovens.clear()
    hpxml.ovens.add(id: 'Oven',
                    is_convection: HotWaterAndAppliances.get_range_oven_reference_is_induction())
  end
end

def set_hpxml_lighting(hpxml_file, hpxml)
  if hpxml_file.include?('RESNET_Tests/4.1_Standard_140') ||
     hpxml_file.include?('RESNET_Tests/4.4_HVAC') ||
     hpxml_file.include?('RESNET_Tests/4.5_DSE')
    # Base configuration
    hpxml.lighting_groups.clear()
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-21.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-21.xml'].include? hpxml_file
    # 75% high efficiency interior and exterior
    hpxml.lighting_groups.clear()
    hpxml.lighting_groups.add(id: 'Lighting_TierI_Interior',
                              location: HPXML::LocationInterior,
                              fration_of_units_in_location: 0.75,
                              third_party_certification: HPXML::LightingTypeTierI)
    hpxml.lighting_groups.add(id: 'Lighting_TierI_Exterior',
                              location: HPXML::LocationExterior,
                              fration_of_units_in_location: 0.75,
                              third_party_certification: HPXML::LightingTypeTierI)
    hpxml.lighting_groups.add(id: 'Lighting_TierI_Garage',
                              location: HPXML::LocationGarage,
                              fration_of_units_in_location: 0.0,
                              third_party_certification: HPXML::LightingTypeTierI)
    hpxml.lighting_groups.add(id: 'Lighting_TierII_Interior',
                              location: HPXML::LocationInterior,
                              fration_of_units_in_location: 0.0,
                              third_party_certification: HPXML::LightingTypeTierII)
    hpxml.lighting_groups.add(id: 'Lighting_TierII_Exterior',
                              location: HPXML::LocationExterior,
                              fration_of_units_in_location: 0.0,
                              third_party_certification: HPXML::LightingTypeTierII)
    hpxml.lighting_groups.add(id: 'Lighting_TierII_Garage',
                              location: HPXML::LocationGarage,
                              fration_of_units_in_location: 0.0,
                              third_party_certification: HPXML::LightingTypeTierII)
  else
    # ERI Reference
    fFI_int, fFI_ext, fFI_grg, fFII_int, fFII_ext, fFII_grg = Lighting.get_reference_fractions()
    hpxml.lighting_groups.clear()
    hpxml.lighting_groups.add(id: 'Lighting_TierI_Interior',
                              location: HPXML::LocationInterior,
                              fration_of_units_in_location: fFI_int,
                              third_party_certification: HPXML::LightingTypeTierI)
    hpxml.lighting_groups.add(id: 'Lighting_TierI_Exterior',
                              location: HPXML::LocationExterior,
                              fration_of_units_in_location: fFI_ext,
                              third_party_certification: HPXML::LightingTypeTierI)
    hpxml.lighting_groups.add(id: 'Lighting_TierI_Garage',
                              location: HPXML::LocationGarage,
                              fration_of_units_in_location: fFI_grg,
                              third_party_certification: HPXML::LightingTypeTierI)
    hpxml.lighting_groups.add(id: 'Lighting_TierII_Interior',
                              location: HPXML::LocationInterior,
                              fration_of_units_in_location: fFII_int,
                              third_party_certification: HPXML::LightingTypeTierII)
    hpxml.lighting_groups.add(id: 'Lighting_TierII_Exterior',
                              location: HPXML::LocationExterior,
                              fration_of_units_in_location: fFII_ext,
                              third_party_certification: HPXML::LightingTypeTierII)
    hpxml.lighting_groups.add(id: 'Lighting_TierII_Garage',
                              location: HPXML::LocationGarage,
                              fration_of_units_in_location: fFII_grg,
                              third_party_certification: HPXML::LightingTypeTierII)
  end
end

def set_hpxml_ceiling_fans(hpxml_file, hpxml)
end

def set_hpxml_plug_loads(hpxml_file, hpxml)
  if hpxml_file.include?('RESNET_Tests/4.1_Standard_140') ||
     hpxml_file.include?('RESNET_Tests/4.4_HVAC') ||
     hpxml_file.include?('RESNET_Tests/4.5_DSE')
    # Base configuration
    hpxml.plug_loads.clear()
    hpxml.plug_loads.add(id: 'PlugLoadMisc',
                         plug_load_type: HPXML::PlugLoadTypeOther,
                         kWh_per_year: 7302,
                         frac_sensible: 0.82,
                         frac_latent: 0.18)
    if ['RESNET_Tests/4.1_Standard_140/L170AC.xml',
        'RESNET_Tests/4.1_Standard_140/L170AL.xml'].include? hpxml_file
      hpxml.plug_loads[0].kWh_per_year = 0
    end
  else
    hpxml.plug_loads.clear()
  end
end

def set_hpxml_misc_load_schedule(hpxml_file, hpxml)
  if hpxml_file.include?('RESNET_Tests/4.1_Standard_140') ||
     hpxml_file.include?('RESNET_Tests/4.4_HVAC') ||
     hpxml_file.include?('RESNET_Tests/4.5_DSE')
    # Base configuration
    hpxml.set_misc_loads_schedule(weekday_fractions: '0.020, 0.020, 0.020, 0.020, 0.020, 0.034, 0.043, 0.085, 0.050, 0.030, 0.030, 0.041, 0.030, 0.025, 0.026, 0.026, 0.039, 0.042, 0.045, 0.070, 0.070, 0.073, 0.073, 0.066',
                                  weekend_fractions: '0.020, 0.020, 0.020, 0.020, 0.020, 0.034, 0.043, 0.085, 0.050, 0.030, 0.030, 0.041, 0.030, 0.025, 0.026, 0.026, 0.039, 0.042, 0.045, 0.070, 0.070, 0.073, 0.073, 0.066',
                                  monthly_multipliers: '1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0')
  else
    hpxml.set_misc_loads_schedule()
  end
end

def create_sample_hpxmls
  # Copy sample files from hpxml-measures subtree
  puts 'Copying sample files...'
  FileUtils.rm_f(Dir.glob('workflow/sample_files/*.xml'))
  FileUtils.rm_f(Dir.glob('workflow/sample_files/invalid_files/*.xml'))
  FileUtils.cp(Dir.glob('hpxml-measures/workflow/sample_files/*.xml'), 'workflow/sample_files')
  FileUtils.cp(Dir.glob('hpxml-measures/workflow/sample_files/invalid_files/*.xml'), 'workflow/sample_files/invalid_files')

  # Remove files we're not interested in
  exclude_list = ['invalid_files/bad-site-neighbor-azimuth.xml',
                  'invalid_files/cfis-with-hydronic-distribution.xml',
                  'invalid_files/clothes-washer-location.xml',
                  'invalid_files/clothes-washer-location-other.xml',
                  'invalid_files/clothes-dryer-location.xml',
                  'invalid_files/clothes-dryer-location-other.xml',
                  'invalid_files/duct-location.xml',
                  'invalid_files/duct-location-other.xml',
                  'invalid_files/duplicate-id.xml',
                  'invalid_files/heat-pump-mixed-fixed-and-autosize-capacities.xml',
                  'invalid_files/heat-pump-mixed-fixed-and-autosize-capacities2.xml',
                  'invalid_files/heat-pump-mixed-fixed-and-autosize-capacities3.xml',
                  'invalid_files/heat-pump-mixed-fixed-and-autosize-capacities4.xml',
                  'invalid_files/hvac-distribution-multiple-attached-cooling.xml',
                  'invalid_files/hvac-distribution-multiple-attached-heating.xml',
                  'invalid_files/hvac-distribution-return-duct-leakage-missing.xml',
                  'invalid_files/hvac-dse-multiple-attached-cooling.xml',
                  'invalid_files/hvac-dse-multiple-attached-heating.xml',
                  'invalid_files/hvac-invalid-distribution-system-type.xml',
                  'invalid_files/invalid-relatedhvac-desuperheater.xml',
                  'invalid_files/invalid-relatedhvac-dhw-indirect.xml',
                  'invalid_files/invalid-timestep.xml',
                  'invalid_files/invalid-window-height.xml',
                  'invalid_files/invalid-window-interior-shading.xml',
                  'invalid_files/lighting-fractions.xml',
                  'invalid_files/mismatched-slab-and-foundation-wall.xml',
                  'invalid_files/missing-surfaces.xml',
                  'invalid_files/net-area-negative-roof.xml',
                  'invalid_files/net-area-negative-wall.xml',
                  'invalid_files/orphaned-hvac-distribution.xml',
                  'invalid_files/slab-zero-exposed-perimeter.xml',
                  'invalid_files/solar-thermal-system-with-combi-tankless.xml',
                  'invalid_files/solar-thermal-system-with-desuperheater.xml',
                  'invalid_files/solar-thermal-system-with-dhw-indirect.xml',
                  'invalid_files/refrigerator-location.xml',
                  'invalid_files/refrigerator-location-other.xml',
                  'invalid_files/repeated-relatedhvac-desuperheater.xml',
                  'invalid_files/repeated-relatedhvac-dhw-indirect.xml',
                  'invalid_files/unattached-cfis.xml',
                  'invalid_files/unattached-door.xml',
                  'invalid_files/unattached-hvac-distribution.xml',
                  'invalid_files/unattached-skylight.xml',
                  'invalid_files/unattached-solar-thermal-system.xml',
                  'invalid_files/unattached-window.xml',
                  'invalid_files/water-heater-location.xml',
                  'invalid_files/water-heater-location-other.xml',
                  'base-appliances-none.xml',
                  'base-appliances-wood.xml',
                  'base-dhw-combi-tankless-outside.xml',
                  'base-dhw-desuperheater-var-speed.xml',
                  'base-dhw-desuperheater-2-speed.xml',
                  'base-dhw-desuperheater-gshp.xml',
                  'base-dhw-desuperheater-tankless.xml',
                  'base-dhw-indirect-outside.xml',
                  'base-dhw-jacket-electric.xml',
                  'base-dhw-jacket-hpwh.xml',
                  'base-dhw-jacket-indirect.xml',
                  'base-dhw-tank-gas-outside.xml',
                  'base-dhw-tank-heat-pump-outside.xml',
                  'base-dhw-tank-heat-pump-with-solar.xml',
                  'base-dhw-tank-heat-pump-with-solar-fraction.xml',
                  'base-dhw-tank-wood.xml',
                  'base-dhw-tankless-electric-outside.xml',
                  'base-dhw-tankless-gas-with-solar.xml',
                  'base-dhw-tankless-gas-with-solar-fraction.xml',
                  'base-dhw-tankless-wood.xml',
                  'base-enclosure-windows-interior-shading.xml',
                  'base-enclosure-windows-none.xml',
                  'base-foundation-complex.xml',
                  'base-hvac-boiler-gas-only-no-eae.xml',
                  'base-hvac-boiler-wood-only.xml',
                  'base-hvac-central-ac-plus-air-to-air-heat-pump-heating.xml',
                  'base-hvac-dual-fuel-air-to-air-heat-pump-2-speed.xml',
                  'base-hvac-dual-fuel-air-to-air-heat-pump-var-speed.xml',
                  'base-hvac-dual-fuel-mini-split-heat-pump-ducted.xml',
                  'base-hvac-ducts-leakage-percent.xml',
                  'base-hvac-ducts-locations.xml',
                  'base-hvac-flowrate.xml',
                  'base-hvac-furnace-gas-only-no-eae.xml',
                  'base-hvac-furnace-x3-dse.xml',
                  'base-hvac-furnace-wood-only.xml',
                  'base-hvac-ideal-air.xml',
                  'base-hvac-mini-split-heat-pump-ductless-no-backup.xml',
                  'base-hvac-portable-heater-electric-only.xml',
                  'base-hvac-stove-oil-only-no-eae.xml',
                  'base-hvac-stove-wood-only.xml',
                  'base-hvac-stove-wood-pellets-only.xml',
                  'base-hvac-undersized.xml',
                  'base-hvac-wall-furnace-propane-only-no-eae.xml',
                  'base-hvac-wall-furnace-wood-only.xml',
                  'base-infiltration-ach-natural.xml',
                  'base-location-epw-filename.xml',
                  'base-mechvent-cfis-evap-cooler-only-ducted.xml',
                  'base-mechvent-exhaust-rated-flow-rate.xml',
                  'base-misc-defaults.xml',
                  'base-misc-lighting-none.xml',
                  'base-misc-timestep-10-mins.xml',
                  'base-site-neighbors.xml',
                  'base-version-2019.xml',
                  'base-version-2019A.xml',
                  'base-version-latest.xml']
  exclude_list.each do |exclude_file|
    if File.exist? "workflow/sample_files/#{exclude_file}"
      FileUtils.rm_f("workflow/sample_files/#{exclude_file}")
    else
      puts "Warning: Excluded file workflow/sample_files/#{exclude_file} not found."
    end
  end

  # Add ERI version
  hpxml_paths = []
  Dir['workflow/sample_files/*.xml'].each do |hpxml_path|
    hpxml_paths << hpxml_path
  end
  Dir['workflow/sample_files/invalid_files/*.xml'].each do |hpxml_path|
    hpxml_paths << hpxml_path
  end
  hpxml_paths.each do |hpxml_path|
    hpxml_doc = XMLHelper.parse_file(hpxml_path)
    eri_calculation = XMLHelper.create_elements_as_needed(hpxml_doc, ['HPXML', 'SoftwareInfo', 'extension', 'ERICalculation'])
    if eri_calculation.elements['Version'].nil?
      XMLHelper.add_element(eri_calculation, 'Version', 'latest')
      XMLHelper.write_file(hpxml_doc, hpxml_path)
    end
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
  command = "\"#{cli_path}\" energy_rating_index.rb -x sample_files/base.xml --hourly fuels --hourly temperatures"
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
  eri_version_change = { from: '0.7.0',
                         to: '0.8.0' }

  file_names = ['workflow/energy_rating_index.rb', 'docs/source/getting_started.rst']

  file_names.each do |file_name|
    text = File.read(file_name)
    new_contents = text.gsub(eri_version_change[:from], eri_version_change[:to])

    # To write changes to the file, use:
    File.open(file_name, 'w') { |file| file.puts new_contents }
  end

  puts 'Done. Now check all changed files before committing.'
end

if ARGV[0].to_sym == :update_measures
  require_relative 'hpxml-measures/HPXMLtoOpenStudio/resources/hpxml'

  # Prevent NREL error regarding U: drive when not VPNed in
  ENV['HOME'] = 'C:' if !ENV['HOME'].nil? && ENV['HOME'].start_with?('U:')
  ENV['HOMEDRIVE'] = 'C:\\' if !ENV['HOMEDRIVE'].nil? && ENV['HOMEDRIVE'].start_with?('U:')

  # Apply rubocop
  cops = ['Layout',
          'Lint/DeprecatedClassMethods',
          'Lint/StringConversionInInterpolation',
          'Style/AndOr',
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
  command = "openstudio -e #{commands.join(' -e ')}"
  puts 'Applying rubocop auto-correct to measures...'
  system(command)

  # Update measures XMLs
  command = "#{OpenStudio.getOpenStudioCLI} measure -t '#{File.join(File.dirname(__FILE__), 'rulesets')}'"
  puts 'Updating measure.xmls...'
  system(command, [:out, :err] => File::NULL)

  create_test_hpxmls
  create_sample_hpxmls

  puts 'Done.'
end

if ARGV[0].to_sym == :create_release_zips
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

  files = ['hpxml-measures/HPXMLtoOpenStudio/measure.*',
           'hpxml-measures/HPXMLtoOpenStudio/resources/*.*',
           'hpxml-measures/SimulationOutputReport/measure.*',
           'hpxml-measures/SimulationOutputReport/resources/*.*',
           'rulesets/301EnergyRatingIndexRuleset/measure.*',
           'rulesets/301EnergyRatingIndexRuleset/resources/*.*',
           'weather/*.*',
           'workflow/*.*',
           'workflow/sample_files/*.*',
           'documentation/index.html',
           'documentation/_static/**/*.*']

  # Only include files under git version control
  command = 'git ls-files'
  begin
    git_files = `#{command}`
  rescue
    puts "Command failed: '#{command}'. Perhaps git needs to be installed?"
    exit!
  end

  release_map = { File.join(File.dirname(__FILE__), 'release-minimal.zip') => false,
                  File.join(File.dirname(__FILE__), 'release-full.zip') => true }

  release_map.keys.each do |zip_path|
    File.delete(zip_path) if File.exist? zip_path
  end

  # Check if we need to download weather files for the full release zip
  num_epws_expected = File.readlines(File.join('weather', 'data.csv')).size - 1
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
  FileUtils.rm_r(File.join(File.dirname(__FILE__), 'documentation'))

  puts 'Done.'
end
