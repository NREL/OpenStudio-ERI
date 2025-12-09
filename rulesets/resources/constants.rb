# frozen_string_literal: true

module RunType
  ERI = 'ERI'
  CO2e = 'CO2e'
  IECC = 'IECC'
  ES = 'ES'
  DENH = 'DENH'
end

module CalcType
  RatedHome = 'Rated Home'
  ReferenceHome = 'Reference Home'
  IndexAdjHome = 'Index Adjustment Home'
  IndexAdjReferenceHome = 'Index Adjustment Reference Home'
end

module InitCalcType
  RatedHome = 'Rated Home'
  TargetHome = 'Target Home'
end

module IECC
  AllVersions = ['2015', '2018', '2021', '2024']
end

module ES
  SFNationalVer3_0 = 'SF_National_3.0'
  SFNationalVer3_1 = 'SF_National_3.1'
  SFNationalVer3_2 = 'SF_National_3.2'
  SFNationalVer3_3 = 'SF_National_3.3'
  SFPacificVer3_0 = 'SF_Pacific_3.0'
  SFFloridaVer3_1 = 'SF_Florida_3.1'
  SFOregonWashingtonVer3_2 = 'SF_OregonWashington_3.2'
  MFNationalVer1_0 = 'MF_National_1.0'
  MFNationalVer1_1 = 'MF_National_1.1'
  MFNationalVer1_2 = 'MF_National_1.2'
  MFNationalVer1_3 = 'MF_National_1.3'
  MFOregonWashingtonVer1_2 = 'MF_OregonWashington_1.2'
  SFVersions = [SFNationalVer3_0, SFNationalVer3_1, SFNationalVer3_2, SFNationalVer3_3, SFPacificVer3_0, SFFloridaVer3_1, SFOregonWashingtonVer3_2]
  MFVersions = [MFNationalVer1_0, MFNationalVer1_1, MFNationalVer1_2, MFNationalVer1_3, MFOregonWashingtonVer1_2]
  NationalVersions = [SFNationalVer3_0, SFNationalVer3_1, SFNationalVer3_2, SFNationalVer3_3, MFNationalVer1_0, MFNationalVer1_1, MFNationalVer1_2, MFNationalVer1_3]
  AllVersions = SFVersions + MFVersions
end

module DENH
  Ver1 = '1.0'
  SFVer2 = 'SF_2.0'
  MFVer2 = 'MF_2.0'
  AllVersions = [Ver1, SFVer2, MFVer2]
  SFVersions = [Ver1, SFVer2]
  MFVersions = [Ver1, MFVer2]
end
