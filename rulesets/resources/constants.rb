# frozen_string_literal: true

module Constants
  CalcTypeCO2eRatedHome = 'CO2e Rated Home'
  CalcTypeCO2eReferenceHome = 'CO2e Reference Home'
  CalcTypeERIRatedHome = 'ERI Rated Home'
  CalcTypeERIReferenceHome = 'ERI Reference Home'
  CalcTypeERIIndexAdjustmentDesign = 'ERI Index Adjustment Design'
  CalcTypeERIIndexAdjustmentReferenceHome = 'ERI Index Adjustment Reference Home'
end

module ESConstants
  CalcTypeEnergyStarRated = 'ES Rated'
  CalcTypeEnergyStarReference = 'ES Reference'
  SFNationalVer3_0 = 'SF_National_3.0'
  SFNationalVer3_1 = 'SF_National_3.1'
  SFNationalVer3_2 = 'SF_National_3.2'
  SFPacificVer3_0 = 'SF_Pacific_3.0'
  SFFloridaVer3_1 = 'SF_Florida_3.1'
  SFOregonWashingtonVer3_2 = 'SF_OregonWashington_3.2'
  MFNationalVer1_0 = 'MF_National_1.0'
  MFNationalVer1_1 = 'MF_National_1.1'
  MFNationalVer1_2 = 'MF_National_1.2'
  MFOregonWashingtonVer1_2 = 'MF_OregonWashington_1.2'
  SFVersions = [SFNationalVer3_0, SFNationalVer3_1, SFNationalVer3_2, SFPacificVer3_0, SFFloridaVer3_1, SFOregonWashingtonVer3_2]
  MFVersions = [MFNationalVer1_0, MFNationalVer1_1, MFNationalVer1_2, MFOregonWashingtonVer1_2]
  NationalVersions = [SFNationalVer3_0, SFNationalVer3_1, SFNationalVer3_2, MFNationalVer1_0, MFNationalVer1_1, MFNationalVer1_2]
  AllVersions = SFVersions + MFVersions
end

module IECCConstants
  AllVersions = ['2015', '2018', '2021', '2024']
end

module ZERHConstants
  CalcTypeZERHRated = 'ZERH Rated'
  CalcTypeZERHReference = 'ZERH Reference'
  Ver1 = '1.0'
  SFVer2 = 'SF_2.0'
  MFVer2 = 'MF_2.0'
  AllVersions = [Ver1, SFVer2, MFVer2]
  SFVersions = [Ver1, SFVer2]
  MFVersions = [Ver1, MFVer2]
end
