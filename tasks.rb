# frozen_string_literal: true

OpenStudio::Logger.instance.standardOutLogger.setLogLevel(OpenStudio::Fatal)

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

  # Copy HERS HVAC files
  FileUtils.rm_f(Dir.glob('workflow/tests/RESNET_Tests/4.4_HVAC/*.xml'))
  FileUtils.cp(Dir.glob('hpxml-measures/workflow/tests/HERS_HVAC/*.xml'), 'workflow/tests/RESNET_Tests/4.4_HVAC')

  # Copy ASHRAE 140 files
  FileUtils.rm_f(Dir.glob('workflow/tests/RESNET_Tests/4.5_DSE/*.xml'))
  FileUtils.cp(Dir.glob('hpxml-measures/workflow/tests/HERS_DSE/*.xml'), 'workflow/tests/RESNET_Tests/4.5_DSE')

  # Copy HERS Hot Water files
  FileUtils.rm_f(Dir.glob('workflow/tests/RESNET_Tests/4.6_Hot_Water/*.xml'))
  FileUtils.cp(Dir.glob('hpxml-measures/workflow/tests/HERS_Hot_Water/*.xml'), 'workflow/tests/RESNET_Tests/4.6_Hot_Water')

  schema_path = File.join(File.dirname(__FILE__), 'hpxml-measures', 'HPXMLtoOpenStudio', 'resources', 'hpxml_schema', 'HPXML.xsd')
  schema_validator = XMLValidator.get_xml_validator(schema_path)

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
    'EPA_Tests/SF_National_3.3/SFNHv33_CZ2_FL_gas_slab.xml' => nil,
    'EPA_Tests/SF_National_3.3/SFNHv33_CZ4_MO_gas_vented_crawl.xml' => nil,
    'EPA_Tests/SF_National_3.3/SFNHv33_CZ6_VT_elec_cond_bsmt.xml' => nil,
    'EPA_Tests/SF_National_3.2/SFNHv32_CZ2_FL_gas_slab.xml' => nil,
    'EPA_Tests/SF_National_3.2/SFNHv32_CZ4_MO_gas_vented_crawl.xml' => nil,
    'EPA_Tests/SF_National_3.2/SFNHv32_CZ6_VT_elec_cond_bsmt.xml' => nil,
    'EPA_Tests/SF_National_3.1/SFNHv31_CZ2_FL_elec_slab.xml' => nil,
    'EPA_Tests/SF_National_3.1/SFNHv31_CZ4_MO_elec_vented_crawl.xml' => nil,
    'EPA_Tests/SF_National_3.1/SFNHv31_CZ6_VT_gas_cond_bsmt.xml' => nil,
    'EPA_Tests/SF_National_3.0/SFNHv3_CZ2_FL_gas_slab.xml' => nil,
    'EPA_Tests/SF_National_3.0/SFNHv3_CZ4_MO_gas_vented_crawl.xml' => nil,
    'EPA_Tests/SF_National_3.0/SFNHv3_CZ6_VT_elec_cond_bsmt.xml' => nil,
    'EPA_Tests/MF_National_1.3/MFNCv13_CZ2_FL_gas_ground_corner_slab.xml' => nil,
    'EPA_Tests/MF_National_1.3/MFNCv13_CZ4_MO_gas_top_corner.xml' => nil,
    'EPA_Tests/MF_National_1.3/MFNCv13_CZ6_VT_elec_middle_interior.xml' => nil,
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
    'RESNET_Tests/4.7_Multi_Climate/03_BaseCase_CZ1A_MiamiFL.xml' => nil,
    'RESNET_Tests/4.7_Multi_Climate/03_BaseCase_CZ2B_PhoenixAZ.xml' => 'RESNET_Tests/4.7_Multi_Climate/03_BaseCase_CZ1A_MiamiFL.xml',
    'RESNET_Tests/4.7_Multi_Climate/03_BaseCase_CZ3C_SanFranCA.xml' => 'RESNET_Tests/4.7_Multi_Climate/03_BaseCase_CZ1A_MiamiFL.xml',
    'RESNET_Tests/4.7_Multi_Climate/03_BaseCase_CZ4A_BaltimoreMD.xml' => 'RESNET_Tests/4.7_Multi_Climate/03_BaseCase_CZ1A_MiamiFL.xml',
    'RESNET_Tests/4.7_Multi_Climate/03_BaseCase_CZ7_DuluthMN.xml' => 'RESNET_Tests/4.7_Multi_Climate/03_BaseCase_CZ1A_MiamiFL.xml',
    'RESNET_Tests/4.7_Multi_Climate/04_AdiabaticRaisedFloor_CZ1A_MiamiFL.xml' => 'RESNET_Tests/4.7_Multi_Climate/03_BaseCase_CZ1A_MiamiFL.xml',
    'RESNET_Tests/4.7_Multi_Climate/04_AdiabaticRaisedFloor_CZ2B_PhoenixAZ.xml' => 'RESNET_Tests/4.7_Multi_Climate/03_BaseCase_CZ2B_PhoenixAZ.xml',
    'RESNET_Tests/4.7_Multi_Climate/04_AdiabaticRaisedFloor_CZ3C_SanFranCA.xml' => 'RESNET_Tests/4.7_Multi_Climate/03_BaseCase_CZ3C_SanFranCA.xml',
    'RESNET_Tests/4.7_Multi_Climate/04_AdiabaticRaisedFloor_CZ4A_BaltimoreMD.xml' => 'RESNET_Tests/4.7_Multi_Climate/03_BaseCase_CZ4A_BaltimoreMD.xml',
    'RESNET_Tests/4.7_Multi_Climate/04_AdiabaticRaisedFloor_CZ7_DuluthMN.xml' => 'RESNET_Tests/4.7_Multi_Climate/03_BaseCase_CZ7_DuluthMN.xml',
    'RESNET_Tests/4.7_Multi_Climate/05_ConditionedBasement_CZ2B_PhoenixAZ.xml' => 'RESNET_Tests/4.7_Multi_Climate/03_BaseCase_CZ2B_PhoenixAZ.xml',
    'RESNET_Tests/4.7_Multi_Climate/05_ConditionedBasement_CZ4A_BaltimoreMD.xml' => 'RESNET_Tests/4.7_Multi_Climate/03_BaseCase_CZ4A_BaltimoreMD.xml',
    'RESNET_Tests/4.7_Multi_Climate/05_ConditionedBasement_CZ7_DuluthMN.xml' => 'RESNET_Tests/4.7_Multi_Climate/03_BaseCase_CZ7_DuluthMN.xml',
    'RESNET_Tests/4.7_Multi_Climate/06_SlabOnGrade_CZ1A_MiamiFL.xml' => 'RESNET_Tests/4.7_Multi_Climate/03_BaseCase_CZ1A_MiamiFL.xml',
    'RESNET_Tests/4.7_Multi_Climate/06_SlabOnGrade_CZ2B_PhoenixAZ.xml' => 'RESNET_Tests/4.7_Multi_Climate/03_BaseCase_CZ2B_PhoenixAZ.xml',
    'RESNET_Tests/4.7_Multi_Climate/06_SlabOnGrade_CZ3C_SanFranCA.xml' => 'RESNET_Tests/4.7_Multi_Climate/03_BaseCase_CZ3C_SanFranCA.xml',
    'RESNET_Tests/4.7_Multi_Climate/06_SlabOnGrade_CZ4A_BaltimoreMD.xml' => 'RESNET_Tests/4.7_Multi_Climate/03_BaseCase_CZ4A_BaltimoreMD.xml',
    'RESNET_Tests/4.7_Multi_Climate/07_ReferenceWindows_CZ1A_MiamiFL.xml' => 'RESNET_Tests/4.7_Multi_Climate/03_BaseCase_CZ1A_MiamiFL.xml',
    'RESNET_Tests/4.7_Multi_Climate/07_ReferenceWindows_CZ2B_PhoenixAZ.xml' => 'RESNET_Tests/4.7_Multi_Climate/03_BaseCase_CZ2B_PhoenixAZ.xml',
    'RESNET_Tests/4.7_Multi_Climate/07_ReferenceWindows_CZ3C_SanFranCA.xml' => 'RESNET_Tests/4.7_Multi_Climate/03_BaseCase_CZ3C_SanFranCA.xml',
    'RESNET_Tests/4.7_Multi_Climate/07_ReferenceWindows_CZ4A_BaltimoreMD.xml' => 'RESNET_Tests/4.7_Multi_Climate/03_BaseCase_CZ4A_BaltimoreMD.xml',
    'RESNET_Tests/4.7_Multi_Climate/07_ReferenceWindows_CZ7_DuluthMN.xml' => 'RESNET_Tests/4.7_Multi_Climate/03_BaseCase_CZ7_DuluthMN.xml',
    'RESNET_Tests/4.7_Multi_Climate/08_CFIS_CZ7_DuluthMN.xml' => 'RESNET_Tests/4.7_Multi_Climate/03_BaseCase_CZ7_DuluthMN.xml',
    'RESNET_Tests/4.7_Multi_Climate/09_CFISDuctsInAttic_CZ7_DuluthMN.xml' => 'RESNET_Tests/4.7_Multi_Climate/08_CFIS_CZ7_DuluthMN.xml',
    'RESNET_Tests/4.7_Multi_Climate/10_DuctsInAttic_CZ1A_MiamiFL.xml' => 'RESNET_Tests/4.7_Multi_Climate/03_BaseCase_CZ1A_MiamiFL.xml',
    'RESNET_Tests/4.7_Multi_Climate/10_DuctsInAttic_CZ2B_PhoenixAZ.xml' => 'RESNET_Tests/4.7_Multi_Climate/03_BaseCase_CZ2B_PhoenixAZ.xml',
    'RESNET_Tests/4.7_Multi_Climate/10_DuctsInAttic_CZ3C_SanFranCA.xml' => 'RESNET_Tests/4.7_Multi_Climate/03_BaseCase_CZ3C_SanFranCA.xml',
    'RESNET_Tests/4.7_Multi_Climate/10_DuctsInAttic_CZ4A_BaltimoreMD.xml' => 'RESNET_Tests/4.7_Multi_Climate/03_BaseCase_CZ4A_BaltimoreMD.xml',
    'RESNET_Tests/4.7_Multi_Climate/10_DuctsInAttic_CZ7_DuluthMN.xml' => 'RESNET_Tests/4.7_Multi_Climate/03_BaseCase_CZ7_DuluthMN.xml',
    'RESNET_Tests/4.7_Multi_Climate/11_NoMechVent_CZ7_DuluthMN.xml' => 'RESNET_Tests/4.7_Multi_Climate/03_BaseCase_CZ7_DuluthMN.xml',
    'RESNET_Tests/4.7_Multi_Climate/12_NoMechVentDuctsInAttic_CZ7_DuluthMN.xml' => 'RESNET_Tests/4.7_Multi_Climate/03_BaseCase_CZ4A_BaltimoreMD.xml',
    'RESNET_Tests/4.7_Multi_Climate/13_HeatPump_CZ4A_BaltimoreMD.xml' => 'RESNET_Tests/4.7_Multi_Climate/03_BaseCase_CZ7_DuluthMN.xml',
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
      hpxml.buildings.add(building_id: 'MyBuilding')
      hpxml_files.each do |hpxml_file|
        if hpxml_file.include? 'RESNET_Tests/4.1_Standard_140'
          hpxml = get_standard_140_hpxml(File.join(tests_dir, hpxml_file))
          next
        end
        hpxml_bldg = hpxml.buildings[0]
        eri_version = set_hpxml_header(hpxml_file, hpxml, hpxml_bldg, orig_parent)
        set_hpxml_site(hpxml_file, hpxml_bldg)
        set_hpxml_building_construction(hpxml_file, hpxml_bldg)
        set_hpxml_building_occupancy(hpxml_file, hpxml_bldg)
        set_hpxml_climate_and_risk_zones(hpxml_file, hpxml_bldg)
        set_hpxml_attics(hpxml_file, hpxml_bldg)
        set_hpxml_foundations(hpxml_file, hpxml_bldg)
        set_hpxml_roofs(hpxml_file, hpxml_bldg)
        set_hpxml_rim_joists(hpxml_file, hpxml_bldg)
        set_hpxml_walls(hpxml_file, hpxml_bldg)
        set_hpxml_foundation_walls(hpxml_file, hpxml_bldg)
        set_hpxml_floors(hpxml_file, hpxml_bldg)
        set_hpxml_slabs(hpxml_file, hpxml_bldg)
        set_hpxml_windows(hpxml_file, hpxml_bldg)
        set_hpxml_doors(hpxml_file, hpxml_bldg)
        set_hpxml_air_infiltration_measurements(hpxml_file, hpxml_bldg)
        set_hpxml_heating_systems(hpxml_file, hpxml_bldg)
        set_hpxml_cooling_systems(hpxml_file, hpxml_bldg)
        set_hpxml_heat_pumps(hpxml_file, hpxml_bldg)
        set_hpxml_hvac_controls(hpxml_file, hpxml_bldg)
        set_hpxml_hvac_distributions(hpxml_file, hpxml_bldg)
        set_hpxml_ventilation_fans(hpxml_file, hpxml_bldg)
        set_hpxml_water_heating_systems(hpxml_file, hpxml_bldg)
        set_hpxml_hot_water_distribution(hpxml_file, hpxml_bldg)
        set_hpxml_water_fixtures(hpxml_file, hpxml_bldg)
        set_hpxml_clothes_washer(hpxml_file, eri_version, hpxml_bldg)
        set_hpxml_clothes_dryer(hpxml_file, eri_version, hpxml_bldg)
        set_hpxml_dishwasher(hpxml_file, eri_version, hpxml_bldg)
        set_hpxml_refrigerator(hpxml_file, hpxml_bldg)
        set_hpxml_cooking_range(hpxml_file, hpxml_bldg)
        set_hpxml_oven(hpxml_file, hpxml_bldg)
        set_hpxml_lighting(hpxml_file, hpxml_bldg)
        set_hpxml_plug_loads(hpxml_file, hpxml_bldg)
      end

      next if derivative.include? 'RESNET_Tests/4.1_Standard_140'

      hpxml_doc = hpxml.to_doc()

      hpxml_path = File.join(tests_dir, derivative)

      FileUtils.mkdir_p(File.dirname(hpxml_path))
      XMLHelper.write_file(hpxml_doc, hpxml_path)

      # Validate file against HPXML schema
      errors, _warnings = XMLValidator.validate_against_schema(hpxml_path, schema_validator)
      if errors.size > 0
        fail errors.to_s
      end

      # Check for additional errors
      errors = hpxml.buildings[0].check_for_errors()
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
  hpxml = HPXML.new(hpxml_path: hpxml_path)

  hpxml_bldg = hpxml.buildings[0]
  if hpxml_bldg.air_infiltration_measurements[0].infiltration_volume.nil?
    hpxml_bldg.air_infiltration_measurements[0].infiltration_volume = hpxml_bldg.building_construction.conditioned_building_volume
  end

  return hpxml
end

def set_hpxml_header(hpxml_file, hpxml, hpxml_bldg, orig_parent)
  if hpxml.header.xml_type.nil?
    hpxml.header.xml_type = 'HPXML'
    hpxml.header.xml_generated_by = 'tasks.rb'
    hpxml.header.transaction = 'create'
    hpxml.header.created_date_and_time = Time.new(2000, 1, 1, 0, 0, 0, '-07:00').strftime('%Y-%m-%dT%H:%M:%S%:z') # Hard-code to prevent diffs
    hpxml_bldg.event_type = 'proposed workscope'
  end
  if hpxml_file.include?('HERS_AutoGen') || hpxml_file.include?('HERS_Method') || hpxml_file.include?('Hot_Water')
    hpxml.header.apply_ashrae140_assumptions = nil
  end
  if hpxml_file.include?('RESNET_Tests/Other_Hot_Water_301_2014_PreAddendumA')
    hpxml.header.eri_calculation_versions = ['2014']
  elsif hpxml_file.include?('RESNET_Tests/Other_HERS_Method_301_2014_PreAddendumE') ||
        hpxml_file.include?('RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014')
    hpxml.header.eri_calculation_versions = ['2014A']
  elsif hpxml_file.include?('RESNET_Tests/Other_HERS_Method_301_2019_PreAddendumA') ||
        hpxml_file.include?('RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA') ||
        hpxml_file.include?('RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2019_PreAddendumA')
    hpxml.header.eri_calculation_versions = ['2019']
  elsif hpxml_file.include?('Other_HERS_AutoGen_IAD_Home')
    hpxml.header.eri_calculation_versions = ['2019ABCD']
  elsif hpxml_file.include?('RESNET_Tests/4.')
    hpxml.header.eri_calculation_versions = ['2022CE']
  elsif hpxml_file.include?('EPA_Tests')
    ES::AllVersions.each do |es_version|
      if hpxml_file.include? es_version
        hpxml.header.energystar_calculation_versions = [es_version]
      end
    end
    hpxml_bldg.state_code = File.basename(hpxml_file)[11..12]
  end
  hpxml_bldg.zip_code = '00000'
  if not orig_parent.nil?
    hpxml_bldg.header.extension_properties = {} if hpxml_bldg.header.extension_properties.nil?
    hpxml_bldg.header.extension_properties['ParentHPXMLFile'] = File.basename(orig_parent)
  end

  eri_version = (hpxml.header.eri_calculation_versions.nil? ? nil : hpxml.header.eri_calculation_versions[0])
  eri_version = 'latest' if eri_version.nil?
  return eri_version
end

def set_hpxml_site(hpxml_file, hpxml_bldg)
  if hpxml_file.include?('EPA_Tests')
    if hpxml_file.include?('elec')
      hpxml_bldg.site.available_fuels = [HPXML::FuelTypeElectricity]
    else
      hpxml_bldg.site.available_fuels = [HPXML::FuelTypeElectricity, HPXML::FuelTypeNaturalGas]
    end
  elsif hpxml_file.include?('HERS_AutoGen') || hpxml_file.include?('HERS_Method') || hpxml_file.include?('Hot_Water') || hpxml_file.include?('Multi_Climate')
    hpxml_bldg.site.available_fuels = [HPXML::FuelTypeElectricity, HPXML::FuelTypeNaturalGas]
  end
end

def set_hpxml_building_construction(hpxml_file, hpxml_bldg)
  hpxml_bldg.building_construction.conditioned_building_volume = nil
  if ['RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/03-L304.xml',
      'RESNET_Tests/4.3_HERS_Method/L100A-03.xml',
      'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AD-HW-01.xml',
      'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AM-HW-01.xml'].include? hpxml_file
    # 2 bedrooms
    hpxml_bldg.building_construction.number_of_bedrooms = 2
  elsif ['RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/04-L324.xml',
         'RESNET_Tests/4.3_HERS_Method/L100A-04.xml',
         'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AD-HW-02.xml',
         'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AM-HW-02.xml'].include? hpxml_file
    # 4 bedrooms
    hpxml_bldg.building_construction.number_of_bedrooms = 4
  elsif hpxml_file.include?('EPA_Tests')
    if hpxml_file.include?('SF')
      hpxml_bldg.building_construction.residential_facility_type = HPXML::ResidentialTypeSFD
      hpxml_bldg.building_construction.number_of_conditioned_floors = 2
      hpxml_bldg.building_construction.number_of_conditioned_floors_above_grade = 2
      hpxml_bldg.building_construction.number_of_bedrooms = 3
      hpxml_bldg.building_construction.conditioned_floor_area = 2376
    elsif hpxml_file.include?('MF')
      hpxml_bldg.building_construction.residential_facility_type = HPXML::ResidentialTypeApartment
      hpxml_bldg.building_construction.number_of_conditioned_floors = 1
      hpxml_bldg.building_construction.number_of_conditioned_floors_above_grade = 1
      hpxml_bldg.building_construction.number_of_bedrooms = 2
      hpxml_bldg.building_construction.conditioned_floor_area = 1200
    end
    if hpxml_file.include?('cond_bsmt')
      footprint_area = (hpxml_bldg.building_construction.conditioned_floor_area / hpxml_bldg.building_construction.number_of_conditioned_floors)
      hpxml_bldg.building_construction.number_of_conditioned_floors += 1
      hpxml_bldg.building_construction.conditioned_floor_area += footprint_area
    end
  elsif hpxml_file.include?('Multi_Climate')
    if hpxml_file.include?('ConditionedBasement')
      hpxml_bldg.building_construction.number_of_conditioned_floors = 3
      hpxml_bldg.building_construction.conditioned_floor_area = 3600
    else
      hpxml_bldg.building_construction.number_of_conditioned_floors = 2
      hpxml_bldg.building_construction.conditioned_floor_area = 2400
    end
    hpxml_bldg.building_construction.residential_facility_type = HPXML::ResidentialTypeSFD
    hpxml_bldg.building_construction.number_of_bedrooms = 3
    hpxml_bldg.building_construction.number_of_conditioned_floors_above_grade = 2
  end
end

def set_hpxml_building_occupancy(hpxml_file, hpxml_bldg)
  if hpxml_file.include?('HERS_AutoGen') || hpxml_file.include?('HERS_Method') || hpxml_file.include?('Hot_Water')
    hpxml_bldg.building_occupancy.number_of_residents = nil
  end
end

def set_hpxml_climate_and_risk_zones(hpxml_file, hpxml_bldg)
  if ['RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/01-L100.xml'].include?(hpxml_file) ||
     hpxml_file.include?('BaltimoreMD')
    # Baltimore
    hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs.clear
    hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs.add(year: 2006,
                                                             zone: '4A')
    hpxml_bldg.climate_and_risk_zones.weather_station_id = 'WeatherStation'
    hpxml_bldg.climate_and_risk_zones.weather_station_name = 'Baltimore, MD'
    hpxml_bldg.climate_and_risk_zones.weather_station_epw_filepath = 'USA_MD_Baltimore-Washington.Intl.AP.724060_TMY3.epw'
    hpxml_bldg.state_code = 'MD'
  elsif ['RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/02-L100.xml'].include?(hpxml_file)
    # Dallas
    hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs.clear
    hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs.add(year: 2006,
                                                             zone: '3A')
    hpxml_bldg.climate_and_risk_zones.weather_station_id = 'WeatherStation'
    hpxml_bldg.climate_and_risk_zones.weather_station_name = 'Dallas, TX'
    hpxml_bldg.climate_and_risk_zones.weather_station_epw_filepath = 'USA_TX_Dallas-Fort.Worth.Intl.AP.722590_TMY3.epw'
    hpxml_bldg.state_code = 'TX'
  elsif ['RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/03-L304.xml',
         'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AM-HW-01.xml'].include?(hpxml_file) ||
        hpxml_file.include?('MiamiFL')
    # Miami
    hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs.clear
    hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs.add(year: 2006,
                                                             zone: '1A')
    hpxml_bldg.climate_and_risk_zones.weather_station_id = 'WeatherStation'
    hpxml_bldg.climate_and_risk_zones.weather_station_name = 'Miami, FL'
    hpxml_bldg.climate_and_risk_zones.weather_station_epw_filepath = 'USA_FL_Miami.Intl.AP.722020_TMY3.epw'
    hpxml_bldg.state_code = 'FL'
  elsif ['RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AD-HW-01.xml'].include?(hpxml_file) ||
        hpxml_file.include?('DuluthMN')
    # Duluth
    hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs.clear
    hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs.add(year: 2006,
                                                             zone: '7')
    hpxml_bldg.climate_and_risk_zones.weather_station_id = 'WeatherStation'
    hpxml_bldg.climate_and_risk_zones.weather_station_name = 'Duluth, MN'
    hpxml_bldg.climate_and_risk_zones.weather_station_epw_filepath = 'USA_MN_Duluth.Intl.AP.727450_TMY3.epw'
    hpxml_bldg.state_code = 'MN'
  elsif hpxml_file.include?('HERS_AutoGen') || hpxml_file.include?('HERS_Method')
    if hpxml_bldg.climate_and_risk_zones.weather_station_epw_filepath == 'USA_CO_Colorado.Springs-Peterson.Field.724660_TMY3.epw'
      hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs.clear
      hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs.add(year: 2006,
                                                               zone: '5B')
      hpxml_bldg.state_code = 'CO'
    end
  elsif hpxml_file.include?('EPA_Tests')
    hpxml_bldg.climate_and_risk_zones.weather_station_id = 'WeatherStation'
    if hpxml_file.include?('CZ2')
      hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs.clear
      hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs.add(year: 2006,
                                                               zone: '2A')
      hpxml_bldg.climate_and_risk_zones.weather_station_name = 'Tampa, FL'
      hpxml_bldg.climate_and_risk_zones.weather_station_epw_filepath = 'USA_FL_Tampa.Intl.AP.722110_TMY3.epw'
      hpxml_bldg.state_code = 'FL'
    elsif hpxml_file.include?('CZ4')
      hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs.clear
      hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs.add(year: 2006,
                                                               zone: '4A')
      hpxml_bldg.climate_and_risk_zones.weather_station_name = 'St Louis, MO'
      hpxml_bldg.climate_and_risk_zones.weather_station_epw_filepath = 'USA_MO_St.Louis-Lambert.Intl.AP.724340_TMY3.epw'
      hpxml_bldg.state_code = 'MO'
    elsif hpxml_file.include?('CZ6')
      hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs.clear
      hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs.add(year: 2006,
                                                               zone: '6A')
      hpxml_bldg.climate_and_risk_zones.weather_station_name = 'Burlington, VT'
      hpxml_bldg.climate_and_risk_zones.weather_station_epw_filepath = 'USA_VT_Burlington.Intl.AP.726170_TMY3.epw'
      hpxml_bldg.state_code = 'VT'
    end
  elsif hpxml_file.include?('PhoenixAZ')
    # Phoenix
    hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs.clear
    hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs.add(year: 2006,
                                                             zone: '2B')
    hpxml_bldg.climate_and_risk_zones.weather_station_id = 'WeatherStation'
    hpxml_bldg.climate_and_risk_zones.weather_station_name = 'Phoenix, AZ'
    hpxml_bldg.climate_and_risk_zones.weather_station_epw_filepath = 'USA_AZ_Phoenix-Sky.Harbor.Intl.AP.722780_TMY3.epw'
    hpxml_bldg.state_code = 'AZ'
  elsif hpxml_file.include?('SanFranCA')
    # San Francisco
    hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs.clear
    hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs.add(year: 2006,
                                                             zone: '3C')
    hpxml_bldg.climate_and_risk_zones.weather_station_id = 'WeatherStation'
    hpxml_bldg.climate_and_risk_zones.weather_station_name = 'San Francisco, CA'
    hpxml_bldg.climate_and_risk_zones.weather_station_epw_filepath = 'USA_CA_San.Francisco.Intl.AP.724940_TMY3.epw'
    hpxml_bldg.state_code = 'CA'
  end
end

def set_hpxml_air_infiltration_measurements(hpxml_file, hpxml_bldg)
  if hpxml_file.include?('Hot_Water') ||
     ['RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2019_PreAddendumA/01-L100.xml',
      'RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2019_PreAddendumA/02-L100.xml',
      'RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2019_PreAddendumA/04-L324.xml'].include?(hpxml_file)
    # 3 ACH50
    hpxml_bldg.air_infiltration_measurements.clear
    hpxml_bldg.air_infiltration_measurements.add(id: "AirInfiltrationMeasurement#{hpxml_bldg.air_infiltration_measurements.size + 1}",
                                                 house_pressure: 50,
                                                 unit_of_measure: HPXML::UnitsACH,
                                                 air_leakage: 3,
                                                 infiltration_volume: hpxml_bldg.building_construction.conditioned_floor_area * 8.0)
  elsif ['RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2019_PreAddendumA/03-L304.xml'].include? hpxml_file
    # 5 ACH50
    hpxml_bldg.air_infiltration_measurements.clear
    hpxml_bldg.air_infiltration_measurements.add(id: "AirInfiltrationMeasurement#{hpxml_bldg.air_infiltration_measurements.size + 1}",
                                                 unit_of_measure: HPXML::UnitsACH,
                                                 house_pressure: 50,
                                                 air_leakage: 5,
                                                 infiltration_volume: hpxml_bldg.building_construction.conditioned_floor_area * 8.0)
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
           'EPA_Tests/SF_National_3.2/SFNHv32_CZ6_VT_elec_cond_bsmt.xml',
           'EPA_Tests/SF_National_3.3/SFNHv33_CZ2_FL_gas_slab.xml',
           'EPA_Tests/SF_National_3.3/SFNHv33_CZ4_MO_gas_vented_crawl.xml'].include? hpxml_file
      ach50 = 3
    elsif ['EPA_Tests/SF_National_3.3/SFNHv33_CZ6_VT_elec_cond_bsmt.xml'].include? hpxml_file
      ach50 = 2.5
    end
    hpxml_bldg.air_infiltration_measurements.clear
    hpxml_bldg.air_infiltration_measurements.add(id: "AirInfiltrationMeasurement#{hpxml_bldg.air_infiltration_measurements.size + 1}",
                                                 unit_of_measure: HPXML::UnitsACH,
                                                 house_pressure: 50,
                                                 air_leakage: ach50,
                                                 infiltration_volume: hpxml_bldg.building_construction.conditioned_floor_area * 8.5)
  elsif hpxml_file.include?('EPA_Tests/MF')
    tot_cb_area, _ext_cb_area = Defaults.get_compartmentalization_boundary_areas(hpxml_bldg, nil)
    if hpxml_file.include?('MF_National_1.3')
      air_leakage = 0.27
    else
      air_leakage = 0.3
    end
    hpxml_bldg.air_infiltration_measurements.clear
    hpxml_bldg.air_infiltration_measurements.add(id: "AirInfiltrationMeasurement#{hpxml_bldg.air_infiltration_measurements.size + 1}",
                                                 unit_of_measure: HPXML::UnitsCFM,
                                                 house_pressure: 50,
                                                 air_leakage: (air_leakage * tot_cb_area).round(3),
                                                 infiltration_volume: hpxml_bldg.building_construction.conditioned_floor_area * 8.5)
  elsif hpxml_file.include?('Multi_Climate')
    if hpxml_file.include?('ConditionedBasement')
      if hpxml_file.include?('PhoenixAZ')
        ach50 = 3.33
      elsif hpxml_file.include?('BaltimoreMD') || hpxml_file.include?('DuluthMN')
        ach50 = 2
      end
    else
      if hpxml_file.include?('MiamiFL') || hpxml_file.include?('PhoenixAZ')
        ach50 = 5
      elsif hpxml_file.include?('SanFranCA') || hpxml_file.include?('BaltimoreMD') ||
            hpxml_file.include?('DuluthMN')
        ach50 = 3
      end
    end
    hpxml_bldg.air_infiltration_measurements.clear
    hpxml_bldg.air_infiltration_measurements.add(id: "AirInfiltrationMeasurement#{hpxml_bldg.air_infiltration_measurements.size + 1}",
                                                 unit_of_measure: HPXML::UnitsACH,
                                                 house_pressure: 50,
                                                 air_leakage: ach50,
                                                 infiltration_volume: hpxml_bldg.building_construction.conditioned_floor_area * 8.5)
  end
end

def set_hpxml_attics(hpxml_file, hpxml_bldg)
  if hpxml_file.include?('EPA_Tests/SF') || hpxml_file.include?('top_corner')
    hpxml_bldg.attics.clear
    hpxml_bldg.attics.add(id: "Attic#{hpxml_bldg.attics.size + 1}",
                          attic_type: HPXML::AtticTypeVented,
                          vented_attic_sla: (1.0 / 300.0).round(6))
  elsif hpxml_file.include?('HERS_AutoGen') || hpxml_file.include?('HERS_Method') || hpxml_file.include?('Hot_Water') || hpxml_file.include?('Multi_Climate')
    hpxml_bldg.attics.clear
    hpxml_bldg.attics.add(id: "Attic#{hpxml_bldg.attics.size + 1}",
                          attic_type: HPXML::AtticTypeVented,
                          vented_attic_sla: (1.0 / 300.0).round(6))
  end
end

def set_hpxml_foundations(hpxml_file, hpxml_bldg)
  if ['RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/02-L100.xml'].include? hpxml_file
    hpxml_bldg.foundations.clear
    hpxml_bldg.foundations.add(id: "Foundation#{hpxml_bldg.foundations.size + 1}",
                               foundation_type: HPXML::FoundationTypeCrawlspaceUnvented,
                               within_infiltration_volume: false)
  elsif hpxml_file.include?('vented_crawl')
    hpxml_bldg.foundations.clear
    hpxml_bldg.foundations.add(id: "Foundation#{hpxml_bldg.foundations.size + 1}",
                               foundation_type: HPXML::FoundationTypeCrawlspaceVented,
                               vented_crawlspace_sla: (1.0 / 150.0).round(6))
  elsif hpxml_file.include?('Multi_Climate')
    hpxml_bldg.foundations.clear
    if hpxml_file.include?('SlabOnGrade')
      return
    elsif hpxml_file.include?('ConditionedBasement')
      hpxml_bldg.foundations.add(id: "Foundation#{hpxml_bldg.foundations.size + 1}",
                                 foundation_type: HPXML::FoundationTypeBasementConditioned)
    else
      hpxml_bldg.foundations.add(id: "Foundation#{hpxml_bldg.foundations.size + 1}",
                                 foundation_type: HPXML::FoundationTypeCrawlspaceVented,
                                 vented_crawlspace_sla: (1.0 / 150.0).round(6))
    end
  end
end

def set_hpxml_roofs(hpxml_file, hpxml_bldg)
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
    hpxml_bldg.roofs.clear
    hpxml_bldg.roofs.add(id: "Roof#{hpxml_bldg.roofs.size + 1}",
                         interior_adjacent_to: HPXML::LocationAtticVented,
                         area: area,
                         solar_absorptance: 0.92,
                         emittance: 0.9,
                         pitch: 9,
                         radiant_barrier: !rb_grade.nil?,
                         radiant_barrier_grade: rb_grade,
                         insulation_assembly_r_value: 1.99)
  elsif hpxml_file.include?('Multi_Climate')
    hpxml_bldg.roofs.clear
    hpxml_bldg.roofs.add(id: "Roof#{hpxml_bldg.roofs.size + 1}_Ceiling",
                         interior_adjacent_to: HPXML::LocationAtticVented,
                         area: 1307,
                         solar_absorptance: 0.75,
                         emittance: 0.9,
                         pitch: 9,
                         radiant_barrier: false,
                         insulation_assembly_r_value: 1.99)
    hpxml_bldg.roofs.add(id: "Roof#{hpxml_bldg.roofs.size + 1}_Eave",
                         interior_adjacent_to: HPXML::LocationAtticVented,
                         area: 193,
                         solar_absorptance: 0.75,
                         emittance: 0.9,
                         pitch: 9,
                         radiant_barrier: false,
                         insulation_assembly_r_value: 1.99)
  end
end

def set_hpxml_rim_joists(hpxml_file, hpxml_bldg)
  if hpxml_file.include?('EPA_Tests/SF')
    if ['EPA_Tests/SF_National_3.1/SFNHv31_CZ2_FL_elec_slab.xml',
        'EPA_Tests/SF_National_3.0/SFNHv3_CZ2_FL_gas_slab.xml',
        'EPA_Tests/SF_National_3.0/SFNHv3_CZ4_MO_gas_vented_crawl.xml'].include? hpxml_file
      assembly_r = 1.0 / 0.082
    elsif ['EPA_Tests/SF_National_3.1/SFNHv31_CZ4_MO_elec_vented_crawl.xml',
           'EPA_Tests/SF_National_3.0/SFNHv3_CZ6_VT_elec_cond_bsmt.xml'].include? hpxml_file
      assembly_r = 1.0 / 0.057
    elsif ['EPA_Tests/SF_National_3.1/SFNHv31_CZ6_VT_gas_cond_bsmt.xml'].include? hpxml_file
      assembly_r = 1.0 / 0.048
    elsif ['EPA_Tests/SF_National_3.2/SFNHv32_CZ2_FL_gas_slab.xml',
           'EPA_Tests/SF_National_3.3/SFNHv33_CZ2_FL_gas_slab.xml'].include? hpxml_file
      assembly_r = 1.0 / 0.084
    elsif ['EPA_Tests/SF_National_3.2/SFNHv32_CZ4_MO_gas_vented_crawl.xml',
           'EPA_Tests/SF_National_3.2/SFNHv32_CZ6_VT_elec_cond_bsmt.xml',
           'EPA_Tests/SF_National_3.3/SFNHv33_CZ4_MO_gas_vented_crawl.xml',
           'EPA_Tests/SF_National_3.3/SFNHv33_CZ6_VT_elec_cond_bsmt.xml'].include? hpxml_file
      assembly_r = 1.0 / 0.045
    end
    hpxml_bldg.rim_joists.clear
    hpxml_bldg.rim_joists.add(id: "RimJoist#{hpxml_bldg.rim_joists.size + 1}",
                              exterior_adjacent_to: HPXML::LocationOutside,
                              interior_adjacent_to: HPXML::LocationConditionedSpace,
                              area: 152,
                              solar_absorptance: 0.75,
                              emittance: 0.9,
                              insulation_assembly_r_value: assembly_r.round(3))
    if hpxml_file.include?('cond_bsmt')
      interior_adjacent_to = HPXML::LocationBasementConditioned
    elsif hpxml_file.include?('vented_crawl')
      interior_adjacent_to = HPXML::LocationCrawlspaceVented
      assembly_r = 4.0
    elsif hpxml_file.include?('slab')
      interior_adjacent_to = nil
    end
    if not interior_adjacent_to.nil?
      hpxml_bldg.rim_joists.add(id: "RimJoist#{hpxml_bldg.rim_joists.size + 1}",
                                exterior_adjacent_to: HPXML::LocationOutside,
                                interior_adjacent_to: interior_adjacent_to,
                                area: 152,
                                solar_absorptance: 0.75,
                                emittance: 0.9,
                                insulation_assembly_r_value: assembly_r.round(3))
    end
  elsif hpxml_file.include?('EPA_Tests/MF')
    if ['EPA_Tests/MF_National_1.0/MFNCv1_CZ2_FL_gas_ground_corner_slab.xml',
        'EPA_Tests/MF_National_1.0/MFNCv1_CZ4_MO_gas_top_corner.xml'].include? hpxml_file
      assembly_r = 1.0 / 0.089
    elsif ['EPA_Tests/MF_National_1.1/MFNCv11_CZ4_MO_elec_ground_corner_vented_crawl.xml',
           'EPA_Tests/MF_National_1.1/MFNCv11_CZ2_FL_elec_top_corner.xml'].include? hpxml_file
      assembly_r = 1.0 / 0.064
    elsif ['EPA_Tests/MF_National_1.1/MFNCv11_CZ6_VT_gas_ground_corner_cond_bsmt.xml',
           'EPA_Tests/MF_National_1.0/MFNCv1_CZ6_VT_elec_middle_interior.xml'].include? hpxml_file
      assembly_r = 1.0 / 0.051
    elsif ['EPA_Tests/MF_National_1.2/MFNCv12_CZ2_FL_gas_ground_corner_slab.xml',
           'EPA_Tests/MF_National_1.3/MFNCv13_CZ2_FL_gas_ground_corner_slab.xml'].include? hpxml_file
      assembly_r = 1.0 / 0.084
    elsif ['EPA_Tests/MF_National_1.2/MFNCv12_CZ4_MO_gas_top_corner.xml',
           'EPA_Tests/MF_National_1.2/MFNCv12_CZ6_VT_elec_middle_interior.xml',
           'EPA_Tests/MF_National_1.3/MFNCv13_CZ4_MO_gas_top_corner.xml',
           'EPA_Tests/MF_National_1.3/MFNCv13_CZ6_VT_elec_middle_interior.xml'].include? hpxml_file
      assembly_r = 1.0 / 0.045
    end
    if hpxml_file.include?('ground_corner') || hpxml_file.include?('top_corner')
      exterior_area = 110
      common_area = 30
    elsif hpxml_file.include?('middle_interior')
      exterior_area = 80
      common_area = 60
    end
    hpxml_bldg.rim_joists.clear
    hpxml_bldg.rim_joists.add(id: "RimJoist#{hpxml_bldg.rim_joists.size + 1}",
                              exterior_adjacent_to: HPXML::LocationOutside,
                              interior_adjacent_to: HPXML::LocationConditionedSpace,
                              area: exterior_area,
                              solar_absorptance: 0.75,
                              emittance: 0.9,
                              insulation_assembly_r_value: assembly_r.round(3))
    hpxml_bldg.rim_joists.add(id: "RimJoist#{hpxml_bldg.rim_joists.size + 1}",
                              exterior_adjacent_to: HPXML::LocationOtherHousingUnit,
                              interior_adjacent_to: HPXML::LocationConditionedSpace,
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
      hpxml_bldg.rim_joists.add(id: "RimJoist#{hpxml_bldg.rim_joists.size + 1}",
                                exterior_adjacent_to: HPXML::LocationOutside,
                                interior_adjacent_to: interior_adjacent_to,
                                area: exterior_area,
                                solar_absorptance: 0.75,
                                emittance: 0.9,
                                insulation_assembly_r_value: assembly_r.round(3))
      hpxml_bldg.rim_joists.add(id: "RimJoist#{hpxml_bldg.rim_joists.size + 1}",
                                exterior_adjacent_to: interior_adjacent_to,
                                interior_adjacent_to: interior_adjacent_to,
                                area: common_area,
                                solar_absorptance: 0.75,
                                emittance: 0.9,
                                insulation_assembly_r_value: 3.75)
    end
  end
end

def set_hpxml_walls(hpxml_file, hpxml_bldg)
  if hpxml_file.include?('EPA_Tests/SF')
    if ['EPA_Tests/SF_National_3.1/SFNHv31_CZ2_FL_elec_slab.xml',
        'EPA_Tests/SF_National_3.0/SFNHv3_CZ2_FL_gas_slab.xml',
        'EPA_Tests/SF_National_3.0/SFNHv3_CZ4_MO_gas_vented_crawl.xml'].include? hpxml_file
      assembly_r = 1.0 / 0.082
    elsif ['EPA_Tests/SF_National_3.1/SFNHv31_CZ4_MO_elec_vented_crawl.xml',
           'EPA_Tests/SF_National_3.0/SFNHv3_CZ6_VT_elec_cond_bsmt.xml'].include? hpxml_file
      assembly_r = 1.0 / 0.057
    elsif ['EPA_Tests/SF_National_3.1/SFNHv31_CZ6_VT_gas_cond_bsmt.xml'].include? hpxml_file
      assembly_r = 1.0 / 0.048
    elsif ['EPA_Tests/SF_National_3.2/SFNHv32_CZ2_FL_gas_slab.xml',
           'EPA_Tests/SF_National_3.3/SFNHv33_CZ2_FL_gas_slab.xml'].include? hpxml_file
      assembly_r = 1.0 / 0.084
    elsif ['EPA_Tests/SF_National_3.2/SFNHv32_CZ4_MO_gas_vented_crawl.xml',
           'EPA_Tests/SF_National_3.2/SFNHv32_CZ6_VT_elec_cond_bsmt.xml',
           'EPA_Tests/SF_National_3.3/SFNHv33_CZ4_MO_gas_vented_crawl.xml',
           'EPA_Tests/SF_National_3.3/SFNHv33_CZ6_VT_elec_cond_bsmt.xml'].include? hpxml_file
      assembly_r = 1.0 / 0.045
    end
    hpxml_bldg.walls.clear
    hpxml_bldg.walls.add(id: "Wall#{hpxml_bldg.walls.size + 1}",
                         exterior_adjacent_to: HPXML::LocationOutside,
                         interior_adjacent_to: HPXML::LocationConditionedSpace,
                         wall_type: HPXML::WallTypeWoodStud,
                         area: 2584,
                         solar_absorptance: 0.75,
                         emittance: 0.9,
                         insulation_assembly_r_value: assembly_r.round(3))
  elsif hpxml_file.include?('EPA_Tests/MF')
    if ['EPA_Tests/MF_National_1.0/MFNCv1_CZ2_FL_gas_ground_corner_slab.xml',
        'EPA_Tests/MF_National_1.0/MFNCv1_CZ4_MO_gas_top_corner.xml'].include? hpxml_file
      assembly_r = 1.0 / 0.089
    elsif ['EPA_Tests/MF_National_1.1/MFNCv11_CZ4_MO_elec_ground_corner_vented_crawl.xml',
           'EPA_Tests/MF_National_1.1/MFNCv11_CZ2_FL_elec_top_corner.xml'].include? hpxml_file
      assembly_r = 1.0 / 0.064
    elsif ['EPA_Tests/MF_National_1.1/MFNCv11_CZ6_VT_gas_ground_corner_cond_bsmt.xml',
           'EPA_Tests/MF_National_1.0/MFNCv1_CZ6_VT_elec_middle_interior.xml'].include? hpxml_file
      assembly_r = 1.0 / 0.051
    elsif ['EPA_Tests/MF_National_1.2/MFNCv12_CZ2_FL_gas_ground_corner_slab.xml',
           'EPA_Tests/MF_National_1.3/MFNCv13_CZ2_FL_gas_ground_corner_slab.xml'].include? hpxml_file
      assembly_r = 1.0 / 0.084
    elsif ['EPA_Tests/MF_National_1.2/MFNCv12_CZ4_MO_gas_top_corner.xml',
           'EPA_Tests/MF_National_1.2/MFNCv12_CZ6_VT_elec_middle_interior.xml',
           'EPA_Tests/MF_National_1.3/MFNCv13_CZ4_MO_gas_top_corner.xml',
           'EPA_Tests/MF_National_1.3/MFNCv13_CZ6_VT_elec_middle_interior.xml'].include? hpxml_file
      assembly_r = 1.0 / 0.045
    end
    if hpxml_file.include?('ground_corner') || hpxml_file.include?('top_corner')
      exterior_area = 935
      common_area = 255
    elsif hpxml_file.include?('middle_interior')
      exterior_area = 680
      common_area = 510
    end
    hpxml_bldg.walls.clear
    hpxml_bldg.walls.add(id: "Wall#{hpxml_bldg.walls.size + 1}",
                         exterior_adjacent_to: HPXML::LocationOutside,
                         interior_adjacent_to: HPXML::LocationConditionedSpace,
                         wall_type: HPXML::WallTypeWoodStud,
                         area: exterior_area,
                         solar_absorptance: 0.75,
                         emittance: 0.9,
                         insulation_assembly_r_value: assembly_r.round(3))
    hpxml_bldg.walls.add(id: "Wall#{hpxml_bldg.walls.size + 1}",
                         exterior_adjacent_to: HPXML::LocationOtherHousingUnit,
                         interior_adjacent_to: HPXML::LocationConditionedSpace,
                         wall_type: HPXML::WallTypeWoodStud,
                         area: common_area,
                         solar_absorptance: 0.75,
                         emittance: 0.9,
                         insulation_assembly_r_value: 3.75)
  elsif hpxml_file.include?('Multi_Climate')
    hpxml_bldg.walls.clear
    if hpxml_file.include?('MiamiFL') || hpxml_file.include?('PhoenixAZ')
      wall_r = 1.0 / 0.087
    elsif hpxml_file.include?('SanFranCA') || hpxml_file.include?('BaltimoreMD')
      wall_r = 1.0 / 0.059
    elsif hpxml_file.include?('DuluthMN')
      wall_r = 1.0 / 0.045
    end
    hpxml_bldg.walls.add(id: "Wall#{hpxml_bldg.walls.size + 1}",
                         exterior_adjacent_to: HPXML::LocationOutside,
                         interior_adjacent_to: HPXML::LocationConditionedSpace,
                         wall_type: HPXML::WallTypeWoodStud,
                         area: 2356,
                         solar_absorptance: 0.75,
                         emittance: 0.9,
                         insulation_assembly_r_value: wall_r.round(3))
  end
end

def set_hpxml_foundation_walls(hpxml_file, hpxml_bldg)
  if ['RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/02-L100.xml'].include? hpxml_file
    # Unvented crawlspace with R-7 crawlspace wall insulation
    hpxml_bldg.foundation_walls.add(id: "FoundationWall#{hpxml_bldg.foundation_walls.size + 1}",
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
    hpxml_bldg.foundation_walls.add(id: "FoundationWall#{hpxml_bldg.foundation_walls.size + 1}",
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
    hpxml_bldg.foundation_walls.add(id: "FoundationWall#{hpxml_bldg.foundation_walls.size + 1}",
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
    hpxml_bldg.foundation_walls.add(id: "FoundationWall#{hpxml_bldg.foundation_walls.size + 1}",
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
    hpxml_bldg.foundation_walls.each do |fwall|
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
  elsif hpxml_file.include?('EPA_Tests')
    if hpxml_file.include?('EPA_Tests/SF')
      exterior_perimeter = 152
      common_perimeter = 0
    elsif hpxml_file.include?('EPA_Tests/MF')
      exterior_perimeter = 110
      common_perimeter = 30
    end
    if hpxml_file.include?('vented_crawl')
      hpxml_bldg.foundation_walls.clear
      hpxml_bldg.foundation_walls.add(id: "FoundationWall#{hpxml_bldg.foundation_walls.size + 1}",
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
        hpxml_bldg.foundation_walls.add(id: "FoundationWall#{hpxml_bldg.foundation_walls.size + 1}",
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
      hpxml_bldg.foundation_walls.clear
      hpxml_bldg.foundation_walls.add(id: "FoundationWall#{hpxml_bldg.foundation_walls.size + 1}",
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
        hpxml_bldg.foundation_walls.add(id: "FoundationWall#{hpxml_bldg.foundation_walls.size + 1}",
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
  elsif hpxml_file.include?('Multi_Climate')
    hpxml_bldg.foundation_walls.clear
    if hpxml_file.include?('SlabOnGrade')
      return
    elsif hpxml_file.include?('ConditionedBasement')
      if hpxml_file.include?('PhoenixAZ')
        insulation_interior_r_value = 0
      elsif hpxml_file.include?('BaltimoreMD')
        insulation_interior_r_value = 10
      elsif hpxml_file.include?('DuluthMN')
        insulation_interior_r_value = 15
      end
      hpxml_bldg.foundation_walls.add(id: "FoundationWall#{hpxml_bldg.foundation_walls.size + 1}",
                                      exterior_adjacent_to: HPXML::LocationGround,
                                      interior_adjacent_to: HPXML::LocationBasementConditioned,
                                      height: 8.5,
                                      area: 1177.8,
                                      thickness: 6,
                                      depth_below_grade: 7.75,
                                      insulation_interior_r_value: insulation_interior_r_value,
                                      insulation_interior_distance_to_top: 0,
                                      insulation_interior_distance_to_bottom: 8.5,
                                      insulation_exterior_r_value: 0,
                                      insulation_exterior_distance_to_top: 0,
                                      insulation_exterior_distance_to_bottom: 0)
    else
      hpxml_bldg.foundation_walls.add(id: "FoundationWall#{hpxml_bldg.foundation_walls.size + 1}",
                                      exterior_adjacent_to: HPXML::LocationGround,
                                      interior_adjacent_to: HPXML::LocationCrawlspaceVented,
                                      height: 2,
                                      area: 277.2,
                                      thickness: 8,
                                      depth_below_grade: 0,
                                      insulation_interior_r_value: 0,
                                      insulation_interior_distance_to_top: 0,
                                      insulation_interior_distance_to_bottom: 0,
                                      insulation_exterior_r_value: 0,
                                      insulation_exterior_distance_to_top: 0,
                                      insulation_exterior_distance_to_bottom: 0)
    end
  end
end

def set_hpxml_floors(hpxml_file, hpxml_bldg)
  if ['RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/02-L100.xml'].include? hpxml_file
    # Uninsulated
    hpxml_bldg.floors[0].insulation_assembly_r_value = 4.24
    hpxml_bldg.floors[0].exterior_adjacent_to = HPXML::LocationCrawlspaceUnvented
  elsif ['RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/04-L324.xml'].include? hpxml_file
    hpxml_bldg.floors.delete_at(1)
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
        ceiling_assembly_r = 1.0 / 0.035
      elsif ['EPA_Tests/SF_National_3.3/SFNHv33_CZ2_FL_gas_slab.xml',
             'EPA_Tests/SF_National_3.1/SFNHv31_CZ2_FL_elec_slab.xml',
             'EPA_Tests/SF_National_3.0/SFNHv3_CZ4_MO_gas_vented_crawl.xml',
             'EPA_Tests/MF_National_1.3/MFNCv13_CZ2_FL_gas_ground_corner_slab.xml'].include? hpxml_file
        ceiling_assembly_r = 1.0 / 0.030
      elsif ['EPA_Tests/MF_National_1.1/MFNCv11_CZ2_FL_elec_top_corner.xml',
             'EPA_Tests/MF_National_1.0/MFNCv1_CZ4_MO_gas_top_corner.xml'].include? hpxml_file
        ceiling_assembly_r = 1.0 / 0.027
      elsif ['EPA_Tests/SF_National_3.3/SFNHv33_CZ4_MO_gas_vented_crawl.xml',
             'EPA_Tests/SF_National_3.3/SFNHv33_CZ6_VT_elec_cond_bsmt.xml',
             'EPA_Tests/SF_National_3.2/SFNHv32_CZ2_FL_gas_slab.xml',
             'EPA_Tests/SF_National_3.1/SFNHv31_CZ4_MO_elec_vented_crawl.xml',
             'EPA_Tests/SF_National_3.1/SFNHv31_CZ6_VT_gas_cond_bsmt.xml',
             'EPA_Tests/SF_National_3.0/SFNHv3_CZ6_VT_elec_cond_bsmt.xml',
             'EPA_Tests/MF_National_1.2/MFNCv12_CZ2_FL_gas_ground_corner_slab.xml',
             'EPA_Tests/MF_National_1.3/MFNCv13_CZ4_MO_gas_top_corner.xml'].include? hpxml_file
        ceiling_assembly_r = 1.0 / 0.026
      elsif ['EPA_Tests/SF_National_3.2/SFNHv32_CZ4_MO_gas_vented_crawl.xml',
             'EPA_Tests/SF_National_3.2/SFNHv32_CZ6_VT_elec_cond_bsmt.xml',
             'EPA_Tests/MF_National_1.2/MFNCv12_CZ4_MO_gas_top_corner.xml'].include? hpxml_file
        ceiling_assembly_r = 1.0 / 0.024
      end
    end
    hpxml_bldg.floors.add(id: "Floor#{hpxml_bldg.floors.size + 1}",
                          exterior_adjacent_to: exterior_adjacent_to,
                          interior_adjacent_to: HPXML::LocationConditionedSpace,
                          floor_type: HPXML::FloorTypeWoodFrame,
                          floor_or_ceiling: floor_or_ceiling,
                          area: area,
                          insulation_assembly_r_value: ceiling_assembly_r.round(3))
    # Floor
    if hpxml_file.include?('vented_crawl')
      if hpxml_file.include?('EPA_Tests/SF')
        floor_assembly_r = 1.0 / 0.047
      elsif hpxml_file.include?('EPA_Tests/MF')
        floor_assembly_r = 1.0 / 0.033
      end
      hpxml_bldg.floors.add(id: "Floor#{hpxml_bldg.floors.size + 1}",
                            exterior_adjacent_to: HPXML::LocationCrawlspaceVented,
                            interior_adjacent_to: HPXML::LocationConditionedSpace,
                            floor_type: HPXML::FloorTypeWoodFrame,
                            area: area,
                            insulation_assembly_r_value: floor_assembly_r.round(3))
    elsif hpxml_file.include?('top_corner') || hpxml_file.include?('middle_interior')
      hpxml_bldg.floors.add(id: "Floor#{hpxml_bldg.floors.size + 1}",
                            exterior_adjacent_to: HPXML::LocationOtherHousingUnit,
                            interior_adjacent_to: HPXML::LocationConditionedSpace,
                            floor_type: HPXML::FloorTypeWoodFrame,
                            floor_or_ceiling: HPXML::FloorOrCeilingFloor,
                            area: area,
                            insulation_assembly_r_value: 3.1)
    end
  elsif hpxml_file.include?('Multi_Climate')
    hpxml_bldg.floors.clear
    if hpxml_file.include?('MiamiFL')
      ceiling_r, eave_area = 1.0 / 0.032, 154.4
    elsif hpxml_file.include?('PhoenixAZ') || hpxml_file.include?('SanFranCA')
      ceiling_r, eave_area = 1.0 / 0.026, 217.7
    elsif hpxml_file.include?('BaltimoreMD') || hpxml_file.include?('DuluthMN')
      ceiling_r, eave_area = 1.0 / 0.020, 304.8
    end
    hpxml_bldg.floors.add(id: "Floor#{hpxml_bldg.floors.size + 1}_Ceiling",
                          exterior_adjacent_to: HPXML::LocationAtticVented,
                          interior_adjacent_to: HPXML::LocationConditionedSpace,
                          floor_type: HPXML::FloorTypeWoodFrame,
                          area: (1200.0 - eave_area).round(1),
                          insulation_assembly_r_value: ceiling_r.round(3))
    hpxml_bldg.floors.add(id: "Floor#{hpxml_bldg.floors.size + 1}_Eave",
                          exterior_adjacent_to: HPXML::LocationAtticVented,
                          interior_adjacent_to: HPXML::LocationConditionedSpace,
                          floor_type: HPXML::FloorTypeWoodFrame,
                          area: eave_area,
                          insulation_assembly_r_value: ceiling_r.round(3))
    if hpxml_file.include?('SlabOnGrade') || hpxml_file.include?('ConditionedBasement')
      return
    else
      if hpxml_file.include?('AdiabaticRaisedFloor')
        floor_carpet_r, floor_tile_r = 1.0 / 0.010, 1.0 / 0.010
      else
        if hpxml_file.include?('MiamiFL') || hpxml_file.include?('PhoenixAZ')
          floor_carpet_r, floor_tile_r = 1.0 / 0.061, 1.0 / 0.066
        elsif hpxml_file.include?('SanFranCA') || hpxml_file.include?('BaltimoreMD')
          floor_carpet_r, floor_tile_r = 1.0 / 0.047, 1.0 / 0.050
        elsif hpxml_file.include?('DuluthMN')
          floor_carpet_r, floor_tile_r = 1.0 / 0.029, 1.0 / 0.031
        end
      end
      hpxml_bldg.floors.add(id: "Floor#{hpxml_bldg.floors.size + 1}_CarpetFloor",
                            exterior_adjacent_to: HPXML::LocationCrawlspaceVented,
                            interior_adjacent_to: HPXML::LocationConditionedSpace,
                            floor_type: HPXML::FloorTypeWoodFrame,
                            area: 960,
                            insulation_assembly_r_value: floor_carpet_r.round(3))
      hpxml_bldg.floors.add(id: "Floor#{hpxml_bldg.floors.size + 1}_TileFloor",
                            exterior_adjacent_to: HPXML::LocationCrawlspaceVented,
                            interior_adjacent_to: HPXML::LocationConditionedSpace,
                            floor_type: HPXML::FloorTypeWoodFrame,
                            area: 240,
                            insulation_assembly_r_value: floor_tile_r.round(3))
    end
  end
end

def set_hpxml_slabs(hpxml_file, hpxml_bldg)
  if ['RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/02-L100.xml'].include? hpxml_file
    # Unvented crawlspace
    hpxml_bldg.slabs.add(id: "Slab#{hpxml_bldg.slabs.size + 1}",
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
  elsif hpxml_file.include?('EPA_Tests')
    if hpxml_file.include?('slab')
      interior_adjacent_to = HPXML::LocationConditionedSpace
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
    hpxml_bldg.slabs.clear
    hpxml_bldg.slabs.add(id: "Slab#{hpxml_bldg.slabs.size + 1}",
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
  elsif hpxml_file.include?('Multi_Climate')
    hpxml_bldg.slabs.clear
    if hpxml_file.include?('SlabOnGrade')
      location = HPXML::LocationConditionedSpace
      carpet_fraction, carpet_r_value = 0.0, 0.0
      if hpxml_file.include?('BaltimoreMD')
        perimeter_insulation_r_value, perimeter_insulation_depth = 10, 2
      else
        perimeter_insulation_r_value, perimeter_insulation_depth = 0, 0
      end
      depth_below_grade = 0.0
    elsif hpxml_file.include?('ConditionedBasement')
      location = HPXML::LocationBasementConditioned
      carpet_fraction, carpet_r_value = 1.0, 2.0
      perimeter_insulation_r_value, perimeter_insulation_depth = 0, 0
    else
      location = HPXML::LocationCrawlspaceVented
      carpet_fraction, carpet_r_value = 0.0, 0.0
      perimeter_insulation_r_value, perimeter_insulation_depth = 0, 0
    end
    hpxml_bldg.slabs.add(id: "Slab#{hpxml_bldg.slabs.size + 1}",
                         interior_adjacent_to: location,
                         area: 1200,
                         thickness: 0,
                         exposed_perimeter: 138.6,
                         depth_below_grade: depth_below_grade,
                         perimeter_insulation_depth: perimeter_insulation_depth,
                         under_slab_insulation_width: 0,
                         under_slab_insulation_spans_entire_slab: nil,
                         perimeter_insulation_r_value: perimeter_insulation_r_value,
                         under_slab_insulation_r_value: 0,
                         carpet_fraction: carpet_fraction,
                         carpet_r_value: carpet_r_value)
  end
end

def set_hpxml_windows(hpxml_file, hpxml_bldg)
  if hpxml_file.include?('HERS_AutoGen') || hpxml_file.include?('HERS_Method') || hpxml_file.include?('Hot_Water')
    hpxml_bldg.windows.each do |window|
      window.interior_shading_factor_summer = nil
      window.interior_shading_factor_winter = nil
      window.interior_shading_type = nil
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
    elsif ['EPA_Tests/SF_National_3.1/SFNHv31_CZ4_MO_elec_vented_crawl.xml',
           'EPA_Tests/SF_National_3.0/SFNHv3_CZ6_VT_elec_cond_bsmt.xml',
           'EPA_Tests/MF_National_1.1/MFNCv11_CZ4_MO_elec_ground_corner_vented_crawl.xml',
           'EPA_Tests/MF_National_1.0/MFNCv1_CZ6_VT_elec_middle_interior.xml'].include? hpxml_file
      ufactor = 0.30
      shgc = 0.40
    elsif ['EPA_Tests/SF_National_3.2/SFNHv32_CZ4_MO_gas_vented_crawl.xml',
           'EPA_Tests/MF_National_1.2/MFNCv12_CZ4_MO_gas_top_corner.xml'].include? hpxml_file
      ufactor = 0.30
      shgc = 0.30
    elsif ['EPA_Tests/SF_National_3.1/SFNHv31_CZ6_VT_gas_cond_bsmt.xml',
           'EPA_Tests/MF_National_1.1/MFNCv11_CZ6_VT_gas_ground_corner_cond_bsmt.xml'].include? hpxml_file
      ufactor = 0.27
      shgc = 0.40
    elsif ['EPA_Tests/SF_National_3.2/SFNHv32_CZ6_VT_elec_cond_bsmt.xml',
           'EPA_Tests/MF_National_1.2/MFNCv12_CZ6_VT_elec_middle_interior.xml'].include? hpxml_file
      ufactor = 0.27
      shgc = 0.30
    elsif ['EPA_Tests/SF_National_3.3/SFNHv33_CZ2_FL_gas_slab.xml',
           'EPA_Tests/MF_National_1.3/MFNCv13_CZ2_FL_gas_ground_corner_slab.xml'].include? hpxml_file
      ufactor = 0.32
      shgc = 0.23
    elsif ['EPA_Tests/SF_National_3.3/SFNHv33_CZ4_MO_gas_vented_crawl.xml',
           'EPA_Tests/SF_National_3.3/SFNHv33_CZ6_VT_elec_cond_bsmt.xml',
           'EPA_Tests/MF_National_1.3/MFNCv13_CZ4_MO_gas_top_corner.xml',
           'EPA_Tests/MF_National_1.3/MFNCv13_CZ6_VT_elec_middle_interior.xml'].include? hpxml_file
      ufactor = 0.25
      shgc = 0.30
    end

    cfa = hpxml_bldg.building_construction.conditioned_floor_area
    ag_bndry_wall_area, bg_bndry_wall_area = hpxml_bldg.thermal_boundary_wall_areas()
    common_wall_area = hpxml_bldg.common_wall_area()
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

    hpxml_bldg.windows.clear
    windows.each do |window_values|
      azimuth, area, wall_idref = window_values
      hpxml_bldg.windows.add(id: "Window#{hpxml_bldg.windows.size + 1}",
                             area: area,
                             azimuth: azimuth,
                             ufactor: ufactor,
                             shgc: shgc,
                             fraction_operable: 0.67,
                             attached_to_wall_idref: wall_idref,
                             performance_class: HPXML::WindowClassResidential)
    end
  elsif hpxml_file.include?('Multi_Climate')
    hpxml_bldg.windows.clear
    if hpxml_file.include?('ReferenceWindows')
      if hpxml_file.include?('MiamiFL')
        ufactor, shgc = 1.20, 0.40
      elsif hpxml_file.include?('PhoenixAZ')
        ufactor, shgc = 0.75, 0.40
      elsif hpxml_file.include?('SanFranCA')
        ufactor, shgc = 0.65, 0.40
      elsif hpxml_file.include?('BaltimoreMD')
        ufactor, shgc = 0.40, 0.40
      elsif hpxml_file.include?('DuluthMN')
        ufactor, shgc = 0.35, 0.40
      end
    else
      if hpxml_file.include?('MiamiFL')
        ufactor, shgc = 0.50, 0.25
      elsif hpxml_file.include?('PhoenixAZ')
        ufactor, shgc = 0.4, 0.25
      elsif hpxml_file.include?('SanFranCA')
        ufactor, shgc = 0.35, 0.25
      elsif hpxml_file.include?('BaltimoreMD')
        ufactor, shgc = 0.35, 0.4
      elsif hpxml_file.include?('DuluthMN')
        ufactor, shgc = 0.32, 0.4
      end
    end
    [0, 90, 180, 270].each do |azimuth|
      hpxml_bldg.windows.add(id: "Window#{hpxml_bldg.windows.size + 1}",
                             area: 108,
                             azimuth: azimuth,
                             ufactor: ufactor,
                             shgc: shgc,
                             fraction_operable: 1.0,
                             attached_to_wall_idref: hpxml_bldg.walls[0].id,
                             performance_class: HPXML::WindowClassResidential)
    end
  end
end

def set_hpxml_skylights(hpxml_file, hpxml_bldg)
end

def set_hpxml_doors(hpxml_file, hpxml_bldg)
  if hpxml_file.include?('EPA_Tests/SF')
    if hpxml_file.include?('SF_National_3.3') || hpxml_file.include?('SF_National_3.2') || hpxml_file.include?('SF_National_3.1')
      r_value = 1.0 / 0.17
    elsif hpxml_file.include?('SF_National_3.0')
      r_value = 1.0 / 0.21
    end
    doors = [[0, 21, 'Wall1'],
             [0, 21, 'Wall1']]
    hpxml_bldg.doors.clear
    doors.each do |door_values|
      azimuth, area, wall_idref = door_values
      hpxml_bldg.doors.add(id: "Door#{hpxml_bldg.doors.size + 1}",
                           attached_to_wall_idref: wall_idref,
                           area: area,
                           azimuth: azimuth,
                           r_value: r_value.round(3))
    end
  elsif hpxml_file.include?('EPA_Tests/MF')
    if hpxml_file.include?('MF_National_1.0')
      r_value = 1.0 / 0.21
    elsif hpxml_file.include?('MF_National_1.3') || hpxml_file.include?('MF_National_1.2') || hpxml_file.include?('MF_National_1.1')
      r_value = 1.0 / 0.17
    end
    doors = [[0, 21, 'Wall1']]
    hpxml_bldg.doors.clear
    doors.each do |door_values|
      azimuth, area, wall_idref = door_values
      hpxml_bldg.doors.add(id: "Door#{hpxml_bldg.doors.size + 1}",
                           attached_to_wall_idref: wall_idref,
                           area: area,
                           azimuth: azimuth,
                           r_value: r_value.round(3))
    end
  elsif hpxml_file.include?('Multi_Climate')
    hpxml_bldg.doors.clear
    if hpxml_file.include?('MiamiFL')
      r_value = 1.0 / 0.50
    elsif hpxml_file.include?('PhoenixAZ')
      r_value = 1.0 / 0.4
    elsif hpxml_file.include?('SanFranCA') || hpxml_file.include?('BaltimoreMD')
      r_value = 1.0 / 0.35
    elsif hpxml_file.include?('DuluthMN')
      r_value = 1.0 / 0.32
    end
    hpxml_bldg.doors.add(id: "Door#{hpxml_bldg.doors.size + 1}",
                         attached_to_wall_idref: hpxml_bldg.walls[0].id,
                         area: 40,
                         azimuth: 0,
                         r_value: r_value.round(3))
  end
end

def set_hpxml_heating_systems(hpxml_file, hpxml_bldg)
  if ['RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/01-L100.xml'].include? hpxml_file
    # Gas furnace with AFUE = 82%
    hpxml_bldg.heating_systems.clear
    hpxml_bldg.heating_systems.add(id: "HeatingSystem#{hpxml_bldg.heating_systems.size + 1}",
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
    hpxml_bldg.heating_systems.clear
    hpxml_bldg.heating_systems.add(id: "HeatingSystem#{hpxml_bldg.heating_systems.size + 1}",
                                   heating_system_type: HPXML::HVACTypeElectricResistance,
                                   heating_system_fuel: HPXML::FuelTypeElectricity,
                                   heating_capacity: -1,
                                   heating_efficiency_percent: 1,
                                   fraction_heat_load_served: 1)
  elsif ['RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/04-L324.xml'].include? hpxml_file
    # Gas furnace with AFUE = 95%
    hpxml_bldg.heating_systems.clear
    hpxml_bldg.heating_systems.add(id: "HeatingSystem#{hpxml_bldg.heating_systems.size + 1}",
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
    hpxml_bldg.heating_systems.clear
    hpxml_bldg.heating_systems.add(id: "HeatingSystem#{hpxml_bldg.heating_systems.size + 1}",
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
    hpxml_bldg.heating_systems.clear
    hpxml_bldg.heating_systems.add(id: "HeatingSystem#{hpxml_bldg.heating_systems.size + 1}",
                                   distribution_system_idref: 'HVACDistribution1',
                                   heating_system_type: HPXML::HVACTypeFurnace,
                                   heating_system_fuel: HPXML::FuelTypeNaturalGas,
                                   heating_capacity: -1,
                                   heating_efficiency_afue: 0.96,
                                   fraction_heat_load_served: 1,
                                   fan_watts_per_cfm: 0.58,
                                   airflow_defect_ratio: -0.25)
  elsif hpxml_file.include? 'Hot_Water'
    # Natural gas furnace with AFUE = 78%
    hpxml_bldg.heating_systems.clear
    hpxml_bldg.heating_systems.add(id: "HeatingSystem#{hpxml_bldg.heating_systems.size + 1}",
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
      if hpxml_file.include?('SF_National_3.3') || hpxml_file.include?('MF_National_1.3')
        afue = 0.95
      else
        afue = 0.90
      end
    elsif hpxml_file.include?('CZ6')
      afue = 0.95
    end

    if hpxml_file.include?('SF_National_3.3') || hpxml_file.include?('MF_National_1.3')
      fan_watts_per_cfm = 0.52
      airflow_defect_ratio = -0.075
    elsif hpxml_file.include?('SF_National_3.2') || hpxml_file.include?('MF_National_1.2')
      fan_watts_per_cfm = 0.52
      airflow_defect_ratio = -0.20
    else
      fan_watts_per_cfm = 0.58
      airflow_defect_ratio = -0.25
    end

    hpxml_bldg.heating_systems.clear
    hpxml_bldg.heating_systems.add(id: "HeatingSystem#{hpxml_bldg.heating_systems.size + 1}",
                                   distribution_system_idref: 'HVACDistribution1',
                                   heating_system_type: HPXML::HVACTypeFurnace,
                                   heating_system_fuel: HPXML::FuelTypeNaturalGas,
                                   heating_capacity: -1,
                                   heating_efficiency_afue: afue,
                                   fraction_heat_load_served: 1,
                                   fan_watts_per_cfm: fan_watts_per_cfm,
                                   airflow_defect_ratio: airflow_defect_ratio)
  elsif hpxml_file.include?('Multi_Climate')
    hpxml_bldg.heating_systems.clear
    return if hpxml_file.include?('HeatPump')

    if hpxml_file.include?('MiamiFL')
      heating_capacity = 15000
    elsif hpxml_file.include?('PhoenixAZ')
      if hpxml_file.include?('ConditionedBasement')
        heating_capacity = 22000
      else
        heating_capacity = 19000
      end
    elsif hpxml_file.include?('SanFranCA')
      heating_capacity = 17000
    elsif hpxml_file.include?('BaltimoreMD')
      heating_capacity = 31000
    elsif hpxml_file.include?('DuluthMN')
      heating_capacity = 42000
    end
    hpxml_bldg.heating_systems.add(id: "HeatingSystem#{hpxml_bldg.heating_systems.size + 1}",
                                   distribution_system_idref: 'HVACDistribution1',
                                   heating_system_type: HPXML::HVACTypeFurnace,
                                   heating_system_fuel: HPXML::FuelTypeNaturalGas,
                                   heating_capacity: heating_capacity,
                                   heating_efficiency_afue: 0.95,
                                   fraction_heat_load_served: 1,
                                   fan_watts_per_cfm: 0.58,
                                   airflow_defect_ratio: -0.25)
  end
end

def set_hpxml_cooling_systems(hpxml_file, hpxml_bldg)
  if ['RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/01-L100.xml'].include? hpxml_file
    # Central air conditioner with SEER = 11.0
    hpxml_bldg.cooling_systems.clear
    hpxml_bldg.cooling_systems.add(id: "CoolingSystem#{hpxml_bldg.cooling_systems.size + 1}",
                                   distribution_system_idref: 'HVACDistribution1',
                                   cooling_system_type: HPXML::HVACTypeCentralAirConditioner,
                                   cooling_system_fuel: HPXML::FuelTypeElectricity,
                                   cooling_capacity: -1,
                                   fraction_cool_load_served: 1,
                                   cooling_efficiency_seer: 11,
                                   cooling_efficiency_eer: 9.6,
                                   compressor_type: HPXML::HVACCompressorTypeSingleStage,
                                   fan_watts_per_cfm: 0.58,
                                   airflow_defect_ratio: -0.25,
                                   charge_defect_ratio: -0.25)
  elsif ['RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/03-L304.xml'].include? hpxml_file
    # Central air conditioner with SEER = 15.0
    hpxml_bldg.cooling_systems.clear
    hpxml_bldg.cooling_systems.add(id: "CoolingSystem#{hpxml_bldg.cooling_systems.size + 1}",
                                   distribution_system_idref: 'HVACDistribution1',
                                   cooling_system_type: HPXML::HVACTypeCentralAirConditioner,
                                   cooling_system_fuel: HPXML::FuelTypeElectricity,
                                   cooling_capacity: -1,
                                   fraction_cool_load_served: 1,
                                   cooling_efficiency_seer: 15,
                                   cooling_efficiency_eer: 12.5,
                                   compressor_type: HPXML::HVACCompressorTypeSingleStage,
                                   fan_watts_per_cfm: 0.58,
                                   airflow_defect_ratio: -0.25,
                                   charge_defect_ratio: -0.25)
  elsif ['RESNET_Tests/4.3_HERS_Method/L100A-03.xml',
         'RESNET_Tests/4.3_HERS_Method/L100A-05.xml'].include? hpxml_file
    # Cooling system – electric A/C with SEER = 10.0
    hpxml_bldg.cooling_systems.clear
    hpxml_bldg.cooling_systems.add(id: "CoolingSystem#{hpxml_bldg.cooling_systems.size + 1}",
                                   distribution_system_idref: 'HVACDistribution1',
                                   cooling_system_type: HPXML::HVACTypeCentralAirConditioner,
                                   cooling_system_fuel: HPXML::FuelTypeElectricity,
                                   cooling_capacity: -1,
                                   fraction_cool_load_served: 1,
                                   cooling_efficiency_seer: 10,
                                   cooling_efficiency_eer: 8.8,
                                   compressor_type: HPXML::HVACCompressorTypeSingleStage,
                                   fan_watts_per_cfm: 0.58,
                                   airflow_defect_ratio: -0.25,
                                   charge_defect_ratio: -0.25)
  elsif hpxml_file.include? 'Hot_Water'
    # Central air conditioner with SEER = 13.0
    hpxml_bldg.cooling_systems.clear
    hpxml_bldg.cooling_systems.add(id: "CoolingSystem#{hpxml_bldg.cooling_systems.size + 1}",
                                   distribution_system_idref: 'HVACDistribution1',
                                   cooling_system_type: HPXML::HVACTypeCentralAirConditioner,
                                   cooling_system_fuel: HPXML::FuelTypeElectricity,
                                   cooling_capacity: -1,
                                   fraction_cool_load_served: 1,
                                   cooling_efficiency_seer: 13,
                                   cooling_efficiency_eer: 11,
                                   compressor_type: HPXML::HVACCompressorTypeSingleStage,
                                   fan_watts_per_cfm: 0.58,
                                   airflow_defect_ratio: -0.25,
                                   charge_defect_ratio: -0.25)
  elsif hpxml_file.include?('EPA_Tests')
    if hpxml_file.include?('_elec_')
      return
    elsif hpxml_file.include?('CZ2')
      if hpxml_file.include?('SF_National_3.3') || hpxml_file.include?('SF_National_3.2') || hpxml_file.include?('MF_National_1.3') || hpxml_file.include?('MF_National_1.2')
        seer = 16
        eer = 13.0
        compressor_type = HPXML::HVACCompressorTypeTwoStage
      else
        seer = 14.5
        eer = 12.2
        compressor_type = HPXML::HVACCompressorTypeSingleStage
      end
    elsif hpxml_file.include?('CZ4')
      if hpxml_file.include?('SF_National_3.3') || hpxml_file.include?('SF_National_3.2') || hpxml_file.include?('MF_National_1.3') || hpxml_file.include?('MF_National_1.2')
        seer = 16
        eer = 13.0
        compressor_type = HPXML::HVACCompressorTypeTwoStage
      else
        seer = 13
        eer = 11.3
        compressor_type = HPXML::HVACCompressorTypeSingleStage
      end
    elsif hpxml_file.include?('CZ6')
      if hpxml_file.include?('SF_National_3.3') || hpxml_file.include?('SF_National_3.2') || hpxml_file.include?('MF_National_1.3') || hpxml_file.include?('MF_National_1.2')
        seer = 14
        eer = 11.9
        compressor_type = HPXML::HVACCompressorTypeSingleStage
      else
        seer = 13
        eer = 11.3
        compressor_type = HPXML::HVACCompressorTypeSingleStage
      end
    end

    if hpxml_file.include?('SF_National_3.3') || hpxml_file.include?('MF_National_1.3')
      fan_watts_per_cfm = 0.52
      airflow_defect_ratio = -0.075
      charge_defect_ratio = -0.25
    elsif hpxml_file.include?('SF_National_3.2') || hpxml_file.include?('MF_National_1.2')
      fan_watts_per_cfm = 0.52
      airflow_defect_ratio = -0.20
      charge_defect_ratio = -0.25
    else
      fan_watts_per_cfm = 0.58
      airflow_defect_ratio = -0.25
      charge_defect_ratio = -0.25
    end

    hpxml_bldg.cooling_systems.clear
    hpxml_bldg.cooling_systems.add(id: "CoolingSystem#{hpxml_bldg.cooling_systems.size + 1}",
                                   distribution_system_idref: 'HVACDistribution1',
                                   cooling_system_type: HPXML::HVACTypeCentralAirConditioner,
                                   cooling_system_fuel: HPXML::FuelTypeElectricity,
                                   cooling_capacity: -1,
                                   fraction_cool_load_served: 1,
                                   cooling_efficiency_seer: seer,
                                   cooling_efficiency_eer: eer,
                                   compressor_type: compressor_type,
                                   fan_watts_per_cfm: fan_watts_per_cfm,
                                   airflow_defect_ratio: airflow_defect_ratio,
                                   charge_defect_ratio: charge_defect_ratio)
  elsif hpxml_file.include?('Multi_Climate')
    hpxml_bldg.cooling_systems.clear
    return if hpxml_file.include?('HeatPump')

    if hpxml_file.include?('MiamiFL')
      cooling_capacity = 27000
    elsif hpxml_file.include?('PhoenixAZ')
      cooling_capacity = 39000
    elsif hpxml_file.include?('SanFranCA')
      cooling_capacity = 19000
    elsif hpxml_file.include?('BaltimoreMD')
      cooling_capacity = 25000
    elsif hpxml_file.include?('DuluthMN')
      cooling_capacity = 18000
    end
    hpxml_bldg.cooling_systems.add(id: "CoolingSystem#{hpxml_bldg.cooling_systems.size + 1}",
                                   distribution_system_idref: 'HVACDistribution1',
                                   cooling_system_type: HPXML::HVACTypeCentralAirConditioner,
                                   cooling_system_fuel: HPXML::FuelTypeElectricity,
                                   compressor_type: HPXML::HVACCompressorTypeSingleStage,
                                   cooling_capacity: cooling_capacity,
                                   fraction_cool_load_served: 1,
                                   cooling_efficiency_seer: 15,
                                   cooling_efficiency_eer: 12.4,
                                   fan_watts_per_cfm: 0.58,
                                   airflow_defect_ratio: -0.25,
                                   charge_defect_ratio: -0.25)
  end
end

def set_hpxml_heat_pumps(hpxml_file, hpxml_bldg)
  if ['RESNET_Tests/4.3_HERS_Method/L100A-03.xml',
      'RESNET_Tests/4.3_HERS_Method/L100A-05.xml'].include? hpxml_file
    hpxml_bldg.heat_pumps.clear
  elsif ['RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/02-L100.xml'].include? hpxml_file
    # Electric heat pump with HSPF = 7.5 and SEER = 12.0
    hpxml_bldg.heat_pumps.clear
    hpxml_bldg.heat_pumps.add(id: "HeatPump#{hpxml_bldg.heat_pumps.size + 1}",
                              distribution_system_idref: 'HVACDistribution1',
                              heat_pump_type: HPXML::HVACTypeHeatPumpAirToAir,
                              heat_pump_fuel: HPXML::FuelTypeElectricity,
                              cooling_capacity: -1,
                              heating_capacity: -1,
                              heating_capacity_17F: -1,
                              backup_type: HPXML::HeatPumpBackupTypeIntegrated,
                              backup_heating_fuel: HPXML::FuelTypeElectricity,
                              backup_heating_capacity: -1,
                              backup_heating_efficiency_percent: 1.0,
                              fraction_heat_load_served: 1,
                              fraction_cool_load_served: 1,
                              heating_efficiency_hspf: 7.5,
                              cooling_efficiency_seer: 12,
                              cooling_efficiency_eer: 10.3,
                              compressor_type: HPXML::HVACCompressorTypeSingleStage,
                              fan_watts_per_cfm: 0.58,
                              airflow_defect_ratio: -0.25,
                              charge_defect_ratio: -0.25)
  elsif ['RESNET_Tests/4.3_HERS_Method/L100A-01.xml'].include? hpxml_file
    # Heating system – electric HP with HSPF = 6.8
    # Cooling system – electric A/C with SEER
    hpxml_bldg.heat_pumps.clear
    hpxml_bldg.heat_pumps.add(id: "HeatPump#{hpxml_bldg.heat_pumps.size + 1}",
                              distribution_system_idref: 'HVACDistribution1',
                              heat_pump_type: HPXML::HVACTypeHeatPumpAirToAir,
                              heat_pump_fuel: HPXML::FuelTypeElectricity,
                              cooling_capacity: -1,
                              heating_capacity: -1,
                              heating_capacity_17F: -1,
                              backup_type: HPXML::HeatPumpBackupTypeIntegrated,
                              backup_heating_fuel: HPXML::FuelTypeElectricity,
                              backup_heating_capacity: -1,
                              backup_heating_efficiency_percent: 1.0,
                              fraction_heat_load_served: 1,
                              fraction_cool_load_served: 1,
                              heating_efficiency_hspf: 6.8,
                              cooling_efficiency_seer: 10,
                              cooling_efficiency_eer: 8.8,
                              compressor_type: HPXML::HVACCompressorTypeSingleStage,
                              fan_watts_per_cfm: 0.58,
                              airflow_defect_ratio: -0.25,
                              charge_defect_ratio: -0.25)
  elsif ['RESNET_Tests/4.3_HERS_Method/L100A-04.xml'].include? hpxml_file
    # Change to a high efficiency HP with HSPF = 9.85
    hpxml_bldg.heat_pumps[0].heating_efficiency_hspf = 9.85
  elsif hpxml_file.include?('EPA_Tests')
    if hpxml_file.include?('_gas_')
      return
    elsif hpxml_file.include?('CZ2')
      if hpxml_file.include?('SF_National_3.3') || hpxml_file.include?('SF_National_3.2') || hpxml_file.include?('MF_National_1.3') || hpxml_file.include?('MF_National_1.2')
        hspf = 9.2
        seer = 16
        eer = 13.0
        compressor_type = HPXML::HVACCompressorTypeTwoStage
      else
        hspf = 8.2
        seer = 15
        eer = 12.4
        compressor_type = HPXML::HVACCompressorTypeSingleStage
      end
    elsif hpxml_file.include?('CZ4')
      if hpxml_file.include?('SF_National_3.3') || hpxml_file.include?('SF_National_3.2') || hpxml_file.include?('MF_National_1.3') || hpxml_file.include?('MF_National_1.2')
        hspf = 9.2
        seer = 16
        eer = 13.0
        compressor_type = HPXML::HVACCompressorTypeTwoStage
      else
        hspf = 8.5
        seer = 15
        eer = 12.4
        compressor_type = HPXML::HVACCompressorTypeSingleStage
      end
    elsif hpxml_file.include?('CZ6')
      if hpxml_file.include?('SF_National_3.3') || hpxml_file.include?('MF_National_1.3')
        hspf = 9.5
        seer = 16
        eer = 13.0
        compressor_type = HPXML::HVACCompressorTypeTwoStage
      elsif hpxml_file.include?('SF_National_3.2') || hpxml_file.include?('MF_National_1.2')
        hspf = 9.2
        seer = 16
        eer = 13.0
        compressor_type = HPXML::HVACCompressorTypeTwoStage
      else
        hspf = 9.5
        seer = 14.5
        eer = 12.2
        compressor_type = HPXML::HVACCompressorTypeSingleStage
      end
    end

    if hpxml_file.include?('SF_National_3.3') || hpxml_file.include?('MF_National_1.3')
      fan_watts_per_cfm = 0.52
      airflow_defect_ratio = -0.075
      charge_defect_ratio = -0.25
    elsif hpxml_file.include?('SF_National_3.2') || hpxml_file.include?('MF_National_1.2')
      fan_watts_per_cfm = 0.52
      airflow_defect_ratio = -0.20
      charge_defect_ratio = -0.25
    else
      fan_watts_per_cfm = 0.58
      airflow_defect_ratio = -0.25
      charge_defect_ratio = -0.25
    end

    hpxml_bldg.heat_pumps.clear
    hpxml_bldg.heat_pumps.add(id: "HeatPump#{hpxml_bldg.heat_pumps.size + 1}",
                              distribution_system_idref: 'HVACDistribution1',
                              heat_pump_type: HPXML::HVACTypeHeatPumpAirToAir,
                              heat_pump_fuel: HPXML::FuelTypeElectricity,
                              cooling_capacity: -1,
                              heating_capacity: -1,
                              heating_capacity_17F: -1,
                              backup_type: HPXML::HeatPumpBackupTypeIntegrated,
                              backup_heating_fuel: HPXML::FuelTypeElectricity,
                              backup_heating_capacity: -1,
                              backup_heating_efficiency_percent: 1.0,
                              fraction_heat_load_served: 1,
                              fraction_cool_load_served: 1,
                              heating_efficiency_hspf: hspf,
                              cooling_efficiency_seer: seer,
                              cooling_efficiency_eer: eer,
                              compressor_type: compressor_type,
                              fan_watts_per_cfm: fan_watts_per_cfm,
                              airflow_defect_ratio: airflow_defect_ratio,
                              charge_defect_ratio: charge_defect_ratio)
  elsif hpxml_file.include?('Multi_Climate') && hpxml_file.include?('HeatPump')
    hpxml_bldg.heat_pumps.clear
    hpxml_bldg.heat_pumps.add(id: "HeatPump#{hpxml_bldg.heat_pumps.size + 1}",
                              distribution_system_idref: 'HVACDistribution1',
                              heat_pump_type: HPXML::HVACTypeHeatPumpAirToAir,
                              heat_pump_fuel: HPXML::FuelTypeElectricity,
                              compressor_type: HPXML::HVACCompressorTypeSingleStage,
                              compressor_lockout_temp: 0,
                              cooling_capacity: 25000,
                              heating_capacity: 31000,
                              heating_capacity_17F: 18290,
                              backup_type: HPXML::HeatPumpBackupTypeIntegrated,
                              backup_heating_fuel: HPXML::FuelTypeElectricity,
                              backup_heating_capacity: -1,
                              backup_heating_efficiency_percent: 1.0,
                              fraction_heat_load_served: 1,
                              fraction_cool_load_served: 1,
                              heating_efficiency_hspf: 8.2,
                              cooling_efficiency_seer: 15,
                              cooling_efficiency_eer: 12.4,
                              fan_watts_per_cfm: 0.58,
                              airflow_defect_ratio: -0.25,
                              charge_defect_ratio: -0.25)
  end
end

def set_hpxml_hvac_controls(hpxml_file, hpxml_bldg)
  if hpxml_file.include?('HERS_AutoGen') || hpxml_file.include?('HERS_Method') || hpxml_file.include?('Hot_Water') || hpxml_file.include?('Multi_Climate')
    hpxml_bldg.hvac_controls.clear
    if hpxml_bldg.heating_systems.size + hpxml_bldg.cooling_systems.size + hpxml_bldg.heat_pumps.size > 0
      hpxml_bldg.hvac_controls.add(id: "HVACControl#{hpxml_bldg.hvac_controls.size + 1}",
                                   control_type: HPXML::HVACControlTypeManual)
    end
  elsif hpxml_file.include?('EPA_Tests')
    hpxml_bldg.hvac_controls.clear
    hpxml_bldg.hvac_controls.add(id: "HVACControl#{hpxml_bldg.hvac_controls.size + 1}",
                                 control_type: HPXML::HVACControlTypeProgrammable)
  end
end

def set_hpxml_hvac_distributions(hpxml_file, hpxml_bldg)
  # Type
  if ['RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/01-L100.xml',
      'RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/02-L100.xml',
      'RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/03-L304.xml',
      'RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/04-L324.xml',
      'RESNET_Tests/4.3_HERS_Method/L100A-01.xml'].include?(hpxml_file) ||
     hpxml_file.include?('Hot_Water') ||
     hpxml_file.include?('EPA_Tests') ||
     hpxml_file.include?('Multi_Climate')
    hpxml_bldg.hvac_distributions.clear
    hpxml_bldg.hvac_distributions.add(id: "HVACDistribution#{hpxml_bldg.hvac_distributions.size + 1}",
                                      distribution_system_type: HPXML::HVACDistributionTypeAir,
                                      air_type: HPXML::AirTypeRegularVelocity)
  end

  # Leakage
  if ['RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/01-L100.xml',
      'RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/02-L100.xml',
      'RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/03-L304.xml',
      'RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/04-L324.xml',
      'RESNET_Tests/4.3_HERS_Method/L100A-01.xml'].include?(hpxml_file) ||
     hpxml_file.include?('Hot_Water') ||
     hpxml_file.include?('EPA_Tests/SF_National_3.3') ||
     hpxml_file.include?('EPA_Tests/SF_National_3.2') ||
     hpxml_file.include?('EPA_Tests/SF_National_3.1') ||
     hpxml_file.include?('EPA_Tests/MF_National_1.3') ||
     hpxml_file.include?('EPA_Tests/MF_National_1.2') ||
     hpxml_file.include?('EPA_Tests/MF_National_1.1')
    # No leakage
    hpxml_bldg.hvac_distributions[0].duct_leakage_measurements.clear
    hpxml_bldg.hvac_distributions[0].duct_leakage_measurements.add(duct_type: HPXML::DuctTypeSupply,
                                                                   duct_leakage_units: HPXML::UnitsCFM25,
                                                                   duct_leakage_value: 0,
                                                                   duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside)
    hpxml_bldg.hvac_distributions[0].duct_leakage_measurements.add(duct_type: HPXML::DuctTypeReturn,
                                                                   duct_leakage_units: HPXML::UnitsCFM25,
                                                                   duct_leakage_value: 0,
                                                                   duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside)
  elsif hpxml_file.include?('EPA_Tests')
    tot_cfm25 = 4.0 * hpxml_bldg.building_construction.conditioned_floor_area / 100.0
    hpxml_bldg.hvac_distributions[0].duct_leakage_measurements.clear
    hpxml_bldg.hvac_distributions[0].duct_leakage_measurements.add(duct_type: HPXML::DuctTypeSupply,
                                                                   duct_leakage_units: HPXML::UnitsCFM25,
                                                                   duct_leakage_value: (tot_cfm25 * 0.5).round(2),
                                                                   duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside)
    hpxml_bldg.hvac_distributions[0].duct_leakage_measurements.add(duct_type: HPXML::DuctTypeReturn,
                                                                   duct_leakage_units: HPXML::UnitsCFM25,
                                                                   duct_leakage_value: (tot_cfm25 * 0.5).round(2),
                                                                   duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside)
  elsif hpxml_file.include?('Multi_Climate')
    hpxml_bldg.hvac_distributions[0].duct_leakage_measurements.clear
    if hpxml_file.include?('10_DuctsInAttic')
      if hpxml_file.include?('MiamiFL')
        duct_lto = 64.8
      elsif hpxml_file.include?('PhoenixAZ')
        duct_lto = 93.6
      elsif hpxml_file.include?('SanFranCA')
        duct_lto = 45.6
      elsif hpxml_file.include?('BaltimoreMD')
        duct_lto = 60.0
      elsif hpxml_file.include?('DuluthMN')
        duct_lto = 43.2
      end
    else
      duct_lto = 0.01
    end
    hpxml_bldg.hvac_distributions[0].duct_leakage_measurements.add(duct_type: HPXML::DuctTypeSupply,
                                                                   duct_leakage_units: HPXML::UnitsCFM25,
                                                                   duct_leakage_value: (duct_lto / 2).round(3),
                                                                   duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside)
    hpxml_bldg.hvac_distributions[0].duct_leakage_measurements.add(duct_type: HPXML::DuctTypeReturn,
                                                                   duct_leakage_units: HPXML::UnitsCFM25,
                                                                   duct_leakage_value: (duct_lto / 2).round(3),
                                                                   duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside)
  end

  # Ducts
  if ['RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/01-L100.xml',
      'RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/02-L100.xml',
      'RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/03-L304.xml',
      'RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/04-L324.xml',
      'RESNET_Tests/4.3_HERS_Method/L100A-01.xml'].include?(hpxml_file) ||
     hpxml_file.include?('Hot_Water')
    # Supply duct area = 308 ft2; Return duct area = 77 ft2
    # Duct R-val = 0
    # Duct Location = 100% conditioned
    hpxml_bldg.hvac_distributions[0].ducts.clear
    hpxml_bldg.hvac_distributions[0].ducts.add(id: "Duct#{hpxml_bldg.hvac_distributions[0].ducts.size + 1}",
                                               duct_type: HPXML::DuctTypeSupply,
                                               duct_insulation_r_value: 0,
                                               duct_location: HPXML::LocationConditionedSpace,
                                               duct_surface_area: 308)
    hpxml_bldg.hvac_distributions[0].ducts.add(id: "Duct#{hpxml_bldg.hvac_distributions[0].ducts.size + 1}",
                                               duct_type: HPXML::DuctTypeReturn,
                                               duct_insulation_r_value: 0,
                                               duct_location: HPXML::LocationConditionedSpace,
                                               duct_surface_area: 77)
  elsif hpxml_file.include?('EPA_Tests')
    supply_area = 0.27 * hpxml_bldg.building_construction.conditioned_floor_area
    return_area = 0.05 * hpxml_bldg.building_construction.conditioned_floor_area
    if hpxml_file.include?('SF_National_3.3') || hpxml_file.include?('SF_National_3.2') || hpxml_file.include?('SF_National_3.1') ||
       hpxml_file.include?('MF_National_1.3') || hpxml_file.include?('MF_National_1.2') || hpxml_file.include?('MF_National_1.1') || hpxml_file.include?('MF_National_1.0')
      if hpxml_file.include?('MF_National_1.0') && hpxml_file.include?('top_corner')
        location = HPXML::LocationAtticVented
        supply_r = 8
        return_r = 6
      else
        location = HPXML::LocationConditionedSpace
        supply_r = 0
        return_r = 0
      end
      hpxml_bldg.hvac_distributions[0].ducts.clear
      hpxml_bldg.hvac_distributions[0].ducts.add(id: "Duct#{hpxml_bldg.hvac_distributions[0].ducts.size + 1}",
                                                 duct_type: HPXML::DuctTypeSupply,
                                                 duct_insulation_r_value: supply_r,
                                                 duct_location: location,
                                                 duct_surface_area: supply_area.round(2))
      hpxml_bldg.hvac_distributions[0].ducts.add(id: "Duct#{hpxml_bldg.hvac_distributions[0].ducts.size + 1}",
                                                 duct_type: HPXML::DuctTypeReturn,
                                                 duct_insulation_r_value: return_r,
                                                 duct_location: location,
                                                 duct_surface_area: return_area.round(2))
    elsif hpxml_file.include?('SF_National_3.0')
      if hpxml_file.include?('slab')
        non_attic_location = HPXML::LocationConditionedSpace
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
      hpxml_bldg.hvac_distributions[0].ducts.clear
      hpxml_bldg.hvac_distributions[0].ducts.add(id: "Duct#{hpxml_bldg.hvac_distributions[0].ducts.size + 1}",
                                                 duct_type: HPXML::DuctTypeSupply,
                                                 duct_insulation_r_value: 8,
                                                 duct_location: HPXML::LocationAtticVented,
                                                 duct_surface_area: (supply_area * (1.0 - non_attic_frac)).round(2))
      hpxml_bldg.hvac_distributions[0].ducts.add(id: "Duct#{hpxml_bldg.hvac_distributions[0].ducts.size + 1}",
                                                 duct_type: HPXML::DuctTypeReturn,
                                                 duct_insulation_r_value: 6,
                                                 duct_location: HPXML::LocationAtticVented,
                                                 duct_surface_area: (return_area * (1.0 - non_attic_frac)).round(2))
      hpxml_bldg.hvac_distributions[0].ducts.add(id: "Duct#{hpxml_bldg.hvac_distributions[0].ducts.size + 1}",
                                                 duct_type: HPXML::DuctTypeSupply,
                                                 duct_insulation_r_value: non_attic_rvalue,
                                                 duct_location: non_attic_location,
                                                 duct_surface_area: (supply_area * non_attic_frac).round(2))
      hpxml_bldg.hvac_distributions[0].ducts.add(id: "Duct#{hpxml_bldg.hvac_distributions[0].ducts.size + 1}",
                                                 duct_type: HPXML::DuctTypeReturn,
                                                 duct_insulation_r_value: non_attic_rvalue,
                                                 duct_location: non_attic_location,
                                                 duct_surface_area: (return_area * non_attic_frac).round(2))
    end
  elsif hpxml_file.include?('Multi_Climate')
    hpxml_bldg.hvac_distributions[0].ducts.clear
    if hpxml_file.include?('DuctsInAttic')
      location = HPXML::LocationAtticVented
    else
      location = HPXML::LocationConditionedSpace
    end
    hpxml_bldg.hvac_distributions[0].ducts.add(id: "Duct#{hpxml_bldg.hvac_distributions[0].ducts.size + 1}",
                                               duct_type: HPXML::DuctTypeSupply,
                                               duct_insulation_r_value: 4.2,
                                               duct_location: location,
                                               duct_surface_area: 486)
    hpxml_bldg.hvac_distributions[0].ducts.add(id: "Duct#{hpxml_bldg.hvac_distributions[0].ducts.size + 1}",
                                               duct_type: HPXML::DuctTypeReturn,
                                               duct_insulation_r_value: 4.2,
                                               duct_location: location,
                                               duct_surface_area: 90)
  end

  # CFA served
  if hpxml_bldg.hvac_distributions.size == 1
    hpxml_bldg.hvac_distributions[0].conditioned_floor_area_served = hpxml_bldg.building_construction.conditioned_floor_area
  end

  # Return registers
  if hpxml_file.include?('EPA_Tests')
    hpxml_bldg.hvac_distributions[0].number_of_return_registers = 1
  else
    hpxml_bldg.hvac_distributions.each do |hvac_distribution|
      next unless hvac_distribution.distribution_system_type == HPXML::HVACDistributionTypeAir

      hvac_distribution.number_of_return_registers = hpxml_bldg.building_construction.number_of_conditioned_floors
    end
  end
end

def set_hpxml_ventilation_fans(hpxml_file, hpxml_bldg)
  if ['RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/02-L100.xml'].include? hpxml_file
    # Exhaust-only whole-dwelling mechanical ventilation
    hpxml_bldg.ventilation_fans.clear
    hpxml_bldg.ventilation_fans.add(id: "VentilationFan#{hpxml_bldg.ventilation_fans.size + 1}",
                                    fan_type: HPXML::MechVentTypeExhaust,
                                    tested_flow_rate: 56.2,
                                    hours_in_operation: 24,
                                    fan_power: 14.7,
                                    used_for_whole_building_ventilation: true,
                                    is_shared_system: false)
  elsif ['RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/03-L304.xml'].include? hpxml_file
    # Balanced whole-dwelling mechanical ventilation without energy recovery
    hpxml_bldg.ventilation_fans.clear
    hpxml_bldg.ventilation_fans.add(id: "VentilationFan#{hpxml_bldg.ventilation_fans.size + 1}",
                                    fan_type: HPXML::MechVentTypeBalanced,
                                    tested_flow_rate: 56.2,
                                    hours_in_operation: 24,
                                    fan_power: 14.7,
                                    used_for_whole_building_ventilation: true,
                                    is_shared_system: false)
  elsif ['RESNET_Tests/Other_HERS_AutoGen_Reference_Home_301_2014/04-L324.xml'].include? hpxml_file
    # Balanced whole-dwelling mechanical ventilation with a 60% energy recovery system
    hpxml_bldg.ventilation_fans.clear
    hpxml_bldg.ventilation_fans.add(id: "VentilationFan#{hpxml_bldg.ventilation_fans.size + 1}",
                                    fan_type: HPXML::MechVentTypeERV,
                                    tested_flow_rate: 56.2,
                                    hours_in_operation: 24,
                                    sensible_recovery_efficiency: 0.6,
                                    total_recovery_efficiency: 0.4, # Unspecified
                                    fan_power: 14.7,
                                    used_for_whole_building_ventilation: true,
                                    is_shared_system: false)
  elsif hpxml_file.include?('EPA_Tests')
    if hpxml_file.include?('SF_National_3.3') || hpxml_file.include?('MF_National_1.3')
      if hpxml_file.include?('CZ2') || hpxml_file.include?('CZ4')
        fan_type = HPXML::MechVentTypeSupply
      elsif hpxml_file.include?('CZ6')
        fan_type = HPXML::MechVentTypeHRV
        sre = 0.65
      end
    else
      if hpxml_file.include?('CZ2') || hpxml_file.include?('CZ4')
        fan_type = HPXML::MechVentTypeSupply
      elsif hpxml_file.include?('CZ6')
        fan_type = HPXML::MechVentTypeExhaust
      end
    end

    tested_flow_rate = (0.01 * hpxml_bldg.building_construction.conditioned_floor_area + 7.5 * (hpxml_bldg.building_construction.number_of_bedrooms + 1)).round(2)
    if hpxml_file.include?('SF_National_3.3') || hpxml_file.include?('MF_National_1.3')
      if hpxml_file.include?('CZ2') || hpxml_file.include?('CZ4')
        cfm_per_w = 3.8
      elsif hpxml_file.include?('CZ6')
        cfm_per_w = 1.2
      end
    elsif hpxml_file.include?('SF_National_3.2') || hpxml_file.include?('SF_National_3.1') ||
          hpxml_file.include?('MF_National_1.2') || hpxml_file.include?('MF_National_1.1')
      cfm_per_w = 2.8
    elsif hpxml_file.include?('SF_National_3.0') || hpxml_file.include?('MF_National_1.0')
      cfm_per_w = 2.2
    end
    hpxml_bldg.ventilation_fans.clear
    hpxml_bldg.ventilation_fans.add(id: "VentilationFan#{hpxml_bldg.ventilation_fans.size + 1}",
                                    fan_type: fan_type,
                                    tested_flow_rate: tested_flow_rate,
                                    hours_in_operation: 24,
                                    fan_power: (tested_flow_rate / cfm_per_w).round(3),
                                    sensible_recovery_efficiency: sre,
                                    used_for_whole_building_ventilation: true,
                                    is_shared_system: false)
  elsif hpxml_file.include?('Multi_Climate')
    hpxml_bldg.ventilation_fans.clear
    if hpxml_file.include?('NoMechVent')
      return
    elsif hpxml_file.include?('CFIS')
      hpxml_bldg.ventilation_fans.add(id: "VentilationFan#{hpxml_bldg.ventilation_fans.size + 1}",
                                      fan_type: HPXML::MechVentTypeCFIS,
                                      tested_flow_rate: 155.4,
                                      hours_in_operation: 12,
                                      used_for_whole_building_ventilation: true,
                                      cfis_addtl_runtime_operating_mode: HPXML::CFISModeAirHandler,
                                      distribution_system_idref: hpxml_bldg.hvac_distributions[0].id,
                                      is_shared_system: false,
                                      cfis_has_outdoor_air_control: true,
                                      cfis_control_type: HPXML::CFISControlTypeOptimized)
    else
      if hpxml_file.include?('ConditionedBasement')
        if hpxml_file.include?('PhoenixAZ')
          fan_power, flow_rate = 60.9, 87.0
        elsif hpxml_file.include?('BaltimoreMD')
          fan_power, flow_rate = 71.75, 102.5
        elsif hpxml_file.include?('DuluthMN')
          fan_power, flow_rate = 61.67, 88.1
        end
      else
        if hpxml_file.include?('MiamiFL')
          fan_power, flow_rate = 37.1, 53.0
        elsif hpxml_file.include?('PhoenixAZ')
          fan_power, flow_rate = 35.7, 51.0
        elsif hpxml_file.include?('SanFranCA')
          fan_power, flow_rate = 41.3, 59.0
        elsif hpxml_file.include?('BaltimoreMD')
          fan_power, flow_rate = 46.2, 66.0
        elsif hpxml_file.include?('DuluthMN')
          fan_power, flow_rate = 36.4, 52.0
        end
      end
      hpxml_bldg.ventilation_fans.add(id: "VentilationFan#{hpxml_bldg.ventilation_fans.size + 1}",
                                      fan_type: HPXML::MechVentTypeBalanced,
                                      tested_flow_rate: flow_rate,
                                      hours_in_operation: 24,
                                      fan_power: fan_power,
                                      used_for_whole_building_ventilation: true,
                                      is_shared_system: false)
    end
  end
end

def set_hpxml_water_heating_systems(hpxml_file, hpxml_bldg)
  if ['RESNET_Tests/4.3_HERS_Method/L100A-01.xml'].include? hpxml_file
    # 40 gal electric with EF = 0.88
    hpxml_bldg.water_heating_systems.clear
    hpxml_bldg.water_heating_systems.add(id: "WaterHeatingSystem#{hpxml_bldg.water_heating_systems.size + 1}",
                                         is_shared_system: false,
                                         fuel_type: HPXML::FuelTypeElectricity,
                                         water_heater_type: HPXML::WaterHeaterTypeStorage,
                                         location: HPXML::LocationConditionedSpace,
                                         tank_volume: 40,
                                         fraction_dhw_load_served: 1,
                                         energy_factor: 0.88)
  elsif ['RESNET_Tests/4.3_HERS_Method/L100A-02.xml'].include? hpxml_file
    # Tankless natural gas with EF = 0.82
    hpxml_bldg.water_heating_systems.clear
    hpxml_bldg.water_heating_systems.add(id: "WaterHeatingSystem#{hpxml_bldg.water_heating_systems.size + 1}",
                                         is_shared_system: false,
                                         fuel_type: HPXML::FuelTypeNaturalGas,
                                         water_heater_type: HPXML::WaterHeaterTypeTankless,
                                         location: HPXML::LocationConditionedSpace,
                                         fraction_dhw_load_served: 1,
                                         energy_factor: 0.82)
  elsif ['RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AD-HW-01.xml',
         'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AM-HW-01.xml'].include? hpxml_file
    # 40 gallon storage; gas; EF = 0.56; RE = 0.78; conditioned space
    hpxml_bldg.water_heating_systems.clear
    hpxml_bldg.water_heating_systems.add(id: "WaterHeatingSystem#{hpxml_bldg.water_heating_systems.size + 1}",
                                         is_shared_system: false,
                                         fuel_type: HPXML::FuelTypeNaturalGas,
                                         water_heater_type: HPXML::WaterHeaterTypeStorage,
                                         location: HPXML::LocationConditionedSpace,
                                         tank_volume: 40,
                                         fraction_dhw_load_served: 1,
                                         energy_factor: 0.56,
                                         recovery_efficiency: 0.78)
  elsif ['RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AD-HW-03.xml',
         'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AM-HW-03.xml'].include? hpxml_file
    # 40 gallon storage; gas; EF = 0.62; RE = 0.78; conditioned space
    hpxml_bldg.water_heating_systems.clear
    hpxml_bldg.water_heating_systems.add(id: "WaterHeatingSystem#{hpxml_bldg.water_heating_systems.size + 1}",
                                         is_shared_system: false,
                                         fuel_type: HPXML::FuelTypeNaturalGas,
                                         water_heater_type: HPXML::WaterHeaterTypeStorage,
                                         location: HPXML::LocationConditionedSpace,
                                         tank_volume: 40,
                                         fraction_dhw_load_served: 1,
                                         energy_factor: 0.62,
                                         recovery_efficiency: 0.78)
  elsif hpxml_file.include?('HERS_AutoGen')
    # 40 gal electric with EF = 0.92
    hpxml_bldg.water_heating_systems.clear
    hpxml_bldg.water_heating_systems.add(id: "WaterHeatingSystem#{hpxml_bldg.water_heating_systems.size + 1}",
                                         is_shared_system: false,
                                         fuel_type: HPXML::FuelTypeElectricity,
                                         water_heater_type: HPXML::WaterHeaterTypeStorage,
                                         location: HPXML::LocationConditionedSpace,
                                         tank_volume: 40,
                                         fraction_dhw_load_served: 1,
                                         energy_factor: 0.92)
  elsif hpxml_file.include?('EPA_Tests')
    hpxml_bldg.water_heating_systems.clear
    if hpxml_file.include?('_gas_')
      if hpxml_file.include?('EPA_Tests/MF')
        if hpxml_file.include?('MF_National_1.3')
          water_heater_type = HPXML::WaterHeaterTypeTankless
          uniform_energy_factor = 0.95
        elsif hpxml_file.include?('MF_National_1.2')
          water_heater_type = HPXML::WaterHeaterTypeTankless
          uniform_energy_factor = 0.9
        else
          water_heater_type = HPXML::WaterHeaterTypeStorage
          tank_volume = 40
          energy_factor = 0.67
        end
      else
        if hpxml_file.include?('SF_National_3.3')
          water_heater_type = HPXML::WaterHeaterTypeTankless
          uniform_energy_factor = 0.95
        elsif hpxml_file.include?('SF_National_3.2')
          water_heater_type = HPXML::WaterHeaterTypeTankless
          uniform_energy_factor = 0.9
        else
          water_heater_type = HPXML::WaterHeaterTypeStorage
          tank_volume = 40
          energy_factor = 0.61
        end
      end
      hpxml_bldg.water_heating_systems.add(id: "WaterHeatingSystem#{hpxml_bldg.water_heating_systems.size + 1}",
                                           is_shared_system: false,
                                           fuel_type: HPXML::FuelTypeNaturalGas,
                                           water_heater_type: water_heater_type,
                                           location: HPXML::LocationConditionedSpace,
                                           tank_volume: tank_volume,
                                           fraction_dhw_load_served: 1,
                                           energy_factor: energy_factor,
                                           uniform_energy_factor: uniform_energy_factor)
    elsif hpxml_file.include?('_elec_')
      if hpxml_file.include?('EPA_Tests/MF')
        if hpxml_file.include?('MF_National_1.3')
          water_heater_type = HPXML::WaterHeaterTypeHeatPump
          tank_volume = 60
          uniform_energy_factor = 2.5
          first_hour_rating = 40
        elsif hpxml_file.include?('MF_National_1.2')
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
        if hpxml_file.include?('SF_National_3.3') || hpxml_file.include?('SF_National_3.2')
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
      hpxml_bldg.water_heating_systems.add(id: "WaterHeatingSystem#{hpxml_bldg.water_heating_systems.size + 1}",
                                           is_shared_system: false,
                                           fuel_type: HPXML::FuelTypeElectricity,
                                           water_heater_type: water_heater_type,
                                           location: HPXML::LocationConditionedSpace,
                                           tank_volume: tank_volume,
                                           fraction_dhw_load_served: 1,
                                           energy_factor: energy_factor,
                                           uniform_energy_factor: uniform_energy_factor,
                                           first_hour_rating: first_hour_rating)
    end
  elsif hpxml_file.include?('Multi_Climate')
    hpxml_bldg.water_heating_systems.clear
    hpxml_bldg.water_heating_systems.add(id: "WaterHeatingSystem#{hpxml_bldg.water_heating_systems.size + 1}",
                                         is_shared_system: false,
                                         fuel_type: HPXML::FuelTypeNaturalGas,
                                         water_heater_type: HPXML::WaterHeaterTypeStorage,
                                         location: HPXML::LocationConditionedSpace,
                                         tank_volume: 40,
                                         fraction_dhw_load_served: 1,
                                         energy_factor: 0.62,
                                         recovery_efficiency: 0.77)
  end
  if hpxml_bldg.water_heating_systems[0].water_heater_type == HPXML::WaterHeaterTypeHeatPump
    hpxml_bldg.water_heating_systems[0].hpwh_confined_space_without_mitigation = false
  end
end

def set_hpxml_hot_water_distribution(hpxml_file, hpxml_bldg)
  if ['RESNET_Tests/4.3_HERS_Method/L100A-01.xml',
      'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AD-HW-01.xml',
      'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AM-HW-01.xml'].include?(hpxml_file) ||
     hpxml_file.include?('EPA_Tests')
    # Standard
    hpxml_bldg.hot_water_distributions.clear
    hpxml_bldg.hot_water_distributions.add(id: "HotWaterDstribution#{hpxml_bldg.hot_water_distributions.size + 1}",
                                           system_type: HPXML::DHWDistTypeStandard,
                                           pipe_r_value: 0.0)
  elsif ['RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AD-HW-05.xml',
         'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AM-HW-05.xml'].include? hpxml_file
    # Change to recirculation: Control = none; 50 W pump; Loop length is same as reference loop length; Branch length is 10 ft; All hot water pipes insulated to R-3
    hpxml_bldg.hot_water_distributions[0].system_type = HPXML::DHWDistTypeRecirc
    hpxml_bldg.hot_water_distributions[0].recirculation_control_type = HPXML::DHWRecircControlTypeNone
    hpxml_bldg.hot_water_distributions[0].recirculation_branch_piping_length = 10
    hpxml_bldg.hot_water_distributions[0].recirculation_pump_power = 50
    hpxml_bldg.hot_water_distributions[0].pipe_r_value = 3
  elsif ['RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AD-HW-06.xml',
         'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AM-HW-06.xml'].include? hpxml_file
    # Change to recirculation: Control = manual
    hpxml_bldg.hot_water_distributions[0].recirculation_control_type = HPXML::DHWRecircControlTypeManual
  elsif ['RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AD-HW-07.xml',
         'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AM-HW-07.xml'].include? hpxml_file
    # Change to drain Water Heat Recovery (DWHR) with all facilities connected; equal flow; DWHR eff = 54%
    hpxml_bldg.hot_water_distributions[0].dwhr_facilities_connected = HPXML::DWHRFacilitiesConnectedAll
    hpxml_bldg.hot_water_distributions[0].dwhr_equal_flow = true
    hpxml_bldg.hot_water_distributions[0].dwhr_efficiency = 0.54
  elsif hpxml_file.include?('HERS_AutoGen')
    # Standard
    hpxml_bldg.hot_water_distributions.clear
    hpxml_bldg.hot_water_distributions.add(id: "HotWaterDstribution#{hpxml_bldg.hot_water_distributions.size + 1}",
                                           system_type: HPXML::DHWDistTypeStandard,
                                           pipe_r_value: 0.0)
  elsif hpxml_file.include?('Multi_Climate')
    hpxml_bldg.hot_water_distributions.clear
    hpxml_bldg.hot_water_distributions.add(id: "HotWaterDstribution#{hpxml_bldg.hot_water_distributions.size + 1}",
                                           system_type: HPXML::DHWDistTypeStandard,
                                           pipe_r_value: 0.0)
  end

  has_uncond_bsmnt = hpxml_bldg.has_location(HPXML::LocationBasementUnconditioned)
  has_cond_bsmnt = hpxml_bldg.has_location(HPXML::LocationBasementConditioned)
  cfa = hpxml_bldg.building_construction.conditioned_floor_area
  ncfl = hpxml_bldg.building_construction.number_of_conditioned_floors

  if hpxml_bldg.hot_water_distributions.size > 0
    if hpxml_bldg.hot_water_distributions[0].system_type == HPXML::DHWDistTypeStandard
      piping_length = Defaults.get_std_pipe_length(has_uncond_bsmnt, has_cond_bsmnt, cfa, ncfl)
      hpxml_bldg.hot_water_distributions[0].standard_piping_length = piping_length.round(3)
    elsif hpxml_bldg.hot_water_distributions[0].system_type == HPXML::DHWDistTypeRecirc
      loop_length = Defaults.get_recirc_loop_length(has_uncond_bsmnt, has_cond_bsmnt, cfa, ncfl)
      hpxml_bldg.hot_water_distributions[0].recirculation_piping_loop_length = loop_length.round(3)
    end
  end
end

def set_hpxml_water_fixtures(hpxml_file, hpxml_bldg)
  if ['RESNET_Tests/4.3_HERS_Method/L100A-01.xml',
      'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AD-HW-01.xml',
      'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AM-HW-01.xml'].include?(hpxml_file) ||
     hpxml_file.include?('EPA_Tests/SF') ||
     hpxml_file.include?('HERS_AutoGen') ||
     hpxml_file.include?('Multi_Climate')
    # Standard
    hpxml_bldg.water_fixtures.clear
    hpxml_bldg.water_fixtures.add(id: "WaterFixture#{hpxml_bldg.water_fixtures.size + 1}",
                                  water_fixture_type: HPXML::WaterFixtureTypeShowerhead,
                                  low_flow: false)
    hpxml_bldg.water_fixtures.add(id: "WaterFixture#{hpxml_bldg.water_fixtures.size + 1}",
                                  water_fixture_type: HPXML::WaterFixtureTypeFaucet,
                                  low_flow: false)
  elsif ['RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AD-HW-04.xml',
         'RESNET_Tests/Other_Hot_Water_301_2019_PreAddendumA/L100AM-HW-04.xml'].include?(hpxml_file) ||
        hpxml_file.include?('EPA_Tests/MF')
    # Low-flow
    hpxml_bldg.water_fixtures.clear
    hpxml_bldg.water_fixtures.add(id: "WaterFixture#{hpxml_bldg.water_fixtures.size + 1}",
                                  water_fixture_type: HPXML::WaterFixtureTypeShowerhead,
                                  low_flow: true)
    hpxml_bldg.water_fixtures.add(id: "WaterFixture#{hpxml_bldg.water_fixtures.size + 1}",
                                  water_fixture_type: HPXML::WaterFixtureTypeFaucet,
                                  low_flow: true)
  end
end

def set_hpxml_clothes_washer(hpxml_file, eri_version, hpxml_bldg)
  return unless hpxml_file.include?('HERS_AutoGen') || hpxml_file.include?('HERS_Method') || hpxml_file.include?('Hot_Water') ||
                hpxml_file.include?('EPA_Tests') || hpxml_file.include?('Multi_Climate')

  if hpxml_file.include?('SF_National_3.3') || hpxml_file.include?('SF_National_3.2') || hpxml_file.include?('MF_National_1.3') || hpxml_file.include?('MF_National_1.2')
    default_values = { integrated_modified_energy_factor: 1.57, # ft3/(kWh/cyc)
                       rated_annual_kwh: 284.0, # kWh/yr
                       label_electric_rate: 0.12, # $/kWh
                       label_gas_rate: 1.09, # $/therm
                       label_annual_gas_cost: 18.0, # $
                       capacity: 4.2, # ft^3
                       label_usage: 6.0 } # cyc/week
  else
    default_values = Defaults.get_clothes_washer_values(eri_version)
  end

  hpxml_bldg.clothes_washers.clear
  hpxml_bldg.clothes_washers.add(id: "ClothesWasher#{hpxml_bldg.clothes_washers.size + 1}",
                                 is_shared_appliance: false,
                                 location: HPXML::LocationConditionedSpace,
                                 integrated_modified_energy_factor: default_values[:integrated_modified_energy_factor],
                                 rated_annual_kwh: default_values[:rated_annual_kwh],
                                 label_electric_rate: default_values[:label_electric_rate],
                                 label_gas_rate: default_values[:label_gas_rate],
                                 label_annual_gas_cost: default_values[:label_annual_gas_cost],
                                 label_usage: default_values[:label_usage],
                                 capacity: default_values[:capacity])
end

def set_hpxml_clothes_dryer(hpxml_file, eri_version, hpxml_bldg)
  return unless hpxml_file.include?('HERS_AutoGen') || hpxml_file.include?('HERS_Method') || hpxml_file.include?('Hot_Water') ||
                hpxml_file.include?('EPA_Tests') || hpxml_file.include?('Multi_Climate')

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
     (hpxml_file.include?('EPA_Tests') && hpxml_file.include?('_gas_')) ||
     hpxml_file.include?('Multi_Climate')
    # Standard gas
    default_values = Defaults.get_clothes_dryer_values(eri_version, HPXML::FuelTypeNaturalGas)
    hpxml_bldg.clothes_dryers.clear
    hpxml_bldg.clothes_dryers.add(id: "ClothesDryer#{hpxml_bldg.clothes_dryers.size + 1}",
                                  is_shared_appliance: false,
                                  location: HPXML::LocationConditionedSpace,
                                  fuel_type: HPXML::FuelTypeNaturalGas,
                                  control_type: default_values[:control_type],
                                  combined_energy_factor: default_values[:combined_energy_factor],
                                  is_vented: true)
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
    default_values = Defaults.get_clothes_dryer_values(eri_version, HPXML::FuelTypeElectricity)
    hpxml_bldg.clothes_dryers.clear
    hpxml_bldg.clothes_dryers.add(id: "ClothesDryer#{hpxml_bldg.clothes_dryers.size + 1}",
                                  is_shared_appliance: false,
                                  location: HPXML::LocationConditionedSpace,
                                  fuel_type: HPXML::FuelTypeElectricity,
                                  control_type: default_values[:control_type],
                                  combined_energy_factor: default_values[:combined_energy_factor],
                                  is_vented: true)
  end
end

def set_hpxml_dishwasher(hpxml_file, eri_version, hpxml_bldg)
  if hpxml_file.include?('EPA_Tests')
    if hpxml_file.include?('SF_National_3.3') || hpxml_file.include?('MF_National_1.3')
      rated_annual_kwh = 240
      label_electric_rate = 0.14
      label_gas_rate = 1.21
      label_annual_gas_cost = 24.00
    else
      rated_annual_kwh = 270
      label_electric_rate = 0.12
      label_gas_rate = 1.09
      label_annual_gas_cost = 22.23
    end
    hpxml_bldg.dishwashers.clear
    hpxml_bldg.dishwashers.add(id: "Dishwasher#{hpxml_bldg.dishwashers.size + 1}",
                               is_shared_appliance: false,
                               location: HPXML::LocationConditionedSpace,
                               place_setting_capacity: 12,
                               rated_annual_kwh: rated_annual_kwh,
                               label_electric_rate: label_electric_rate,
                               label_gas_rate: label_gas_rate,
                               label_annual_gas_cost: label_annual_gas_cost,
                               label_usage: 208 / 52)
  elsif hpxml_file.include?('HERS_AutoGen') || hpxml_file.include?('HERS_Method') || hpxml_file.include?('Hot_Water') || hpxml_file.include?('Multi_Climate')
    default_values = Defaults.get_dishwasher_values(eri_version)
    hpxml_bldg.dishwashers.clear
    hpxml_bldg.dishwashers.add(id: "Dishwasher#{hpxml_bldg.dishwashers.size + 1}",
                               is_shared_appliance: false,
                               location: HPXML::LocationConditionedSpace,
                               place_setting_capacity: default_values[:place_setting_capacity],
                               rated_annual_kwh: default_values[:rated_annual_kwh],
                               label_electric_rate: default_values[:label_electric_rate],
                               label_gas_rate: default_values[:label_gas_rate],
                               label_annual_gas_cost: default_values[:label_annual_gas_cost],
                               label_usage: default_values[:label_usage])
  end
end

def set_hpxml_refrigerator(hpxml_file, hpxml_bldg)
  if hpxml_file.include?('EPA_Tests')
    hpxml_bldg.refrigerators.clear

    if hpxml_file.include?('SF_National_3.3')
      default_values = Defaults.get_refrigerator_values(hpxml_bldg.building_construction.number_of_bedrooms)
      rated_annual_kwh = default_values[:rated_annual_kwh]
    elsif hpxml_file.include?('SF_National_3.2') || hpxml_file.include?('MF_National_1.3') || hpxml_file.include?('MF_National_1.2')
      rated_annual_kwh = 450.0
    else
      rated_annual_kwh = 423.0
    end

    hpxml_bldg.refrigerators.add(id: "Refrigerator#{hpxml_bldg.refrigerators.size + 1}",
                                 location: HPXML::LocationConditionedSpace,
                                 rated_annual_kwh: rated_annual_kwh)
  elsif hpxml_file.include?('HERS_AutoGen') || hpxml_file.include?('HERS_Method') || hpxml_file.include?('Hot_Water') || hpxml_file.include?('Multi_Climate')
    # Standard
    default_values = Defaults.get_refrigerator_values(hpxml_bldg.building_construction.number_of_bedrooms)
    hpxml_bldg.refrigerators.clear
    hpxml_bldg.refrigerators.add(id: "Refrigerator#{hpxml_bldg.refrigerators.size + 1}",
                                 location: HPXML::LocationConditionedSpace,
                                 rated_annual_kwh: default_values[:rated_annual_kwh])
  end
end

def set_hpxml_cooking_range(hpxml_file, hpxml_bldg)
  return unless hpxml_file.include?('HERS_AutoGen') || hpxml_file.include?('HERS_Method') || hpxml_file.include?('Hot_Water') ||
                hpxml_file.include?('EPA_Tests') || hpxml_file.include?('Multi_Climate')

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
     (hpxml_file.include?('EPA_Tests') && hpxml_file.include?('_gas_')) ||
     hpxml_file.include?('Multi_Climate')
    # Standard gas
    default_values = Defaults.get_range_oven_values()
    hpxml_bldg.cooking_ranges.clear
    hpxml_bldg.cooking_ranges.add(id: "CookingRange#{hpxml_bldg.cooking_ranges.size + 1}",
                                  location: HPXML::LocationConditionedSpace,
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
    default_values = Defaults.get_range_oven_values()
    hpxml_bldg.cooking_ranges.clear
    hpxml_bldg.cooking_ranges.add(id: "CookingRange#{hpxml_bldg.cooking_ranges.size + 1}",
                                  location: HPXML::LocationConditionedSpace,
                                  fuel_type: HPXML::FuelTypeElectricity,
                                  is_induction: default_values[:is_induction])
  end
end

def set_hpxml_oven(hpxml_file, hpxml_bldg)
  return unless hpxml_file.include?('HERS_AutoGen') || hpxml_file.include?('HERS_Method') || hpxml_file.include?('Hot_Water') ||
                hpxml_file.include?('EPA_Tests') || hpxml_file.include?('Multi_Climate')

  default_values = Defaults.get_range_oven_values()
  hpxml_bldg.ovens.clear
  hpxml_bldg.ovens.add(id: "Oven#{hpxml_bldg.ovens.size + 1}",
                       is_convection: default_values[:is_convection])
end

def set_hpxml_lighting(hpxml_file, hpxml_bldg)
  return unless hpxml_file.include?('HERS_AutoGen') || hpxml_file.include?('HERS_Method') || hpxml_file.include?('Hot_Water') ||
                hpxml_file.include?('EPA_Tests') || hpxml_file.include?('Multi_Climate')

  if hpxml_file.include?('EPA_Tests/SF_National_3.3') || hpxml_file.include?('EPA_Tests/SF_National_3.2') || hpxml_file.include?('EPA_Tests/MF_National_1.3') || hpxml_file.include?('EPA_Tests/MF_National_1.2')
    ltg_fracs = { [HPXML::LocationInterior, HPXML::LightingTypeLED] => 1.0,
                  [HPXML::LocationExterior, HPXML::LightingTypeLED] => 1.0,
                  [HPXML::LocationGarage, HPXML::LightingTypeLED] => 1.0,
                  [HPXML::LocationInterior, HPXML::LightingTypeCFL] => 0,
                  [HPXML::LocationExterior, HPXML::LightingTypeCFL] => 0,
                  [HPXML::LocationGarage, HPXML::LightingTypeCFL] => 0,
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
  elsif hpxml_file.include?('Multi_Climate')
    ltg_fracs = { [HPXML::LocationInterior, HPXML::LightingTypeLED] => 0,
                  [HPXML::LocationExterior, HPXML::LightingTypeLED] => 0,
                  [HPXML::LocationGarage, HPXML::LightingTypeLED] => 0,
                  [HPXML::LocationInterior, HPXML::LightingTypeCFL] => 0.75,
                  [HPXML::LocationExterior, HPXML::LightingTypeCFL] => 0.75,
                  [HPXML::LocationGarage, HPXML::LightingTypeCFL] => 0.75,
                  [HPXML::LocationInterior, HPXML::LightingTypeLFL] => 0,
                  [HPXML::LocationExterior, HPXML::LightingTypeLFL] => 0,
                  [HPXML::LocationGarage, HPXML::LightingTypeLFL] => 0 }
  else
    ltg_fracs = Defaults.get_lighting_fractions()
  end

  hpxml_bldg.lighting_groups.clear
  ltg_fracs.each do |key, fraction|
    location, lighting_type = key
    hpxml_bldg.lighting_groups.add(id: "LightingGroup#{hpxml_bldg.lighting_groups.size + 1}",
                                   location: location,
                                   fraction_of_units_in_location: fraction,
                                   lighting_type: lighting_type)
  end
end

def set_hpxml_plug_loads(hpxml_file, hpxml_bldg)
  return unless hpxml_file.include?('HERS_AutoGen') || hpxml_file.include?('HERS_Method') || hpxml_file.include?('EPA_Tests')

  hpxml_bldg.plug_loads.clear
end

def create_sample_hpxmls
  # Copy sample files from hpxml-measures subtree
  puts 'Copying sample files from OS-HPXML...'
  FileUtils.rm_f(Dir.glob('workflow/sample_files/*.xml'))

  # Copy files we're interested in
  include_list = ['base.xml',
                  'base-appliances-dehumidifier.xml',
                  'base-appliances-dehumidifier-ef-portable.xml',
                  'base-appliances-dehumidifier-ef-whole-home.xml',
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
                  'base-battery.xml',
                  'base-bldgtype-mf-unit.xml',
                  'base-bldgtype-mf-unit-adjacent-to-multiple.xml',
                  'base-bldgtype-mf-unit-shared-boiler-only-baseboard.xml',
                  'base-bldgtype-mf-unit-shared-boiler-only-fan-coil.xml',
                  'base-bldgtype-mf-unit-shared-boiler-only-fan-coil-ducted.xml',
                  'base-bldgtype-mf-unit-shared-boiler-only-water-loop-heat-pump.xml',
                  'base-bldgtype-mf-unit-shared-chiller-only-baseboard.xml',
                  'base-bldgtype-mf-unit-shared-chiller-only-fan-coil.xml',
                  'base-bldgtype-mf-unit-shared-chiller-only-fan-coil-ducted.xml',
                  'base-bldgtype-mf-unit-shared-chiller-only-water-loop-heat-pump.xml',
                  'base-bldgtype-mf-unit-shared-cooling-tower-only-water-loop-heat-pump.xml',
                  'base-bldgtype-mf-unit-shared-generator.xml',
                  'base-bldgtype-mf-unit-shared-ground-loop-ground-to-air-heat-pump.xml',
                  'base-bldgtype-mf-unit-shared-laundry-room.xml',
                  'base-bldgtype-mf-unit-shared-laundry-room-multiple-water-heaters.xml',
                  'base-bldgtype-mf-unit-shared-mechvent.xml',
                  'base-bldgtype-mf-unit-shared-mechvent-preconditioning.xml',
                  'base-bldgtype-mf-unit-shared-pv.xml',
                  'base-bldgtype-mf-unit-shared-pv-battery.xml',
                  'base-bldgtype-mf-unit-shared-water-heater.xml',
                  'base-bldgtype-mf-unit-shared-water-heater-heat-pump.xml',
                  'base-bldgtype-mf-unit-shared-water-heater-recirc.xml',
                  'base-bldgtype-sfa-unit.xml',
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
                  'base-dhw-tank-elec-ef.xml',
                  'base-dhw-tank-gas-ef.xml',
                  'base-dhw-tank-heat-pump-ef.xml',
                  'base-dhw-tank-heat-pump-confined-space.xml',
                  'base-dhw-tankless-electric-ef.xml',
                  'base-dhw-tankless-gas-ef.xml',
                  'base-dhw-tankless-propane.xml',
                  'base-dhw-tank-oil.xml',
                  'base-dhw-tank-wood.xml',
                  'base-enclosure-2stories.xml',
                  'base-enclosure-2stories-garage.xml',
                  'base-enclosure-beds-1.xml',
                  'base-enclosure-beds-2.xml',
                  'base-enclosure-beds-4.xml',
                  'base-enclosure-beds-5.xml',
                  'base-enclosure-ceilingtypes.xml',
                  'base-enclosure-floortypes.xml',
                  'base-enclosure-garage.xml',
                  'base-enclosure-infil-ach-house-pressure.xml',
                  'base-enclosure-infil-cfm50.xml',
                  'base-enclosure-infil-cfm-house-pressure.xml',
                  'base-enclosure-infil-ela.xml',
                  'base-enclosure-infil-natural-ach.xml',
                  'base-enclosure-infil-natural-cfm.xml',
                  'base-enclosure-overhangs.xml',
                  'base-enclosure-skylights.xml',
                  'base-enclosure-skylights-cathedral.xml',
                  'base-enclosure-walltypes.xml',
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
                  'base-foundation-vented-crawlspace-above-grade.xml',
                  'base-foundation-walkout-basement.xml',
                  'base-hvac-air-to-air-heat-pump-1-speed.xml',
                  'base-hvac-air-to-air-heat-pump-1-speed-cooling-only.xml',
                  'base-hvac-air-to-air-heat-pump-1-speed-heating-only.xml',
                  'base-hvac-air-to-air-heat-pump-1-speed-lockout-temperatures.xml',
                  'base-hvac-air-to-air-heat-pump-1-speed-seer-hspf.xml',
                  'base-hvac-air-to-air-heat-pump-2-speed.xml',
                  'base-hvac-air-to-air-heat-pump-var-speed.xml',
                  'base-hvac-boiler-elec-only.xml',
                  'base-hvac-boiler-gas-only.xml',
                  'base-hvac-boiler-oil-only.xml',
                  'base-hvac-boiler-propane-only.xml',
                  'base-hvac-central-ac-only-1-speed.xml',
                  'base-hvac-central-ac-only-1-speed-seer.xml',
                  'base-hvac-central-ac-only-2-speed.xml',
                  'base-hvac-central-ac-only-var-speed.xml',
                  'base-hvac-central-ac-plus-air-to-air-heat-pump-heating.xml',
                  'base-hvac-dse.xml',
                  'base-hvac-ducts-areas.xml',
                  'base-hvac-ducts-leakage-cfm50.xml',
                  'base-hvac-ducts-buried.xml',
                  'base-hvac-dual-fuel-air-to-air-heat-pump-1-speed.xml',
                  'base-hvac-elec-resistance-only.xml',
                  'base-hvac-evap-cooler-only.xml',
                  'base-hvac-evap-cooler-only-ducted.xml',
                  'base-hvac-fan-motor-type.xml',
                  'base-hvac-fireplace-wood-only.xml',
                  'base-hvac-floor-furnace-propane-only.xml',
                  'base-hvac-furnace-elec-only.xml',
                  'base-hvac-furnace-gas-only.xml',
                  'base-hvac-furnace-gas-plus-air-to-air-heat-pump-cooling.xml',
                  'base-hvac-ground-to-air-heat-pump-1-speed.xml', # FUTURE: Add 2/var-speed files when OS-HPXML modeling reflects it
                  'base-hvac-ground-to-air-heat-pump-cooling-only.xml',
                  'base-hvac-ground-to-air-heat-pump-heating-only.xml',
                  'base-hvac-install-quality-air-to-air-heat-pump-1-speed.xml',
                  'base-hvac-install-quality-furnace-gas-central-ac-1-speed.xml',
                  'base-hvac-install-quality-ground-to-air-heat-pump-1-speed.xml',
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
                  'base-hvac-space-heater-gas-only.xml',
                  'base-hvac-ptac.xml',
                  'base-hvac-ptac-with-heating-electricity.xml',
                  'base-hvac-ptac-with-heating-natural-gas.xml',
                  'base-hvac-pthp.xml',
                  'base-hvac-room-ac-only.xml',
                  'base-hvac-room-ac-only-eer.xml',
                  'base-hvac-room-ac-with-heating.xml',
                  'base-hvac-room-ac-with-reverse-cycle.xml',
                  'base-hvac-stove-wood-pellets-only.xml',
                  'base-hvac-undersized.xml',
                  'base-hvac-wall-furnace-elec-only.xml',
                  'base-lighting-ceiling-fans.xml',
                  'base-lighting-ceiling-fans-label-energy-use.xml',
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
                  'base-mechvent-cfis-control-type-timer.xml',
                  'base-mechvent-cfis-no-additional-runtime.xml',
                  'base-mechvent-cfis-no-outdoor-air-control.xml',
                  'base-mechvent-cfis-supplemental-fan-exhaust.xml',
                  'base-mechvent-cfis-supplemental-fan-exhaust-synchronized.xml',
                  'base-mechvent-erv.xml',
                  'base-mechvent-erv-atre-asre.xml',
                  'base-mechvent-exhaust.xml',
                  'base-mechvent-hrv.xml',
                  'base-mechvent-hrv-asre.xml',
                  'base-mechvent-multiple.xml',
                  'base-mechvent-supply.xml',
                  'base-mechvent-whole-house-fan.xml',
                  'base-misc-generators.xml',
                  'base-pv.xml',
                  'base-pv-battery.xml']
  include_list.each do |include_file|
    if File.exist? "hpxml-measures/workflow/sample_files/#{include_file}"
      FileUtils.cp("hpxml-measures/workflow/sample_files/#{include_file}", "workflow/sample_files/#{include_file}")
    else
      puts "Warning: Included file hpxml-measures/workflow/sample_files/#{include_file} not found."
    end
  end

  # Update HPXMLs as needed
  puts 'Updating HPXML inputs for OS-ERI...'
  Dir['workflow/sample_files/*.xml'].each do |hpxml_path|
    next unless File.file? hpxml_path

    hpxml = HPXML.new(hpxml_path: hpxml_path)
    hpxml_bldg = hpxml.buildings[0]

    # Handle different inputs for ERI

    hpxml.header.eri_calculation_versions = ['latest']
    hpxml.header.co2index_calculation_versions = ['latest']
    hpxml.header.iecc_eri_calculation_versions = [IECC::AllVersions[-1]]
    hpxml.header.utility_bill_scenarios.clear
    hpxml.header.timestep = nil
    hpxml_bldg.site.site_type = nil
    hpxml_bldg.site.surroundings = nil
    hpxml_bldg.site.vertical_surroundings = nil
    hpxml_bldg.site.shielding_of_home = nil
    hpxml_bldg.site.orientation_of_front_of_home = nil
    hpxml_bldg.site.azimuth_of_front_of_home = nil
    hpxml_bldg.site.ground_conductivity = nil
    hpxml_bldg.building_construction.number_of_units_in_building = nil
    hpxml_bldg.building_construction.number_of_bathrooms = nil
    hpxml_bldg.air_infiltration_measurements.each do |measurement|
      measurement.infiltration_type = nil
      if measurement.infiltration_volume.nil?
        measurement.infiltration_volume = hpxml_bldg.building_construction.conditioned_building_volume
      end
    end
    hpxml_bldg.building_construction.conditioned_building_volume = nil
    hpxml_bldg.building_construction.average_ceiling_height = nil
    hpxml_bldg.building_construction.unit_height_above_grade = nil
    hpxml_bldg.attics.each do |attic|
      if attic.attic_type == HPXML::AtticTypeVented
        attic.vented_attic_sla = 0.003 if attic.vented_attic_sla.nil?
      end
      if [HPXML::AtticTypeVented,
          HPXML::AtticTypeUnvented].include? attic.attic_type
        attic.within_infiltration_volume = false if attic.within_infiltration_volume.nil?
      end
    end
    hpxml_bldg.foundations.each do |foundation|
      if foundation.foundation_type == HPXML::FoundationTypeCrawlspaceVented
        foundation.vented_crawlspace_sla = 0.00667 if foundation.vented_crawlspace_sla.nil?
      end
      next unless [HPXML::FoundationTypeBasementUnconditioned,
                   HPXML::FoundationTypeCrawlspaceUnvented,
                   HPXML::FoundationTypeCrawlspaceVented].include? foundation.foundation_type

      foundation.within_infiltration_volume = false if foundation.within_infiltration_volume.nil?
    end
    hpxml_bldg.roofs.each do |roof|
      roof.roof_type = nil
      roof.interior_finish_type = nil
      roof.interior_finish_thickness = nil
      if roof.radiant_barrier && roof.radiant_barrier_grade.nil?
        roof.radiant_barrier_grade = 2
      end
      roof.roof_color = nil
      roof.solar_absorptance = 0.7
      roof.emittance = 0.92
    end
    (hpxml_bldg.rim_joists + hpxml_bldg.walls).each do |wall_or_rim_joist|
      wall_or_rim_joist.siding = nil
      wall_or_rim_joist.color = nil
      if wall_or_rim_joist.is_exterior
        wall_or_rim_joist.solar_absorptance = 0.7 if wall_or_rim_joist.solar_absorptance.nil?
        wall_or_rim_joist.emittance = 0.92 if wall_or_rim_joist.emittance.nil?
      else
        wall_or_rim_joist.solar_absorptance = nil
        wall_or_rim_joist.emittance = nil
      end
      next unless wall_or_rim_joist.is_a? HPXML::Wall

      wall_or_rim_joist.attic_wall_type = nil
      wall_or_rim_joist.interior_finish_type = nil
      wall_or_rim_joist.interior_finish_thickness = nil
    end
    hpxml_bldg.floors.each do |floor|
      floor.interior_finish_type = nil
      floor.interior_finish_thickness = nil
      next if [HPXML::LocationOtherHousingUnit,
               HPXML::LocationOtherHeatedSpace,
               HPXML::LocationOtherMultifamilyBufferSpace,
               HPXML::LocationOtherNonFreezingSpace].include? floor.exterior_adjacent_to

      floor.floor_or_ceiling = nil
    end
    hpxml_bldg.foundation_walls.each do |fwall|
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
    hpxml_bldg.slabs.each do |slab|
      if slab.carpet_fraction.nil?
        slab.carpet_fraction = 0.0
      end
      if slab.carpet_r_value.nil?
        slab.carpet_r_value = 0.0
      end
    end
    hpxml_bldg.windows.each do |window|
      window.interior_shading_factor_winter = nil
      window.interior_shading_factor_summer = nil
      window.interior_shading_type = nil
    end
    hpxml_bldg.cooling_systems.each do |cooling_system|
      cooling_system.primary_system = nil
    end
    hpxml_bldg.heating_systems.each do |heating_system|
      heating_system.primary_system = nil
      heating_system.pilot_light = nil
      next unless heating_system.heating_system_type == HPXML::HVACTypeBoiler
      next unless heating_system.is_shared_system.nil?

      heating_system.is_shared_system = false
    end
    hpxml_bldg.heat_pumps.each do |heat_pump|
      heat_pump.primary_heating_system = nil
      heat_pump.primary_cooling_system = nil
      next unless heat_pump.heat_pump_type == HPXML::HVACTypeHeatPumpGroundToAir

      heat_pump.compressor_type = nil # FUTURE: Eventually remove this when OS-HPXML modeling reflects it

      next unless heat_pump.is_shared_system.nil?

      heat_pump.is_shared_system = false
    end
    hpxml_bldg.water_heating_systems.each do |water_heating_system|
      water_heating_system.temperature = nil
      water_heating_system.is_shared_system = false if water_heating_system.is_shared_system.nil?
      if water_heating_system.water_heater_type == HPXML::WaterHeaterTypeHeatPump
        water_heating_system.hpwh_confined_space_without_mitigation = false if water_heating_system.hpwh_confined_space_without_mitigation.nil?
      end
    end
    hpxml_bldg.water_fixtures.each do |water_fixture|
      water_fixture.count = nil
      next unless water_fixture.low_flow.nil?

      water_fixture.low_flow = (water_fixture.flow_rate <= 2)
      water_fixture.flow_rate = nil
    end
    shared_water_heaters = hpxml_bldg.water_heating_systems.select { |wh| wh.is_shared_system }
    if not hpxml_bldg.clothes_washers.empty?
      if hpxml_bldg.clothes_washers[0].is_shared_appliance
        hpxml_bldg.clothes_washers[0].number_of_units_served = shared_water_heaters[0].number_of_bedrooms_served / hpxml_bldg.building_construction.number_of_bedrooms
        hpxml_bldg.clothes_washers[0].count = 2
      else
        hpxml_bldg.clothes_washers[0].is_shared_appliance = false
      end
    end
    if not hpxml_bldg.clothes_dryers.empty?
      if hpxml_bldg.clothes_dryers[0].is_vented.nil?
        hpxml_bldg.clothes_dryers[0].is_vented = (![HPXML::DryingMethodCondensing, HPXML::DryingMethodHeatPump].include? hpxml_bldg.clothes_dryers[0].drying_method)
        hpxml_bldg.clothes_dryers[0].drying_method = nil
      end
      if hpxml_bldg.clothes_dryers[0].is_shared_appliance
        hpxml_bldg.clothes_dryers[0].number_of_units_served = shared_water_heaters[0].number_of_bedrooms_served / hpxml_bldg.building_construction.number_of_bedrooms
        hpxml_bldg.clothes_dryers[0].count = 2
      else
        hpxml_bldg.clothes_dryers[0].is_shared_appliance = false
      end
    end
    if not hpxml_bldg.dishwashers.empty?
      if not hpxml_bldg.dishwashers[0].is_shared_appliance
        hpxml_bldg.dishwashers[0].is_shared_appliance = false
      end
    end
    hpxml_bldg.ventilation_fans.each do |ventilation_fan|
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
      ventilation_fan.cfis_vent_mode_airflow_fraction = nil
      if ventilation_fan.fan_type == HPXML::MechVentTypeCFIS
        ventilation_fan.fan_power = nil
        if ventilation_fan.cfis_has_outdoor_air_control.nil?
          ventilation_fan.cfis_has_outdoor_air_control = true
        end
        if ventilation_fan.cfis_control_type.nil?
          ventilation_fan.cfis_control_type = HPXML::CFISControlTypeOptimized
        end
      end
      next if ventilation_fan.is_cfis_supplemental_fan

      if ventilation_fan.hours_in_operation.nil?
        if ventilation_fan.fan_type == HPXML::MechVentTypeCFIS
          ventilation_fan.hours_in_operation = 8.0
        else
          ventilation_fan.hours_in_operation = 24.0
        end
      end
    end
    hpxml_bldg.ventilation_fans.reverse_each do |ventilation_fan|
      next if ventilation_fan.used_for_whole_building_ventilation
      next if ventilation_fan.used_for_seasonal_cooling_load_reduction

      ventilation_fan.delete
    end
    hpxml_bldg.plug_loads.clear
    hpxml_bldg.fuel_loads.clear
    hpxml_bldg.heating_systems.each do |heating_system|
      heating_system.electric_auxiliary_energy = nil
      next unless [HPXML::HVACTypeFurnace].include? heating_system.heating_system_type

      if heating_system.fan_watts_per_cfm.nil?
        heating_system.fan_watts_per_cfm = 0.58
      end
      if heating_system.airflow_defect_ratio.nil?
        heating_system.airflow_defect_ratio = -0.25
      end
    end
    hpxml_bldg.cooling_systems.each do |cooling_system|
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
    hpxml_bldg.heat_pumps.each do |heat_pump|
      heat_pump.backup_heating_lockout_temp = nil
      heat_pump.backup_heating_switchover_temp = nil

      if heat_pump.heating_capacity_17F.nil?
        if [HPXML::HVACTypeHeatPumpAirToAir,
            HPXML::HVACTypeHeatPumpMiniSplit,
            HPXML::HVACTypeHeatPumpPTHP,
            HPXML::HVACTypeHeatPumpRoom].include? heat_pump.heat_pump_type
          if not heat_pump.heating_capacity_fraction_17F.nil?
            heat_pump.heating_capacity_17F = (heat_pump.heating_capacity * heat_pump.heating_capacity_fraction_17F).round
          else
            heat_pump.heating_capacity_17F = (heat_pump.heating_capacity * 0.6).round
          end
          heat_pump.heating_capacity_fraction_17F = nil
        end
      end

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
    hpxml_bldg.heating_systems.each do |heating_system|
      next unless heating_system.heating_system_type == HPXML::HVACTypeBoiler
      next unless heating_system.is_shared_system
      next unless heating_system.heating_capacity.nil?

      heating_system.heating_capacity = 300000
    end
    (hpxml_bldg.cooling_systems + hpxml_bldg.heat_pumps).each do |hvac_system|
      next unless hvac_system.cooling_efficiency_eer.nil? && hvac_system.cooling_efficiency_eer2.nil?
      next if hvac_system.cooling_efficiency_seer.nil? && hvac_system.cooling_efficiency_seer2.nil?

      orig_equipment_type = hvac_system.equipment_type
      hvac_system.equipment_type = HPXML::HVACEquipmentTypeSplit
      hvac_system.cooling_efficiency_eer2 = Defaults.get_hvac_eer2(hvac_system)
      if not hvac_system.cooling_efficiency_seer.nil? # Specify EER instead of EER2
        hvac_system.cooling_efficiency_eer = HVAC.calc_eer_from_eer2(hvac_system).round(1)
        hvac_system.cooling_efficiency_eer2 = nil
      else
        hvac_system.cooling_efficiency_eer2 = hvac_system.cooling_efficiency_eer2.round(1)
      end
      hvac_system.equipment_type = orig_equipment_type
    end
    hpxml_bldg.pv_systems.each do |pv_system|
      pv_system.is_shared_system = false if pv_system.is_shared_system.nil?
      pv_system.location = HPXML::LocationRoof if pv_system.location.nil?
      pv_system.module_type = HPXML::PVModuleTypeStandard if pv_system.module_type.nil?
      pv_system.tracking = HPXML::PVTrackingTypeFixed if pv_system.tracking.nil?
      pv_system.system_losses_fraction = 0.14 if pv_system.system_losses_fraction.nil?
      if pv_system.inverter.nil?
        if hpxml_bldg.inverters.empty?
          hpxml_bldg.inverters.add(id: 'Inverter1')
        end
        pv_system.inverter_idref = hpxml_bldg.inverters[0].id
      end
      pv_system.inverter.inverter_efficiency = 0.96 if pv_system.inverter.inverter_efficiency.nil?
    end
    hpxml_bldg.generators.each do |generator|
      generator.is_shared_system = false if generator.is_shared_system.nil?
    end
    hpxml_bldg.batteries.each do |battery|
      battery.is_shared_system = false if battery.is_shared_system.nil?
      battery.location = nil
      battery.round_trip_efficiency = 0.925
      battery.nominal_capacity_kwh = nil
    end
    n_htg_systems = (hpxml_bldg.heating_systems + hpxml_bldg.heat_pumps).select { |h| h.fraction_heat_load_served.to_f > 0 }.size
    n_clg_systems = (hpxml_bldg.cooling_systems + hpxml_bldg.heat_pumps).select { |h| h.fraction_cool_load_served.to_f > 0 }.size
    hpxml_bldg.hvac_distributions.each do |hvac_distribution|
      next unless hvac_distribution.conditioned_floor_area_served.nil?
      next unless hvac_distribution.distribution_system_type == HPXML::HVACDistributionTypeAir
      next unless hvac_distribution.ducts.size > 0

      n_hvac_systems = [n_htg_systems, n_clg_systems].max
      hvac_distribution.conditioned_floor_area_served = hpxml_bldg.building_construction.conditioned_floor_area / n_hvac_systems
    end

    hpxml_bldg.hvac_distributions.each do |hvac_distribution|
      next unless hvac_distribution.number_of_return_registers.nil?
      next unless hvac_distribution.distribution_system_type == HPXML::HVACDistributionTypeAir

      if hvac_distribution.ducts.select { |d| d.duct_type == HPXML::DuctTypeReturn }.size > 0
        hvac_distribution.number_of_return_registers = hpxml_bldg.building_construction.number_of_conditioned_floors.ceil
      elsif hvac_distribution.air_type != HPXML::AirTypeFanCoil
        hvac_distribution.number_of_return_registers = 0
      end
    end
    hpxml_bldg.water_heating_systems.each do |dhw_system|
      next unless dhw_system.tank_volume.nil?

      if dhw_system.water_heater_type == HPXML::WaterHeaterTypeStorage
        if dhw_system.fuel_type == HPXML::FuelTypeElectricity
          dhw_system.tank_volume = 40
        else
          dhw_system.tank_volume = 30
        end
      elsif dhw_system.water_heater_type == HPXML::WaterHeaterTypeHeatPump
        dhw_system.tank_volume = 80
      elsif dhw_system.water_heater_type == HPXML::WaterHeaterTypeCombiStorage
        dhw_system.tank_volume = 50
      end
    end
    # TODO: Allow UsageBin in 301validator and remove code below
    hpxml_bldg.water_heating_systems.each do |dhw_system|
      next if dhw_system.uniform_energy_factor.nil?
      next unless [HPXML::WaterHeaterTypeStorage, HPXML::WaterHeaterTypeHeatPump].include? dhw_system.water_heater_type
      next unless dhw_system.first_hour_rating.nil?

      dhw_system.first_hour_rating = 56.0
    end
    hpxml_bldg.hot_water_distributions.each do |hot_water_distribution|
      if hot_water_distribution.system_type == HPXML::DHWDistTypeStandard
        hot_water_distribution.standard_piping_length = 50.0 if hot_water_distribution.standard_piping_length.nil?
      elsif hot_water_distribution.system_type == HPXML::DHWDistTypeRecirc
        hot_water_distribution.recirculation_piping_loop_length = 50.0 if hot_water_distribution.recirculation_piping_loop_length.nil?
        hot_water_distribution.recirculation_branch_piping_length = 50.0 if hot_water_distribution.recirculation_branch_piping_length.nil?
        hot_water_distribution.recirculation_pump_power = 50.0 if hot_water_distribution.recirculation_pump_power.nil?
      end
    end
    hpxml_bldg.cooking_ranges.each do |cooking_range|
      next unless cooking_range.is_induction.nil?

      cooking_range.is_induction = false
    end
    (hpxml_bldg.clothes_washers +
     hpxml_bldg.clothes_dryers +
     hpxml_bldg.dishwashers +
     hpxml_bldg.refrigerators +
     hpxml_bldg.cooking_ranges).each do |appliance|
      next unless appliance.location.nil?

      appliance.location = HPXML::LocationConditionedSpace
    end
    zip_map = { 'USA_CO_Denver.Intl.AP.725650_TMY3.epw' => '80019',
                'USA_OR_Portland.Intl.AP.726980_TMY3.epw' => '97214',
                'US_CO_Boulder_AMY_2012.epw' => '80305-3447',
                'USA_MD_Baltimore-Washington.Intl.AP.724060_TMY3.epw' => '21221',
                'USA_TX_Dallas-Fort.Worth.Intl.AP.722590_TMY3.epw' => '75014',
                'USA_MN_Duluth.Intl.AP.727450_TMY3.epw' => '55807',
                'USA_MT_Helena.Rgnl.AP.727720_TMY3.epw' => '59602',
                'USA_HI_Honolulu.Intl.AP.911820_TMY3.epw' => '96817',
                'USA_FL_Miami.Intl.AP.722020_TMY3.epw' => '33134',
                'USA_AZ_Phoenix-Sky.Harbor.Intl.AP.722780_TMY3.epw' => '85001',
                'ZAF_Cape.Town.688160_IWEC.epw' => '00000' }
    hpxml_bldg.zip_code = zip_map[hpxml_bldg.climate_and_risk_zones.weather_station_epw_filepath]
    if hpxml_bldg.zip_code.nil?
      fail "#{hpxml_path}: EPW location (#{hpxml_bldg.climate_and_risk_zones.weather_station_epw_filepath}) not handled. Need to update zip_map."
    end

    if hpxml_bldg.climate_and_risk_zones.weather_station_epw_filepath.include? 'TMY3'
      # Test zipcode -> TMY3 lookup
      hpxml_bldg.climate_and_risk_zones.weather_station_id = nil
      hpxml_bldg.climate_and_risk_zones.weather_station_name = nil
      hpxml_bldg.climate_and_risk_zones.weather_station_epw_filepath = nil
    end

    if hpxml_path.include? 'base-location-capetown-zaf'
      if hpxml_bldg.state_code.nil?
        hpxml_bldg.state_code = 'NA'
      end
      hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs.add(year: 2006,
                                                               zone: '3A')
    end

    # Handle different inputs for ENERGY STAR/DENH

    if hpxml_path.include? 'base-bldgtype-mf-unit'
      hpxml.header.denh_calculation_versions = [DENH::MFVersions.select { |v| v.include?('MF') }.max_by { |v| v.scan(/\d+\.\d+/).first.to_f }]
    else
      hpxml.header.denh_calculation_versions = [DENH::SFVersions.select { |v| v.include?('SF') }.max_by { |v| v.scan(/\d+\.\d+/).first.to_f }]
    end
    if hpxml_path.include? 'base-bldgtype-mf-unit'
      hpxml.header.energystar_calculation_versions = [ES::MFVersions.select { |v| v.include?('MF_National') }.max_by { |v| v.scan(/\d+\.\d+/).first.to_f }]
    elsif hpxml_bldg.state_code == 'FL'
      hpxml.header.energystar_calculation_versions = [ES::SFVersions.select { |v| v.include?('SF_Florida') }.max_by { |v| v.scan(/\d+\.\d+/).first.to_f }]
    elsif hpxml_bldg.state_code == 'HI'
      hpxml.header.energystar_calculation_versions = [ES::SFVersions.select { |v| v.include?('SF_Pacific') }.max_by { |v| v.scan(/\d+\.\d+/).first.to_f }]
    elsif hpxml_bldg.state_code == 'OR'
      hpxml.header.energystar_calculation_versions = [ES::SFVersions.select { |v| v.include?('SF_OregonWashington') }.max_by { |v| v.scan(/\d+\.\d+/).first.to_f }]
    else
      hpxml.header.energystar_calculation_versions = [ES::SFVersions.select { |v| v.include?('SF_National') }.max_by { |v| v.scan(/\d+\.\d+/).first.to_f }]
    end
    hpxml_bldg.hvac_systems.each do |hvac_system|
      next if hvac_system.shared_loop_watts.nil?

      hvac_system.shared_loop_motor_efficiency = 0.9
    end
    hpxml_bldg.hot_water_distributions.each do |dhw_dist|
      next if dhw_dist.shared_recirculation_pump_power.nil?

      dhw_dist.shared_recirculation_motor_efficiency = 0.9
    end

    # Drop all thermostat setpoint info
    if not hpxml_bldg.hvac_controls.empty?
      control_type = hpxml_bldg.hvac_controls[0].control_type
      control_type = HPXML::HVACControlTypeManual if control_type.nil?
      control_id = hpxml_bldg.hvac_controls[0].id
      hpxml_bldg.hvac_controls[0].delete
      hpxml_bldg.hvac_controls.add(id: control_id,
                                   control_type: control_type)
    end

    XMLHelper.write_file(hpxml.to_doc, hpxml_path)
  end

  # Create additional files
  puts 'Creating additional HPXML files for OS-ERI...'

  # base-hvac-programmable-thermostat.xml
  hpxml = HPXML.new(hpxml_path: 'workflow/sample_files/base.xml')
  hpxml_bldg = hpxml.buildings[0]
  hpxml_bldg.hvac_controls[0].control_type = HPXML::HVACControlTypeProgrammable
  XMLHelper.write_file(hpxml.to_doc, 'workflow/sample_files/base-hvac-programmable-thermostat.xml')

  major_eri_versions = Constants::ERIVersions.select { |v| "#{v.to_i}" == v }
  latest_major_eri_versions = major_eri_versions.map { |mv| Constants::ERIVersions.select { |v| v.include?(mv) }.last }

  # All versions, single-family
  hpxml = HPXML.new(hpxml_path: 'workflow/sample_files/base.xml')
  hpxml_bldg = hpxml.buildings[0]
  hpxml.header.eri_calculation_versions = latest_major_eri_versions
  hpxml.header.co2index_calculation_versions = latest_major_eri_versions.select { |v| Constants::ERIVersions.index(v) >= Constants::ERIVersions.index('2019ABCD') }
  hpxml.header.iecc_eri_calculation_versions = IECC::AllVersions
  hpxml.header.energystar_calculation_versions = ES::SFVersions.select { |v| ES::NationalVersions.include?(v) }
  hpxml.header.denh_calculation_versions = DENH::SFVersions
  hpxml_bldg.clothes_dryers[0].control_type = HPXML::ClothesDryerControlTypeTimer # Need old input for clothes dryers
  XMLHelper.write_file(hpxml.to_doc, 'workflow/sample_files/base-versions-multiple-sf.xml')

  # All versions, multi-family
  hpxml = HPXML.new(hpxml_path: 'workflow/sample_files/base-bldgtype-mf-unit.xml')
  hpxml_bldg = hpxml.buildings[0]
  hpxml.header.eri_calculation_versions = latest_major_eri_versions
  hpxml.header.co2index_calculation_versions = latest_major_eri_versions.select { |v| Constants::ERIVersions.index(v) >= Constants::ERIVersions.index('2019ABCD') }
  hpxml.header.iecc_eri_calculation_versions = IECC::AllVersions
  hpxml.header.energystar_calculation_versions = ES::MFVersions.select { |v| ES::NationalVersions.include?(v) }
  hpxml.header.denh_calculation_versions = DENH::MFVersions
  hpxml_bldg.clothes_dryers[0].control_type = HPXML::ClothesDryerControlTypeTimer # Need old input for clothes dryers
  XMLHelper.write_file(hpxml.to_doc, 'workflow/sample_files/base-versions-multiple-mf.xml')

  # Additional ENERGY STAR files
  hpxml = HPXML.new(hpxml_path: 'workflow/sample_files/base-bldgtype-mf-unit.xml')
  hpxml_bldg = hpxml.buildings[0]
  hpxml.header.energystar_calculation_versions = [ES::MFVersions.select { |v| v.include?('MF_OregonWashington') }.max_by { |v| v.scan(/\d+\.\d+/).first.to_f }]
  hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs[0].zone = '4C'
  hpxml_bldg.state_code = 'OR'
  hpxml_bldg.zip_code = '97214'
  XMLHelper.write_file(hpxml.to_doc, 'workflow/sample_files/base-bldgtype-mf-unit-location-portland-or.xml')

  # Reformat real_homes HPXMLs
  puts 'Reformatting real_homes HPXMLs...'
  Dir['workflow/real_homes/*.xml'].each do |hpxml_path|
    hpxml = HPXML.new(hpxml_path: hpxml_path)
    hpxml.header.eri_calculation_versions = ['latest']
    hpxml.header.co2index_calculation_versions = ['latest']
    hpxml.header.iecc_eri_calculation_versions = [IECC::AllVersions[-1]]
    hpxml_bldg = hpxml.buildings[0]
    if hpxml_bldg.building_construction.residential_facility_type == HPXML::ResidentialTypeApartment
      hpxml.header.denh_calculation_versions = [DENH::MFVersions.select { |v| v.include?('MF') }.max_by { |v| v.scan(/\d+\.\d+/).first.to_f }]
      hpxml.header.energystar_calculation_versions = [ES::MFVersions.select { |v| v.include?('MF_National') }.max_by { |v| v.scan(/\d+\.\d+/).first.to_f }]
    else
      hpxml.header.denh_calculation_versions = [DENH::SFVersions.select { |v| v.include?('SF') }.max_by { |v| v.scan(/\d+\.\d+/).first.to_f }]
      hpxml.header.energystar_calculation_versions = [ES::SFVersions.select { |v| v.include?('SF_National') }.max_by { |v| v.scan(/\d+\.\d+/).first.to_f }]
    end
    XMLHelper.write_file(hpxml.to_doc, hpxml_path)
  end
end

command_list = [
  :update_measures,
  :update_hpxmls,
  :ruleset_tests,
  :sample_files_tests1,
  :sample_files_tests2,
  :real_home_tests,
  :other_tests,
  :create_release_zips
]

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
  # Apply rubocop (uses .rubocop.yml)
  commands = ["\"require 'rubocop/rake_task'\"",
              "\"require 'stringio' \"",
              "\"RuboCop::RakeTask.new(:rubocop) do |t| t.options = ['--autocorrect', '--format', 'simple'] end\"",
              '"Rake.application[:rubocop].invoke"']
  command = "#{OpenStudio.getOpenStudioCLI} -e #{commands.join(' -e ')}"
  puts 'Applying rubocop auto-correct to measures...'
  system(command)

  puts 'Done.'
end

if ARGV[0].to_sym == :update_hpxmls
  require 'oga'
  require_relative 'rulesets/resources/constants'

  t = Time.now
  create_test_hpxmls
  create_sample_hpxmls
  puts "Completed in #{(Time.now - t).round(1)}s"
end

if [:ruleset_tests, :sample_files_tests1, :sample_files_tests2, :real_home_tests, :other_tests].include? ARGV[0].to_sym
  case ARGV[0].to_sym
  when :ruleset_tests
    tests_rbs = Dir['rulesets/tests/*.rb']
  when :sample_files_tests1
    tests_rbs = Dir['workflow/tests/sample_files1_test.rb']
  when :sample_files_tests2
    tests_rbs = Dir['workflow/tests/sample_files2_test.rb']
  when :real_home_tests
    tests_rbs = Dir['workflow/tests/real_homes_test.rb']
  when :other_tests
    tests_rbs = Dir['workflow/tests/*test.rb'] - Dir['workflow/tests/real_homes_test.rb'] - Dir['workflow/tests/sample_files*test.rb']
  end

  # Run tests in random order; we don't want them to only
  # work when run in a specific order
  tests_rbs.shuffle!

  # Ensure we run all tests even if there are failures
  failed_tests = []
  tests_rbs.each do |test_rb|
    success = system("#{OpenStudio.getOpenStudioCLI} #{test_rb}")
    failed_tests << test_rb unless success
  end

  puts
  puts

  if not failed_tests.empty?
    puts 'The following tests FAILED:'
    failed_tests.each do |failed_test|
      puts "- #{failed_test}"
    end
    exit! 1
  end

  puts 'All tests passed.'
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
           'hpxml-measures/workflow/tests/util.rb',
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
