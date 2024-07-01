# frozen_string_literal: true

module Constants
  def self.CalcTypeCO2eRatedHome
    return 'CO2e Rated Home'
  end

  def self.CalcTypeCO2eReferenceHome
    return 'CO2e Reference Home'
  end

  def self.CalcTypeERIRatedHome
    return 'ERI Rated Home'
  end

  def self.CalcTypeERIReferenceHome
    return 'ERI Reference Home'
  end

  def self.CalcTypeERIIndexAdjustmentDesign
    return 'ERI Index Adjustment Design'
  end

  def self.CalcTypeERIIndexAdjustmentReferenceHome
    return 'ERI Index Adjustment Reference Home'
  end
end

module ESConstants
  def self.CalcTypeEnergyStarRated
    return 'ES Rated'
  end

  def self.CalcTypeEnergyStarReference
    return 'ES Reference'
  end

  def self.AllVersions
    return self.SFVersions + self.MFVersions
  end

  def self.SFVersions
    return [self.SFNationalVer3_0, self.SFNationalVer3_1, self.SFNationalVer3_2, self.SFPacificVer3_0, self.SFFloridaVer3_1, self.SFOregonWashingtonVer3_2]
  end

  def self.MFVersions
    return [self.MFNationalVer1_0, self.MFNationalVer1_1, self.MFNationalVer1_2, self.MFOregonWashingtonVer1_2]
  end

  def self.NationalVersions
    return [self.SFNationalVer3_0, self.SFNationalVer3_1, self.SFNationalVer3_2, self.MFNationalVer1_0, self.MFNationalVer1_1, self.MFNationalVer1_2]
  end

  def self.SFNationalVer3_0
    return 'SF_National_3.0'
  end

  def self.SFNationalVer3_1
    return 'SF_National_3.1'
  end

  def self.SFNationalVer3_2
    return 'SF_National_3.2'
  end

  def self.SFPacificVer3_0
    return 'SF_Pacific_3.0'
  end

  def self.SFFloridaVer3_1
    return 'SF_Florida_3.1'
  end

  def self.SFOregonWashingtonVer3_2
    return 'SF_OregonWashington_3.2'
  end

  def self.MFNationalVer1_0
    return 'MF_National_1.0'
  end

  def self.MFNationalVer1_1
    return 'MF_National_1.1'
  end

  def self.MFNationalVer1_2
    return 'MF_National_1.2'
  end

  def self.MFOregonWashingtonVer1_2
    return 'MF_OregonWashington_1.2'
  end
end

module IECCConstants
  def self.AllVersions
    return ['2015', '2018', '2021']
  end
end

module ZERHConstants
  def self.CalcTypeZERHRated
    return 'ZERH Rated'
  end

  def self.CalcTypeZERHReference
    return 'ZERH Reference'
  end

  def self.AllVersions
    return [self.Ver1, self.SFVer2, self.MFVer2]
  end

  def self.SFVersions
    return [self.Ver1, self.SFVer2]
  end

  def self.MFVersions
    return [self.Ver1, self.MFVer2]
  end

  def self.Ver1
    return '1.0'
  end

  def self.SFVer2
    return 'SF_2.0'
  end

  def self.MFVer2
    return 'MF_2.0'
  end
end
